FROM node:20-alpine

WORKDIR /app

# Install git for cloning the MCP server
RUN apk add --no-cache git

# Clone the obsidian-mcp-server repository
RUN git clone --depth 1 https://github.com/cyanheads/obsidian-mcp-server.git .

# Install dependencies
RUN npm ci

# Build the TypeScript project
RUN npm run build

# Health check endpoint
EXPOSE 3000

# Start the MCP server
CMD ["node", "dist/index.js"]
