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

  # Obsidian Web GUI HTTP (IPv4)
  dynamic "rule" {
    for_each = var.enable_ipv4 ? [1] : []
    content {
      direction  = "in"
      protocol   = "tcp"
      port       = "3000"
      source_ips = var.firewall_allowed_ips
    }
  }

  # Obsidian Web GUI HTTP (IPv6)
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "3000"
    source_ips = var.firewall_allowed_ipv6
  }

  # Obsidian Web GUI HTTPS (IPv4)
  dynamic "rule" {
    for_each = var.enable_ipv4 ? [1] : []
    content {
      direction  = "in"
      protocol   = "tcp"
      port       = "3001"
      source_ips = var.firewall_allowed_ips
    }
  }

  # Obsidian Web GUI HTTPS (IPv6)
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "3001"
    source_ips = var.firewall_allowed_ipv6
  }

  # MCP Server (IPv4)
  dynamic "rule" {
    for_each = var.enable_ipv4 ? [1] : []
    content {
      direction  = "in"
      protocol   = "tcp"
      port       = "3002"
      source_ips = var.firewall_allowed_ips
    }
  }

  # MCP Server (IPv6)
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "3002"
    source_ips = var.firewall_allowed_ipv6
  }

  # Note: Port 27123 (Obsidian REST API) intentionally NOT exposed
  # It's only accessible within the Docker network for security
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
    vnc_password   = var.vnc_password
    mcp_jwt_secret = var.mcp_jwt_secret
  })

  labels = {
    purpose = "obsidian-mcp"
    managed = "terraform"
  }
}
