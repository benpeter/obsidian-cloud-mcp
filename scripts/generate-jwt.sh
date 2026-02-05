#!/bin/bash
#
# Generate a JWT token for MCP Server authentication
#
# Usage: ./generate-jwt.sh <secret> [expiry_hours]
#
# Example:
#   ./generate-jwt.sh "your_secret_key" 24
#

set -e

SECRET="${1:-}"
EXPIRY_HOURS="${2:-24}"

if [ -z "$SECRET" ]; then
    echo "Usage: $0 <jwt_secret> [expiry_hours]"
    echo ""
    echo "Arguments:"
    echo "  jwt_secret    - The MCP_JWT_SECRET from your .env file"
    echo "  expiry_hours  - Token validity in hours (default: 24)"
    echo ""
    echo "Example:"
    echo "  $0 'qo9O6WRvXaTHzz13JBg7MU4kWFQX0FXia07UKsKlgkC3zXuMvAkbNPeDE2Ug3ftz' 720"
    exit 1
fi

# Check if required tools are available
if ! command -v openssl &> /dev/null; then
    echo "Error: openssl is required but not installed."
    exit 1
fi

# Calculate expiry timestamp
NOW=$(date +%s)
EXPIRY=$((NOW + EXPIRY_HOURS * 3600))

# Create JWT header
HEADER=$(echo -n '{"alg":"HS256","typ":"JWT"}' | openssl base64 -e | tr -d '=' | tr '/+' '_-' | tr -d '\n')

# Create JWT payload
PAYLOAD=$(echo -n "{\"sub\":\"mcp-client\",\"iat\":$NOW,\"exp\":$EXPIRY}" | openssl base64 -e | tr -d '=' | tr '/+' '_-' | tr -d '\n')

# Create signature
SIGNATURE=$(echo -n "$HEADER.$PAYLOAD" | openssl dgst -sha256 -hmac "$SECRET" -binary | openssl base64 -e | tr -d '=' | tr '/+' '_-' | tr -d '\n')

# Output the token
TOKEN="$HEADER.$PAYLOAD.$SIGNATURE"

echo "=============================================="
echo "JWT Token Generated Successfully"
echo "=============================================="
echo ""
echo "Token (valid for $EXPIRY_HOURS hours):"
echo ""
echo "$TOKEN"
echo ""
echo "=============================================="
echo ""
echo "Usage with curl:"
echo "  curl -X POST http://YOUR_SERVER:3002/mcp \\"
echo "    -H 'Authorization: Bearer $TOKEN' \\"
echo "    -H 'Content-Type: application/json' \\"
echo "    -d '{\"jsonrpc\":\"2.0\",\"method\":\"tools/list\",\"id\":1}'"
echo ""
echo "Usage in MCP client config:"
echo "  {"
echo "    \"mcpServers\": {"
echo "      \"obsidian\": {"
echo "        \"url\": \"http://YOUR_SERVER:3002/mcp\","
echo "        \"headers\": {"
echo "          \"Authorization\": \"Bearer $TOKEN\""
echo "        }"
echo "      }"
echo "    }"
echo "  }"
echo ""
