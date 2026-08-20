import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/network/dio_client.dart';
import '../logger/app_logger.dart';
import 'app_translations.dart';

/// Fetches translations from backend API and caches locally.
class RemoteTranslationService {
  static const _kTranslationsPrefix = 'remote_translations_';
  static const _kChecksumPrefix = 'remote_translations_checksum_';
  static const _endpoint = '/v1/translations';
  static const _fallbackEndpoint = '/api/v1/translations';

  /// Fetch translations for a locale, using local cache first for instant UI response,
  /// then updating silently from API in the background.
  static Future<Map<String, String>> fetchLocale(
    String locale, {
    bool forceRefresh = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = '$_kTranslationsPrefix$locale';

    // 1. Check cached translations first for instant UI response (<1ms)
    final fallback = prefs.getString(cacheKey);
    Map<String, String> cachedMap = {};
    if (fallback != null && fallback.isNotEmpty) {
      try {
        cachedMap = _decodeMap(fallback);
      } catch (_) {}
    }

    // 2. Trigger asynchronous background update from API
    _refreshFromApi(locale, prefs, cacheKey);

    return cachedMap;
  }

  static Future<void> _refreshFromApi(
    String locale,
    SharedPreferences prefs,
    String cacheKey,
  ) async {
    try {
      final dio = DioClient.instance;
      Response<dynamic>? res;
      try {
        res = await dio.get(_endpoint, queryParameters: {'locale': locale});
      } catch (_) {
        // Try direct /api prefix fallback if domain root routing differed
        res = await dio.get(_fallbackEndpoint, queryParameters: {'locale': locale});
      }

      if (res.statusCode == 200 && res.data is Map) {
        final data = res.data as Map<String, dynamic>;
        if (data['success'] == true && data['data'] is Map) {
          final localeMap = (data['data'] as Map)[locale];
          if (localeMap is Map) {
            final flat = <String, String>{};
            localeMap.forEach((k, v) {
              final valStr = v.toString().replaceAll(r'\n', '\n').replaceAll('\\n', '\n');
              flat[k.toString()] = valStr;
            });
            // Persist to local cache
            await prefs.setString(cacheKey, _encodeMap(flat));
            if (data['checksum'] is String) {
              await prefs.setString(
                '$_kChecksumPrefix$locale',
                data['checksum'] as String,
              );
            }
            AppLogger.i(
              'Remote translations loaded: $locale (${flat.length} keys)',
            );
            if (AppTranslations.locale == locale) {
              AppTranslations.updateCurrent(flat);
            }
          }
        }
      }
    } catch (e) {
      AppLogger.w('Remote translations fetch failed for $locale: $e');
    }
  }

  static String _encodeMap(Map<String, String> m) {
    final pairs = m.entries
        .map((e) => '${_escape(e.key)}=${_escape(e.value)}')
        .join('\n');
    return pairs;
  }

  static Map<String, String> _decodeMap(String s) {
    final out = <String, String>{};
    for (final line in s.split('\n')) {
      final idx = line.indexOf('=');
      if (idx <= 0) continue;
      final k = _unescape(line.substring(0, idx));
      final v = _unescape(line.substring(idx + 1));
      out[k] = v;
    }
    return out;
  }

  static String _escape(String s) =>
      s.replaceAll('\\', '\\\\').replaceAll('\n', '\\n').replaceAll('=', '\\=');
  static String _unescape(String s) {
    final buf = StringBuffer();
    var esc = false;
    for (var i = 0; i < s.length; i++) {
      final c = s[i];
      if (esc) {
        if (c == 'n') {
          buf.write('\n');
        } else if (c == '=') {
          buf.write('=');
        } else {
          buf.write(c);
        }
        esc = false;
      } else if (c == '\\') {
        esc = true;
      } else {
        buf.write(c);
      }
    }
    return buf.toString();
  }
}
