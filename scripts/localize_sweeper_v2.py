"""
Sweeper V2: catches ALL remaining hardcoded strings missed by v1.
More aggressive pattern matching, handles dialogs, SnackBars, helpers.
"""
import os
import re
import json
import sys

sys.stdout.reconfigure(encoding='utf-8')

SCREENS_DIR = r"d:\vidyasetu\lib\screens"
EXISTING_DICT = r"d:\vidyasetu\scripts\extracted_strings.json"
OUTPUT_DICT = r"d:\vidyasetu\scripts\extracted_strings_v2.json"

# Load existing dict
with open(EXISTING_DICT, 'r', encoding='utf-8') as f:
    extracted_dict = json.load(f)

# --- SKIP LIST: strings that should NOT be translated ---
SKIP_STRINGS = {
    # Language names (must stay in native script)
    'English', 'Hindi (हिन्दी)', 'Bengali (বাংলা)', 'Marathi (मराठी)',
    'Telugu (తెలుగు)', 'Tamil (தமிழ்)', 'Gujarati (ગુજરાતી)',
    'Kannada (ಕನ್ನಡ)', 'Urdu (اردو)',
    # Ringtone names (product names)
    'Nokia Classic', 'Classic Phone', 'Gentle Chime', 'Morning Bell',
    'Soft Melody', 'Bright Tone', 'Crystal Alert', 'Rising Pulse', 'Echo Ring',
    # Technical / non-translatable
    'VidyaSetu', 'Jitsi Meet', 'Google', 'Firebase',
}

def get_key_name(text):
    key = re.sub(r'[^a-zA-Z0-9 ]', '', text).strip().lower().replace(' ', '_')
    if len(key) > 40:
        key = key[:40].strip('_')
    if not key:
        return None
    return key

def should_skip(text):
    text = text.strip()
    if len(text) <= 1:
        return True
    if text in SKIP_STRINGS:
        return True
    if '$' in text:  # interpolation
        return True
    if text.startswith('assets/') or text.startswith('http'):
        return True
    if re.match(r'^[#0-9xA-Fa-f]+$', text):
        return True
    return False

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original = content
    modified = False
    
    # Pattern: Text('static string') or Text("static string")
    # But NOT already context.tr
    def text_replacer(match):
        nonlocal modified
        full = match.group(0)
        text = match.group(1)
        
        if should_skip(text):
            return full
        
        key = get_key_name(text)
        if not key:
            return full
        
        # Dedupe key
        base_key = key
        counter = 1
        while key in extracted_dict and extracted_dict[key] != text:
            key = f"{base_key}_{counter}"
            counter += 1
        
        extracted_dict[key] = text
        modified = True
        
        # Replace the string with context.tr('key')
        return full.replace(f"'{text}'", f"context.tr('{key}')").replace(f'"{text}"', f"context.tr('{key}')")
    
    # Match Text('...') and Text("...")
    content = re.sub(r"(?<!context\.tr\()Text\(\s*'([^']+)'\s*([,)])", text_replacer, content)
    content = re.sub(r'(?<!context\.tr\()Text\(\s*"([^"]+)"\s*([,)])', text_replacer, content)
    
    # hintText: '...' and labelText: '...'
    def hint_replacer(match):
        nonlocal modified
        full = match.group(0)
        prefix = match.group(1)
        text = match.group(2)
        
        if should_skip(text):
            return full
        
        key = get_key_name(text)
        if not key:
            return full
        
        base_key = key
        counter = 1
        while key in extracted_dict and extracted_dict[key] != text:
            key = f"{base_key}_{counter}"
            counter += 1
        
        extracted_dict[key] = text
        modified = True
        return f"{prefix}: context.tr('{key}')"
    
    content = re.sub(r"(hintText|labelText|helperText):\s*'([^']+)'", hint_replacer, content)
    
    # title: Text('...')
    def title_text_replacer(match):
        nonlocal modified
        full = match.group(0)
        text = match.group(1)
        
        if should_skip(text):
            return full
        
        key = get_key_name(text)
        if not key:
            return full
        
        base_key = key
        counter = 1
        while key in extracted_dict and extracted_dict[key] != text:
            key = f"{base_key}_{counter}"
            counter += 1
        
        extracted_dict[key] = text
        modified = True
        return full.replace(f"'{text}'", f"context.tr('{key}')")
    
    content = re.sub(r"title:\s*Text\(\s*'([^']+)'\s*([,)])", title_text_replacer, content)
    
    # Remove const from any widget now containing context.tr
    content = re.sub(r'const\s+Text\(context\.tr', r'Text(context.tr', content)
    content = re.sub(r'const\s+SnackBar\(([^;]*?)context\.tr', r'SnackBar(\1context.tr', content, flags=re.DOTALL)
    content = re.sub(r'const\s+InputDecoration\(([^;]*?)context\.tr', r'InputDecoration(\1context.tr', content, flags=re.DOTALL)
    
    if modified:
        # Ensure import exists
        if 'localization_service.dart' not in content:
            last_import = content.rfind('import ')
            if last_import != -1:
                end_of_line = content.find('\n', last_import)
                import_str = "\nimport 'package:vidyasetu/services/localization_service.dart';\n"
                content = content[:end_of_line+1] + import_str + content[end_of_line+1:]
        
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Updated: {os.path.relpath(filepath, SCREENS_DIR)}")

# Process all files
for root, _, files in os.walk(SCREENS_DIR):
    for file in files:
        if file.endswith('.dart'):
            process_file(os.path.join(root, file))

# Write updated dict
with open(OUTPUT_DICT, 'w', encoding='utf-8') as f:
    json.dump(extracted_dict, f, indent=2, ensure_ascii=False)

print(f"\nTotal dictionary size: {len(extracted_dict)} keys")
