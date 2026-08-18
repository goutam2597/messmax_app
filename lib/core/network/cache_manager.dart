import 'package:messmax_app/features/ads/data/repositories/ads_repository.dart';
import 'package:messmax_app/features/ads/data/repositories/user_ad_repository.dart';
import 'package:messmax_app/features/bazar_schedule/data/repositories/bazar_schedule_repository.dart';
import 'package:messmax_app/features/blog/data/repositories/blog_repository.dart';
import 'package:messmax_app/features/dashboard/data/repositories/dashboard_repository.dart';
import 'package:messmax_app/features/home/data/repositories/home_repository.dart';
import 'package:messmax_app/features/members/data/repositories/member_repository.dart';
import 'package:messmax_app/features/mess/data/repositories/mess_repository.dart';
import 'package:messmax_app/features/profile/data/repositories/account_repository.dart';
import 'package:messmax_app/core/network/auth_storage.dart';
import 'package:messmax_app/core/network/dio_client.dart';
import 'package:messmax_app/core/logger/app_logger.dart';

/// Central Cache Manager for MessMax App.
/// Provides a unified method to clear all in-memory repository caches
/// during user logout or account switching.
class CacheManager {
  CacheManager._();

  static void clearAll() {
    try {
      DashboardRepository.clearCache();
      MessRepository.clearCache();
      MemberRepository.clearCache();
      BazarScheduleRepository.clearCache();
      AccountRepository.clearCache();
      AdsRepository.clearCache();
      UserAdRepository.clearCache();
      BlogRepository.clearCache();
      HomeRepository.clearCache();
      AppLogger.i('CacheManager: all repository caches successfully cleared');
    } catch (e) {
      AppLogger.e('CacheManager.clearAll error: $e');
    }
  }

  static Future<void> onLogout() async {
    clearAll();
    await AuthStorage.clear();
    DioClient.clearAuthToken();
  }
}
