import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_colors.dart';

/// Minimal rich-text renderer for the limited HTML the backend legal pages
/// contain: <ul>/<li>, <strong>/<b>, <em>/<i>, <code>, <a href>, <p>, <br>.
///
/// Links open externally via url_launcher; unknown tags are stripped.
class RichHtmlText extends StatefulWidget {
  const RichHtmlText(this.html, {super.key, this.baseStyle});

  final String html;
  final TextStyle? baseStyle;

  @override
  State<RichHtmlText> createState() => _RichHtmlTextState();
}

class _RichHtmlTextState extends State<RichHtmlText> {
  final List<TapGestureRecognizer> _recognizers = [];

  static final RegExp _tagExp = RegExp(
    r'<(/?)(ul|li|strong|b|em|i|code|a|p|br)([^>]*)>',
    caseSensitive: false,
  );

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  TextSpan _buildSpan(String text, TextStyle style) {
    return TextSpan(text: text, style: style);
  }

  InlineSpan _linkSpan(
    String label,
    TextStyle style,
    Future<void> Function() onTap,
  ) {
    final recognizer = TapGestureRecognizer()
      ..onTap = () {
        onTap();
      };
    _recognizers.add(recognizer);
    return TextSpan(
      text: label,
      style: style.copyWith(
        color: AppColors.brandDark,
        decoration: TextDecoration.underline,
        decorationColor: AppColors.brandDark.withValues(alpha: 0.4),
      ),
      recognizer: recognizer,
    );
  }

  List<InlineSpan> _parse(BuildContext context) {
    final base =
        widget.baseStyle ??
        const TextStyle(fontSize: 13, height: 1.55, color: AppColors.inkSoft);
    final codeStyle = base.copyWith(
      fontSize: base.fontSize != null ? base.fontSize! - 1 : 12,
      fontFamily: 'monospace',
      color: AppColors.brandDeep,
    );

    // Decode common entities.
    final src = widget.html
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&nbsp;', ' ');

    final spans = <InlineSpan>[];
    var bold = 0;
    var italic = 0;
    var inCode = false;
    Object? pendingLink; // Uri when inside <a>

    var cursor = 0;
    TextStyle current() {
      var s = base;
      if (bold > 0) s = s.copyWith(fontWeight: FontWeight.w800);
      if (italic > 0) s = s.copyWith(fontStyle: FontStyle.italic);
      if (inCode) s = codeStyle;
      return s;
    }

    void addText(String raw) {
      if (raw.isEmpty) return;
      final link = pendingLink;
      if (link is Uri) {
        spans.add(_linkSpan(raw, current(), () => _open(link)));
      } else {
        spans.add(_buildSpan(raw, current()));
      }
    }

    void ensureBreak() {
      final last = spans.isEmpty ? null : (spans.last as TextSpan).text;
      if (last == null || last.isEmpty || last.endsWith('\n')) return;
      spans.add(TextSpan(text: '\n', style: base));
    }

    for (final m in _tagExp.allMatches(src)) {
      addText(src.substring(cursor, m.start));
      cursor = m.end;

      final closing = m.group(1)!.isNotEmpty;
      final tag = m.group(2)!.toLowerCase();
      final attrs = m.group(3) ?? '';

      switch (tag) {
        case 'strong':
        case 'b':
          bold += closing ? -1 : 1;
          if (bold < 0) bold = 0;
          break;
        case 'em':
        case 'i':
          italic += closing ? -1 : 1;
          if (italic < 0) italic = 0;
          break;
        case 'code':
          inCode = !closing;
          break;
        case 'a':
          if (closing) {
            pendingLink = null;
          } else {
            final href = RegExp(
              "href\\s*=\\s*[\"']([^\"']+)[\"']",
              caseSensitive: false,
            ).firstMatch(attrs)?.group(1);
            pendingLink = Uri.tryParse(href ?? '') ?? '';
            if ((pendingLink as Uri).toString().isEmpty) pendingLink = null;
          }
          break;
        case 'li':
          if (!closing) {
            ensureBreak();
            spans.add(const TextSpan(text: '\u2022\u00A0\u00A0'));
          } else {
            ensureBreak();
            spans.add(TextSpan(text: '\n', style: base));
          }
          break;
        case 'ul':
        case 'ol':
          break; // spacing handled by li breaks
        case 'br':
          ensureBreak();
          spans.add(TextSpan(text: '\n', style: base));
          break;
        case 'p':
          if (closing) {
            ensureBreak();
            spans.add(TextSpan(text: '\n', style: base));
          }
          break;
      }
    }
    addText(src.substring(cursor));

    // Collapse leading/trailing stray newlines produced by block tags.
    while (spans.isNotEmpty) {
      final first = spans.first as TextSpan;
      if (first.text != null && first.text!.startsWith('\n')) {
        spans[0] = TextSpan(
          text: first.text!.replaceFirst(RegExp(r'^\n+'), ''),
          style: first.style,
        );
        if ((spans.first as TextSpan).text!.isEmpty) spans.removeAt(0);
        continue;
      }
      break;
    }

    return spans;
  }

  static Future<void> _open(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text.rich(TextSpan(children: _parse(context)));
  }
}
