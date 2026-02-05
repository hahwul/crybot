# REPL Mode

The advanced REPL (Read-Eval-Print Loop) provides a powerful command-line interface.

## Starting the REPL

```bash
./bin/crybot repl
```

## Features

### Fancyline Integration

- **Syntax Highlighting** - Commands are highlighted
- **Tab Completion** - Complete commands and history
- **History Search** - `Ctrl+R` to search history
- **Navigation** - Up/Down arrows for history

### Built-in Commands

- `help` - Show available commands
- `model` - Display current model
- `clear` - Clear screen
- `quit` or `exit` - Exit REPL

### Command History

History is saved to `~/.crybot/repl_history.txt` for persistence across sessions.

## Tips

- Use `Ctrl+R` for reverse history search
- Type partial commands then `Tab` to complete
- Messages are auto-submitted to the agent

The REPL is ideal for power users who prefer keyboard-driven interaction.
