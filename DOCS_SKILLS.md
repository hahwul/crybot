# Crybot Skills System

The Skills System allows you to add new tools to Crybot without modifying core code. Skills are defined using YAML configuration files and are automatically discovered and loaded from the `~/.crybot/workspace/skills/` directory.

## How It Works

1. Create a skill using the Web UI or manually in `~/.crybot/workspace/skills/`
2. Define the tool and execution configuration in `skill.yml`
3. Optionally add documentation in `SKILL.md`
4. Reload skills - the skill will be automatically loaded and registered as a tool

## Web UI Management

The easiest way to manage skills is through the Crybot Web UI:

1. Start Crybot with the web feature enabled
2. Navigate to the "Skills" section
3. Click "+ Add Skill" to create a new skill from templates
4. Edit skill configuration, documentation, and set environment variables
5. Click "Reload Skills" to apply changes

The Web UI provides:
- **Skill Templates**: Start from blank, weather API, or command execution templates
- **Visual Editor**: Edit `skill.yml` and `SKILL.md` directly in the browser
- **Status Indicators**: See which skills are loaded, have missing config, or need environment variables
- **Environment Setup**: Set required environment variables for the current session

## Manual Skill Creation

### Directory Structure

```
~/.crybot/workspace/skills/
└── your-skill-name/
    ├── skill.yml      # Required: Skill definition
    └── SKILL.md       # Optional: Documentation
```

### Example: Weather Skill

Here's a complete example of a weather skill that uses the OpenWeatherMap API:

#### Directory Structure

```
~/.crybot/workspace/skills/
└── weather/
    ├── skill.yml
    └── SKILL.md
```

#### skill.yml

```yaml
name: weather
version: 1.0.0
description: Get current weather information for any location

tool:
  name: get_weather
  description: Get current weather for a location using OpenWeatherMap API
  parameters:
    type: object
    properties:
      location:
        type: string
        description: City name, state code, or country code (e.g., "London", "New York", "Tokyo")
      units:
        type: string
        description: Temperature units
        enum_values:
          - celsius
          - fahrenheit
        default: celsius
    required:
      - location

execution:
  type: http
  url: https://api.openweathermap.org/data/2.5/weather
  method: GET
  params:
    q: "{{location}}"
    units: "{% if units == 'fahrenheit' %}imperial{% else %}metric{% endif %}"
    appid: "${CRYBOT_WEATHER_API_KEY}"
  response_format: |
    Weather in {{name}}, {{sys.country}}: {{weather[0].description}}
    Temperature: {{main.temp}}° {{main.feels_like}}° (feels like)
    Humidity: {{main.humidity}}%
    Wind: {{wind.speed}} m/s
    Conditions: {{weather[0].main}}

requires:
  - CRYBOT_WEATHER_API_KEY
```

### SKILL.md

```markdown
# Weather Skill

Get current weather information for any location worldwide using the OpenWeatherMap API.

## Setup

1. Get a free API key from [OpenWeatherMap](https://openweathermap.org/api)
2. Set the environment variable:
   ```bash
   export CRYBOT_WEATHER_API_KEY="your_api_key_here"
   ```
3. Restart Crybot to load the skill

## Usage

Ask Crybot questions like:
- "What's the weather in Tokyo?"
- "How's the weather in London?"
- "What's the temperature in New York in Fahrenheit?"

## Tool

This skill provides the `get_weather` tool to the agent.

## Configuration

- **location**: City name, state code, or country code (e.g., "London", "New York", "Tokyo")
- **units**: Temperature units (celsius or fahrenheit, default: celsius)
```

## skill.yml Reference

### Top-Level Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Unique identifier for the skill |
| `version` | string | No | Version string (default: "1.0.0") |
| `description` | string | No | Human-readable description |
| `tool` | object | Yes | Tool definition (see below) |
| `execution` | object | Yes | Execution configuration (see below) |
| `requires` | array | No | List of required environment variables |

### Tool Definition

```yaml
tool:
  name: tool_name              # Tool name (used by LLM)
  description: Tool description
  parameters:
    type: object
    properties:
      param_name:
        type: string
        description: Parameter description
        enum_values:            # Optional: list of valid values
          - value1
          - value2
        default: default_value  # Optional: default value
    required:
      - param_name              # List of required parameters
```

### Execution Configuration

#### HTTP Execution (Currently Supported)

```yaml
execution:
  type: http
  url: https://api.example.com/endpoint
  method: GET                  # GET, POST, PUT, DELETE, PATCH
  params:                      # Optional: Query parameters
    param1: "{{value}}"
    param2: "${ENV_VAR}"
  headers:                     # Optional: Request headers
    Authorization: "Bearer ${API_KEY}"
  body:                        # Optional: Request body (POST/PUT/PATCH)
    '{"key": "{{value}}"}'
  response_format: |           # Optional: Response template
    Result: {{field.name}}
```

#### Command Execution (Future)

```yaml
execution:
  type: command
  command: /path/to/script
  args:
    - "{{arg1}}"
    - "{{arg2}}"
  working_dir: /optional/path
```

#### Crystal Execution (Future)

```yaml
execution:
  type: crystal
  class_name: MySkillClass
  method: execute              # Optional (default: "execute")
```

## Template Syntax

Skills use a simple template syntax for dynamic values:

### Variable Substitution

- `{{variable}}` - Substitute a parameter value
- `${ENV_VAR}` - Substitute an environment variable

### Conditionals

```yaml
{% if variable == 'value' %}
  value_if_true
{% endif %}
```

```yaml
{% if variable == 'value' %}
  value_if_equal
{% else %}
  value_if_not_equal
{% endif %}
```

### Response Formatting

The `response_format` field uses templates to extract and format values from JSON responses:

```yaml
response_format: |
  Weather in {{name}}: {{weather[0].description}}
  Temperature: {{main.temp}}°
```

For nested arrays, use index notation:
- `{{array[0].field}}` - First item's field
- `{{array[1].field}}` - Second item's field

## Environment Variables

Use the `requires` field to specify required environment variables:

```yaml
requires:
  - API_KEY
  - ANOTHER_VAR
```

Skills with missing environment variables will show a "Missing Env" status in the Web UI and will not be loaded until the variables are set.

### Setting Environment Variables

**Via Web UI:**
1. Open the skill editor
2. Go to the "Environment" tab
3. Enter values for the required environment variables
4. Click "Set Environment Variables"
5. Click "Reload Skills" to apply

**Note:** Environment variables set via the Web UI only affect the current session. For persistence, set them in your shell profile (`~/.bashrc`, `~/.zshrc`, etc.):

```bash
export API_KEY="your_api_key_here"
export ANOTHER_VAR="your_value_here"
```

## Incomplete Configuration Handling

When a skill is added or has incomplete configuration, Crybot provides helpful feedback:

### Status Indicators

The Web UI shows different status badges for each skill:

| Status | Description |
|--------|-------------|
| 🟢 **Loaded** | Skill is properly configured and all requirements are met |
| 🔵 **Configured** | Skill has valid config but needs to be reloaded |
| 🟡 **Missing Env** | Skill config is valid but environment variables are not set |
| 🔴 **Invalid Config** | The `skill.yml` file has syntax or validation errors |
| ⚫ **No Config** | The skill directory exists but has no `skill.yml` file |

### Automatic Validation

When you save a skill in the Web UI:
1. The YAML syntax is validated
2. Required fields are checked
3. Environment variable requirements are detected
4. Any errors are displayed immediately

### Prompting for Missing Data

When a skill requires environment variables:
1. Open the skill in the Web UI
2. Navigate to the "Environment" tab
3. The UI will show all required environment variables
4. Enter values and click "Set Environment Variables"
5. Reload skills to activate the skill

## Troubleshooting

### Skill Not Loading

1. Check the Crybot logs for error messages
2. In the Web UI, look for red "Invalid Config" badges
3. Verify the `skill.yml` syntax is correct (use the Validate button)
4. Ensure all required environment variables are set
5. Check that the skill directory is in `~/.crybot/workspace/skills/`
6. Click "Reload Skills" after making changes

### View Loaded Skills

**Via Logs:**
```
[Skill] Loaded: weather
[Skill] Loaded 1 skill(s), 0 error(s)
```

**Via Web UI:**
Skills with a green "Loaded" badge are currently active.

### Testing a Skill

You can test skills by asking Crybot to use the tool:
```
You: What's the weather in Tokyo?
Crybot: [Calls get_weather tool]
```

The tool call will appear in the logs:
```
[Tool] Calling get_weather with {location: "Tokyo"}
```

## Future Enhancements

The following features are planned for future releases:

- **Command Skills**: Execute external scripts (Python, bash, etc.)
- **Crystal Skills**: Compiled Crystal classes for complex tools
- **Skill Dependencies**: Skills that depend on other skills
- **Skill Validation Testing**: Built-in testing framework for skills
- **Hot Reload**: Automatically reload skills when files change
