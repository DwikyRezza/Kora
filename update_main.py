import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Replace the import
content = content.replace("import 'screens/home_screen.dart';", "import 'features/home/presentation/screens/home_screen.dart';\nimport 'package:flutter_bloc/flutter_bloc.dart';\nimport 'features/home/bloc/home_bloc.dart';")

# Wrap HomeScreen with BlocProvider
home_screen_regex = r'(HomeScreen\(\s*onGoToWorkout:.*?\s*onGoToProtein:.*?\s*onGoToSchedule:.*?\s*onGoToBodyStats:.*?\s*\))'

def replacement(match):
    return f'''BlocProvider<HomeBloc>(
                create: (context) => HomeBloc(),
                child: {match.group(1)},
              )'''

content = re.sub(home_screen_regex, replacement, content, flags=re.DOTALL)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(content)
