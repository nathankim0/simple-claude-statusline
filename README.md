# simple-claude-statusline

A minimal Claude Code status line that shows model name, current workspace path, and ASCII progress bars for context window and rate limit usage.

## Preview

```
Claude Sonnet 4.6 | /Users/you/my-project | ctx:[██░░░░░░░░] 21% | 5h:[██░░░░░░░░] 23% | 7d:[████░░░░░░] 37%
```

## Requirements

- [jq](https://stedolan.github.io/jq/)
- `awk` (standard on macOS/Linux)

## Installation

1. Copy `statusline.sh` to a permanent location:

```sh
cp statusline.sh ~/.claude/statusline.sh
chmod +x ~/.claude/statusline.sh
```

2. Add to `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/statusline.sh"
  }
}
```

3. Restart Claude Code.

## What it shows

| Field | Description |
|-------|-------------|
| Model | Current model display name |
| Path | Full working directory path |
| `ctx:[████░░░░░░] N%` | Context window usage |
| `5h:[████░░░░░░] N%` | 5-hour rate limit usage |
| `7d:[████░░░░░░] N%` | 7-day rate limit usage |

Rate limit fields only appear when data is available (after first response).
