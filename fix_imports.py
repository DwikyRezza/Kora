import re

with open('lib/features/home/presentation/screens/home_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Fix relative imports
content = content.replace("import '../models/", "import '../../../../models/")
content = content.replace("import '../services/", "import '../../../../services/")
content = content.replace("import '../theme/", "import '../../../../theme/")
content = content.replace("import '../utils/", "import '../../../../utils/")
content = content.replace("import '../widgets/", "import '../../../../widgets/")
content = content.replace("import '../main.dart';", "import '../../../../main.dart';")

content = content.replace("import 'search_screen.dart';", "import '../../../../screens/search_screen.dart';")
content = content.replace("import 'notification_screen.dart';", "import '../../../../screens/notification_screen.dart';")
content = content.replace("import 'running_tracker_screen.dart';", "import '../../../../screens/running_tracker_screen.dart';")
content = content.replace("import 'workout_setup_screen.dart';", "import '../../../../screens/workout_setup_screen.dart';")
content = content.replace("import 'profile_screen.dart';", "import '../../../../screens/profile_screen.dart';")
content = content.replace("import 'workout_detail_screen.dart';", "import '../../../../screens/workout_detail_screen.dart';")

# Fix _isLoadingFeed which wasn't replaced
content = content.replace("_isLoadingFeed", "(state.status == HomeStatus.loading)")

with open('lib/features/home/presentation/screens/home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
