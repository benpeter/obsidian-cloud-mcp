#!/bin/bash

# Health Check Script for Obsidian MCP Server
# Run manually or set up as a cron job

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║           Obsidian MCP Server - Health Check                   ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Check Docker
echo -n "Docker Service: "
if systemctl is-active --quiet docker; then
    echo -e "${GREEN}Running${NC}"
else
    echo -e "${RED}Not Running${NC}"
    exit 1
fi

# Check Obsidian container
echo -n "Obsidian Container: "
if docker ps --format '{{.Names}}' | grep -q '^obsidian$'; then
    echo -e "${GREEN}Running${NC}"
else
    echo -e "${RED}Not Running${NC}"
fi

# Check MCP container
echo -n "MCP Server Container: "
if docker ps --format '{{.Names}}' | grep -q '^obsidian-mcp$'; then
    echo -e "${GREEN}Running${NC}"
else
    echo -e "${RED}Not Running${NC}"
fi

# Check Obsidian Web GUI
echo -n "Obsidian Web GUI (3001): "
if curl -sk --connect-timeout 5 https://localhost:3001 > /dev/null 2>&1; then
    echo -e "${GREEN}Accessible${NC}"
else
    echo -e "${YELLOW}Not Accessible (may still be starting)${NC}"
fi

# Check MCP Server
echo -n "MCP Server (3002): "
if curl -s --connect-timeout 5 http://localhost:3002/health > /dev/null 2>&1; then
    echo -e "${GREEN}Accessible${NC}"
else
    echo -e "${YELLOW}Not Accessible (check API key configuration)${NC}"
fi

# Check REST API
echo -n "Obsidian REST API (27123): "
if curl -s --connect-timeout 5 http://localhost:27123 > /dev/null 2>&1; then
    echo -e "${GREEN}Accessible${NC}"
else
    echo -e "${YELLOW}Not Accessible (install Local REST API plugin)${NC}"
fi

echo ""
echo "Container Status:"
docker ps --filter "name=obsidian" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "Disk Usage:"
df -h /opt/obsidian-mcp 2>/dev/null || df -h /

echo ""
echo "Memory Usage:"
free -h
