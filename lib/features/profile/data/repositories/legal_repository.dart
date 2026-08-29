import 'package:dio/dio.dart';

import '../../../../core/locale/app_translations.dart';
import '../../../../core/logger/app_logger.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/legal_document_model.dart';

/// Fetches legal pages (Privacy Policy / Terms) from the backend.
///
/// Responses are cached in memory per slug+locale so switching tabs (or
/// revisiting after a locale change) is instant and offline-friendly for the
/// session duration.
class LegalRepository {
  static final Map<String, LegalDocument> _cache = {};

  static String _cacheKey(String slug, String locale) => '$slug:$locale';

  /// Returns a previously fetched document without hitting the network.
  static LegalDocument? cached(String slug) =>
      _cache[_cacheKey(slug, AppTranslations.locale)];

  static Future<LegalDocument> fetch(String slug) async {
    final key = _cacheKey(slug, AppTranslations.locale);
    final hit = _cache[key];
    if (hit != null) return hit;

    try {
      final res = await DioClient.instance.get<dynamic>(
        '${ApiEndpoints.pagesPrivacyTerms}/$slug',
        queryParameters: {'locale': AppTranslations.locale},
        options: Options(extra: {'bypass_deduplication': true}),
      );

      if (res.statusCode == 200 && res.data is Map) {
        final body = res.data as Map<String, dynamic>;
        if (body['success'] == true && body['data'] is Map) {
          final doc = LegalDocument.fromJson(
            Map<String, dynamic>.from(body['data'] as Map),
          );
          _cache[key] = doc;
          return doc;
        }
      }
      throw DioException(
        requestOptions: RequestOptions(path: ApiEndpoints.pagesPrivacyTerms),
      );
    } on DioException {
      rethrow;
    } catch (e) {
      AppLogger.w('LegalRepository[$slug] failed: $e');
      rethrow;
    }
  }
}
