import os
import re

SCREENS_DIR = r"d:\vidyasetu\lib\screens"

def process(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original = content
    
    # "const SnackBar(content: Text(context.tr"
    # Wait, simple sub for `const SnackBar`
    
    def replacer_snackbar(match):
        body = match.group(0)
        if 'context.tr' in body:
            return body.replace('const SnackBar(', 'SnackBar(')
        return body
    content = re.sub(r'const\s+SnackBar\([^;]+', replacer_snackbar, content)

    # PopupMenuItem
    def replacer_popup(match):
        body = match.group(0)
        if 'context.tr' in body:
            return body.replace('const PopupMenuItem(', 'PopupMenuItem(')
        return body
    content = re.sub(r'const\s+PopupMenuItem\([^;]+', replacer_popup, content)

    # OutlinedButton.icon
    def replacer_outbtn(match):
        body = match.group(0)
        if 'context.tr' in body:
            return body.replace('const OutlinedButton.icon(', 'OutlinedButton.icon(')
        return body
    content = re.sub(r'const\s+OutlinedButton\.icon\([^;]+', replacer_outbtn, content)

    # ElevatedButton.icon
    def replacer_elevbtn(match):
        body = match.group(0)
        if 'context.tr' in body:
            return body.replace('const ElevatedButton.icon(', 'ElevatedButton.icon(')
        return body
    content = re.sub(r'const\s+ElevatedButton\.icon\([^;]+', replacer_elevbtn, content)
    
    # Catch all: replace "const " if it ends up wrapping context.tr directly inside a parenthesis before semicolon
    # e.g. const SnackBar( ... context.tr... );
    # A bit complex so we stick to explicitly known ones.
    
    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Fixed const wrappers in {filepath}")

for root, _, files in os.walk(SCREENS_DIR):
    for file in files:
        if file.endswith('.dart'):
             process(os.path.join(root, file))
