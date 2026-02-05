// Augment the global Env interface with secrets and custom vars
// These are not in wrangler.jsonc but are set via `wrangler secret put`

declare global {
	namespace Cloudflare {
		interface Env {
			// Secrets (set via wrangler secret put)
			GITHUB_CLIENT_ID: string;
			GITHUB_CLIENT_SECRET: string;
			COOKIE_ENCRYPTION_KEY: string;
			MCP_PROXY_SECRET: string;
		}
	}
}

export {};
