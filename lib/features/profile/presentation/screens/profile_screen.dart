import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/locale/app_translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/messmax_app_bar.dart';
import '../../../../core/widgets/sign_out_dialog.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../ads/presentation/screens/my_ads_screen.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';
import 'account_screen.dart';
import 'legal_screen.dart';
import 'package:messmax_app/features/main/presentation/screens/main_shell_screen.dart';
import '../../../dashboard/presentation/widgets/dash_ui.dart';

/// Rounded design language matching [HomeScreen] cards (home uses 14�16px).
abstract final class _ProfileRadii {
  static const double card = 16;
  static const double button = 14;
  static const double chip = 12;
  static const double badge = 10;
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _goLogin(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        if (authState is AuthLoading) {
          return Scaffold(
            backgroundColor: AppColors.paper,
            body: SafeArea(
              child: Column(
                children: [
                  ValueListenableBuilder<int>(
                    valueListenable: AppTranslations.notifier,
                    builder: (context, _, _) =>
                        MessMaxAppBar(title: 'ui.profile_title'.tr2),
                  ),
                  Expanded(child: Center(child: _loadingHeader())),
                ],
              ),
            ),
          );
        }
        if (authState is! AuthAuthenticated) {
          return Scaffold(
            backgroundColor: AppColors.paper,
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ValueListenableBuilder<int>(
                      valueListenable: AppTranslations.notifier,
                      builder: (context, _, _) =>
                          MessMaxAppBar(title: 'ui.profile_title'.tr2),
                    ),
                    const SizedBox(height: 12),
                    DashUI.accentedCard(
                      accent: AppColors.brand,
                      shape: DashShape.blob,
                      radius: _ProfileRadii.card,
                      shadow: DashUI.cardShadow,
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: AppColors.brandSoft,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.brandDark.withValues(
                                    alpha: 0.12,
                                  ),
                                ),
                              ),
                              child: const Icon(
                                Icons.lock_rounded,
                                color: AppColors.brandDark,
                                size: 36,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ValueListenableBuilder<int>(
                              valueListenable: AppTranslations.notifier,
                              builder: (context, _, _) => Text(
                                'ui.sign_in_required'.tr2,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ValueListenableBuilder<int>(
                              valueListenable: AppTranslations.notifier,
                              builder: (context, _, _) => Text(
                                'ui.sign_in_to_continue'.tr2,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.inkFaded,
                                  height: 1.4,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: () => _goLogin(context),
                                icon: const Icon(Icons.login_rounded, size: 18),
                                label: ValueListenableBuilder<int>(
                                  valueListenable: AppTranslations.notifier,
                                  builder: (context, _, _) => Text(
                                    'ui.go_to_login'.tr2,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.brandDark,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      _ProfileRadii.button,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: TextButton(
                        onPressed: () =>
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const MainShellScreen(initialTab: 0),
                              ),
                              (_) => false,
                            ),
                        child: ValueListenableBuilder<int>(
                          valueListenable: AppTranslations.notifier,
                          builder: (context, _, _) => Text(
                            'ui.back_to_home'.tr2,
                            style: const TextStyle(
                              color: AppColors.brandDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return Scaffold(
          backgroundColor: AppColors.paper,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ValueListenableBuilder<int>(
                    valueListenable: AppTranslations.notifier,
                    builder: (context, _, _) =>
                        MessMaxAppBar(title: 'ui.profile_title'.tr2),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _authedHeader(context, authState),
                        const SizedBox(height: 16),
                        _buildDashboardButton(context),
                        const SizedBox(height: 16),
                        _quickActionsAuthed(context),
                        const SizedBox(height: 24),
                        ValueListenableBuilder<int>(
                          valueListenable: AppTranslations.notifier,
                          builder: (context, _, _) =>
                              _sectionTitle('ui.account_settings'.tr2),
                        ),
                        ValueListenableBuilder<int>(
                          valueListenable: AppTranslations.notifier,
                          builder: (context, _, _) => _menuGroup(context, [
                            (
                              icon: Icons.person_outline_rounded,
                              title: 'ui.personal_information'.tr2,
                              subtitle: 'ui.personal_info_sub'.tr2,
                            ),
                            (
                              icon: Icons.notifications_none_rounded,
                              title: 'ui.notification_preferences'.tr2,
                              subtitle: 'ui.notification_sub'.tr2,
                            ),
                          ], shape: DashShape.band),
                        ),
                        const SizedBox(height: 20),
                        ValueListenableBuilder<int>(
                          valueListenable: AppTranslations.notifier,
                          builder: (context, _, _) =>
                              _sectionTitle('ui.mess_management'.tr2),
                        ),
                        ValueListenableBuilder<int>(
                          valueListenable: AppTranslations.notifier,
                          builder: (context, _, _) => _menuGroup(context, [
                            (
                              icon: Icons.storefront_rounded,
                              title: 'ui.my_posted_seats'.tr2,
                              subtitle: 'ui.view_edit_seats'.tr2,
                            ),
                            (
                              icon: Icons.event_note_rounded,
                              title: 'ui.bazar_roster'.tr2,
                              subtitle: 'ui.assign_shopping'.tr2,
                            ),
                          ], shape: DashShape.arc),
                        ),
                        const SizedBox(height: 20),
                        ValueListenableBuilder<int>(
                          valueListenable: AppTranslations.notifier,
                          builder: (context, _, _) =>
                              _sectionTitle('ui.help_legal'.tr2),
                        ),
                        ValueListenableBuilder<int>(
                          valueListenable: AppTranslations.notifier,
                          builder: (context, _, _) => _menuGroup(context, [
                            (
                              icon: Icons.help_outline_rounded,
                              title: 'ui.help_center'.tr2,
                              subtitle: 'ui.help_sub'.tr2,
                            ),
                            (
                              icon: Icons.shield_outlined,
                              title: 'ui.privacy_terms'.tr2,
                              subtitle: 'ui.privacy_sub'.tr2,
                            ),
                          ], shape: DashShape.dots),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final confirmed = await SignOutDialog.show(
                                context,
                                userEmail: authState.user.email,
                                userName: authState.user.name,
                              );
                              if (confirmed == true && context.mounted) {
                                final rootNav = Navigator.of(
                                  context,
                                  rootNavigator: true,
                                );
                                await context.read<AuthCubit>().logout();
                                rootNav.pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const MainShellScreen(initialTab: 0),
                                  ),
                                  (_) => false,
                                );
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.danger,
                              side: const BorderSide(
                                color: AppColors.danger,
                                width: 1.2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  _ProfileRadii.button,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            icon: const Icon(Icons.logout_rounded, size: 18),
                            label: ValueListenableBuilder<int>(
                              valueListenable: AppTranslations.notifier,
                              builder: (context, _, _) => Text(
                                'ui.sign_out'.tr2,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        Center(
                          child: Column(
                            children: [
                              ValueListenableBuilder<int>(
                                valueListenable: AppTranslations.notifier,
                                builder: (context, _, _) => Text(
                                  'ui.app_version'.tr2,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.inkFaded,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                authState.user.email,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.inkFaded,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDashboardButton(BuildContext context) {
    return DashUI.accentedCard(
      accent: AppColors.brand,
      shape: DashShape.arc,
      radius: _ProfileRadii.card,
      shadow: DashUI.cardShadow,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const DashboardScreen()));
          },
          borderRadius: BorderRadius.circular(_ProfileRadii.card),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.brandSoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.dashboard_rounded,
                    color: AppColors.brandDark,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ValueListenableBuilder<int>(
                        valueListenable: AppTranslations.notifier,
                        builder: (context, _, _) => Text(
                          'ui.open_manager_dashboard'.tr2,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      ValueListenableBuilder<int>(
                        valueListenable: AppTranslations.notifier,
                        builder: (context, _, _) => Text(
                          'ui.dashboard_subtitle'.tr2,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.inkFaded,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.inkFaded,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _loadingHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.paperRaised,
        borderRadius: BorderRadius.circular(_ProfileRadii.card),
        border: Border.all(color: AppColors.paperLine),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: AppColors.brandDark,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _authedHeader(BuildContext context, AuthAuthenticated state) {
    final user = state.user;
    final avatarUrl = AppConfig.sanitizeImageUrl(user.avatarUrl);
    final isPremiumUser = user.isHostelOwner;

    return DashUI.accentedCard(
      accent: AppColors.brand,
      shape: DashShape.blob,
      radius: _ProfileRadii.card,
      rich: true,
      shadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.brandSoft,
                border: Border.all(
                  color: AppColors.brandDark.withValues(alpha: 0.15),
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: avatarUrl != null
                    ? Image.network(
                        avatarUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, obj, stk) =>
                            _initialAvatar(user.initials),
                      )
                    : _initialAvatar(user.initials),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.email,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.inkFaded,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: user.isIndividual
                          ? AppColors.amberSoft
                          : AppColors.emeraldSoft,
                      borderRadius: BorderRadius.circular(_ProfileRadii.badge),
                    ),
                    child: Text(
                      user.roleLabel,
                      style: TextStyle(
                        color: user.isIndividual
                            ? AppColors.amber
                            : AppColors.emerald,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _AccountTierBadge(isPremium: isPremiumUser),
          ],
        ),
      ),
    );
  }

  Widget _initialAvatar(String ch) => Center(
    child: Text(
      ch,
      style: const TextStyle(
        color: AppColors.brandDark,
        fontSize: 24,
        fontWeight: FontWeight.w800,
      ),
    ),
  );

  Widget _quickActionsAuthed(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AppTranslations.notifier,
      // ignore: unnecessary_underscores
      builder: (context, _, __) => Row(
        children: [
          Expanded(
            child: _actionCard(
              context,
              icon: Icons.add_circle_outline_rounded,
              title: 'ui.quick_post_seat'.tr2,
              subtitle: 'ui.quick_post_seat_sub'.tr2,
              shape: DashShape.blob,
              onTap: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const MyAdsScreen()));
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _actionCard(
              context,
              icon: Icons.restaurant_menu_rounded,
              title: 'ui.quick_meal_counter'.tr2,
              subtitle: 'ui.quick_meal_counter_sub'.tr2,
              shape: DashShape.dots,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DashboardScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required DashShape shape,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: DashUI.accentedCard(
        accent: AppColors.brand,
        shape: shape,
        radius: _ProfileRadii.card,
        shadow: DashUI.cardShadow,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.brandSoft,
                ),
                child: Icon(icon, color: AppColors.brandDark, size: 20),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.inkFaded,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(
      t,
      style: const TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w900,
        color: AppColors.inkFaded,
        letterSpacing: 0.6,
      ),
    ),
  );

  Widget _menuGroup(
    BuildContext context,
    List<({IconData icon, String title, String subtitle})> items, {
    DashShape shape = DashShape.band,
  }) => DashUI.accentedCard(
    accent: AppColors.brand,
    shape: shape,
    radius: _ProfileRadii.card,
    shadow: DashUI.cardShadow,
    child: Material(
      color: Colors.transparent,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.paperLine),
            _menuRow(context, items[i]),
          ],
        ],
      ),
    ),
  );

  Widget _menuRow(
    BuildContext context,
    ({IconData icon, String title, String subtitle}) item,
  ) => ListTile(
    onTap: () {
      if (item.icon == Icons.person_outline_rounded) {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const AccountScreen()));
      } else if (item.icon == Icons.storefront_rounded) {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const MyAdsScreen()));
      } else if (item.icon == Icons.event_note_rounded) {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const DashboardScreen()));
      } else if (item.icon == Icons.shield_outlined) {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const LegalScreen()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${item.title} \u2014 coming soon')),
        );
      }
    },
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    tileColor: Colors.transparent,
    leading: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.brandSoft,
        borderRadius: BorderRadius.circular(_ProfileRadii.chip),
      ),
      child: Icon(item.icon, color: AppColors.brandDark, size: 20),
    ),
    title: Text(
      item.title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: AppColors.ink,
      ),
    ),
    subtitle: Text(
      item.subtitle,
      style: const TextStyle(fontSize: 11.5, color: AppColors.inkFaded),
    ),
    trailing: const Icon(
      Icons.chevron_right_rounded,
      color: AppColors.inkFaded,
      size: 20,
    ),
  );
}

class _AccountTierBadge extends StatelessWidget {
  final bool isPremium;
  const _AccountTierBadge({required this.isPremium});

  @override
  Widget build(BuildContext context) {
    if (isPremium) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Icon(
          Icons.workspace_premium_rounded,
          color: Colors.white,
          size: 20,
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: AppColors.paperLine, width: 1),
      ),
      child: const Icon(
        Icons.verified_user_outlined,
        color: AppColors.inkFaded,
        size: 20,
      ),
    );
  }
}
