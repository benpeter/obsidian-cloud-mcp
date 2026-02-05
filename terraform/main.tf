# SSH Key
resource "hcloud_ssh_key" "default" {
  name       = "${var.server_name}-key"
  public_key = var.ssh_public_key
}

# Firewall
resource "hcloud_firewall" "obsidian" {
  name = "${var.server_name}-firewall"

  # SSH (IPv4)
  dynamic "rule" {
    for_each = var.enable_ipv4 ? [1] : []
    content {
      direction  = "in"
      protocol   = "tcp"
      port       = "22"
      source_ips = var.firewall_allowed_ips
    }
  }

  # SSH (IPv6)
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22"
    source_ips = var.firewall_allowed_ipv6
  }

  # HTTP for ACME/Let's Encrypt (IPv4)
  dynamic "rule" {
    for_each = var.enable_ipv4 ? [1] : []
    content {
      direction  = "in"
      protocol   = "tcp"
      port       = "80"
      source_ips = ["0.0.0.0/0"]  # Must be open for Let's Encrypt
    }
  }

  # HTTP for ACME/Let's Encrypt (IPv6)
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "80"
    source_ips = ["::/0"]  # Must be open for Let's Encrypt
  }

  # HTTPS - MCP Server via Caddy (IPv4)
  dynamic "rule" {
    for_each = var.enable_ipv4 ? [1] : []
    content {
      direction  = "in"
      protocol   = "tcp"
      port       = "443"
      source_ips = ["0.0.0.0/0"]  # Claude.ai needs access
    }
  }

  # HTTPS - MCP Server via Caddy (IPv6)
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "443"
    source_ips = ["::/0"]  # Claude.ai needs access
  }

  # Obsidian Web GUI HTTPS (IPv4) - restricted access
  dynamic "rule" {
    for_each = var.enable_ipv4 ? [1] : []
    content {
      direction  = "in"
      protocol   = "tcp"
      port       = "3001"
      source_ips = var.firewall_allowed_ips
    }
  }

  # Obsidian Web GUI HTTPS (IPv6) - restricted access
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "3001"
    source_ips = var.firewall_allowed_ipv6
  }

  # Note: Port 27123 (Obsidian REST API) intentionally NOT exposed
  # Note: Port 3002 removed - MCP now accessible via Caddy on 443
}

# Server
resource "hcloud_server" "obsidian" {
  name        = var.server_name
  server_type = var.server_type
  location    = var.server_location
  image       = var.server_image

  ssh_keys = [hcloud_ssh_key.default.id]

  firewall_ids = [hcloud_firewall.obsidian.id]

  public_net {
    ipv4_enabled = var.enable_ipv4
    ipv6_enabled = true
  }

  user_data = templatefile("${path.module}/../scripts/cloud-init.yml", {
    vnc_password          = var.vnc_password
    mcp_domain            = var.mcp_domain
    cloudflare_worker_url = var.cloudflare_worker_url
  })

  labels = {
    purpose = "obsidian-mcp"
    managed = "terraform"
  }
}
