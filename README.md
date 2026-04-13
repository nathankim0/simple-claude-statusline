# simple-claude-statusline

A compact, zero-dependency Claude Code status line. Shows model, git branch, session changes, context usage, and rate limits — all in a single readable line.

## Preview

```
Sonnet 4.6 | my-project [main*] | +356 -48 | ctx:39% | 5h:24% ⏳ 2h16m | 7d:37% ⏳ 4d6h
```

## Requirements

- [jq](https://stedolan.github.io/jq/) — `brew install jq`
- `git`, `awk`, `date` (standard on macOS/Linux)

## One-line Install

```sh
curl -fsSL https://raw.githubusercontent.com/nathankim0/simple-claude-statusline/main/install.sh | sh
```

Then restart Claude Code.

## Manual Installation

1. Copy `statusline.sh` to a permanent location:

```sh
cp statusline.sh ~/.claude/statusline.sh
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

| Field | Example | Description |
|-------|---------|-------------|
| Model | `Sonnet 4.6` | Current model (`Claude ` prefix stripped) |
| Workspace | `my-project [main*]` | Git root name + branch (`*` = uncommitted changes) |
| Worktree | `my-project [main] {feat}` | Worktree name shown in braces when active |
| Lines changed | `+356 -48` | Lines added/removed this session |
| Vim mode | `-- INS --` | Shown only when not in NORMAL mode |
| Context | `ctx:39%` | Context window usage |
| 5h rate limit | `5h:24% ⏳ 2h16m` | 5-hour usage + time until reset |
| 7d rate limit | `7d:37% ⏳ 4d6h` | 7-day usage + time until reset |

- Rate limit and reset timer only appear after the first response
- Lines changed hidden when both are zero
- Reset time format: `23m` / `2h16m` / `4d6h`
