import 'package:shared_preferences/shared_preferences.dart';

import '../../core/network/dio_client.dart';
import '../logger/app_logger.dart';

/// Fetches translations from backend API and caches locally.
/// Falls back to bundled assets if API unavailable.
class RemoteTranslationService {
  static const _kTranslationsPrefix = 'remote_translations_';
  static const _kChecksumPrefix = 'remote_translations_checksum_';
  static const _endpoint = '/v1/translations';

  /// Fetch translations for a locale, merge with fallback.
  /// Returns flat map "group.key" => value.
  static Future<Map<String, String>> fetchLocale(
    String locale, {
    bool forceRefresh = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = '$_kTranslationsPrefix$locale';

    // Always try API first to pick up admin edits; use cached only as fallback.
    // Previous early-return from SharedPreferences caused stale auth keys to persist
    // until app reinstall — now we fetch fresh every cold start / locale switch.

    try {
      final dio = DioClient.instance;
      final res = await dio.get(_endpoint, queryParameters: {'locale': locale});
      if (res.statusCode == 200 && res.data is Map) {
        final data = res.data as Map<String, dynamic>;
        if (data['success'] == true && data['data'] is Map) {
          final localeMap = (data['data'] as Map)[locale];
          if (localeMap is Map) {
            final flat = <String, String>{};
            localeMap.forEach((k, v) => flat[k.toString()] = v.toString());
            // Persist
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
            return flat;
          }
        }
      }
    } catch (e) {
      AppLogger.w('Remote translations fetch failed for $locale: $e');
    }

    // Fallback to cached
    final fallback = prefs.getString(cacheKey);
    if (fallback != null) {
      try {
        return _decodeMap(fallback);
      } catch (_) {}
    }
    return {};
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
    for (int i = 0; i < s.length; i++) {
      if (s[i] == '\\' && i + 1 < s.length) {
        final n = s[i + 1];
        if (n == 'n') {
          buf.write('\n');
          i++;
        } else if (n == '\\') {
          buf.write('\\');
          i++;
        } else if (n == '=') {
          buf.write('=');
          i++;
        } else {
          buf.write(s[i]);
        }
      } else {
        buf.write(s[i]);
      }
    }
    return buf.toString();
  }
}
