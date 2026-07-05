import re

with open('lib/features/home/presentation/screens/home_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add imports
import_addition = '''import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/home_bloc.dart';
import '../../bloc/home_event.dart';
import '../../bloc/home_state.dart';
'''
content = re.sub(r'(import .*?;[\r\n]+)(class HomeScreen)', r'\1' + import_addition + r'\n\2', content)

# 2. Replace the variables and initState
new_state_class = '''class _HomeScreenState extends State<HomeScreen> {
  late ScrollController _scrollController;
  
  HomeState get state => context.watch<HomeBloc>().state;

  bool get _isLoading => state.status == HomeStatus.loading || state.status == HomeStatus.initial;
  String get _userName => state.userName;
  String? get _userPhotoUrl => state.userPhotoUrl;
  double get _baseTargetProtein => state.baseTargetProtein;
  double get _targetCalories => state.targetCalories;
  int get _unreadNotifs => state.unreadNotifs;
  List<Workout> get _todayWorkouts => state.todayWorkouts;
  List<ProteinEntry> get _todayProtein => state.todayProtein;
  List<ScheduleEvent> get _upcomingEvents => state.upcomingEvents;
  int get _todayCaloriesConsumed => state.todayCaloriesConsumed;
  int get _todayCaloriesBurned => state.todayCaloriesBurned;
  int get _todayWorkoutDuration => state.todayWorkoutDuration;
  double get _todayWorkoutDistance => state.todayWorkoutDistance;
  int get _currentWorkoutStreak => state.currentWorkoutStreak;
  List<Map<String, dynamic>> get _feedPosts => state.feedPosts;
  bool get _isLoadingMore => state.isLoadingMore;
  bool get _hasMoreData => state.hasMoreData;
  int get _dashboardTab => state.dashboardTab;
  double get _totalProteinToday => state.totalProteinToday;
  double get _totalProteinNeeded => state.totalProteinNeeded;

  @override
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
content = re.sub(r'class _HomeScreenState extends State<HomeScreen>.*?@override\s+Widget build\(BuildContext context\) \{', new_state_class + '\n  @override\n  Widget build(BuildContext context) {', content, flags=re.DOTALL)

# Replace assignments to _dashboardTab
content = content.replace('setState(() => _dashboardTab = 0)', 'context.read<HomeBloc>().add(const HomeChangeTab(0))')
content = content.replace('setState(() => _dashboardTab = 1)', 'context.read<HomeBloc>().add(const HomeChangeTab(1))')
content = content.replace('setState(() => _dashboardTab = index)', 'context.read<HomeBloc>().add(HomeChangeTab(index))')

# Replace _loadData() calls
content = content.replace('_loadData()', 'context.read<HomeBloc>().add(const HomeLoadData(isRefresh: true))')

with open('lib/features/home/presentation/screens/home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
