output "server_ip" {
  description = "Public IP address of the server"
  value       = hcloud_server.obsidian.ipv4_address
}

output "ssh_command" {
  description = "SSH command to connect to the server"
  value       = "ssh root@${hcloud_server.obsidian.ipv4_address}"
}

output "vnc_url" {
  description = "URL for VNC access to Obsidian GUI (after Docker starts)"
  value       = "https://${hcloud_server.obsidian.ipv4_address}:3001"
}

output "mcp_endpoint" {
  description = "MCP Server endpoint URL"
  value       = "http://${hcloud_server.obsidian.ipv4_address}:3002"
}

output "obsidian_rest_api" {
  description = "Obsidian REST API endpoint (internal, for testing)"
  value       = "http://${hcloud_server.obsidian.ipv4_address}:27123"
}

output "next_steps" {
  description = "Instructions for completing setup"
  value       = <<-EOT

    ╔════════════════════════════════════════════════════════════════╗
    ║                    DEPLOYMENT COMPLETE                         ║
    ╠════════════════════════════════════════════════════════════════╣
    ║                                                                ║
    ║  1. Wait 2-3 minutes for Docker containers to start            ║
    ║                                                                ║
    ║  2. Open VNC in browser:                                       ║
    ║     https://${hcloud_server.obsidian.ipv4_address}:3001
    ║                                                                ║
    ║  3. Login to Obsidian Sync manually                            ║
    ║                                                                ║
    ║  4. Install & configure "Local REST API" plugin                ║
    ║                                                                ║
    ║  5. Copy API key to /opt/obsidian-mcp/.env on server           ║
    ║                                                                ║
    ║  6. Restart MCP server: docker compose restart mcp-server      ║
    ║                                                                ║
    ╚════════════════════════════════════════════════════════════════╝
  EOT
}
