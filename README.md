# Crybot

Crybot is a personal AI assistant built in Crystal, inspired by nanobot (Python). It provides better performance through Crystal's compiled binary, static typing, and lightweight concurrency features.

## Features

- **Multiple LLM Support**: Currently supports z.ai / Zhipu GLM models (glm-4.7-flash, glm-4-plus, etc.)
- **Tool Calling**: Built-in tools for file operations, shell commands, and web search/fetch
- **MCP Support**: Model Context Protocol client for connecting to external tools and resources
- **Session Management**: Persistent conversation history with JSONL storage
- **Telegram Integration**: Full Telegram bot support with message tracking
- **Interactive & CLI Modes**: Use via CLI or Telegram
- **Workspace System**: Organized workspace with memory, skills, and bootstrap files

## Yes, it DOES work.

It can even reconfigure itself.

<img width="726" height="1276" alt="image" src="https://github.com/user-attachments/assets/5b8b7155-5c7a-4965-9aca-e2907f4ed641" />



## Installation

1. Clone the repository
2. Install dependencies: `shards install`
3. Build: `shards build`

## Configuration

Run the onboarding command to initialize:

```bash
./bin/crybot onboard
```

This creates:
- Configuration file: `~/.crybot/config.yml`
- Workspace directory: `~/.crybot/workspace/`

Edit `~/.crybot/config.yml` to add your z.ai API key:

```yaml
providers:
  zhipu:
    api_key: "your_api_key_here"  # Get from https://open.bigmodel.cn/
```

## Usage

### Interactive CLI Mode

```bash
./bin/crybot agent
```

### Single Message CLI Mode

```bash
./bin/crybot agent -m "Your message here"
```

### Telegram Gateway

```bash
./bin/crybot gateway
```

Configure Telegram in `config.yml`:

```yaml
channels:
  telegram:
    enabled: true
    token: "YOUR_BOT_TOKEN"
    allow_from: []  # Empty = allow all users
```

Get a bot token from [@BotFather](https://t.me/BotFather) on Telegram.

## Built-in Tools

- `read_file` - Read file contents
- `write_file` - Write/create files
- `edit_file` - Edit files (find and replace)
- `list_dir` - List directory contents
- `exec` - Execute shell commands
- `web_search` - Search the web (Brave Search API)
- `web_fetch` - Fetch and read web pages

## MCP Integration

Crybot supports the [Model Context Protocol (MCP)](https://modelcontextprotocol.io/), which allows it to connect to external tools and resources via stdio-based MCP servers.

### Configuring MCP Servers

Add MCP servers to your `~/.crybot/config.yml`:

```yaml
mcp:
  servers:
    # Filesystem access
    - name: filesystem
      command: npx -y @modelcontextprotocol/server-filesystem /path/to/allowed/directory

    # GitHub integration
    - name: github
      command: npx -y @modelcontextprotocol/server-github
      # Requires GITHUB_TOKEN environment variable

    # Brave Search
    - name: brave-search
      command: npx -y @modelcontextprotocol/server-brave-search
      # Requires BRAVE_API_KEY environment variable

    # PostgreSQL database
    - name: postgres
      command: npx -y @modelcontextprotocol/server-postgres "postgresql://user:pass@localhost/db"
```

### Available MCP Servers

Find more MCP servers at https://github.com/modelcontextprotocol/servers

### How It Works

1. When Crybot starts, it connects to all configured MCP servers
2. Tools provided by each server are automatically registered
3. The agent can call these tools just like built-in tools
4. MCP tools appear with the server name as prefix (e.g., `filesystem/write_file`)

### Configuration Fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Unique identifier for this server (used as tool name prefix) |
| `command` | No* | Shell command to start the stdio-based MCP server |
| `url` | No* | URL for HTTP-based MCP servers (not yet implemented) |

*Either `command` or `url` must be provided (currently only `command` is supported)

### Example Session

If you configure the filesystem server:

```yaml
mcp:
  servers:
    - name: fs
      command: npx -y @modelcontextprotocol/server-filesystem /home/user/projects
```

Then tools like `fs/read_file`, `fs/write_file`, `fs/list_directory` will be automatically available to the agent.

## Development

Run linter:
```bash
ameba --fix
```

Build:
```bash
shards build
```

## License

MIT
