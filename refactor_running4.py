import re

with open('lib/features/running/presentation/screens/running_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

wrapper_class = '''class RunningTrackerScreen extends StatelessWidget {
  final double userWeight;
  const RunningTrackerScreen({super.key, required this.userWeight});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RunningBloc(),
      child: RunningTrackerView(userWeight: userWeight),
    );
  }
}

class RunningTrackerView extends StatefulWidget {
  final double userWeight;
  const RunningTrackerView({super.key, required this.userWeight});

  @override
  State<RunningTrackerView> createState() => _RunningTrackerViewState();
}

class _RunningTrackerViewState extends State<RunningTrackerView>
'''

content = re.sub(r'class RunningTrackerScreen extends StatefulWidget \{.*?class _RunningTrackerScreenState extends State<RunningTrackerScreen>', wrapper_class, content, flags=re.DOTALL)

with open('lib/features/running/presentation/screens/running_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
