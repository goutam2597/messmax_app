import 'package:flutter/material.dart';

import '../locale/app_translations.dart';
import '../theme/app_colors.dart';

/// Premium confirmation dialog when user is at the root of the app and presses back.
class AppExitDialog extends StatelessWidget {
  const AppExitDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) => const AppExitDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380),
        decoration: BoxDecoration(
          color: AppColors.paperRaised,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.paperLine, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Medallion icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.brandSoft,
                  border: Border.all(
                    color: AppColors.brand.withValues(alpha: 0.28),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brand.withValues(alpha: 0.18),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.exit_to_app_rounded,
                    size: 32,
                    color: AppColors.brandDark,
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Title
              ValueListenableBuilder<int>(
                valueListenable: AppTranslations.notifier,
                builder: (context, _, _) => Text(
                  'ui.exit_title'.tr2,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Message
              ValueListenableBuilder<int>(
                valueListenable: AppTranslations.notifier,
                builder: (context, _, _) => Text(
                  'ui.exit_message'.tr2,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: AppColors.inkFaded,
                    height: 1.45,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.inkSoft,
                        side: const BorderSide(
                          color: AppColors.paperLine,
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        minimumSize: const Size(0, 48),
                        fixedSize: const Size.fromHeight(48),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: ValueListenableBuilder<int>(
                        valueListenable: AppTranslations.notifier,
                        builder: (context, _, _) => Text(
                          'ui.cancel'.tr2,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
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
                        backgroundColor: AppColors.brandDark,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        minimumSize: const Size(0, 48),
                        fixedSize: const Size.fromHeight(48),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: ValueListenableBuilder<int>(
                        valueListenable: AppTranslations.notifier,
                        builder: (context, _, _) => Text(
                          'ui.exit_confirm'.tr2,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
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
