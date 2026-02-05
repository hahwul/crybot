---
title: "MCP Integration in Crybot"
date: 2025-02-05
tags: [mcp, integration, features]
category: development
---

I've just added Model Context Protocol (MCP) support to Crybot, opening up a world of possibilities for extending the AI assistant's capabilities.

## What is MCP?

The [Model Context Protocol](https://modelcontextprotocol.io/) is an open standard that allows AI applications to connect to external tools and data sources. Think of it as a universal plugin system for AI assistants.

## How It Works in Crybot

Crybot acts as an MCP client, connecting to stdio-based MCP servers. When Crybot starts, it:

1. Connects to all configured MCP servers
2. Discovers what tools each server provides
3. Registers those tools with the agent
4. Makes tools available during conversations

## Configuration

Add MCP servers to your `~/.crybot/config.yml`:

```yaml
mcp:
  servers:
    - name: playwright
      command: npx @playwright/mcp@latest

    - name: filesystem
      command: npx -y @modelcontextprotocol/server-filesystem /home/user/Documents
```

## Using MCP Tools

Once configured, MCP tools are automatically available to the agent:

```
You: Navigate to example.com and take a screenshot
Crybot: [Uses playwright/browser_navigate]
       [Uses playwright/browser_take_screenshot]
       Done! Here's your screenshot...
```

## Available MCP Servers

The MCP ecosystem is growing fast. Some popular servers:

- **@playwright/mcp** - Browser automation
- **@modelcontextprotocol/server-filesystem** - File operations
- **@modelcontextprotocol/server-brave-search** - Web search
- **@modelcontextprotocol/server-github** - GitHub integration
- **@modelcontextprotocol/server-postgres** - Database queries

Find more at [github.com/modelcontextprotocol/servers](https://github.com/modelcontextprotocol/servers).

## Web UI Management

Crybot's web UI includes an MCP Servers section where you can:

- View configured servers
- Add new servers
- Remove servers
- Reload configuration

## Technical Details

The MCP implementation in Crybot:

- Uses stdio transport for server communication
- Supports fiber-based non-blocking I/O
- Handles server failures gracefully
- Prefixes tool names with server name
- Integrates with Crybot's existing tool system

## Future Plans

- HTTP-based MCP servers
- Bidirectional streaming
- Resource support
- Prompt templates

MCP integration makes Crybot incredibly extensible. What servers would you like to see supported?
