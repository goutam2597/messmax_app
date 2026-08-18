import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/filter_pill_bar.dart';
import '../../../../core/widgets/messmax_app_bar.dart';
import '../../../../core/widgets/network_image_cover.dart';
import '../cubit/blog_cubit.dart';
import '../cubit/blog_state.dart';
import '../../data/models/blog_model.dart';
import 'blog_detail_screen.dart';

class BlogScreen extends StatefulWidget {
  const BlogScreen({super.key});

  @override
  State<BlogScreen> createState() => _BlogScreenState();
}

class _BlogScreenState extends State<BlogScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<BlogCubit>().fetchBlogs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openDetail(BuildContext context, BlogModel blog) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BlogDetailScreen(blog: blog)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            MessMaxAppBar(
              title: 'MessMax Guides',
              subtitle:
                  'Articles & tips on room hunting and mess meal management',
              bottom: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.paperRaised,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.paperLine),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.search_rounded,
                      color: AppColors.inkFaded,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onSubmitted: (query) =>
                            context.read<BlogCubit>().searchBlogs(query),
                        decoration: const InputDecoration(
                          hintText: 'Search articles, guides, topics…',
                          hintStyle: TextStyle(
                            color: AppColors.inkFaded,
                            fontSize: 13.5,
                          ),
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty) ...[
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: AppColors.inkFaded,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          context.read<BlogCubit>().searchBlogs('');
                        },
                      ),
                      const SizedBox(width: 4),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: BlocBuilder<BlogCubit, BlogState>(
                builder: (context, state) {
                  if (state is BlogLoading || state is BlogInitial) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.brandDark,
                      ),
                    );
                  }

                  if (state is BlogError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              size: 48,
                              color: AppColors.inkFaded,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Could not load blog guides',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.brandDark,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () =>
                                  context.read<BlogCubit>().fetchBlogs(forceRefresh: true),
                              child: const Text('Try Again'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (state is BlogLoaded) {
                    final categories = state.response.categories;
                    final blogs = state.response.blogs;
                    final selectedCategory = state.selectedCategory;
                    final selectedIndex = categories.indexOf(selectedCategory);

                    return Column(
                      children: [
                        FilterPillBar(
                          labels: categories,
                          selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
                          onSelected: (index) => context
                              .read<BlogCubit>()
                              .filterCategory(categories[index]),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: blogs.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(32),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: const BoxDecoration(
                                            color: AppColors.brandSoft,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.search_off_rounded,
                                            size: 40,
                                            color: AppColors.inkFaded,
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        const Text(
                                          'No guides found',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.ink,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'No articles match your search or filter.',
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            color: AppColors.inkFaded,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : RefreshIndicator(
                                  color: AppColors.accent,
                                  onRefresh: () => context
                                      .read<BlogCubit>()
                                      .fetchBlogs(forceRefresh: true),
                                  child: ListView.separated(
                                    padding: const EdgeInsets.all(12),
                                    itemCount: blogs.length,
                                    separatorBuilder: (_, _) =>
                                        const SizedBox(height: 14),
                                    itemBuilder: (context, index) {
                                      final blog = blogs[index];
                                      return _buildArticleCard(context, blog);
                                    },
                                  ),
                                ),
                        ),
                      ],
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArticleCard(BuildContext context, BlogModel blog) {
    return GestureDetector(
      onTap: () => _openDetail(context, blog),
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (blog.coverImageUrl != null)
              SizedBox(
                height: 150,
                width: double.infinity,
                child: NetworkImageCover(url: blog.coverImageUrl),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.brandSoft,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          blog.category,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.brandDark,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        blog.readTime,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.inkFaded,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    blog.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    blog.summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: AppColors.inkSoft,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 12,
                        color: AppColors.inkFaded,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        blog.date,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.inkFaded,
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'Read Article →',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.accentDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
