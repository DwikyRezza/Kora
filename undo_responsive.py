import re

with open('lib/features/running/presentation/screens/running_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("Responsive.space", "context.space")
content = content.replace("Responsive.font", "context.font")

with open('lib/features/running/presentation/screens/running_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
