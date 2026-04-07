---
name: ltz-windows-encoding
description: Handle GBK encoding for Windows version source files — detect, read, convert, and write back
origin: user
---

# Windows File GBK Encoding Handling

Handle GBK encoding when reading or editing Windows version source files. Always use temp files for conversion — never convert in-place.

## Windows File Detection

A file is considered a Windows file when ANY of the following conditions are met:

- **WSL path**: absolute path starts with `/mnt/{c,d,e,...}/`
- **Windows path**: absolute path starts with `{C,D,E,...}:\`

> Linux files do not need this skill.

## Reading

Read the file **directly** (Read tool handles it). If content appears garbled, the file is likely GBK-encoded — proceed with the conversion workflow below.

## Conversion Workflow

When you need to edit a Windows file, convert via temp files to avoid data loss. **Never convert in-place** (overwriting the original before reading).

### Step 1: Convert GBK → UTF-8 (temp file)

```bash
iconv -f GBK -t UTF-8 "/path/to/file.cpp" -o "/tmp/file_utf8.cpp"
```

### Step 2: Read and edit the temp file

Use the Read tool on `/tmp/file_utf8.cpp`. Edit with the Edit/Write tool on the temp file path.

### Step 3: Convert UTF-8 → GBK (temp file to destination)

```bash
iconv -f UTF-8 -t GBK "/tmp/file_utf8.cpp" -o "/path/to/file.cpp"
```

### Step 4: Verify

Confirm the round-trip did not corrupt content:
```bash
iconv -f GBK -t UTF-8 "/path/to/file.cpp" | diff - "/tmp/file_utf8.cpp"
```

## When GBK Tools Are Unavailable

If `iconv` lacks GBK support (e.g., minimal containers), use Python:

```python
with open("/path/to/file.cpp", "rb") as f:
    content = f.read().decode("gbk")

with open("/tmp/file_utf8.cpp", "w", encoding="utf-8") as f:
    f.write(content)
```

## Key Principle

**Read from original, write back through temp file.** Only overwrite the original after the full round-trip is verified.
