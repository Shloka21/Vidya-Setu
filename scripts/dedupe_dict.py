import re

FILE_PATH = r"d:\vidyasetu\lib\services\localization_service.dart"

with open(FILE_PATH, 'r', encoding='utf-8') as f:
    content = f.read()

# Extract just the map part
start_idx = content.find('static const Map<String, String> _english = {')
end_idx = content.find('  };\n}', start_idx)

if start_idx != -1 and end_idx != -1:
    map_str = content[start_idx:end_idx]
    
    # We will iterate lines, map keys. If key seen before, we skip line.
    lines = map_str.split('\n')
    seen_keys = set()
    new_lines = []
    
    key_pattern = re.compile(r"^\s*'([^']+)'\s*:")
    for line in lines:
        match = key_pattern.search(line)
        if match:
            key = match.group(1)
            if key in seen_keys:
                continue # Skip duplicate
            seen_keys.add(key)
        new_lines.append(line)
        
    new_map_str = '\n'.join(new_lines)
    new_content = content[:start_idx] + new_map_str + content[end_idx:]
    
    with open(FILE_PATH, 'w', encoding='utf-8') as f:
        f.write(new_content)
    print("Deduplicated!")
