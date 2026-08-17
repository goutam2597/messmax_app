import 'package:equatable/equatable.dart';
import '../../../../core/config/app_config.dart';

class BlogModel extends Equatable {
  final int id;
  final String title;
  final String slug;
  final String category;
  final String readTime;
  final String summary;
  final String? content;
  final String? coverImageUrl;
  final bool isFeatured;
  final String date;
  final String authorName;

  const BlogModel({
    required this.id,
    required this.title,
    required this.slug,
    required this.category,
    required this.readTime,
    required this.summary,
    this.content,
    this.coverImageUrl,
    required this.isFeatured,
    required this.date,
    required this.authorName,
  });

  factory BlogModel.fromJson(Map<String, dynamic> json) {
    final rawUrl = json['cover_image_url'] as String?;
    final sanitizedUrl = AppConfig.sanitizeImageUrl(rawUrl);

    return BlogModel(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      category: json['category'] as String? ?? 'Mess Life',
      readTime: json['read_time'] as String? ?? '4 min read',
      summary: json['summary'] as String? ?? '',
      content: json['content'] as String?,
      coverImageUrl: sanitizedUrl,
      isFeatured: json['is_featured'] as bool? ?? false,
      date: json['date'] as String? ?? '',
      authorName: json['author_name'] as String? ?? 'MessMax Admin',
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        slug,
        category,
        readTime,
        summary,
        content,
        coverImageUrl,
        isFeatured,
        date,
        authorName,
      ];
}
