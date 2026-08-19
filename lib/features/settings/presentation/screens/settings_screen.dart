import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/locale/app_translations.dart';
import '../../../../core/locale/locale_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_back_button.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paperRaised,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: const AppBackButton(),
        title: Text(
          'ui.settings'.tr2,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
            fontSize: 16,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                decoration: BoxDecoration(
                  color: AppColors.paperRaised,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.paperLine),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.brandSoft,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.translate_rounded,
                            color: AppColors.brandDark,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ui.app_settings'.tr2,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'ui.settings_subtitle'.tr2,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.inkFaded,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: AppColors.paperLine),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ui.change_language'.tr2,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        BlocBuilder<LocaleCubit, Locale>(
                          builder: (context, locale) {
                            return Text(
                              locale.languageCode == 'bn'
                                  ? 'ui.bengali'.tr2
                                  : 'ui.english'.tr2,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.inkFaded,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ui.language_desc'.tr2,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.inkFaded,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    BlocBuilder<LocaleCubit, Locale>(
                      builder: (context, locale) {
                        final isEn = locale.languageCode == 'en';
                        return Row(
                          children: [
                            Expanded(
                              child: _LanguageOptionCard(
                                title: 'English',
                                subtitle: 'English',
                                selected: isEn,
                                onTap: () => context
                                    .read<LocaleCubit>()
                                    .setLocale('en'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _LanguageOptionCard(
                                title: 'বাংলা',
                                subtitle: 'Bengali',
                                selected: !isEn,
                                onTap: () => context
                                    .read<LocaleCubit>()
                                    .setLocale('bn'),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageOptionCard({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.brandDark : AppColors.paper,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.brandDark : AppColors.paperLine,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected
                    ? Colors.white.withValues(alpha: 0.18)
                    : AppColors.paperRaised,
                border: Border.all(
                  color: selected ? Colors.white : AppColors.paperLine,
                  width: selected ? 2 : 1,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: selected ? Colors.white : AppColors.ink,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? Colors.white.withValues(alpha: 0.75)
                          : AppColors.inkFaded,
                    ),
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
