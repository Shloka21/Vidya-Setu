"""
Multiline const remover: finds const widgets that span multiple lines
and contain context.tr() deeper inside.
"""
import os
import re
import sys

sys.stdout.reconfigure(encoding='utf-8')

SCREENS_DIR = r"d:\vidyasetu\lib\screens"

total_fixes = 0

for root, _, files in os.walk(SCREENS_DIR):
    for file in files:
        if not file.endswith('.dart'):
            continue
        filepath = os.path.join(root, file)
        
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original = content
        
        # Pattern: const <WidgetName>(  ...  context.tr  ...  )
        # We need to find 'const ' followed by an identifier and ( 
        # where context.tr appears before the matching )
        
        # Strategy: find all occurrences of 'const ' followed by a capitalized word and (
        # then check if context.tr appears within that scope
        
        # Simple approach: find const keywords, look ahead for context.tr in next ~10 lines
        lines = content.split('\n')
        new_lines = []
        i = 0
        while i < len(lines):
            line = lines[i]
            # Check if this line has 'const ' followed by a widget constructor
            const_match = re.search(r'\bconst\s+([A-Z]\w*)\s*\(', line)
            if const_match and 'context.tr' not in line:
                # Look ahead up to 15 lines for context.tr
                lookahead = '\n'.join(lines[i:min(i+15, len(lines))])
                if 'context.tr(' in lookahead:
                    # Count parens to see if context.tr is inside this const scope
                    # Simple heuristic: just remove const from this line
                    new_line = line.replace('const ' + const_match.group(1), const_match.group(1), 1)
                    if new_line != line:
                        total_fixes += 1
                        new_lines.append(new_line)
                        i += 1
                        continue
            new_lines.append(line)
            i += 1
        
        new_content = '\n'.join(new_lines)
        if new_content != original:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(new_content)
            print(f"Fixed multiline const: {os.path.relpath(filepath, SCREENS_DIR)}")

print(f"\nTotal multiline fixes: {total_fixes}")
