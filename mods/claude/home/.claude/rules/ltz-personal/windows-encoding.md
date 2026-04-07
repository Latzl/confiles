---
name: windows-encoding
description: GBK encoding handling for Windows files (WSL /mnt/ or C: paths)
paths: ["**"]
---

# Windows File GBK Encoding Handling

When a file path matches Windows file patterns, encoding must be handled per the `ltz-windows-encoding` skill.

## Windows File Detection

A file is considered a Windows file when ANY of the following conditions are met:

- **WSL path**: absolute path starts with `/mnt/{c,d,e,...}/`
- **Windows path**: absolute path starts with `{C,D,E,...}:\`

> Linux files do not need this handling.

## Reference

See skill: **ltz-windows-encoding**