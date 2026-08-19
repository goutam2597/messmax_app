import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/locale/app_translations.dart';
import '../../../../core/theme/app_colors.dart';

class AppAuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const AppAuthHeader({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SvgPicture.asset(
          'assets/images/logo.svg',
          height: 40,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 18),
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: AppColors.ink,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13.5,
            color: AppColors.inkFaded,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class FieldLabel extends StatelessWidget {
  final String text;
  const FieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: AppColors.inkSoft,
          letterSpacing: 0.2,
        ),
      );
}

class AuthErrorBanner extends StatelessWidget {
  final String message;
  const AuthErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFFDF2F2),
        border: Border.all(color: const Color(0xFFF8D7D7)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            bottom: 0,
            left: 0,
            child: Container(width: 4, color: const Color(0xFFA02626)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 11, 14, 11),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.error_outline_rounded, size: 18, color: Color(0xFFA02626)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF852222),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool loading;
  const GoogleSignInButton({super.key, this.onPressed, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: loading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.ink,
          elevation: 0,
          side: const BorderSide(color: AppColors.paperLine, width: 1.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ink),
              )
            : ValueListenableBuilder<int>(
                valueListenable: AppTranslations.notifier,
                builder: (context, _, _) => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset('assets/icons/google_g.svg', width: 20, height: 20),
                    const SizedBox(width: 10),
                    Text(
                      'auth.continue_with_google'.tr2,
                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, letterSpacing: -0.1),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class AccountTypeTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const AccountTypeTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF8F2) : AppColors.paperRaised,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xFFE2701C) : AppColors.paperLine,
            width: selected ? 2.0 : 1.2,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFFE2701C).withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFFE2701C).withValues(alpha: 0.14)
                    : AppColors.paper,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 20,
                color: selected ? const Color(0xFFE2701C) : AppColors.inkFaded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: selected ? AppColors.ink : AppColors.inkSoft,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.inkFaded,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
