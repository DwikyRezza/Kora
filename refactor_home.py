import re

with open('lib/features/home/presentation/screens/home_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add imports
content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:flutter_bloc/flutter_bloc.dart';\nimport '../../bloc/home_bloc.dart';\nimport '../../bloc/home_event.dart';\nimport '../../bloc/home_state.dart';")

# Replace variable accesses
replacements = {
    r'_isLoading\b': '(state.status == HomeStatus.loading || state.status == HomeStatus.initial)',
    r'_isLoadingFeed\b': 'false', # Not strictly tracked separately now, or use isLoadingMore
    r'_isLoadingMore\b': 'state.isLoadingMore',
    r'_userName\b': 'state.userName',
    r'_userPhotoUrl\b': 'state.userPhotoUrl',
    r'_baseTargetProtein\b': 'state.baseTargetProtein',
    r'_targetCalories\b': 'state.targetCalories',
    r'_unreadNotifs\b': 'state.unreadNotifs',
    r'_todayWorkouts\b': 'state.todayWorkouts',
    r'_todayProtein\b': 'state.todayProtein',
    r'_upcomingEvents\b': 'state.upcomingEvents',
    r'_todayCaloriesConsumed\b': 'state.todayCaloriesConsumed',
    r'_todayCaloriesBurned\b': 'state.todayCaloriesBurned',
    r'_todayWorkoutDuration\b': 'state.todayWorkoutDuration',
    r'_todayWorkoutDistance\b': 'state.todayWorkoutDistance',
    r'_currentWorkoutStreak\b': 'state.currentWorkoutStreak',
    r'_feedPosts\b': 'state.feedPosts',
    r'_dashboardTab\b': 'state.dashboardTab',
    r'_totalProteinToday\b': 'state.totalProteinToday',
    r'_totalProteinNeeded\b': 'state.totalProteinNeeded',
}

# The trick is to only replace them inside the Widget methods. 
# But let's just do a global replace for these safe variable names.
for old, new in replacements.items():
    content = re.sub(old, new, content)

# Remove the state variables from the class
# Just let them be replaced, and we will manually fix any issues or just ignore warnings for unused variables if they were somehow missed.
# Actually, the methods _loadData, _refreshData, etc. can be stripped or changed to use context.read().

with open('lib/features/home/presentation/screens/home_screen_refactored.dart', 'w', encoding='utf-8') as f:
    f.write(content)
