#!/bin/sh
DIR="$HOME/.claude/skills/api-usage"
mkdir -p "$DIR"
curl -fsSL https://raw.githubusercontent.com/you/claude-api-usage/main/SKILL.md -o "$DIR/SKILL.md"
curl -fsSL https://raw.githubusercontent.com/you/claude-api-usage/main/api_usage.py -o "$DIR/api_usage.py"
echo "Installed. Use /api-usage in Claude Code."
