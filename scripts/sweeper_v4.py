import os
import re
import json
import sys

sys.stdout.reconfigure(encoding='utf-8')

SCREENS_DIR = r"d:\vidyasetu\lib\screens"
WIDGETS_DIR = r"d:\vidyasetu\lib\widgets"
EXISTING_DICT = r"d:\vidyasetu\scripts\extracted_strings_v2.json"

# Load existing dict
with open(EXISTING_DICT, 'r', encoding='utf-8') as f:
    extracted_dict = json.load(f)

# --- SKIP LIST ---
SKIP_STRINGS = {
    'English', 'Hindi (हिन्दी)', 'Bengali (বাংলা)', 'Marathi (मराठी)',
    'Telugu (తెలుగు)', 'Tamil (தமிழ்)', 'Gujarati (ગુજરાતી)',
    'Kannada (ಕನ್ನಡ)', 'Urdu (اردو)',
    'Nokia Classic', 'Classic Phone', 'Gentle Chime', 'Morning Bell',
    'Soft Melody', 'Bright Tone', 'Crystal Alert', 'Rising Pulse', 'Echo Ring',
    'VidyaSetu', 'Google', 'Firebase', '0xFF'
}

def get_key_name(text):
    text = text.replace('\\n', ' ')
    key = re.sub(r'[^a-zA-Z0-9 ]', '', text).strip().lower().replace(' ', '_')
    if len(key) > 40:
        key = key[:40].strip('_')
    if not key:
        return None
    return key

def should_skip(text):
    text = text.strip()
    if len(text) <= 1: return True
    if text in SKIP_STRINGS: return True
    if '$' in text or '{' in text: return True
    if text.startswith('assets/') or text.startswith('http'): return True
    if re.match(r'^[#0-9xA-Fa-f]+$', text): return True
    if text.endswith('.png') or text.endswith('.json') or text.endswith('.svg') or text.endswith('.jpg'): return True
    return False

def add_to_dict(text):
    key = get_key_name(text)
    if not key: return None
    
    base_key = key
    counter = 1
    while key in extracted_dict and extracted_dict[key] != text:
        key = f"{base_key}_{counter}"
        counter += 1
    
    extracted_dict[key] = text
    return key

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original = content
    modified = False

    # Helper function to do text replacements for specific regex patterns
    def replace_pattern(match):
        nonlocal modified
        full = match.group(0)
        prefix = match.group(1)
        text = match.group(2)
        suffix = match.group(3)
        
        if should_skip(text):
            return full
        
        key = add_to_dict(text)
        if not key:
            return full
            
        modified = True
        return f"{prefix}context.tr('{key}'){suffix}"

    # Handle missed Text(...) variants (that aren't already context.tr)
    text_pattern = re.compile(r"(Text\(\s*)['\"]([^'\"]+)['\"]([^)]*\))")
    content = text_pattern.sub(replace_pattern, content)

    # Handle AppButton patterns: text: 'xyz' -> text: context.tr('xyz')
    prop_pattern = re.compile(r"((?:text|label|title|content|tooltip):\s*)['\"]([^'\"]+)['\"]([,\)])")
    content = prop_pattern.sub(replace_pattern, content)
    
    # Handle passing strings to helper methods: _buildStat('xyz', ...)
    def helper_replacer(match):
        nonlocal modified
        full = match.group(0)
        prefix = match.group(1) # e.g. " _buildStat( "
        text = match.group(2)
        
        if should_skip(text): return full
        
        key = add_to_dict(text)
        if not key: return full
        
        modified = True
        return f"{prefix}context.tr('{key}')"
        
    helper_pattern = re.compile(r"((?:_\w+|SectionTitle|AppButton)\(\s*)[`'\"]([^`'\"]+)[`'\"]")
    content = helper_pattern.sub(helper_replacer, content)

    if modified:
        # Remove any newly created const violations
        content = re.sub(r'const\s+Text\(context\.tr', r'Text(context.tr', content)
        content = re.sub(r'const\s+SnackBar\(([^;]*?)context\.tr', r'SnackBar(\1context.tr', content, flags=re.DOTALL)
        content = re.sub(r'const\s+InputDecoration\(([^;]*?)context\.tr', r'InputDecoration(\1context.tr', content, flags=re.DOTALL)
        
        if 'localization_service.dart' not in content:
            last_import = content.rfind('import ')
            if last_import != -1:
                end_of_line = content.find('\n', last_import)
                import_str = "\nimport 'package:vidyasetu/services/localization_service.dart';\n"
                content = content[:end_of_line+1] + import_str + content[end_of_line+1:]
        
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Updated: {os.path.basename(filepath)}")

for d in [SCREENS_DIR, WIDGETS_DIR]:
    for root, _, files in os.walk(d):
        for file in files:
            if file.endswith('.dart'):
                process_file(os.path.join(root, file))

with open(EXISTING_DICT, 'w', encoding='utf-8') as f:
    json.dump(extracted_dict, f, indent=2, ensure_ascii=False)

print(f"\nDictionary size now: {len(extracted_dict)} keys")
