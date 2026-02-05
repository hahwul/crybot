# Web Interface

The web UI is Crybot's primary interface - a modern, browser-based chat with real-time updates.

## Accessing the Web UI

Start Crybot with web enabled:

```bash
./bin/crybot start
```

Then open `http://127.0.0.1:3000` in your browser.

## Features

### Chat Sessions

- Multiple persistent conversations
- Session switching from sidebar
- Auto-scroll to latest messages
- Session history preserved

### Real-time Streaming

Watch responses generate in real-time with:
- Typing indicators
- Live message updates
- Tool execution display

### Tool Execution

See what Crybot is doing:
- Tool names and commands
- Execution output in terminal
- Success/error status

### Skills Management

Navigate to **Skills** section to:

- Create new skills from markdown
- Edit existing skills
- Execute skills on demand
- Delete skills

### Scheduled Tasks

Navigate to **Scheduled Tasks** to:

- Create automated tasks
- Set schedules (daily, hourly, etc.)
- Configure output forwarding
- Run tasks immediately

### MCP Servers

Navigate to **MCP Servers** to:

- View configured servers
- Add/remove servers
- Reload configuration

### Telegram Integration

Send messages to Telegram chats directly from the web UI.

## Authentication (Optional)

Enable authentication in `config.yml`:

```yaml
web:
  auth_token: "your-secret-token"
```

Then access via: `http://127.0.0.1:3000/?token=your-secret-token`

## Keyboard Shortcuts

- `Ctrl+K` - Command palette (if available)
- `Escape` - Close modals
- `Enter` - Send message
- `Shift+Enter` - New line in message input
