import os
import re

package_name = 'ai_vision_pro'
lib_dir = 'lib'

# Pattern for relative imports starting with '
pattern_single = re.compile(r"import\s+'(\.\./|\./|(?!\w+:|dart:))([^']+)'")
# Pattern for relative imports starting with "
pattern_double = re.compile(r'import\s+"(\.\./|\./|(?!\w+:|dart:))([^"]+)"')

for root, dirs, files in os.walk(lib_dir):
    for file in files:
        if file.endswith('.dart'):
            filepath = os.path.join(root, file)
            with open(filepath, 'r', encoding='utf-8') as f:
                lines = f.readlines()
            
            new_lines = []
            changed = False
            
            current_rel_path = os.path.relpath(root, lib_dir).replace('\\', '/')
            if current_rel_path == '.':
                current_rel_path = ''

            for line in lines:
                new_line = line
                
                # Check single quotes
                match = pattern_single.search(line)
                if match and 'package:' not in line and 'dart:' not in line:
                    rel_path = match.group(1) + match.group(2)
                    # Convert rel_path to absolute package path
                    abs_path = os.path.normpath(os.path.join(root, rel_path))
                    rel_to_lib = os.path.relpath(abs_path, lib_dir).replace('\\', '/')
                    new_line = f"import 'package:{package_name}/{rel_to_lib}';\n"
                    changed = True
                
                # Check double quotes
                match = pattern_double.search(line)
                if match and 'package:' not in line and 'dart:' not in line:
                    rel_path = match.group(1) + match.group(2)
                    abs_path = os.path.normpath(os.path.join(root, rel_path))
                    rel_to_lib = os.path.relpath(abs_path, lib_dir).replace('\\', '/')
                    new_line = f'import "package:{package_name}/{rel_to_lib}";\n'
                    changed = True
                
                new_lines.append(new_line)
            
            if changed:
                print(f"Updating {filepath}")
                with open(filepath, 'w', encoding='utf-8') as f:
                    f.writelines(new_lines)
