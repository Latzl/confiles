---
name: ltz-edit-tool-troubleshooting
description: Diagnose and resolve Edit/Write tool failures, especially "String not found" errors
origin: user
---

# Edit Tool Troubleshooting

When `Edit` fails with `String not found in file`, the `old_string` does not match the file exactly. This skill provides a systematic diagnosis process.

## Root Cause

The `Edit` tool requires **exact character-level matching** of `old_string` against file content. Common causes of mismatch:

1. **Indentation mismatch** — tabs vs spaces, or wrong number of tabs/spaces
2. **Heredoc/multiline strings** — physical lines in the file may have different indentation than expected
3. **Escape sequences** — `\"` vs `"`, or `\\` vs `\`
4. **Hidden characters** — trailing whitespace, Windows line endings (`\r\n`)
5. **String truncated** — file lines longer than expected, causing visual misalignment
6. **File modified** — another process changed the file since the last read

## Diagnosis Workflow

### Step 1: Read the exact file content

Read the specific lines you want to edit **immediately before** each Edit attempt.

```bash
# Use python3 to show raw bytes — reveals tabs, trailing spaces, \r
python3 -c "
with open('/path/to/file', 'r') as f:
    lines = f.readlines()
for i, l in enumerate(lines[start-1:end], start):
    print(f'{i}: {repr(l)}')
"
```

Compare `repr()` output against your `old_string`. The difference is the problem.

### Step 2: Match indentation exactly

If the file uses tabs, your `old_string` must start with the same number of `\t` characters.

File content shown as:
```
   → → foo
```
Means 2 tabs + `foo`. Use `\t\tfoo` in `old_string`.

### Step 3: Handle multiline strings

For multiline `old_string`, use the **full physical lines** as they appear in the file, including all leading tabs.

If the preview display collapses tabs visually, use `repr()` (Step 1) to see exact whitespace.

### Step 4: Single-line Edit for clarity

When `old_string` is complex (long, multiline, special chars), prefer a **single-line** Edit targeting the unique prefix of the block you want to replace. One Edit, one unique string = no ambiguity.

## Decision Tree

```
Edit fails
  │
  ├─ "String not found" → Read file with repr() → fix old_string
  │
  ├─ "File has not been read yet" → Read the file first, then Edit
  │
  ├─ "Ambiguous" → Make old_string longer/more unique
  │
  └─ Unsolvable (binary file, huge file) → Ask user to make the change manually
```

## Key Principle

**Diagnose before retrying.** Running the same Edit with the same `old_string` after a failure will always fail. Either:
- Fix `old_string` based on `repr()` output, OR
- Use `Write` to replace the entire file (when the target section is large enough)

Do NOT use Bash/sed/python as a workaround — that defeats the purpose of the audit trail and the rule.

## Quick Reference

| Problem | Diagnosis | Fix |
|---------|-----------|-----|
| Indentation off | `repr()` line | Use `\t` / exact spaces |
| `"` vs `\"` | `repr()` char | Use actual `"` not escaped |
| Lines 207-208 no indent | File is tab-indented | Remove leading spaces in old_string |
| Hidden `\r` | `repr()` shows `\r` | File may need `dos2unix` — tell user |
| File changed | Content differs | Re-read file |
