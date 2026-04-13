"""
Inject the v2 dictionary into localization_service.dart,
replacing the entire _english map contents.
"""
import json
import re
import sys

sys.stdout.reconfigure(encoding='utf-8')

DICT_FILE = r"d:\vidyasetu\scripts\extracted_strings_v2.json"
TARGET_FILE = r"d:\vidyasetu\lib\services\localization_service.dart"

with open(DICT_FILE, 'r', encoding='utf-8') as f:
    extracted_dict = json.load(f)

# Build the dart map entries
entries = []
for k, v in sorted(extracted_dict.items()):
    safe_v = v.replace("\\", "\\\\").replace("'", "\\'")
    entries.append(f"    '{k}': '{safe_v}',")

entries_str = "\n".join(entries)

with open(TARGET_FILE, 'r', encoding='utf-8') as f:
    content = f.read()

# Find and replace the entire _english map
pattern = r"(static const Map<String, String> _english = \{)\n.*?(\n  \};\n\})"
replacement = f"\\1\n{entries_str}\n  }};\n}}"

new_content = re.sub(pattern, replacement, content, flags=re.DOTALL)

if new_content != content:
    with open(TARGET_FILE, 'w', encoding='utf-8') as f:
        f.write(new_content)
    print(f"Injected {len(extracted_dict)} keys into localization_service.dart")
else:
    print("ERROR: Could not find insertion pattern!")
