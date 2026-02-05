# Installation

This chapter covers installing Crybot on your system.

## Prerequisites

Crybot requires:

- **Crystal** 1.13.0 or later
- **shards** - Crystal dependency manager (comes with Crystal)

### Installing Crystal

**Arch Linux:**
```bash
pacman -S crystal shards
```

**From source:** See [crystal-lang.org](https://crystal-lang.org/install/)

## Installation

### 1. Clone the Repository

```bash
git clone https://github.com/ralsina/crybot.git
cd crybot
```

### 2. Install Dependencies

```bash
shards install
```

### 3. Build Crybot

```bash
shards build
```

This creates the `./bin/crybot` binary.

### 4. Run Onboarding

The onboarding command sets up your initial configuration:

```bash
./bin/crybot onboard
```

This creates:

```
~/.crybot/
├── config.yml              # Main configuration
├── workspace/
│   ├── MEMORY.md           # Long-term memory
│   ├── skills/             # AI skills
│   ├── memory/             # Daily logs
│   └── scheduled_tasks.yml # Scheduled tasks
├── sessions/               # Chat history
└── repl_history.txt        # REPL history
```

## Verifying Installation

Test that Crybot works:

```bash
./bin/crybot agent "Hello, Crybot!"
```

You should see a response from the AI assistant.

## Next Steps

Once installed, you need to configure Crybot with your API keys. Continue to [Configuration](02-configuration.md).
