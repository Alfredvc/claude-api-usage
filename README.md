# claude-meta

## Understanding how you interact with Claude — and how Claude performs

This plugin extracts structured data from your Claude Code sessions. It turns raw JSONL logs into queryable interaction data and detailed cost breakdowns — giving you visibility into collaboration patterns, failure modes, token efficiency, and spend.

```
  extract-conversations                api-usage
  ┌─────────────────────┐        ┌──────────────────┐
  │ Parse session logs   │        │ Token counts and  │
  │ into structured      │        │ cost breakdown    │
  │ conversation data    │        │ by model and type │
  └─────────────────────┘        └──────────────────┘
  conversations → sessions          per-model pricing
  → turns with tool usage,          cache efficiency
  skills, errors, tokens            monthly projections
```

**Extract** your interaction history as structured data. **Analyze** what that usage costs.

---

## Install

Requires Python 3.10+ and Claude Code 1.0.33+.

### From marketplace

```sh
/plugin install claude-meta
```

### Local development

Register as a local marketplace, install, then symlink for live editing:

```sh
claude plugin marketplace add /path/to/claude-meta
claude plugin install claude-meta@claude-meta

# Replace cache with symlink to source
rm -rf ~/.claude/plugins/cache/claude-meta/claude-meta/1.0.0
ln -s /path/to/claude-meta ~/.claude/plugins/cache/claude-meta/claude-meta/1.0.0
```

Skills are namespaced under the plugin:
- `claude-meta:api-usage`
- `claude-meta:extract-conversations`

---

## Skills

### `extract-conversations` — Structured interaction data

Parses Claude Code session logs into structured JSON organized as **conversations → sessions → turns**, capturing everything needed to understand how you and Claude collaborate.

Per-turn data includes:
- User messages, timestamps, and durations
- Tool usage counts and skill invocations (CLI vs model-triggered)
- Token usage (input, cache read, cache write, output)
- Interruptions with post-interrupt user text
- Errors (bash failures, tool errors)
- Subagent metadata (inlined from separate log files)
- Session file paths and turn UUIDs for drilling deeper

```sh
python3 skills/extract-conversations/scripts/extract_session_data.py [project_dir] [options]
```

| Argument | Description |
|---|---|
| `project_dir` | Path to the project root (default: current directory) |
| `--no-subdirs` | Exclude worktrees and sub-directories |
| `--all` | Scan every Claude project |
| `--from YYYY-MM-DD` | Filter sessions starting from this date |
| `--to YYYY-MM-DD` | Filter sessions up to this date |
| `--session ID` | Filter to a specific session |

**Example queries with jq:**

```sh
# Extract to file
python3 skills/extract-conversations/scripts/extract_session_data.py ~/src/my-project > /tmp/conversations.json

# Find all interrupted turns
jq '[.conversations[].sessions[].turns[] | select(.interrupted)]' /tmp/conversations.json

# Skill usage frequency
jq '[.conversations[].sessions[].turns[].skills[].name] | group_by(.) | map({skill: .[0], count: length}) | sort_by(-.count)' /tmp/conversations.json

# Turns with errors
jq '[.conversations[].sessions[].turns[] | select(.errors | length > 0) | {timestamp, errors, tools: (.tools | keys)}]' /tmp/conversations.json

# Subagent summary
jq '{total: [.conversations[].sessions[].turns[].subagents[]?] | length, with_errors: [.conversations[].sessions[].turns[].subagents[]? | select(.errors | length > 0)] | length}' /tmp/conversations.json
```

---

### `api-usage` — Token usage and cost breakdown

Answers the question: what would your Claude Code usage cost at API prices?

![Example output](docs/output.png)

- Per-model breakdown — input, cache write (5m and 1h TTL), cache read, and output tokens
- Cost matrix across all models and token types
- Cache efficiency stats — hit rate, savings, and effective cost multiplier
- Time summary with average monthly cost and per-model projections
- Multi-project support — single project, worktrees, or everything at once
- Parallel processing for large log sets

```sh
python3 skills/api-usage/scripts/api_usage.py [project_dir] [--no-subdirs] [--all]
```

| Argument | Description |
|---|---|
| `project_dir` | Path to the project root (default: current directory) |
| `--no-subdirs` | Exclude worktrees and sub-directories from the scan |
| `--all` | Scan every Claude project — your grand total across everything |
