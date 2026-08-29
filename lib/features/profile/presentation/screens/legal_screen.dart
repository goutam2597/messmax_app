import 'package:flutter/material.dart';

import '../../../../core/locale/app_translations.dart';
import '../../../../core/logger/app_logger.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/rich_html_text.dart';
import '../../data/models/legal_document_model.dart';
import '../../data/repositories/legal_repository.dart';

/// Privacy Policy & Terms & Conditions, fetched from
/// `/api/v1/pages/{privacy|terms}` and presented as two tabs.
class LegalScreen extends StatefulWidget {
  const LegalScreen({super.key});

  @override
  State<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends State<LegalScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _slugs = ['privacy', 'terms'];
  static const _labelKeys = ['pages.privacy_policy', 'pages.terms_conditions'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _slugs.length, vsync: this);
    // Warm both documents so switching tabs is instant.
    for (final slug in _slugs) {
      LegalRepository.fetch(slug).catchError((e) {
        AppLogger.w('Legal prefetch[$slug] failed: $e');
        return LegalDocument(
          slug: slug,
          kicker: '',
          title: '',
          intro: '',
          meta: const [],
          sections: const [],
        );
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: ValueListenableBuilder<int>(
          valueListenable: AppTranslations.notifier,
          builder: (context, _, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    const AppBackButton(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'ui.privacy_terms'.tr2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: AppColors.ink,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Tabs — labels come from the same translation pool as web.
              TabBar(
                controller: _tabController,
                labelColor: AppColors.brandDark,
                unselectedLabelColor: AppColors.inkFaded,
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                indicatorColor: AppColors.brand,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: AppColors.paperLine,
                tabs: [
                  for (var i = 0; i < _slugs.length; i++)
                    Tab(text: _labelKeys[i].tr2),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    for (final slug in _slugs) _DocumentView(slug: slug),
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

/// One document (privacy or terms): header card + stacked section cards.
class _DocumentView extends StatefulWidget {
  const _DocumentView({required this.slug});

  final String slug;

  @override
  State<_DocumentView> createState() => _DocumentViewState();
}

class _DocumentViewState extends State<_DocumentView> {
  int _attempt = 0;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AppTranslations.notifier,
      builder: (context, _, _) {
        final locale = AppTranslations.locale;
        return FutureBuilder<LegalDocument>(
          // Re-fetch when the tab retries or the locale changes.
          key: ValueKey('${widget.slug}:$_attempt:$locale'),
          future: LegalRepository.fetch(widget.slug),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                LegalRepository.cached(widget.slug) == null) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppColors.brandDark,
                  strokeWidth: 2,
                ),
              );
            }

            final doc = snapshot.data ?? LegalRepository.cached(widget.slug);
            if (doc == null || doc.sections.isEmpty) {
              return AppErrorView(
                title: 'ui.error_title'.tr2,
                retryLabel: 'ui.try_again'.tr2,
                onRetry: () => setState(() => _attempt++),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _HeaderCard(doc: doc),
                  const SizedBox(height: 14),
                  for (final section in doc.sections)
                    _SectionCard(section: section),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// Document header: kicker chip, title, meta chips and the intro note.
class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.doc});

  final LegalDocument doc;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.paperRaised,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.paperLine),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (doc.kicker.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.brandSoft,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                doc.kicker.toUpperCase(),
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                  color: AppColors.brandDark,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          const SizedBox(height: 10),
          Text(
            doc.title,
            style: const TextStyle(
              fontSize: 20,
              height: 1.25,
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (final m in doc.meta)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.paper,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.paperLine),
                  ),
                  child: Text(
                    m,
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.inkFaded,
                    ),
                  ),
                ),
            ],
          ),
          if (doc.intro.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.brandSoft.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.brandDark.withValues(alpha: 0.10),
                ),
              ),
              child: RichHtmlText(
                doc.intro,
                baseStyle: const TextStyle(
                  fontSize: 12.5,
                  height: 1.55,
                  color: AppColors.inkSoft,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A single section block. `card` renders boxed neutral, `highlight` renders
/// the attention box, `plain` is a standard white card.
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.section});

  final LegalSection section;

  @override
  Widget build(BuildContext context) {
    final Color background;
    final Color borderColor;
    switch (section.style) {
      case 'highlight':
        background = AppColors.amberSoft;
        borderColor = AppColors.amber.withValues(alpha: 0.30);
        break;
      case 'card':
        background = AppColors.paper;
        borderColor = AppColors.paperLine;
        break;
      default:
        background = AppColors.paperRaised;
        borderColor = AppColors.paperLine;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.heading,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
              height: 1.3,
            ),
          ),
          if (section.body.isNotEmpty) ...[
            const SizedBox(height: 6),
            RichHtmlText(section.body),
          ],
          for (final sub in section.children) ...[
            const SizedBox(height: 12),
            Text(
              sub.heading,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            RichHtmlText(sub.body),
          ],
        ],
      ),
    );
  }
}
