# Obsidian Cloud MCP

Deploy an Obsidian MCP Server in the cloud with Obsidian Sync support.

## What is this?

This repository provides Infrastructure-as-Code to deploy a cloud-based [Obsidian](https://obsidian.md) instance with an MCP (Model Context Protocol) server. This allows AI assistants like Claude to access your Obsidian vault from anywhere.

**The Problem:** Obsidian runs locally, so AI assistants can't access your vault when you're on mobile or using cloud-based AI interfaces.

**The Solution:** Run Obsidian in the cloud with Sync enabled, and expose it via an MCP server.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         Cloud Server                         │
│  ┌─────────────────┐     ┌─────────────────────────────┐   │
│  │    Obsidian     │────▶│    MCP Server               │   │
│  │  (GUI via VNC)  │     │  (cyanheads/obsidian-mcp)   │   │
│  │                 │     │                             │   │
│  │  + Obsidian     │     │  Exposes vault via          │   │
│  │    Sync         │     │  Model Context Protocol     │   │
│  │  + REST API     │     │                             │   │
│  │    Plugin       │     │                             │   │
│  └─────────────────┘     └─────────────────────────────┘   │
│         :3001                      :3002                    │
└─────────────────────────────────────────────────────────────┘
                               │
                               ▼
                    ┌─────────────────┐
                    │   Claude / AI   │
                    │   (via MCP)     │
                    └─────────────────┘
```

## Important Limitation

**Obsidian Sync requires a one-time manual login via VNC.** There is no headless CLI authentication for Obsidian Sync.

- Infrastructure deployment = fully automated ✅
- Docker container start = fully automated ✅
- **First Obsidian Sync login = MANUAL via browser/VNC** ⚠️

After the initial login, Sync runs automatically.

## Prerequisites

1. **Hetzner Cloud Account** - [Sign up here](https://console.hetzner.cloud/)
2. **Obsidian Sync License** - [Get it here](https://obsidian.md/sync)
3. **Terraform** installed locally (optional, for local deployment)
4. **SSH Key Pair** for server access

## Quick Start

### Option A: GitHub Actions (Recommended)

1. **Fork this repository**

2. **Add GitHub Secrets:**
   - `HCLOUD_TOKEN` - Your Hetzner API token
   - `SSH_PUBLIC_KEY` - Your SSH public key
   - `SSH_PRIVATE_KEY` - Your SSH private key (for updates)
   - `VNC_PASSWORD` - Password for VNC access (min 6 chars)

3. **Run the Deploy workflow:**
   - Go to Actions → Deploy Infrastructure → Run workflow
   - Wait for completion (~3-5 minutes)

4. **Complete manual setup:**
   - Open the VNC URL from the workflow output
   - Log in to Obsidian Sync
   - Install "Local REST API" plugin
   - **Important:** Enable "Bind to all network interfaces" in plugin settings
   - Copy the API key

5. **Configure the API key:**
   - Go to Actions → Configure API Key → Run workflow
   - Enter your API key
   - The workflow will configure the server and restart the MCP server

### Option B: Local Terraform

1. **Clone and configure:**
   ```bash
   git clone https://github.com/YOUR_USERNAME/obsidian-cloud-mcp.git
   cd obsidian-cloud-mcp/terraform
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

2. **Deploy:**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

3. **Complete manual setup** (same as Option A, steps 4-5)

## Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `hcloud_token` | Hetzner API token | (required) |
| `ssh_public_key` | SSH public key | (required) |
| `vnc_password` | VNC access password | (required) |
| `server_type` | Hetzner server type | `cx23` |
| `server_location` | Server location | `nbg1` |
| `enable_ipv4` | Enable IPv4 (adds €0.50/month) | `true` |
| `firewall_allowed_ips` | Allowed IPv4 ranges | `["0.0.0.0/0"]` |
| `firewall_allowed_ipv6` | Allowed IPv6 ranges | `["::/0"]` |

## Server Types

| Type | Specs | Monthly Cost |
|------|-------|--------------|
| `cx23` | 2 vCPU, 4 GB RAM | ~€3.56 |
| `cx33` | 4 vCPU, 8 GB RAM | ~€5.94 |

**Note:** Add €0.50/month for IPv4 address. IPv6-only is supported if you have IPv6 connectivity.

## GitHub Workflows

| Workflow | Description |
|----------|-------------|
| **Deploy Infrastructure** | Creates the Hetzner server with Obsidian + MCP |
| **Configure API Key** | Sets the REST API key on the server |
| **Update Docker Images** | Pulls latest images and restarts containers |
| **Destroy Infrastructure** | Removes all cloud resources |

## Post-Deployment Setup

1. **Access Obsidian GUI:**
   ```
   https://YOUR_SERVER_IP:3001
   ```
   (Accept the self-signed certificate warning)

2. **Login to Obsidian:**
   - Open Obsidian
   - Go to Settings → Core plugins → Enable Sync
   - Log in with your Obsidian account
   - Select your vault to sync

3. **Install REST API Plugin:**
   - Go to Settings → Community plugins
   - Browse and install "Local REST API"
   - Enable the plugin
   - **Important:** Enable "Bind to all network interfaces" (0.0.0.0)
   - Copy the API key from plugin settings

4. **Configure MCP Server:**

   Use the "Configure API Key" workflow, or manually:
   ```bash
   ssh root@YOUR_SERVER_IP
   echo "OBSIDIAN_API_KEY=your_api_key_here" > /opt/obsidian-mcp/.env
   cd /opt/obsidian-mcp
   docker compose restart mcp-server
   ```

## Using with Claude

Add the MCP endpoint to your Claude configuration:

```json
{
  "mcpServers": {
    "obsidian": {
      "url": "http://YOUR_SERVER_IP:3002/mcp"
    }
  }
}
```

## Costs

| Component | Monthly Cost |
|-----------|--------------|
| Hetzner cx23 Server | ~€3.56 |
| IPv4 Address | €0.50 |
| Obsidian Sync | $4-8 |
| **Total** | **~€8-12/month** |

## Security

- **REST API not exposed externally** - Port 27123 is only accessible within the Docker network
- **Firewall rules** - Only necessary ports are open (22, 3000, 3001, 3002)
- **IP restrictions** - You can limit access to specific IPs via `firewall_allowed_ips`
- **Automatic cleanup** - Failed deployments automatically clean up resources

### Security Recommendations

1. **Restrict IP access** - Set `firewall_allowed_ips` to your IPs only
2. **Use strong passwords** - Especially for VNC
3. **Regular updates** - Use the Update workflow to keep images current
4. **Monitor access** - Check server logs regularly

## Troubleshooting

**VNC not accessible:**
- Wait 2-3 minutes after deployment for Docker containers to start
- Check: `docker logs obsidian`

**MCP server not responding:**
- Verify API key is set: `cat /opt/obsidian-mcp/.env`
- Ensure REST API plugin is set to bind to 0.0.0.0
- Check logs: `docker exec obsidian-mcp cat /app/logs/error.log`
- Restart: `docker compose restart mcp-server`

**Obsidian Sync not working:**
- Must be logged in via GUI
- Check internet connectivity from server

**Out of memory:**
- Upgrade to cx33 server type
- Check: `free -h` on server

## Cleanup

To destroy all infrastructure:

```bash
cd terraform
terraform destroy
```

Or use the "Destroy Infrastructure" GitHub Action (type "DESTROY" to confirm).

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

Apache 2.0 - see [LICENSE](LICENSE)
