/// A legal document (Privacy Policy / Terms & Conditions) served by
/// `/api/v1/pages/{privacy|terms}`.
class LegalDocument {
  final String slug;
  final String kicker;
  final String title;
  final String intro;
  final List<String> meta;
  final List<LegalSection> sections;

  const LegalDocument({
    required this.slug,
    required this.kicker,
    required this.title,
    required this.intro,
    required this.meta,
    required this.sections,
  });

  factory LegalDocument.fromJson(Map<String, dynamic> json) {
    return LegalDocument(
      slug: (json['slug'] ?? '').toString(),
      kicker: (json['kicker'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      intro: (json['intro'] ?? '').toString(),
      meta: (json['meta'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(growable: false),
      sections: (json['sections'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(LegalSection.fromJson)
          .toList(growable: false),
    );
  }
}

/// One titled block of the document.
///
/// [style] mirrors the web layout: `plain`, `card` (soft boxed note) or
/// `highlight` (attention box). [children] renders sub-headed groups under a
/// parent heading.
class LegalSection {
  final String heading;
  final String body;
  final String style;
  final List<LegalSubSection> children;

  const LegalSection({
    required this.heading,
    required this.body,
    required this.style,
    required this.children,
  });

  bool get isCard => style == 'card';
  bool get isHighlight => style == 'highlight';

  factory LegalSection.fromJson(Map<String, dynamic> json) {
    return LegalSection(
      heading: (json['heading'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
      style: (json['style'] ?? 'plain').toString(),
      children: (json['children'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(LegalSubSection.fromJson)
          .toList(growable: false),
    );
  }
}

class LegalSubSection {
  final String heading;
  final String body;

  const LegalSubSection({required this.heading, required this.body});

  factory LegalSubSection.fromJson(Map<String, dynamic> json) {
    return LegalSubSection(
      heading: (json['heading'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
    );
  }
}
