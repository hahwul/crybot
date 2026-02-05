Crybot can be accessed through Telegram, allowing you to chat from your phone.

## Setting Up Telegram Bot

### 1. Create a Bot

1. Open Telegram and search for [@BotFather](https://t.me/BotFather)
2. Send `/newbot`
3. Follow the prompts to choose a name and username
4. Copy the bot token

### 2. Configure Crybot

Edit `~/.crybot/config.yml`:

```yaml
channels:
  telegram:
    enabled: true
    token: "YOUR_BOT_TOKEN_HERE"
    allow_from: []  # Empty = allow all users
```

### 3. Start Crybot

```bash
./bin/crybot gateway
```

Or enable with `./bin/crybot start` if gateway feature is enabled.

## Using Crybot on Telegram

- Send messages to your bot
- Crybot responds as the assistant
- Supports both text and file inputs
- Tool execution results are included

### Access Control

To restrict access, add usernames to `allow_from`:

```yaml
channels:
  telegram:
    enabled: true
    token: "YOUR_BOT_TOKEN"
    allow_from:
      - "username1"
      - "username2"
```

## Web UI Integration

You can also send messages to Telegram chats from the web UI, with responses appearing in Telegram.

## Auto-Restart

The gateway automatically restarts when you modify `config.yml` - no manual restart needed!
