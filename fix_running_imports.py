import os, glob

def replace_import(file_path):
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Replace the old import path
        # It could be import 'running_tracker_screen.dart'; or import '../screens/running_tracker_screen.dart';
        # Because we moved it to eatures/running/presentation/screens/running_screen.dart
        if 'screens/running_tracker_screen.dart' in content:
            new_content = content.replace('screens/running_tracker_screen.dart', 'features/running/presentation/screens/running_screen.dart')
            
            if new_content != content:
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(new_content)
                print(f"Fixed {file_path}")
    except Exception as e:
        pass

for root, _, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            replace_import(os.path.join(root, file))
