import os
import re
import sys

sys.stdout.reconfigure(encoding='utf-8')

SCREENS_DIR = r"d:\vidyasetu\lib\screens"
WIDGETS_DIR = r"d:\vidyasetu\lib\widgets"

def find_hardcoded_strings():
    results = []
    
    # We want to find strings that are NOT wrapped in context.tr
    # and are passed as common UI arguments.
    patterns = [
        # Button text: AppButton(text: '...')
        r"text:\s*['\"]([^'\"]+)['\"]",
        # Label text: label: '...' (e.g. NavigationBarItem)
        r"label:\s*['\"]([^'\"]+)['\"]",
        # Dialog title/content, SnackBar content
        r"title:\s*['\"]([^'\"]+)['\"]",
        r"content:\s*['\"]([^'\"]+)['\"]",
        # Tooltip
        r"tooltip:\s*['\"]([^'\"]+)['\"]",
        # Custom helper texts passed as strings: _buildStat('...', '...')
        r"_\w+\(\s*['\"]([^'\"]+)['\"]",
        r"_\w+\([^,]+,\s*['\"]([^'\"]+)['\"]",
    ]
    
    for d in [SCREENS_DIR, WIDGETS_DIR]:
        for root, _, files in os.walk(d):
            for file in files:
                if not file.endswith('.dart'):
                    continue
                path = os.path.join(root, file)
                
                with open(path, 'r', encoding='utf-8') as f:
                    lines = f.readlines()
                    
                for i, line in enumerate(lines):
                    # skip if already translated
                    if 'context.tr(' in line:
                        continue
                        
                    # Also find plain Text('...') that we might have missed
                    text_matches = re.findall(r"Text\(\s*['\"]([^'\"]+)['\"](?:(?:,\s*style)|\))", line)
                    for tm in text_matches:
                        if not tm.startswith('assets') and len(tm) > 2 and 'http' not in tm and '$' not in tm:
                            results.append(f"{os.path.basename(path)}:{i+1} Text() -> {tm}")

                    for pat in patterns:
                        matches = re.findall(pat, line)
                        for m in matches:
                            # Heuristic skips: 
                            if len(m) <= 1 or m.startswith('http') or m.startswith('assets/'):
                                continue
                            if m.endswith('.png') or m.endswith('.json') or m.endswith('.svg') or m.endswith('.jpg'):
                                continue
                            if '{' in m or '$' in m: # skip pure interpolation
                                continue
                            
                            results.append(f"{os.path.basename(path)}:{i+1} -> {m}")
                            
    return results

hits = find_hardcoded_strings()
with open(r"d:\vidyasetu\scripts\hardcoded_report.txt", "w", encoding="utf-8") as f:
    for h in hits:
        f.write(h + "\n")
print(f"Found {len(hits)} missed strings!")
