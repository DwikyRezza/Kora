import re

with open('lib/features/home/presentation/screens/home_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

replacement = '''class _HomeScreenState extends State<HomeScreen> {
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
'''

content = re.sub(r'class _HomeScreenState extends State<HomeScreen>.*?@override\s+Widget build\(BuildContext context\) \{', replacement, content, flags=re.DOTALL)

# Find the end of the build method to insert the closing brace for BlocBuilder
# It returns Scaffold. We need to find where the Scaffold ends.
# Since it's hard to parse matching braces in regex, we can just replace the end of the file or use a simpler trick.
# Actually, the build method ends with:
#       ),
#     );
#   }
# 
#   Widget _buildHeader() {

content = content.replace('''      ),
    );
  }

  Widget _buildHeader() {''', '''      ),
    );
      },
    );
  }

  Widget _buildHeader(HomeState state) {''')

content = content.replace('''Widget _buildDashboardCard() {''', '''Widget _buildDashboardCard(HomeState state) {''')
content = content.replace('''Widget _buildNutritionTab() {''', '''Widget _buildNutritionTab(HomeState state) {''')
content = content.replace('''Widget _buildActivityTab() {''', '''Widget _buildActivityTab(HomeState state) {''')
content = content.replace('''Widget _buildProteinList() {''', '''Widget _buildProteinList(HomeState state) {''')
content = content.replace('''Widget _buildScheduleList() {''', '''Widget _buildScheduleList(HomeState state) {''')
content = content.replace('''List<Widget> _buildSocialFeedSlivers() {''', '''List<Widget> _buildSocialFeedSlivers(HomeState state) {''')

with open('lib/features/home/presentation/screens/home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
