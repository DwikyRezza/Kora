import re

with open('lib/features/running/presentation/screens/running_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("import '../theme/", "import '../../../../theme/")
content = content.replace("import '../models/", "import '../../../../models/")
content = content.replace("import '../services/", "import '../../../../services/")
content = content.replace("import '../utils/", "import '../../../../utils/")
content = content.replace("import '../widgets/", "import '../../../../widgets/")
content = content.replace("context.space", "Responsive.space")
content = content.replace("context.font", "Responsive.font")

with open('lib/features/running/presentation/screens/running_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
