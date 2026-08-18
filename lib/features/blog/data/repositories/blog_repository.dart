import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/blog_model.dart';
import '../models/blog_response_model.dart';

class BlogRepository {
  final Dio _dioClient;
  static BlogResponseModel? _defaultBlogsCache;
  static final Map<String, BlogModel> _detailCache = {};

  BlogRepository({Dio? dioClient})
      : _dioClient = dioClient ?? DioClient.instance;

  static BlogResponseModel? getDefaultCached() => _defaultBlogsCache;

  static void clearCache() {
    _defaultBlogsCache = null;
    _detailCache.clear();
  }

  Future<BlogResponseModel> getBlogs({
    String? search,
    String? category,
    int page = 1,
    bool forceRefresh = false,
  }) async {
    final isDefault = page == 1 &&
        (search == null || search.isEmpty) &&
        (category == null || category.isEmpty || category == 'All');

    if (isDefault && !forceRefresh && _defaultBlogsCache != null) {
      return _defaultBlogsCache!;
    }

    final query = <String, dynamic>{
      'page': page,
    };
    if (search != null && search.isNotEmpty) {
      query['q'] = search;
    }
    if (category != null && category.isNotEmpty && category != 'All') {
      query['category'] = category;
    }

    final response = await _dioClient.get(
      ApiEndpoints.blogs,
      queryParameters: query,
    );

    final data = response.data['data'] as Map<String, dynamic>;
    final result = BlogResponseModel.fromJson(data);
    if (isDefault) {
      _defaultBlogsCache = result;
    }
    return result;
  }

  Future<BlogModel> getBlogDetails(String slug, {bool forceRefresh = false}) async {
    if (!forceRefresh && _detailCache.containsKey(slug)) {
      return _detailCache[slug]!;
    }
    final response = await _dioClient.get('${ApiEndpoints.blogs}/$slug');
    final data = response.data['data'] as Map<String, dynamic>;
    final result = BlogModel.fromJson(data['blog'] as Map<String, dynamic>);
    _detailCache[slug] = result;
    return result;
  }
}
