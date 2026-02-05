# Features Overview

This chapter provides an overview of all Crybot's features and capabilities.

## Core Features

### Multiple Interaction Modes

Crybot supports four ways to interact:

1. **Web UI** - Browser-based chat at `http://127.0.0.1:3000`
2. **REPL** - Advanced command-line interface
3. **Telegram Bot** - Chat through Telegram messenger
4. **Voice** - Voice-activated with wake word detection

### Multi-Provider Support

Crybot works with multiple AI providers:

- **OpenAI** - GPT models
- **Anthropic** - Claude models
- **Zhipu GLM** - Chinese AI models
- **OpenRouter** - Access to many providers
- **vLLM** - Local model hosting

### Tool Calling

Built-in tools extend Crybot's capabilities:

- **File Operations** - Read, write, edit files
- **Shell Commands** - Execute system commands
- **Web Search** - Search and fetch web pages
- **Memory Management** - Long-term memory with daily logs

### MCP Integration

Connect to external tools via Model Context Protocol:

- Playwright - Browser automation
- Filesystem - File operations
- Brave Search - Web search
- GitHub - Repository operations
- And many more!

## Advanced Features

### Skills System

Create reusable AI behaviors as markdown files. Skills can:

- Execute HTTP requests
- Run MCP commands
- Execute shell commands
- Use CodeMirror for code execution

**Built-in Skills:**
- `weather` - Weather information
- `tldr` - Simplified explanations
- `tech_news_reader` - Tech news aggregator

### Scheduled Tasks

Automate recurring AI tasks with natural language scheduling:

- `daily at 9:30 AM` - Daily at specific time
- `every 30 minutes` - Regular intervals
- `hourly`, `daily`, `weekly`, `monthly`

Tasks can forward output to:
- Telegram chats
- Web sessions
- Voice output
- REPL

### Session Management

Crybot maintains persistent conversation history:

- Multiple concurrent sessions
- Per-channel sessions (telegram, web, voice, repl)
- Session history in JSONL format
- Web UI session switching

## Unified Channels

Crybot's unified channel system allows:

- Forwarding messages to any channel
- Format conversion (Markdown ↔ HTML ↔ Plain text)
- Consistent API across all channels
- Easy addition of new channels

## Development Features

### Hot Config Reload

Configuration changes take effect automatically - no restart needed!

### Real-time Updates

Web UI supports WebSocket streaming for live message updates.

### Extensibility

- Add custom tools in Crystal
- Create skills without coding
- Connect MCP servers for new capabilities
- Add new channels by implementing the Channel interface

## Feature Comparison

| Feature | Web UI | REPL | Telegram | Voice |
|---------|--------|-----|----------|-------|
| Chat | ✅ | ✅ | ✅ | ✅ |
| Session History | ✅ | ✅ | ✅ | ✅ |
| Tool Execution Display | ✅ | ✅ | ❌ | ✅* |
| Voice Output | ❌ | ❌ | ❌ | ✅ |
| Scheduled Tasks | ✅ | ❌ | ✅ | ✅ |
| Skills Management | ✅ | ❌ | ❌ | ❌ |
| MCP Management | ✅ | ❌ | ❌ | ❌ |

*Errors announced in voice mode, details shown in web UI

## Next Steps

Learn how to use the [Web Interface](04-web-interface.md).
