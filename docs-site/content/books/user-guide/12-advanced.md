# Advanced Topics

This chapter covers advanced usage and customization.

## Hot Config Reload

Crybot automatically reloads `~/.crybot/config.yml` on changes. No restart needed!

This works for:
- API keys
- Model selection
- Feature toggles
- MCP server configuration
- Telegram settings

## Session Management

### Session Keys

Sessions follow the pattern: `{channel}:{identifier}`

Examples:
- `web:68d4ec74b8359478b3ccdc9a9b6ad740`
- `telegram:57433113`
- `voice:`
- `repl:`
- `scheduled/daily-summary`

### Session Storage

Sessions are stored in `~/.crybot/sessions/` as JSONL files:

```jsonl
{"role":"user","content":"Hello"}
{"role":"assistant","content":"Hi there!"}
```

## Custom Templates

Crybot uses Crinja templates (Jinja-like) for prompts. Customize in `~/.crybot/workspace/`:

- `AGENTS.md` - Agent behavior
- `USER.md` - User persona
- `TOOLS.md` - Tool descriptions
- `SOUL.md` - Core personality

## Debugging

### Verbose Mode

Set verbosity in `config.yml`:

```yaml
# 0: fatal, 1: errors, 2: warnings, 3: info, 4: debug, 5: trace
verbosity: 4
```

### Logs

Check logs for:
- MCP connection issues
- Tool execution failures
- Feature startup problems

## Performance

### Incremental Builds

Crybot only rebuilds what changes - sessions load only their own history.

### Fiber-based Concurrency

Features run in separate fibers for efficient concurrent operation.

## Security

### Authentication

Enable web UI authentication:

```yaml
web:
  auth_token: "your-secret-token"
```

Access with: `http://127.0.0.1:3000/?token=your-secret-token`

### Telegram Access Control

Restrict Telegram access by username:

```yaml
channels:
  telegram:
    allow_from:
      - "username1"
      - "username2"
```

## Deployment

### Production Considerations

- Use environment variables for API keys
- Enable authentication on web UI
- Configure proper reverse proxy (nginx)
- Set up process manager (systemd)
- Monitor logs

### Systemd Service

Create `/etc/systemd/system/crybot.service`:

```ini
[Unit]
Description=Crybot AI Assistant
After=network.target

[Service]
Type=simple
User=your-user
WorkingDirectory=/path/to/crybot
ExecStart=/path/to/crybot start
Restart=always

[Install]
WantedBy=multi-user.target
```

## Getting Help

- **GitHub Issues** - [github.com/ralsina/crybot/issues](https://github.com/ralsina/crybot/issues)
- **Source Code** - [github.com/ralsina/crybot](https://github.com/ralsina/crybot)
- **Documentation** - This guide!

Thank you for using Crybot!
