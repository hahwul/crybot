# Scheduled Tasks

Automate recurring AI tasks with natural language scheduling.

## What are Scheduled Tasks?

Scheduled tasks run automatically at specified intervals, executing prompts and optionally forwarding results to other channels.

## Creating Tasks

### Via Web UI

1. Navigate to **Scheduled Tasks**
2. Click **+ Add Task**
3. Configure:
   - **Name** - Task identifier
   - **Description** - What it does
   - **Prompt** - The AI prompt to execute
   - **Schedule** - When to run (e.g., "daily at 9AM", "every 30 minutes")
   - **Forward to** - Where to send results (optional)
   - **Memory Expiration** - How long to keep task context (optional)

4. Click **Save Task**

## Schedule Formats

Supported formats:

- `hourly` - Every hour
- `daily` - Every day at midnight
- `daily at 9:30 AM` - Daily at specific time
- `every 30 minutes` - Intervals
- `every 6 hours` - Every 6 hours
- `weekly` - Every week
- `monthly` - Every month

## Forwarding Results

Task output can be forwarded to:

- **Telegram** - `telegram:chat_id`
- **Web** - `web:session_id`
- **Voice** - `voice:`
- **REPL** - `repl:`

## Task Storage

Tasks are stored in `~/.crybot/workspace/scheduled_tasks.yml`:

```yaml
tasks:
  - id: daily-summary
    name: Daily Summary
    prompt: "Generate a summary of today's activities"
    interval: daily at 9AM
    enabled: true
    forward_to: telegram:123456789
```

## Manual Execution

Click **Run Now** on any task to execute it immediately, regardless of schedule.

## Task Sessions

Each task has its own session context at `scheduled/{task_id}`, so:

- Task history is preserved
- Context is maintained across runs
- Memory expiration can be configured

## Enabling/Disabling

Toggle tasks without deleting them using the enable/disable checkbox.

## Hot Reload

Changes take effect immediately - no restart needed!
