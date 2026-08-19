import 'package:flutter/material.dart';
import '../locale/app_translations.dart';
import '../theme/app_colors.dart';

/// Premium, high-converting Sign Out confirmation dialog for MessMax.
class SignOutDialog extends StatelessWidget {
  final String? userEmail;
  final String? userName;

  const SignOutDialog({
    super.key,
    this.userEmail,
    this.userName,
  });

  static Future<bool?> show(
    BuildContext context, {
    String? userEmail,
    String? userName,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) => SignOutDialog(
        userEmail: userEmail,
        userName: userName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = userEmail?.trim();
    final name = userName?.trim();

    return Dialog(
      backgroundColor: AppColors.paperRaised,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.paperLine),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Glowing Logout Medallion Icon
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: AppColors.dangerSoft,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.danger.withValues(alpha: 0.22),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.danger.withValues(alpha: 0.15),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.logout_rounded,
                    color: AppColors.danger,
                    size: 28,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // 2. Title & Message
              ValueListenableBuilder<int>(
                valueListenable: AppTranslations.notifier,
                builder: (context, _, _) => Text(
                  'ui.sign_out_title'.tr2,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              ValueListenableBuilder<int>(
                valueListenable: AppTranslations.notifier,
                builder: (context, _, _) => Text(
                  'ui.sign_out_message'.tr2,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.inkFaded,
                    height: 1.45,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // 3. User Badge (if available)
              if (email != null && email.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.paper,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.paperLine),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.brandSoft,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.brand.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            (name != null && name.isNotEmpty
                                    ? name.substring(0, 1)
                                    : email.substring(0, 1))
                                .toUpperCase(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.brandDark,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          email,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.inkSoft,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // 4. Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.inkSoft,
                        side: const BorderSide(color: AppColors.paperLine),
                        minimumSize: const Size(0, 48),
                        fixedSize: const Size.fromHeight(48),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        backgroundColor: AppColors.paper,
                      ),
                      child: ValueListenableBuilder<int>(
                        valueListenable: AppTranslations.notifier,
                        builder: (context, _, _) => Text(
                          'ui.cancel'.tr2,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.danger,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        minimumSize: const Size(0, 48),
                        fixedSize: const Size.fromHeight(48),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        shadowColor: AppColors.danger.withValues(alpha: 0.35),
                      ),
                      icon: const Icon(Icons.logout_rounded, size: 16),
                      label: ValueListenableBuilder<int>(
                        valueListenable: AppTranslations.notifier,
                        builder: (context, _, _) => Text(
                          'ui.sign_out'.tr2,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
