# Skills System

Skills are reusable AI behaviors stored as markdown files that Crybot can reference during conversations.

## What are Skills?

Skills are structured markdown files in `~/.crybot/workspace/skills/` that contain:

- **Purpose** - What the skill does
- **Usage** - When to use it
- **Instructions** - How to perform the task

## Built-in Skills

Crybot includes several built-in skills:

### Weather

Get weather information for any location.

### TLDR

Get simplified explanations of complex topics.

### Tech News Reader

Aggregate tech news from Hacker News, Slashdot, and TechCrunch.

## Creating Skills

### Via Web UI

1. Navigate to **Skills** section
2. Click **+ Create Skill**
3. Fill in:
   - Name
   - Description
   - Instructions (markdown supported)
4. Click **Save**

### Manual Creation

Create a directory in `~/.crybot/workspace/skills/`:

```bash
mkdir -p ~/.crybot/workspace/skills/my-skill
```

Create `SKILL.md`:

```markdown
# My Skill

## Purpose
What this skill does.

## When to Use
When to trigger this skill.

## Instructions
Step-by-step instructions for the AI.
```

## Skill Types

Skills can perform:

- **HTTP Requests** - Call APIs with custom headers
- **MCP Commands** - Use MCP servers
- **Shell Commands** - Execute system commands
- **Code Execution** - Write and run code in editor

## Managing Skills

### Reload

Click **Reload Skills** in the web UI to reload all skills.

### Delete

Use the delete button on any skill card.

### Execute

Click **Run** on any skill to execute it immediately.

Skills are automatically included in agent context when relevant to the conversation.
