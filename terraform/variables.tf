variable "hcloud_token" {
  description = "Hetzner Cloud API Token"
  type        = string
  sensitive   = true
}

variable "server_name" {
  description = "Name of the server"
  type        = string
  default     = "obsidian-mcp"
}

variable "server_type" {
  description = "Hetzner server type (cx23 = 2 vCPU, 4GB RAM, ~€3.56/month)"
  type        = string
  default     = "cx23"
}

variable "server_location" {
  description = "Server location (nbg1 = Nuremberg, fsn1 = Falkenstein, hel1 = Helsinki)"
  type        = string
  default     = "nbg1"
}

variable "server_image" {
  description = "Server OS image"
  type        = string
  default     = "ubuntu-24.04"
}

variable "ssh_public_key" {
  description = "SSH public key for server access"
  type        = string
}

variable "vnc_password" {
  description = "Password for VNC/Web GUI access to Obsidian"
  type        = string
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Domain & HTTPS
# -----------------------------------------------------------------------------

variable "mcp_domain" {
  description = "Domain name for MCP server (e.g., mcp.example.com). Required for HTTPS."
  type        = string
}

# -----------------------------------------------------------------------------
# Cloudflare Worker (OAuth + Token Introspection)
# -----------------------------------------------------------------------------

variable "cloudflare_worker_url" {
  description = "URL of the Cloudflare Worker that handles OAuth and token introspection (e.g., https://your-worker.workers.dev)"
  type        = string
}

# -----------------------------------------------------------------------------
# Firewall
# -----------------------------------------------------------------------------

variable "firewall_allowed_ips" {
  description = "List of IPv4 addresses/ranges allowed to access SSH and Web GUI (CIDR notation). Use 0.0.0.0/0 for any."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "firewall_allowed_ipv6" {
  description = "List of IPv6 addresses/ranges allowed to access SSH and Web GUI (CIDR notation). Use ::/0 for any."
  type        = list(string)
  default     = ["::/0"]
}

variable "enable_ipv4" {
  description = "Enable IPv4 address (costs +€0.50/month). Set to false for IPv6-only."
  type        = bool
  default     = true
}
