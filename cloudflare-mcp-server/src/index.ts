import OAuthProvider from "@cloudflare/workers-oauth-provider";
import { McpAgent } from "agents/mcp";
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { GitHubHandler } from "./github-handler";
import type { Props } from "./utils";

/**
 * MCP Proxy Server
 *
 * This McpAgent doesn't implement tools directly - instead it proxies
 * all MCP requests to the Hetzner server. We need to extend McpAgent
 * so that OAuthProvider can properly manage tokens via Durable Objects.
 */
export class ObsidianMcpProxy extends McpAgent<Env, {}, Props> {
	server = new McpServer({
		name: "Obsidian MCP Proxy",
		version: "1.0.0",
	});

	async init() {
		this.server.tool(
			"ping",
			"Test connectivity to the Obsidian MCP server",
			{},
			async () => {
				try {
					const response = await fetch(
						`${this.env.HETZNER_MCP_URL || "https://REDACTED_DOMAIN"}/mcp`,
						{
							method: "POST",
							headers: {
								"Content-Type": "application/json",
							},
							body: JSON.stringify({
								jsonrpc: "2.0",
								id: 1,
								method: "ping",
								params: {},
							}),
						},
					);
					const status = response.ok ? "connected" : `error: ${response.status}`;
					return {
						content: [
							{
								type: "text",
								text: `Hetzner MCP server status: ${status}`,
							},
						],
					};
				} catch (error: any) {
					return {
						content: [
							{
								type: "text",
								text: `Connection error: ${error.message}`,
							},
						],
					};
				}
			},
		);
	}
}

// Export the OAuth Provider
export default new OAuthProvider({
	apiHandler: ObsidianMcpProxy.serve("/mcp"),
	apiRoute: "/mcp",
	authorizeEndpoint: "/authorize",
	clientRegistrationEndpoint: "/register",
	defaultHandler: GitHubHandler as any,
	tokenEndpoint: "/token",
});
