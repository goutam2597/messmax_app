import 'package:equatable/equatable.dart';
import 'blog_model.dart';

class BlogResponseModel extends Equatable {
  final List<BlogModel> blogs;
  final List<String> categories;
  final int total;
  final int currentPage;
  final int lastPage;
  final bool hasMore;

  const BlogResponseModel({
    required this.blogs,
    required this.categories,
    required this.total,
    required this.currentPage,
    required this.lastPage,
    required this.hasMore,
  });

  factory BlogResponseModel.fromJson(Map<String, dynamic> json) {
    final blogsList = (json['blogs'] as List<dynamic>?)
            ?.map((e) => BlogModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];

    final categoriesList = (json['categories'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const ['All'];

    final pagination = json['pagination'] as Map<String, dynamic>? ?? {};

    return BlogResponseModel(
      blogs: blogsList,
      categories: categoriesList,
      total: pagination['total'] as int? ?? blogsList.length,
      currentPage: pagination['current_page'] as int? ?? 1,
      lastPage: pagination['last_page'] as int? ?? 1,
      hasMore: pagination['has_more'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        blogs,
        categories,
        total,
        currentPage,
        lastPage,
        hasMore,
      ];
}
