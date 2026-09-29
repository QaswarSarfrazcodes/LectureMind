class NoteBullet {
  const NoteBullet({
    required this.point,
    this.explanation = '',
  });

  final String point;
  final String explanation;

  NoteBullet copyWith({
    String? point,
    String? explanation,
  }) {
    return NoteBullet(
      point: point ?? this.point,
      explanation: explanation ?? this.explanation,
    );
  }

  Map<String, dynamic> toJson() => {
        'point': point,
        'explanation': explanation,
      };

  factory NoteBullet.fromJson(dynamic json) {
    if (json is String) {
      return NoteBullet(point: json, explanation: '');
    } else if (json is Map<String, dynamic>) {
      return NoteBullet(
        point: json['point'] as String? ??
            json['bullet'] as String? ??
            json['title'] as String? ??
            '',
        explanation: json['explanation'] as String? ??
            json['detail'] as String? ??
            json['description'] as String? ??
            '',
      );
    }
    return NoteBullet(point: json?.toString() ?? '', explanation: '');
  }
}

class NoteSection {
  const NoteSection({
    required this.title,
    required this.body,
    this.bullets = const [],
    this.bulletItems = const [],
    this.keyTerms = const [],
    this.simplifiedBody,
    this.aiSynthesis,
  });

  final String title;
  final String body;
  final List<String> bullets;
  final List<NoteBullet> bulletItems;
  final List<String> keyTerms;
  final String? simplifiedBody;
  final String? aiSynthesis;

  NoteSection copyWith({
    String? title,
    String? body,
    List<String>? bullets,
    List<NoteBullet>? bulletItems,
    List<String>? keyTerms,
    String? simplifiedBody,
    String? aiSynthesis,
  }) {
    return NoteSection(
      title: title ?? this.title,
      body: body ?? this.body,
      bullets: bullets ?? this.bullets,
      bulletItems: bulletItems ?? this.bulletItems,
      keyTerms: keyTerms ?? this.keyTerms,
      simplifiedBody: simplifiedBody ?? this.simplifiedBody,
      aiSynthesis: aiSynthesis ?? this.aiSynthesis,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'body': body,
        'bullets': bullets,
        'bullet_items': bulletItems.map((b) => b.toJson()).toList(),
        'key_terms': keyTerms,
        'simplified_body': simplifiedBody,
        'ai_synthesis': aiSynthesis,
      };

  factory NoteSection.fromJson(Map<String, dynamic> json) {
    final rawBullets = json['bullets'] as List<dynamic>? ?? [];
    final rawBulletItems = json['bullet_items'] as List<dynamic>? ?? [];

    final List<NoteBullet> items = [];
    final List<String> simpleBullets = [];

    if (rawBulletItems.isNotEmpty) {
      for (final item in rawBulletItems) {
        final b = NoteBullet.fromJson(item);
        items.add(b);
        simpleBullets.add(b.point);
      }
    } else {
      for (final item in rawBullets) {
        final b = NoteBullet.fromJson(item);
        items.add(b);
        simpleBullets.add(b.point);
      }
    }

    return NoteSection(
      title: json['title'] as String? ?? 'Section',
      body: json['body'] as String? ?? '',
      bullets: simpleBullets,
      bulletItems: items,
      keyTerms: (json['key_terms'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      simplifiedBody: json['simplified_body'] as String?,
      aiSynthesis: json['ai_synthesis'] as String? ?? json['synthesis'] as String?,
    );
  }
}

class MindMapNode {
  const MindMapNode({
    required this.id,
    required this.label,
    this.parentId,
    this.tier = 1,
    this.colorHex,
    this.isExpansion = false,
  });

  final String id;
  final String label;
  final String? parentId;
  final int tier;
  final String? colorHex;
  final bool isExpansion;

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'parent_id': parentId,
        'tier': tier,
        'color_hex': colorHex,
        'is_expansion': isExpansion,
      };

  factory MindMapNode.fromJson(Map<String, dynamic> json) {
    final isExp = json['is_expansion'] == true;
    final color = json['color_hex'] as String? ??
        json['color'] as String? ??
        (isExp ? '#F59E0B' : null);
    return MindMapNode(
      id: json['id'] as String? ?? '0',
      label: json['label'] as String? ?? '',
      parentId: json['parent'] as String? ?? json['parent_id'] as String?,
      tier: json['tier'] as int? ?? 1,
      colorHex: color,
      isExpansion: isExp,
    );
  }
}
