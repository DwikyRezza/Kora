import re

with open('lib/features/home/presentation/screens/home_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace('_loadData()', 'context.read<HomeBloc>().add(const HomeLoadData(isRefresh: true))')

with open('lib/features/home/presentation/screens/home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
