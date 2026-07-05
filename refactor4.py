import re

with open('lib/features/home/presentation/screens/home_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add imports at the end of the import block
import_addition = '''import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/home_bloc.dart';
import '../../bloc/home_event.dart';
import '../../bloc/home_state.dart';
'''
content = re.sub(r'(import .*?;[\r\n]+)(class HomeScreen)', r'\1' + import_addition + r'\n\2', content)

# 2. Update initState and dispose
init_state_replacement = '''  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    context.read<HomeBloc>().add(const HomeLoadData());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.7) {
      context.read<HomeBloc>().add(HomeLoadMoreFeed());
    }
  }

  Future<void> _refreshData() async {
    context.read<HomeBloc>().add(const HomeLoadData(isRefresh: true));
  }
'''
content = re.sub(r'  @override\s+void initState\(\) \{.*?(?=  @override\s+Widget build)', init_state_replacement, content, flags=re.DOTALL)

# 3. Update build method to include BlocBuilder and extract state variables locally
build_method_replacement = '''  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        // Map state to local variables to minimize changes below
        final _isLoading = state.status == HomeStatus.loading || state.status == HomeStatus.initial;
        final _unreadNotifs = state.unreadNotifs;
        final _dashboardTab = state.dashboardTab;
        final _todayCaloriesConsumed = state.todayCaloriesConsumed;
        final _todayCaloriesBurned = state.todayCaloriesBurned;
        final _todayWorkoutDuration = state.todayWorkoutDuration;
        final _todayWorkoutDistance = state.todayWorkoutDistance;
        final _totalProteinNeeded = state.totalProteinNeeded;
        final _totalProteinToday = state.totalProteinToday;
        final _targetCalories = state.targetCalories;
        final _upcomingEvents = state.upcomingEvents;
        final _feedPosts = state.feedPosts;
        final _hasMoreData = state.hasMoreData;
        final _isLoadingMore = state.isLoadingMore;

        return Scaffold('''
content = re.sub(r'  @override\s+Widget build\(BuildContext context\) \{\s+return Scaffold\(', build_method_replacement, content)

# 4. We need to pass state variables to helper methods if we don't define them globally.
# But wait! The helper methods in _HomeScreenState already expect instance variables (_isLoading, etc.)
# If we keep them as instance variables, they won't update when state changes!
# So we MUST replace _variableName with state.variableName in the entire class EXCEPT where they are declared.

