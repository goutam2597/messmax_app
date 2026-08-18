import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/blog_repository.dart';
import 'blog_state.dart';

class BlogCubit extends Cubit<BlogState> {
  final BlogRepository _repository;

  String? _searchQuery;
  String _selectedCategory = 'All';

  BlogCubit({BlogRepository? repository})
      : _repository = repository ?? BlogRepository(),
        super(
          BlogRepository.getDefaultCached() != null
              ? BlogLoaded(
                  response: BlogRepository.getDefaultCached()!,
                  selectedCategory: 'All',
                )
              : const BlogInitial(),
        );

  Future<void> fetchBlogs({
    String? search,
    String? category,
    bool forceRefresh = false,
  }) async {
    _searchQuery = search;
    if (category != null) {
      _selectedCategory = category;
    }

    final isDefault = (search == null || search.isEmpty) &&
        (_selectedCategory == 'All');

    if (isDefault && !forceRefresh && BlogRepository.getDefaultCached() != null) {
      emit(BlogLoaded(
        response: BlogRepository.getDefaultCached()!,
        searchQuery: _searchQuery,
        selectedCategory: _selectedCategory,
      ));
      return;
    }

    if (state is! BlogLoaded) {
      emit(const BlogLoading());
    }

    try {
      final res = await _repository.getBlogs(
        search: _searchQuery,
        category: _selectedCategory,
        forceRefresh: forceRefresh,
      );
      emit(BlogLoaded(
        response: res,
        searchQuery: _searchQuery,
        selectedCategory: _selectedCategory,
      ));
    } catch (e) {
      if (state is! BlogLoaded) {
        emit(BlogError(e.toString()));
      }
    }
  }

  void searchBlogs(String query) {
    fetchBlogs(
      search: query,
      category: _selectedCategory,
    );
  }

  void filterCategory(String category) {
    fetchBlogs(
      search: _searchQuery,
      category: category,
    );
  }
}
