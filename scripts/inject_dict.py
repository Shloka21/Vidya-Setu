import json
import re

DICT_FILE = r"d:\vidyasetu\scripts\extracted_strings.json"
TARGET_FILE = r"d:\vidyasetu\lib\services\localization_service.dart"

with open(DICT_FILE, 'r', encoding='utf-8') as f:
    extracted_dict = json.load(f)

# Format the dict as dart map entries
entries = []
for k, v in extracted_dict.items():
    # escape single quotes
    safe_v = v.replace("'", "\\'")
    # remove any literal newlines inside values that might break it
    safe_v = safe_v.replace('\n', '\\n')
    entries.append(f"    '{k}': '{safe_v}',")

entries_str = "\n".join(entries)

with open(TARGET_FILE, 'r', encoding='utf-8') as f:
    content = f.read()

# find where _english ends
end_idx = content.find('  };\n}')
if end_idx != -1:
    # insert our entries right before the closing brace
    new_content = content[:end_idx] + "\n    // --- AUTO INJECTED ---\n" + entries_str + "\n" + content[end_idx:]
    with open(TARGET_FILE, 'w', encoding='utf-8') as f:
        f.write(new_content)
    print("Injected successfully!")
else:
    print("Could not find insertion point!")
