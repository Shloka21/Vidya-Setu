"""
Aggressive const remover: finds ANY line with both 'const' and 'context.tr'
and removes the 'const' keyword from that line.
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
            lines = f.readlines()
        
        modified = False
        new_lines = []
        for line in lines:
            if 'const ' in line and 'context.tr(' in line:
                # Remove ALL const keywords from this line
                new_line = line.replace('const ', '')
                if new_line != line:
                    modified = True
                    total_fixes += 1
                new_lines.append(new_line)
            else:
                new_lines.append(line)
        
        if modified:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.writelines(new_lines)
            print(f"Fixed: {os.path.relpath(filepath, SCREENS_DIR)}")

print(f"\nTotal lines fixed: {total_fixes}")
