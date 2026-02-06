FROM node:20-alpine

WORKDIR /app

# Install git for cloning the MCP server
RUN apk add --no-cache git

# Clone the obsidian-mcp-server repository at a pinned commit
# Update this hash to upgrade: https://github.com/cyanheads/obsidian-mcp-server/commits/main
RUN git clone https://github.com/cyanheads/obsidian-mcp-server.git . && \
    git checkout 57cce8836261b6014e8f82c9b100896cf87e48b3

# Install dependencies
RUN npm ci

# Build the TypeScript project
RUN npm run build

# Health check endpoint
EXPOSE 3000

# Start the MCP server
CMD ["node", "dist/index.js"]
