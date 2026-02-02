# Crybot

Crybot is a personal AI assistant built in Crystal, inspired by nanobot (Python). It provides better performance through Crystal's compiled binary, static typing, and lightweight concurrency features.

## Features

- **Multiple LLM Support**: Currently supports z.ai / Zhipu GLM models (glm-4.7-flash, glm-4-plus, etc.)
- **Tool Calling**: Built-in tools for file operations, shell commands, and web search/fetch
- **Session Management**: Persistent conversation history with JSONL storage
- **Telegram Integration**: Full Telegram bot support with message tracking
- **Interactive & CLI Modes**: Use via CLI or Telegram
- **Workspace System**: Organized workspace with memory, skills, and bootstrap files

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
