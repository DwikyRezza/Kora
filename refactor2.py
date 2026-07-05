import re

with open('lib/features/home/presentation/screens/home_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Remove the state variables and initState/dispose
content = re.sub(r'class _HomeScreenState extends State<HomeScreen>.*?@override\s+Widget build\(BuildContext context\) \{', 
'''class _HomeScreenState extends State<HomeScreen> {
  late ScrollController _scrollController;
  
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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
''', content, flags=re.DOTALL)

# Add closing brace for BlocBuilder
content = re.sub(r'(\s+)(return Scaffold\()', r'\1\2', content)
# Find the end of build method and close BlocBuilder... Actually, we can just replace the end of build method manually.
