# simple-claude-statusline

> Minimal, readable status line for [Claude Code](https://claude.ai/code) — no Node, no npm, just a shell script.

```
Sonnet 4.6 | my-project [main*] | +356 -48 | ctx:39% | 5h:24% ⏳ 2h16m | 7d:37% ⏳ 4d6h
```

---

## Features

- **Git-aware** — shows repo name, branch, and dirty state
- **Session tracking** — lines added/removed since session start
- **Rate limits** — 5h and 7d usage with countdown to reset
- **Context window** — how full your context is
- **Worktree support** — shows active worktree name
- **Vim mode** — INSERT/VISUAL indicator (silent in NORMAL)
- **No dependencies** — just `jq`, `git`, `awk` (all standard on macOS/Linux)

---

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/nathankim0/simple-claude-statusline/main/install.sh | sh
```

Requires `jq` — install with `brew install jq` if missing.

Restart Claude Code after install.

---

## What each field means

```
Sonnet 4.6 | my-project [main*] | +356 -48 | ctx:39% | 5h:24% ⏳ 2h16m | 7d:37% ⏳ 4d6h
│             │                   │           │          │                   │
│             │                   │           │          │                   └ 7-day rate limit + reset
│             │                   │           │          └ 5-hour rate limit + reset
│             │                   │           └ context window usage
│             │                   └ lines added / removed this session
│             └ git root name + branch (* = uncommitted changes)
└ model name (Claude prefix stripped)
```

| Field | Notes |
|-------|-------|
| Model | `Claude ` prefix stripped for brevity |
| Workspace | Git root directory name. Falls back to `basename` of cwd |
| Branch | `[main]` clean · `[main*]` dirty · `{name}` worktree |
| Lines | Hidden when both are zero |
| Vim mode | Only shown when INSERT / VISUAL / REPLACE |
| Reset time | `23m` · `2h16m` · `4d6h` — hidden when limit already reset |

---

## Manual install

```sh
cp statusline.sh ~/.claude/statusline.sh
```

Add to `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/statusline.sh"
  }
}
```

Restart Claude Code.
