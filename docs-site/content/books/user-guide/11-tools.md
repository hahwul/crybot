# Built-in Tools

Crybot includes a comprehensive set of built-in tools for various operations.

## File Operations

### read_file

Read the contents of a file.

```
read_file(path="/path/to/file.txt")
```

### write_file

Write or create a file with content.

```
write_file(path="/path/to/file.txt", content="Hello, World!")
```

### edit_file

Edit a file using find and replace.

```
edit_file(path="/path/to/file.txt", find="old", replace="new")
```

### list_dir

List directory contents.

```
list_dir(path="/path/to/directory")
```

## System & Web

### exec

Execute shell commands.

```
exec(command="ls -la")
```

### web_search

Search the web using Brave Search API.

```
web_search(query="Crystal programming language")
```

### web_fetch

Fetch and read web pages.

```
web_fetch(url="https://example.com")
```

## Memory Management

### save_memory

Save important information to long-term memory.

```
save_memory(information="Crystal is a programming language")
```

Saved to `~/.crybot/workspace/MEMORY.md`.

### search_memory

Search long-term memory and daily logs.

```
search_memory(query="Crystal language features")
```

### list_recent_memories

List recent memory entries from daily logs.

```
list_recent_memories(days=7)
```

### record_memory

Record events or observations to the daily log.

```
record_memory(note="Implemented new feature today")
```

### memory_stats

Get statistics about memory usage.

```
memory_stats()
```

## Skill Creation

### create_skill

Create a new skill from the conversation.

```
create_skill(name="my-skill", description="Does X")
```

### create_web_scraper_skill

Create a web scraping skill.

```
create_web_scraper_skill(url="https://example.com", name="scraper")
```

## Tool Execution Display

When tools are executed, Crybot displays:

- Tool name and arguments
- Execution status (success/error)
- Output or error message
- Duration (in some interfaces)

## Adding Custom Tools

Custom tools can be added in `src/agent/tools/` as Crystal classes extending the `Tool` base class.

See the source code for examples of how tools are implemented.
