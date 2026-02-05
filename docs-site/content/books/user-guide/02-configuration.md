This chapter covers configuring Crybot with API keys and model settings.

## Configuration File

Crybot's configuration is stored in `~/.crybot/config.yml`.

## API Keys

You need to configure at least one LLM provider. Edit `~/.crybot/config.yml`:

```yaml
providers:
  zhipu:
    api_key: "your_api_key_here"  # Get from https://open.bigmodel.cn/
  openai:
    api_key: "your_openai_key"    # Get from https://platform.openai.com/
  anthropic:
    api_key: "your_anthropic_key" # Get from https://console.anthropic.com/
  openrouter:
    api_key: "your_openrouter_key" # Get from https://openrouter.ai/
```

### Free Options

- **Zhipu GLM** - Free tier available with generous limits
- **OpenRouter** - Aggregates multiple providers, some with free tiers

## Selecting a Model

Set the default model in your config:

```yaml
agents:
  defaults:
    model: "gpt-4o-mini"  # Uses OpenAI
    # model: "claude-3-5-sonnet-20241022"  # Uses Anthropic
    # model: "glm-4.7-flash"  # Uses Zhipu (default if not specified)
```

### Provider Auto-Detection

Crybot automatically detects the provider from model name prefixes:

| Model Prefix | Provider |
|-------------|----------|
| `gpt-*` | OpenAI |
| `claude-*` | Anthropic |
| `glm-*` | Zhipu |
| `deepseek-*`, `qwen-*` | OpenRouter |

You can also explicitly specify the provider:

```yaml
model: "openai/gpt-4o-mini"
model: "anthropic/claude-3-5-sonnet-20241022"
model: "openrouter/deepseek/deepseek-chat"
```

## Feature Configuration

Enable/disable features in `config.yml`:

```yaml
features:
  web: true              # Web UI at http://127.0.0.1:3000
  gateway: true          # Telegram bot
  voice: false           # Voice interaction
  repl: false            # Advanced REPL
  scheduled_tasks: true  # Automated tasks
```

## Web Configuration

Configure the web UI:

```yaml
web:
  enabled: true
  host: "127.0.0.1"
  port: 3000
  # auth_token: "your-secret-token"  # Optional authentication
```

## Telegram Configuration

Configure Telegram bot:

```yaml
channels:
  telegram:
    enabled: true
    token: "YOUR_BOT_TOKEN"     # Get from @BotFather on Telegram
    allow_from: []             # Empty = allow all users
```

## Voice Configuration

Configure voice interaction (optional):

```yaml
voice:
  wake_word: "crybot"         # Word to trigger listening
  whisper_stream_path: "/usr/bin/whisper-stream"
  model_path: "/path/to/ggml-base.en.bin"
  language: "en"
  threads: 4
  piper_model: "/path/to/voice.onnx"
  piper_path: "/usr/bin/piper-tts"
```

## MCP Configuration

Configure Model Context Protocol servers:

```yaml
mcp:
  servers:
    - name: playwright
      command: npx @playwright/mcp@latest
    - name: filesystem
      command: npx -y @modelcontextprotocol/server-filesystem /allowed/path
```

## Reloading Configuration

Crybot automatically reloads configuration when `~/.crybot/config.yml` changes. No restart needed!

## Next Steps

With Crybot configured, learn about the [available features](03-features.md).
