import re

with open('lib/features/running/bloc/running_bloc.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("import '../../../services/social_service.dart';", "import '../../../services/social_service.dart';\nimport '../../../services/profile_service.dart';")

with open('lib/features/running/bloc/running_bloc.dart', 'w', encoding='utf-8') as f:
    f.write(content)
