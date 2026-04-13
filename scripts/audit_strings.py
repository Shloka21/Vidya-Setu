"""
Audit script: finds all remaining hardcoded English strings in screens
that are NOT wrapped in context.tr().
"""
import os
import re
import sys

sys.stdout.reconfigure(encoding='utf-8')

SCREENS_DIR = r"d:\vidyasetu\lib\screens"

# Patterns to find hardcoded strings that SHOULD be translated
patterns = [
    # Text('something') NOT using context.tr
    (r"Text\(\s*'([^']+)'\s*[,)]", "Text('...')"),
    (r'Text\(\s*"([^"]+)"\s*[,)]', 'Text("...")'),
    # title: Text('something')
    (r"title:\s*Text\(\s*'([^']+)'\s*[,)]", "title: Text('...')"),
    # hintText / labelText / helperText
    (r"hintText:\s*'([^']+)'", "hintText: '...'"),
    (r'hintText:\s*"([^"]+)"', 'hintText: "..."'),
    (r"labelText:\s*'([^']+)'", "labelText: '...'"),
    # SnackBar content Text
    (r"SnackBar\(content:\s*Text\(\s*'([^']+)'", "SnackBar Text"),
    # AppBar title Text
    (r"AppBar\([^)]*title:\s*Text\(\s*'([^']+)'", "AppBar title"),
]

# Strings to SKIP (not translatable)
skip_patterns = [
    r'^\d+$',           # pure numbers
    r'^#[0-9a-fA-F]+$', # hex colors
    r'^\$',             # interpolation
    r'^https?://',      # URLs
    r'^assets/',        # asset paths
    r'^[A-Z]{1,3}$',    # short codes like 'S', 'M'
    r'^\.',             # file extensions
    r'^[a-z_]+$',       # looks like a key already
    r'^\\u',            # unicode escapes
    r'^context\.tr',    # already translated
]

def should_skip(text):
    text = text.strip()
    if len(text) <= 1:
        return True
    for pat in skip_patterns:
        if re.match(pat, text):
            return True
    return False

results = {}

for root, _, files in os.walk(SCREENS_DIR):
    for file in files:
        if not file.endswith('.dart'):
            continue
        filepath = os.path.join(root, file)
        rel = os.path.relpath(filepath, SCREENS_DIR)
        
        with open(filepath, 'r', encoding='utf-8') as f:
            lines = f.readlines()
        
        file_hits = []
        for line_num, line in enumerate(lines, 1):
            # Skip lines that already use context.tr
            if 'context.tr(' in line:
                continue
            
            for pattern, label in patterns:
                for match in re.finditer(pattern, line):
                    text = match.group(1)
                    if should_skip(text):
                        continue
                    # Skip if it contains $ (interpolation)
                    if '$' in text:
                        continue
                    file_hits.append((line_num, label, text))
        
        if file_hits:
            results[rel] = file_hits

# Print report
total = 0
for filepath, hits in sorted(results.items()):
    print(f"\n{'='*60}")
    print(f"FILE: {filepath} ({len(hits)} untranslated strings)")
    print(f"{'='*60}")
    for line_num, label, text in hits:
        print(f"  Line {line_num:4d} | {label:20s} | \"{text}\"")
        total += 1

print(f"\n{'='*60}")
print(f"TOTAL: {total} untranslated strings across {len(results)} files")
print(f"{'='*60}")
