import os
import re

SCREENS_DIR = r"d:\vidyasetu\lib\screens"

# 1. 'const Text(context' -> 'Text(context'
# 2. 'const InputDecoration(hintText: context' -> 'InputDecoration(hintText: context'
# 3. 'const [..., Text(context' -- this is harder, usually it's `const [Text` or similar. Let's just blindly remove `const ` in front of elements containing `context.tr`.

def process(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original = content
    # Remove const before Text
    content = re.sub(r'const\s+Text\(context\.tr', r'Text(context.tr', content)
    # Remove const before InputDecoration if it has context inside
    content = re.sub(r'const\s+InputDecoration\(\s*hintText:\s*(context\.tr.*?)\)', r'InputDecoration(hintText: \1)', content)
    content = re.sub(r'const\s+InputDecoration\(\s*labelText:\s*(context\.tr.*?)\)', r'InputDecoration(labelText: \1)', content)

    # Some times there's `const [Text(...)`
    # Let's do `const \[\n?\s*Text\(context\.tr` -> `[\nText(context.tr`
    content = re.sub(r'const\s+\[\s*Text\(context\.tr', r'[Text(context.tr', content)
    
    # Catch any leftover like `const <Widget>[ Text...` 
    content = re.sub(r'const\s+<Widget>\[\s*Text\(context\.tr', r'<Widget>[Text(context.tr', content)
    
    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Fixed const in {filepath}")

for root, _, files in os.walk(SCREENS_DIR):
    for file in files:
        if file.endswith('.dart'):
             process(os.path.join(root, file))
