# MCP Integration

Model Context Protocol (MCP) allows Crybot to connect to external tools and services.

## What is MCP?

MCP is an open standard for AI applications to connect to external tools and data sources. Think of it as a universal plugin system.

## Configuring MCP Servers

Edit `~/.crybot/config.yml`:

```yaml
mcp:
  servers:
    - name: filesystem
      command: npx -y @modelcontextprotocol/server-filesystem /path/to/allow

    - name: playwright
      command: npx @playwright/mcp@latest
```

## Available MCP Servers

Popular MCP servers:

- **@playwright/mcp** - Browser automation
- **@modelcontextprotocol/server-filesystem** - File operations
- **@modelcontextprotocol/server-brave-search** - Web search
- **@modelcontextprotocol/server-github** - GitHub integration
- **@modelcontextprotocol/server-postgres** - PostgreSQL database

Find more at [github.com/modelcontextprotocol/servers](https://github.com/modelcontextprotocol/servers)

## Using MCP Tools

Once configured, tools are automatically available:

```
You: Read the file /home/user/document.txt
Crybot: [Uses filesystem/read_file]
       File content: ...
```

## Tool Names

MCP tools are prefixed with the server name:

- `filesystem/read_file`
- `playwright/browser_navigate`
- `brave-search/web_search`

## Management via Web UI

Navigate to **MCP Servers** section to:

- View configured servers
- Add new servers (name + command)
- Remove servers
- Reload configuration

## Environment Variables

Some MCP servers require environment variables:

```yaml
mcp:
  servers:
    - name: github
      command: npx -y @modelcontextprotocol/server-github
      env:
        GITHUB_TOKEN: "your_token"
```

## Troubleshooting

If an MCP server fails to connect:

1. Check the server command is correct
2. Verify required environment variables
3. Check server logs in Crybot output
4. Some servers may require specific dependencies

MCP servers run in stdio mode, which means Crybot starts each server as a subprocess and communicates via standard input/output.
