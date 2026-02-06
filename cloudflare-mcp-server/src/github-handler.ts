import { env } from "cloudflare:workers";
import type { AuthRequest, OAuthHelpers } from "@cloudflare/workers-oauth-provider";
import { Hono } from "hono";
import { Octokit } from "octokit";
import { fetchUpstreamAuthToken, getUpstreamAuthorizeUrl, type Props } from "./utils";
import {
	addApprovedClient,
	bindStateToSession,
	createOAuthState,
	generateCSRFProtection,
	isClientApproved,
	OAuthError,
	renderApprovalDialog,
	validateCSRFToken,
	validateOAuthState,
} from "./workers-oauth-utils";

/**
 * Check if an email is in the allowed list stored in KV.
 * KV key format: allowed_email:<email>
 */
async function isEmailAllowed(kv: KVNamespace, email: string): Promise<boolean> {
	const value = await kv.get(`allowed_email:${email.toLowerCase()}`);
	return value !== null;
}

const app = new Hono<{ Bindings: Env & { OAUTH_PROVIDER: OAuthHelpers } }>();

/**
 * Homepage - simple info page
 */
app.get("/", async (c) => {
	return c.html(`
		<!DOCTYPE html>
		<html>
		<head>
			<title>Obsidian MCP OAuth Proxy</title>
			<style>
				body { font-family: system-ui; max-width: 600px; margin: 50px auto; padding: 20px; }
				h1 { color: #7c3aed; }
				code { background: #f3f4f6; padding: 2px 6px; border-radius: 4px; }
			</style>
		</head>
		<body>
			<h1>🔮 Obsidian MCP Server</h1>
			<p>This is an OAuth-protected MCP server for Obsidian.</p>
			<p>Connect via Claude.ai Custom Connectors using:</p>
			<code>${new URL(c.req.url).origin}/mcp</code>
		</body>
		</html>
	`);
});

/**
 * RFC 9470 - OAuth 2.0 Protected Resource Metadata
 * Required by MCP auth spec for client discovery
 */
app.get("/.well-known/oauth-protected-resource", async (c) => {
	const baseUrl = new URL(c.req.url).origin;
	return c.json({
		resource: baseUrl,
		authorization_servers: [baseUrl],
		// MCP uses Bearer tokens
		bearer_methods_supported: ["header"],
	});
});

app.get("/authorize", async (c) => {
	const oauthReqInfo = await c.env.OAUTH_PROVIDER.parseAuthRequest(c.req.raw);
	const { clientId } = oauthReqInfo;
	if (!clientId) {
		return c.text("Invalid request", 400);
	}

	// Check if client is already approved
	if (await isClientApproved(c.req.raw, clientId, env.COOKIE_ENCRYPTION_KEY)) {
		// Skip approval dialog but still create secure state and bind to session
		const { stateToken } = await createOAuthState(oauthReqInfo, c.env.OAUTH_KV);
		const { setCookie: sessionBindingCookie } = await bindStateToSession(stateToken);
		return redirectToGithub(c.req.raw, stateToken, { "Set-Cookie": sessionBindingCookie });
	}

	// Generate CSRF protection for the approval form
	const { token: csrfToken, setCookie } = generateCSRFProtection();

	return renderApprovalDialog(c.req.raw, {
		client: await c.env.OAUTH_PROVIDER.lookupClient(clientId),
		csrfToken,
		server: {
			description: "OAuth-protected MCP server for Obsidian, authenticated via GitHub.",
			logo: "https://avatars.githubusercontent.com/u/314135?s=200&v=4",
			name: "Obsidian MCP Server",
		},
		setCookie,
		state: { oauthReqInfo },
	});
});

app.post("/authorize", async (c) => {
	try {
		// Read form data once
		const formData = await c.req.raw.formData();

		// Validate CSRF token
		validateCSRFToken(formData, c.req.raw);

		// Extract state from form data
		const encodedState = formData.get("state");
		if (!encodedState || typeof encodedState !== "string") {
			return c.text("Missing state in form data", 400);
		}

		let state: { oauthReqInfo?: AuthRequest };
		try {
			state = JSON.parse(atob(encodedState));
		} catch (_e) {
			return c.text("Invalid state data", 400);
		}

		if (!state.oauthReqInfo || !state.oauthReqInfo.clientId) {
			return c.text("Invalid request", 400);
		}

		// Add client to approved list
		const approvedClientCookie = await addApprovedClient(
			c.req.raw,
			state.oauthReqInfo.clientId,
			c.env.COOKIE_ENCRYPTION_KEY,
		);

		// Create OAuth state and bind it to this user's session
		const { stateToken } = await createOAuthState(state.oauthReqInfo, c.env.OAUTH_KV);
		const { setCookie: sessionBindingCookie } = await bindStateToSession(stateToken);

		// Set both cookies: approved client list + session binding
		const headers = new Headers();
		headers.append("Set-Cookie", approvedClientCookie);
		headers.append("Set-Cookie", sessionBindingCookie);

		return redirectToGithub(c.req.raw, stateToken, Object.fromEntries(headers));
	} catch (error: any) {
		console.error("POST /authorize error:", error);
		if (error instanceof OAuthError) {
			return error.toResponse();
		}
		// Unexpected non-OAuth error
		return c.text(`Internal server error: ${error.message}`, 500);
	}
});

async function redirectToGithub(
	request: Request,
	stateToken: string,
	headers: Record<string, string> = {},
) {
	return new Response(null, {
		headers: {
			...headers,
			location: getUpstreamAuthorizeUrl({
				client_id: env.GITHUB_CLIENT_ID,
				redirect_uri: new URL("/callback", request.url).href,
				// Need user:email to fetch verified emails for authorization check
				scope: "read:user user:email",
				state: stateToken,
				upstream_url: "https://github.com/login/oauth/authorize",
			}),
		},
		status: 302,
	});
}

/**
 * OAuth Callback Endpoint
 *
 * This route handles the callback from GitHub after user authentication.
 * It exchanges the temporary code for an access token, then stores some
 * user metadata & the auth token as part of the 'props' on the token passed
 * down to the client. It ends by redirecting the client back to _its_ callback URL
 *
 * SECURITY: This endpoint validates that the state parameter from GitHub
 * matches both:
 * 1. A valid state token in KV (proves it was created by our server)
 * 2. The __Host-CONSENTED_STATE cookie (proves THIS browser consented to it)
 *
 * This prevents CSRF attacks where an attacker's state token is injected
 * into a victim's OAuth flow.
 */
app.get("/callback", async (c) => {
	// Validate OAuth state with session binding
	// This checks both KV storage AND the session cookie
	let oauthReqInfo: AuthRequest;
	let clearSessionCookie: string;

	try {
		const result = await validateOAuthState(c.req.raw, c.env.OAUTH_KV);
		oauthReqInfo = result.oauthReqInfo;
		clearSessionCookie = result.clearCookie;
	} catch (error: any) {
		if (error instanceof OAuthError) {
			return error.toResponse();
		}
		// Unexpected non-OAuth error
		return c.text("Internal server error", 500);
	}

	if (!oauthReqInfo.clientId) {
		return c.text("Invalid OAuth request data", 400);
	}

	// Exchange the code for an access token
	const [accessToken, errResponse] = await fetchUpstreamAuthToken({
		client_id: c.env.GITHUB_CLIENT_ID,
		client_secret: c.env.GITHUB_CLIENT_SECRET,
		code: c.req.query("code"),
		redirect_uri: new URL("/callback", c.req.url).href,
		upstream_url: "https://github.com/login/oauth/access_token",
	});
	if (errResponse) return errResponse;

	// Fetch the user info from GitHub
	const octokit = new Octokit({ auth: accessToken });
	const user = await octokit.rest.users.getAuthenticated();
	const { login, name, email } = user.data;

	// Also fetch the user's emails to find a verified primary email
	// (public profile email might be null if user hasn't set one public)
	let verifiedEmail = email;
	if (!verifiedEmail) {
		try {
			const emailsResponse = await octokit.rest.users.listEmailsForAuthenticatedUser();
			const primaryEmail = emailsResponse.data.find((e) => e.primary && e.verified);
			if (primaryEmail) {
				verifiedEmail = primaryEmail.email;
			}
		} catch (e) {
			console.log("Could not fetch user emails (might need user:email scope):", e);
		}
	}

	// Check if user's email is in the allowed list (stored in KV)
	if (!verifiedEmail || !(await isEmailAllowed(c.env.OAUTH_KV, verifiedEmail))) {
		console.log(`Access denied for email: ${verifiedEmail || "unknown"} (login: ${login})`);
		return c.html(
			`<!DOCTYPE html>
			<html>
			<head><title>Access Denied</title></head>
			<body style="font-family: system-ui; padding: 2rem; text-align: center;">
				<h1>🚫 Access Denied</h1>
				<p>Your GitHub account (${login}) is not authorized to access this MCP server.</p>
				<p style="color: #666;">Contact the administrator if you believe this is an error.</p>
			</body>
			</html>`,
			403,
		);
	}

	console.log(`Access granted for ${verifiedEmail} (login: ${login})`);

	// Return back to the MCP client a new token
	const { redirectTo } = await c.env.OAUTH_PROVIDER.completeAuthorization({
		metadata: {
			label: name,
		},
		// This will be available on this.props inside MyMCP
		props: {
			accessToken,
			email,
			login,
			name,
		} as Props,
		request: oauthReqInfo,
		scope: oauthReqInfo.scope,
		userId: login,
	});

	// Clear the session binding cookie (one-time use) by creating response with headers
	const headers = new Headers({ Location: redirectTo });
	if (clearSessionCookie) {
		headers.set("Set-Cookie", clearSessionCookie);
	}

	return new Response(null, {
		status: 302,
		headers,
	});
});

/**
 * Token Introspection Endpoint (RFC 7662)
 * Allows resource servers to validate opaque tokens
 *
 * The token format used by @cloudflare/workers-oauth-provider is:
 * userId:grantId:tokenValue
 *
 * Tokens are stored in KV with key: token:${userId}:${grantId}:${sha256(token)}
 */
app.post("/introspect", async (c) => {
	const formData = await c.req.formData();
	const token = formData.get("token")?.toString();

	if (!token) {
		return c.json({ active: false }, 200);
	}

	// Parse the token format: userId:grantId:tokenValue
	const parts = token.split(":");
	if (parts.length !== 3) {
		return c.json({ active: false }, 200);
	}

	const [userId, grantId] = parts;

	// Generate the token ID (SHA-256 hash of the full token)
	const encoder = new TextEncoder();
	const data = encoder.encode(token);
	const hashBuffer = await crypto.subtle.digest("SHA-256", data);
	const hashArray = Array.from(new Uint8Array(hashBuffer));
	const tokenId = hashArray.map((b) => b.toString(16).padStart(2, "0")).join("");

	// Look up the token in KV
	const tokenKey = `token:${userId}:${grantId}:${tokenId}`;
	const tokenData = await c.env.OAUTH_KV.get(tokenKey, { type: "json" });

	if (!tokenData) {
		console.log(`Token not found in KV: ${tokenKey}`);
		return c.json({ active: false }, 200);
	}

	// Type assertion for token data structure
	const info = tokenData as {
		expiresAt: number;
		createdAt: number;
		userId: string;
		grant: {
			clientId: string;
			scope: string[];
		};
	};

	// Check if token is expired
	if (info.expiresAt * 1000 < Date.now()) {
		console.log(`Token expired: ${tokenKey}`);
		return c.json({ active: false }, 200);
	}

	console.log(`Token introspection successful for user: ${info.userId}`);

	// Return RFC 7662 compliant response
	return c.json({
		active: true,
		client_id: info.grant.clientId,
		scope: info.grant.scope.join(" "),
		sub: info.userId,
		exp: info.expiresAt,
		iat: info.createdAt,
		token_type: "Bearer",
	});
});

export { app as GitHubHandler };
