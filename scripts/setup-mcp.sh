#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║         Obsidian MCP Server - Manual Setup Script              ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root (sudo)${NC}"
    exit 1
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}Installing Docker...${NC}"
    apt-get update
    apt-get install -y docker.io docker-compose-v2
    systemctl enable docker
    systemctl start docker
fi

# Create directory
INSTALL_DIR="/opt/obsidian-mcp"
echo -e "${YELLOW}Creating installation directory: ${INSTALL_DIR}${NC}"
mkdir -p "$INSTALL_DIR"

# Check if repo files exist locally or need to be downloaded
if [ -f "./docker/docker-compose.yml" ]; then
    echo -e "${YELLOW}Copying local files...${NC}"
    cp -r ./docker/* "$INSTALL_DIR/"
    cp -r ./mcp-server "$INSTALL_DIR/"
else
    echo -e "${YELLOW}Downloading from GitHub...${NC}"
    git clone --depth 1 https://github.com/benpeter/obsidian-cloud-mcp.git /tmp/obsidian-setup
    cp -r /tmp/obsidian-setup/docker/* "$INSTALL_DIR/"
    cp -r /tmp/obsidian-setup/mcp-server "$INSTALL_DIR/"
    rm -rf /tmp/obsidian-setup
fi

# Create data directories
mkdir -p "$INSTALL_DIR/config"
mkdir -p "$INSTALL_DIR/vault"

# Create .env if not exists
if [ ! -f "$INSTALL_DIR/.env" ]; then
    echo "OBSIDIAN_API_KEY=not_configured_yet" > "$INSTALL_DIR/.env"
fi

# Start containers
echo -e "${YELLOW}Starting Docker containers...${NC}"
cd "$INSTALL_DIR"
docker compose up -d --build

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                    INSTALLATION COMPLETE                       ║${NC}"
echo -e "${GREEN}╠════════════════════════════════════════════════════════════════╣${NC}"
echo -e "${GREEN}║                                                                ║${NC}"
echo -e "${GREEN}║  Obsidian GUI:  https://YOUR_SERVER_IP:3001                    ║${NC}"
echo -e "${GREEN}║  MCP Endpoint:  http://YOUR_SERVER_IP:3002                     ║${NC}"
echo -e "${GREEN}║                                                                ║${NC}"
echo -e "${GREEN}║  Next Steps:                                                   ║${NC}"
echo -e "${GREEN}║  1. Open the GUI URL in your browser                           ║${NC}"
echo -e "${GREEN}║  2. Log in to Obsidian Sync                                    ║${NC}"
echo -e "${GREEN}║  3. Install 'Local REST API' plugin                            ║${NC}"
echo -e "${GREEN}║  4. Edit /opt/obsidian-mcp/.env with your API key              ║${NC}"
echo -e "${GREEN}║  5. Run: docker compose restart                                ║${NC}"
echo -e "${GREEN}║                                                                ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
