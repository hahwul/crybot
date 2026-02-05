# Crybot

Crybot is a modular personal AI assistant built in Crystal. It provides multiple interaction modes, supports multiple LLM providers, and includes extensible tool calling, MCP integration, skills, and scheduled tasks.

## Features

- **Multiple LLM Support** - OpenAI, Anthropic, Zhipu GLM, OpenRouter, and vLLM
- **Provider Auto-Detection** - Automatically selects provider based on model name
- **Tool Calling** - Built-in tools for files, shell, web, and memory
- **MCP Support** - Connect to external tools via Model Context Protocol
- **Skills System** - Create reusable AI behaviors as markdown files
- **Scheduled Tasks** - Automate recurring AI tasks with natural language
- **Multiple Interfaces** - REPL, Web UI, Telegram bot, and Voice
- **Session Management** - Persistent conversation history

## Quick Start

```bash
git clone https://github.com/ralsina/crybot.git
cd crybot
shards install
shards build
./bin/crybot onboard
```

## Documentation

- **[User Guide](books/user-guide/)** - Complete guide to using Crybot
- **[Installation](books/user-guide/01-installation.md)** - Setup and configuration
- **[Features](books/user-guide/02-features.md)** - Overview of all features

## Source Code

[github.com/ralsina/crybot](https://github.com/ralsina/crybot)
