# Edit Tool Usage

## Mandatory: Built-in Tools Only for File Modification

**ALWAYS** use `Edit`, `Write`, or `NotebookEdit` to modify files. These are the **only** acceptable tools for file writes.

**NEVER** use the following for file modifications:
- `Bash` with `sed`, `awk`, `perl`, `python`, `ruby`, etc.
- Any shell redirection (`>`, `>>`) via Bash
- `Bash` with heredoc/`cat` tricks

```bash
# WRONG
python3 << 'PYEOF'
with open('file', 'w') as f:
    f.write(...)
PYEOF

sed -i 's/old/new/' file

awk '{gsub(/old/,"new")}1' file > tmp && mv tmp file
```

```bash
# CORRECT
Edit tool:
  file_path: /absolute/path
  old_string: exact text to replace
  new_string: replacement text
```

## Why This Rule Exists

The `Edit` tool is strict: `old_string` must match the file **exactly** — character-for-character, including whitespace and indentation. Repeated "String not found" errors are a symptom of not following this rule.

## When Edit Fails Repeatedly

See skill: **ltz-edit-tool-troubleshooting** (`~/.claude/skills/ltz-edit-tool-troubleshooting/SKILL.md`)