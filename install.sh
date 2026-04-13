#!/bin/sh
set -e

INSTALL_DIR="$HOME/.claude"
SCRIPT_PATH="$INSTALL_DIR/statusline.sh"
SETTINGS_PATH="$INSTALL_DIR/settings.json"

# Download statusline.sh
echo "Installing simple-claude-statusline..."
curl -fsSL https://raw.githubusercontent.com/nathankim0/simple-claude-statusline/main/statusline.sh -o "$SCRIPT_PATH"
chmod +x "$SCRIPT_PATH"

# Inject into settings.json
if [ ! -f "$SETTINGS_PATH" ]; then
  echo '{}' > "$SETTINGS_PATH"
fi

# Check if jq is available
if ! command -v jq >/dev/null 2>&1; then
  echo "Warning: jq is not installed. Please install it first (brew install jq)."
  exit 1
fi

# Add statusLine to settings.json (preserves existing config)
tmp=$(mktemp)
jq --arg cmd "bash $SCRIPT_PATH" \
  '.statusLine = {"type": "command", "command": $cmd}' \
  "$SETTINGS_PATH" > "$tmp" && mv "$tmp" "$SETTINGS_PATH"

echo "Done! Restart Claude Code to apply."
echo ""
echo "Preview:"
echo "  Claude Sonnet 4.6 | /your/workspace | ctx:[██░░░░░░░░] 21% | 5h:[██░░░░░░░░] 23% | 7d:[████░░░░░░] 37%"
