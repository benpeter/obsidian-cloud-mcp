locals {
  # Use IPv4 if available, otherwise use IPv6 with brackets for URLs
  server_ip     = var.enable_ipv4 ? hcloud_server.obsidian.ipv4_address : hcloud_server.obsidian.ipv6_address
  server_ip_url = var.enable_ipv4 ? hcloud_server.obsidian.ipv4_address : "[${hcloud_server.obsidian.ipv6_address}]"
}

output "server_ipv4" {
  description = "Public IPv4 address of the server (if enabled)"
  value       = var.enable_ipv4 ? hcloud_server.obsidian.ipv4_address : "IPv4 disabled"
}

output "server_ipv6" {
  description = "Public IPv6 address of the server"
  value       = hcloud_server.obsidian.ipv6_address
}

output "ssh_command" {
  description = "SSH command to connect to the server"
  value       = var.enable_ipv4 ? "ssh root@${hcloud_server.obsidian.ipv4_address}" : "ssh root@${hcloud_server.obsidian.ipv6_address}"
}

output "vnc_url" {
  description = "URL for VNC access to Obsidian GUI (after Docker starts)"
  value       = "https://${local.server_ip_url}:3001"
}

output "mcp_endpoint" {
  description = "MCP Server endpoint URL"
  value       = "http://${local.server_ip_url}:3002"
}

output "ip_mode" {
  description = "IP configuration mode"
  value       = var.enable_ipv4 ? "IPv4 + IPv6 (Dual Stack)" : "IPv6 Only (saves €0.50/month)"
}

output "next_steps" {
  description = "Instructions for completing setup"
  value       = <<-EOT

    ╔════════════════════════════════════════════════════════════════╗
    ║                    DEPLOYMENT COMPLETE                         ║
    ╠════════════════════════════════════════════════════════════════╣
    ║                                                                ║
    ║  IP Mode: ${var.enable_ipv4 ? "Dual Stack (IPv4 + IPv6)" : "IPv6 Only"}
    ║                                                                ║
    ║  1. Wait 2-3 minutes for Docker containers to start            ║
    ║                                                                ║
    ║  2. Open VNC in browser:                                       ║
    ║     https://${local.server_ip_url}:3001
    ║                                                                ║
    ║  3. Login to Obsidian Sync manually                            ║
    ║                                                                ║
    ║  4. Install "Local REST API" plugin:                            ║
    ║     - Enable "Bind to all interfaces" (0.0.0.0)                ║
    ║     - Copy the API key                                         ║
    ║                                                                ║
    ║  5. SSH to server, add API key to /opt/obsidian-mcp/.env       ║
    ║                                                                ║
    ║  6. Restart MCP server: docker compose restart mcp-server      ║
    ║                                                                ║
    ╚════════════════════════════════════════════════════════════════╝
  EOT
}
