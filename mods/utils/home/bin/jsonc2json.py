#!/usr/bin/env python3
import json5
import json
import sys
import os

if len(sys.argv) < 2:
    print("Usage: python convert_jsonc.py <input_file.jsonc>")
    sys.exit(1)

input_path = sys.argv[1]

output_path = os.path.splitext(input_path)[0] + ".json"

with open(input_path, 'r') as f:
    data = json5.load(f)

with open(output_path, 'w') as f:
    json.dump(data, f, indent=2)

print(f"Converted: {input_path} -> {output_path}")