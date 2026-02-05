# SSH Key
resource "hcloud_ssh_key" "default" {
  name       = "${var.server_name}-key"
  public_key = var.ssh_public_key
}

# Firewall
resource "hcloud_firewall" "obsidian" {
  name = "${var.server_name}-firewall"

  # SSH
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22"
    source_ips = var.firewall_allowed_ips
  }

  # Obsidian Web GUI (HTTP)
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "3000"
    source_ips = var.firewall_allowed_ips
  }

  # Obsidian Web GUI (HTTPS) - Primary VNC access
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "3001"
    source_ips = var.firewall_allowed_ips
  }

  # MCP Server
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "3002"
    source_ips = var.firewall_allowed_ips
  }

  # Obsidian REST API (optional, for direct testing)
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "27123"
    source_ips = var.firewall_allowed_ips
  }
}

# Server
resource "hcloud_server" "obsidian" {
  name        = var.server_name
  server_type = var.server_type
  location    = var.server_location
  image       = var.server_image

  ssh_keys = [hcloud_ssh_key.default.id]

  firewall_ids = [hcloud_firewall.obsidian.id]

  user_data = templatefile("${path.module}/../scripts/cloud-init.yml", {
    vnc_password = var.vnc_password
  })

  labels = {
    purpose = "obsidian-mcp"
    managed = "terraform"
  }
}
