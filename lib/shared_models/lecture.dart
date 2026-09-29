import 'language.dart';
import 'notes.dart';

class Lecture {
  const Lecture({
    required this.id,
    required this.title,
    required this.transcript,
    required this.summary,
    required this.createdAt,
    required this.language,
    this.sections = const [],
    this.mindMapNodes = const [],
    this.quizId,
    this.audioDurationSeconds = 0,
  });

  final String id;
  final String title;
  final String transcript;
  final String summary;
  final DateTime createdAt;
  final Language language;
  final List<NoteSection> sections;
  final List<MindMapNode> mindMapNodes;
  final String? quizId;
  final int audioDurationSeconds;

  String get languageLabel => switch (language) {
        Language.urdu => 'Urdu (اردو)',
        Language.english => 'English',
        Language.romanUrdu => 'Roman Urdu',
      };

  Lecture copyWith({
    String? id,
    String? title,
    String? transcript,
    String? summary,
    DateTime? createdAt,
    Language? language,
    List<NoteSection>? sections,
    List<MindMapNode>? mindMapNodes,
    String? quizId,
    int? audioDurationSeconds,
  }) {
    return Lecture(
      id: id ?? this.id,
      title: title ?? this.title,
      transcript: transcript ?? this.transcript,
      summary: summary ?? this.summary,
      createdAt: createdAt ?? this.createdAt,
      language: language ?? this.language,
      sections: sections ?? this.sections,
      mindMapNodes: mindMapNodes ?? this.mindMapNodes,
      quizId: quizId ?? this.quizId,
      audioDurationSeconds: audioDurationSeconds ?? this.audioDurationSeconds,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'transcript': transcript,
        'summary': summary,
        'created_at': createdAt.toIso8601String(),
        'language': language.name,
        'sections': sections.map((s) => s.toJson()).toList(),
        'mind_map_nodes': mindMapNodes.map((n) => n.toJson()).toList(),
        'quiz_id': quizId,
        'audio_duration_seconds': audioDurationSeconds,
      };

  factory Lecture.fromJson(Map<String, dynamic> json) => Lecture(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? 'Untitled Lecture',
        transcript: json['transcript'] as String? ?? '',
        summary: json['summary'] as String? ?? '',
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
        language: Language.values.firstWhere(
          (e) => e.name == json['language'],
          orElse: () => Language.english,
        ),
        sections: (json['sections'] as List<dynamic>?)
                ?.map((e) => NoteSection.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        mindMapNodes: (json['mind_map_nodes'] as List<dynamic>?)
                ?.map((e) => MindMapNode.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        quizId: json['quiz_id'] as String?,
        audioDurationSeconds: json['audio_duration_seconds'] as int? ?? 0,
      );
}
