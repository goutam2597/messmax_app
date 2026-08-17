import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/blog_model.dart';
import '../models/blog_response_model.dart';

class BlogRepository {
  final Dio _dioClient;

  BlogRepository({Dio? dioClient})
      : _dioClient = dioClient ?? DioClient.instance;

  Future<BlogResponseModel> getBlogs({
    String? search,
    String? category,
    int page = 1,
  }) async {
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
    return BlogResponseModel.fromJson(data);
  }

  Future<BlogModel> getBlogDetails(String slug) async {
    final response = await _dioClient.get('${ApiEndpoints.blogs}/$slug');
    final data = response.data['data'] as Map<String, dynamic>;
    return BlogModel.fromJson(data['blog'] as Map<String, dynamic>);
  }
}
