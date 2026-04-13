import json
import re

def update_localization():
    d = json.load(open('scripts/missing_strings.json', encoding='utf-8-sig'))
    with open('lib/services/localization_service.dart', 'r', encoding='utf-8') as f:
        content = f.read()
        
    start_str = 'static const Map<String, String> _english = {'
    start = content.find(start_str) + len(start_str)
    end = content.find('};', start)
    
    english_code = content[start:end]
    english_dict = {}
    
    for line in english_code.split('\n'):
        line = line.strip()
        if not line:
            continue
            
        # Match 'key': 'value',
        match = re.match(r"'([^']+)':\s*'(.*)',?$", line)
        if match:
            english_dict[match.group(1)] = match.group(2).replace("\\'", "'")
            continue
            
        # Match 'key': "value",
        match2 = re.match(r"'([^']+)':\s*\"([^\"]+)\",?$", line)
        if match2:
            english_dict[match2.group(1)] = match2.group(2).replace('\\"', '"')

    # Update with new strings
    english_dict.update(d)
    
    new_lines = []
    for k in sorted(english_dict.keys()):
        # Escape quotes
        v = english_dict[k].replace("'", "\\'")
        new_lines.append(f"    '{k}': '{v}',")
        
    new_dict_code = '\n'.join(new_lines)
    
    new_content = content[:start] + '\n' + new_dict_code + '\n  ' + content[end:]
    
    with open('lib/services/localization_service.dart', 'w', encoding='utf-8') as f:
        f.write(new_content)

if __name__ == '__main__':
    update_localization()
