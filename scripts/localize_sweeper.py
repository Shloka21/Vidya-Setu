import os
import re
import json
import logging

logging.basicConfig(level=logging.INFO)

SCREENS_DIR = r"d:\vidyasetu\lib\screens"
OUTPUT_DICT_FILE = r"d:\vidyasetu\scripts\extracted_strings.json"

# Regex to find Text('something static') or Text("something static")
text_pattern = re.compile(r"Text\(\s*['\"]([^'\"]+)['\"]\s*(?:,.*?)?\)")
hint_pattern = re.compile(r"hintText:\s*['\"]([^'\"]+)['\"]")
label_txt_pattern = re.compile(r"labelText:\s*['\"]([^'\"]+)['\"]")
title_txt_pattern = re.compile(r"title:\s*Text\(\s*['\"]([^'\"]+)['\"]\s*(?:,.*?)?\)")

extracted_dict = {}

def get_key_name(text):
    # Convert text to snake case key
    key = re.sub(r'[^a-zA-Z0-9 ]', '', text).strip().lower().replace(' ', '_')
    if len(key) > 30:
        key = key[:30].strip('_')
    if not key:
        return None
    return key

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original_content = content
    modified = False

    def replacer(match):
        nonlocal modified
        original_text = match.group(1)
        
        # Skip empty or highly interpolated looking strings directly
        if not original_text.strip() or '$' in original_text:
            return match.group(0)

        key = get_key_name(original_text)
        if not key:
            return match.group(0)

        # Build unique key if duplicate string values clash 
        base_key = key
        counter = 1
        while key in extracted_dict and extracted_dict[key] != original_text:
            key = f"{base_key}_{counter}"
            counter += 1

        extracted_dict[key] = original_text
        modified = True
        
        # Determine replacement shape based on what matched
        full_match = match.group(0)
        if full_match.startswith('Text('):
            # Preserve rest of arguments if they exist
            rest = full_match[full_match.find(match.group(1))+len(match.group(1))+1:]
            return f"Text(context.tr('{key}'){rest}"
        elif full_match.startswith('hintText:'):
            return f"hintText: context.tr('{key}')"
        elif full_match.startswith('labelText:'):
            return f"labelText: context.tr('{key}')"
        elif full_match.startswith('title: Text('):
            rest = full_match[full_match.find(match.group(1))+len(match.group(1))+1:]
            return f"title: Text(context.tr('{key}'){rest}"
            
        return match.group(0)

    # Note: re.sub only works dynamically via function if substitution is simple.
    new_content = text_pattern.sub(replacer, content)
    new_content = hint_pattern.sub(replacer, new_content)
    new_content = label_txt_pattern.sub(replacer, new_content)
    
    if modified:
        # Check if localization extension needs importing
        if 'LocalizationExtension' not in new_content and 'localization_service.dart' not in new_content:
            # Add package import at the top
            import_str = "import 'package:vidyasetu/services/localization_service.dart';\n"
            # Find last import to place it cleanly
            last_import_idx = new_content.rfind('import ')
            if last_import_idx != -1:
                end_of_line = new_content.find('\n', last_import_idx)
                new_content = new_content[:end_of_line+1] + import_str + new_content[end_of_line+1:]
            else:
                new_content = import_str + new_content

        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        logging.info(f"Updated: {filepath}")

if not os.path.exists(os.path.dirname(OUTPUT_DICT_FILE)):
    os.makedirs(os.path.dirname(OUTPUT_DICT_FILE))

for root, _, files in os.walk(SCREENS_DIR):
    for file in files:
        if file.endswith('.dart'):
            # Skip profile screens which we already localized manually
            if 'profile_screen' in file or 'localization' in file:
                continue
            process_file(os.path.join(root, file))

# Write out dict
with open(OUTPUT_DICT_FILE, 'w', encoding='utf-8') as f:
    json.dump(extracted_dict, f, indent=2)

print(f"Extracted {len(extracted_dict)} unique strings.")
