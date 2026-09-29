enum ChatRole { user, assistant, system }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.lectureId,
    required this.role,
    required this.content,
    required this.timestamp,
    this.isVoice = false,
    this.subjectFolder = 'General',
    this.rating,
  });

  final String id;
  final String lectureId;
  final ChatRole role;
  final String content;
  final DateTime timestamp;
  final bool isVoice;
  final String subjectFolder;
  final String? rating;

  bool get isUser => role == ChatRole.user;

  ChatMessage copyWith({
    String? id,
    String? lectureId,
    ChatRole? role,
    String? content,
    DateTime? timestamp,
    bool? isVoice,
    String? subjectFolder,
    String? rating,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      lectureId: lectureId ?? this.lectureId,
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isVoice: isVoice ?? this.isVoice,
      subjectFolder: subjectFolder ?? this.subjectFolder,
      rating: rating ?? this.rating,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'lecture_id': lectureId,
        'role': role.name,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
        'is_voice': isVoice,
        'subject_folder': subjectFolder,
        'rating': rating,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String? ?? '',
        lectureId: json['lecture_id'] as String? ?? '',
        role: ChatRole.values.firstWhere(
          (e) => e.name == json['role'],
          orElse: () => ChatRole.assistant,
        ),
        content: json['content'] as String? ?? '',
        timestamp: json['timestamp'] != null
            ? DateTime.parse(json['timestamp'] as String)
            : DateTime.now(),
        isVoice: json['is_voice'] as bool? ?? false,
        subjectFolder: json['subject_folder'] as String? ?? 'General',
        rating: json['rating'] as String?,
      );
}
