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
  description = "Hetzner server type (cx22 = 2 vCPU, 4GB RAM, ~€4/month)"
  type        = string
  default     = "cx22"
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
  description = "Password for VNC access to Obsidian GUI"
  type        = string
  sensitive   = true
}

variable "firewall_allowed_ips" {
  description = "List of IP addresses/ranges allowed to access the server (CIDR notation). Use 0.0.0.0/0 for any."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
