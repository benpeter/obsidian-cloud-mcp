# Obsidian Cloud MCP

Deploy an Obsidian MCP Server in the cloud with Obsidian Sync support.

**[English](#english) | [Deutsch](#deutsch)**

---

## English

### What is this?

This repository provides Infrastructure-as-Code to deploy a cloud-based [Obsidian](https://obsidian.md) instance with an MCP (Model Context Protocol) server. This allows AI assistants like Claude to access your Obsidian vault from anywhere.

**The Problem:** Obsidian runs locally, so AI assistants can't access your vault when you're on mobile or using cloud-based AI interfaces.

**The Solution:** Run Obsidian in the cloud with Sync enabled, and expose it via an MCP server.

### Architecture

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

### Important Limitation

**Obsidian Sync requires a one-time manual login via VNC.** There is no headless CLI authentication for Obsidian Sync.

- Infrastructure deployment = fully automated ✅
- Docker container start = fully automated ✅
- **First Obsidian Sync login = MANUAL via browser/VNC** ⚠️

After the initial login, Sync runs automatically.

### Prerequisites

1. **Hetzner Cloud Account** - [Sign up here](https://console.hetzner.cloud/)
2. **Obsidian Sync License** - [Get it here](https://obsidian.md/sync)
3. **Terraform** installed locally (optional, for local deployment)
4. **SSH Key Pair** for server access

### Quick Start

#### Option A: GitHub Actions (Recommended)

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
   - Copy the API key
   - SSH to server and add key to `/opt/obsidian-mcp/.env`
   - Restart: `docker compose restart mcp-server`

#### Option B: Local Terraform

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

3. **Complete manual setup** (same as Option A, step 4)

### Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `hcloud_token` | Hetzner API token | (required) |
| `ssh_public_key` | SSH public key | (required) |
| `vnc_password` | VNC access password | (required) |
| `server_type` | Hetzner server type | `cx22` |
| `server_location` | Server location | `nbg1` |
| `firewall_allowed_ips` | Allowed IP ranges | `["0.0.0.0/0"]` |

### Server Types

| Type | Specs | Monthly Cost |
|------|-------|--------------|
| `cx22` | 2 vCPU, 4 GB RAM | ~€4 |
| `cx32` | 4 vCPU, 8 GB RAM | ~€8 |

### Post-Deployment Setup

1. **Access Obsidian GUI:**
   ```
   https://YOUR_SERVER_IP:3001
   ```

2. **Login to Obsidian:**
   - Open Obsidian
   - Go to Settings → Core plugins → Enable Sync
   - Log in with your Obsidian account
   - Select your vault to sync

3. **Install REST API Plugin:**
   - Go to Settings → Community plugins
   - Browse and install "Local REST API"
   - Enable the plugin
   - Copy the API key from plugin settings

4. **Configure MCP Server:**
   ```bash
   ssh root@YOUR_SERVER_IP
   echo "OBSIDIAN_API_KEY=your_api_key_here" > /opt/obsidian-mcp/.env
   cd /opt/obsidian-mcp
   docker compose restart mcp-server
   ```

5. **Verify:**
   ```bash
   curl http://YOUR_SERVER_IP:3002/health
   ```

### Using with Claude

Add the MCP endpoint to your Claude configuration:

```json
{
  "mcpServers": {
    "obsidian": {
      "url": "http://YOUR_SERVER_IP:3002"
    }
  }
}
```

### Costs

| Component | Monthly Cost |
|-----------|--------------|
| Hetzner cx22 Server | ~€4 |
| Obsidian Sync | $4-8 |
| **Total** | **~€8-12/month** |

### Security Recommendations

1. **Restrict IP access** - Set `firewall_allowed_ips` to your IPs only
2. **Use strong passwords** - Especially for VNC
3. **Enable HTTPS** - The linuxserver/obsidian image supports it on port 3001
4. **Regular updates** - Use the Update workflow to keep images current
5. **Monitor access** - Check server logs regularly

### Troubleshooting

**VNC not accessible:**
- Wait 2-3 minutes after deployment
- Check: `docker logs obsidian`

**MCP server not responding:**
- Verify API key is set: `cat /opt/obsidian-mcp/.env`
- Check: `docker logs obsidian-mcp`
- Restart: `docker compose restart mcp-server`

**Obsidian Sync not working:**
- Must be logged in via GUI
- Check internet connectivity from server

**Out of memory:**
- Upgrade to cx32 server type
- Check: `free -h` on server

### Cleanup

To destroy all infrastructure:

```bash
cd terraform
terraform destroy
```

Or use the "Destroy Infrastructure" GitHub Action.

---

## Deutsch

### Was ist das?

Dieses Repository stellt Infrastructure-as-Code bereit, um eine cloud-basierte [Obsidian](https://obsidian.md)-Instanz mit einem MCP (Model Context Protocol) Server zu deployen. So können KI-Assistenten wie Claude von überall auf deinen Obsidian Vault zugreifen.

**Das Problem:** Obsidian läuft lokal, sodass KI-Assistenten nicht auf deinen Vault zugreifen können, wenn du mobil unterwegs bist oder cloud-basierte KI-Interfaces nutzt.

**Die Lösung:** Obsidian in der Cloud betreiben mit aktiviertem Sync und über einen MCP Server zugänglich machen.

### Wichtige Einschränkung

**Obsidian Sync erfordert ein einmaliges manuelles Login via VNC.** Es gibt keine headless CLI-Authentifizierung für Obsidian Sync.

- Infrastruktur-Deployment = vollautomatisch ✅
- Docker Container Start = vollautomatisch ✅
- **Erstes Obsidian Sync Login = MANUELL via Browser/VNC** ⚠️

Nach dem initialen Login läuft Sync automatisch weiter.

### Voraussetzungen

1. **Hetzner Cloud Account** - [Hier registrieren](https://console.hetzner.cloud/)
2. **Obsidian Sync Lizenz** - [Hier kaufen](https://obsidian.md/sync)
3. **Terraform** lokal installiert (optional, für lokales Deployment)
4. **SSH Key Pair** für Server-Zugriff

### Schnellstart

#### Option A: GitHub Actions (Empfohlen)

1. **Repository forken**

2. **GitHub Secrets hinzufügen:**
   - `HCLOUD_TOKEN` - Dein Hetzner API Token
   - `SSH_PUBLIC_KEY` - Dein öffentlicher SSH Key
   - `SSH_PRIVATE_KEY` - Dein privater SSH Key (für Updates)
   - `VNC_PASSWORD` - Passwort für VNC-Zugang (min. 6 Zeichen)

3. **Deploy Workflow starten:**
   - Gehe zu Actions → Deploy Infrastructure → Run workflow
   - Warte auf Abschluss (~3-5 Minuten)

4. **Manuelles Setup abschließen:**
   - Öffne die VNC URL aus dem Workflow-Output
   - In Obsidian Sync einloggen
   - "Local REST API" Plugin installieren
   - API Key kopieren
   - Per SSH auf den Server und Key in `/opt/obsidian-mcp/.env` eintragen
   - Neustart: `docker compose restart mcp-server`

#### Option B: Lokales Terraform

1. **Klonen und konfigurieren:**
   ```bash
   git clone https://github.com/DEIN_USERNAME/obsidian-cloud-mcp.git
   cd obsidian-cloud-mcp/terraform
   cp terraform.tfvars.example terraform.tfvars
   # terraform.tfvars mit deinen Werten bearbeiten
   ```

2. **Deployen:**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

3. **Manuelles Setup abschließen** (wie Option A, Schritt 4)

### Kosten

| Komponente | Monatliche Kosten |
|------------|-------------------|
| Hetzner cx22 Server | ~€4 |
| Obsidian Sync | €4-8 |
| **Gesamt** | **~€8-12/Monat** |

### Sicherheitsempfehlungen

1. **IP-Zugriff einschränken** - `firewall_allowed_ips` auf deine IPs setzen
2. **Starke Passwörter** - Besonders für VNC
3. **HTTPS aktivieren** - Das linuxserver/obsidian Image unterstützt es auf Port 3001
4. **Regelmäßige Updates** - Update Workflow nutzen
5. **Zugriffe überwachen** - Server-Logs regelmäßig prüfen

### Aufräumen

Um alle Infrastruktur zu löschen:

```bash
cd terraform
terraform destroy
```

Oder die "Destroy Infrastructure" GitHub Action verwenden.

---

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

Apache 2.0 - see [LICENSE](LICENSE)
