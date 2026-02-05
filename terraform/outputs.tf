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
  description = "MCP Server endpoint URL (HTTPS via Caddy)"
  value       = "https://${var.mcp_domain}"
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
    ║  MCP Endpoint: https://${var.mcp_domain}
    ║  Web GUI: https://${local.server_ip_url}:3001
    ║                                                                ║
    ║  1. Ensure DNS for ${var.mcp_domain} points to ${local.server_ip}
    ║                                                                ║
    ║  2. Wait 3-5 minutes for containers + SSL certificate          ║
    ║                                                                ║
    ║  3. Open Web GUI and log in (user: admin)                      ║
    ║                                                                ║
    ║  4. Log in to Obsidian Sync manually                           ║
    ║                                                                ║
    ║  5. Install "Local REST API" plugin:                           ║
    ║     - Enable "Bind to all interfaces" (0.0.0.0)                ║
    ║     - Copy the API key                                         ║
    ║                                                                ║
    ║  6. Run "Configure API Key" workflow                           ║
    ║                                                                ║
    ║  7. Add MCP connector in Claude.ai:                             ║
    ║     Server URL: https://${var.mcp_domain}/mcp
    ║                                                                ║
    ╚════════════════════════════════════════════════════════════════╝
  EOT
}
