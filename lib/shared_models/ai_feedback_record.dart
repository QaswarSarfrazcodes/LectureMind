class AiFeedbackRecord {
  const AiFeedbackRecord({
    required this.id,
    required this.messageId,
    required this.lectureId,
    required this.userQuestion,
    required this.aiResponse,
    required this.rating,
    required this.taskType,
    required this.model,
    required this.timestamp,
    this.subjectFolder,
    this.feedbackComment,
  });

  final String id;
  final String messageId;
  final String lectureId;
  final String userQuestion;
  final String aiResponse;
  final String rating; // 'thumbsUp' | 'thumbsDown'
  final String taskType;
  final String model;
  final DateTime timestamp;
  final String? subjectFolder;
  final String? feedbackComment;

  bool get isPositive => rating == 'thumbsUp';

  AiFeedbackRecord copyWith({
    String? id,
    String? messageId,
    String? lectureId,
    String? userQuestion,
    String? aiResponse,
    String? rating,
    String? taskType,
    String? model,
    DateTime? timestamp,
    String? subjectFolder,
    String? feedbackComment,
  }) =>
      AiFeedbackRecord(
        id: id ?? this.id,
        messageId: messageId ?? this.messageId,
        lectureId: lectureId ?? this.lectureId,
        userQuestion: userQuestion ?? this.userQuestion,
        aiResponse: aiResponse ?? this.aiResponse,
        rating: rating ?? this.rating,
        taskType: taskType ?? this.taskType,
        model: model ?? this.model,
        timestamp: timestamp ?? this.timestamp,
        subjectFolder: subjectFolder ?? this.subjectFolder,
        feedbackComment: feedbackComment ?? this.feedbackComment,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'message_id': messageId,
        'lecture_id': lectureId,
        'user_question': userQuestion,
        'ai_response': aiResponse,
        'rating': rating,
        'task_type': taskType,
        'model': model,
        'timestamp': timestamp.toIso8601String(),
        if (subjectFolder != null) 'subject_folder': subjectFolder,
        if (feedbackComment != null) 'feedback_comment': feedbackComment,
      };

  factory AiFeedbackRecord.fromJson(Map<String, dynamic> json) =>
      AiFeedbackRecord(
        id: json['id'] as String? ?? 'fb_${DateTime.now().millisecondsSinceEpoch}',
        messageId: json['message_id'] as String? ?? '',
        lectureId: json['lecture_id'] as String? ?? '',
        userQuestion: json['user_question'] as String? ?? '',
        aiResponse: json['ai_response'] as String? ?? '',
        rating: json['rating'] as String? ?? 'thumbsUp',
        taskType: json['task_type'] as String? ?? 'chatQa',
        model: json['model'] as String? ?? 'openai/gpt-oss-120b',
        timestamp: json['timestamp'] != null
            ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
            : DateTime.now(),
        subjectFolder: json['subject_folder'] as String?,
        feedbackComment: json['feedback_comment'] as String?,
      );
}
