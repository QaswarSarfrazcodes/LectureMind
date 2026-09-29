enum QuestionType { mcq, shortAnswer }

class QuizOption {
  const QuizOption({
    required this.text,
    required this.isCorrect,
  });

  final String text;
  final bool isCorrect;

  Map<String, dynamic> toJson() => {
        'text': text,
        'is_correct': isCorrect,
      };

  factory QuizOption.fromJson(Map<String, dynamic> json) => QuizOption(
        text: json['text'] as String? ?? '',
        isCorrect: json['is_correct'] as bool? ?? false,
      );
}

class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.type,
    required this.question,
    this.options = const [],
    required this.correctAnswer,
    this.explanation = '',
  });

  final String id;
  final QuestionType type;
  final String question;
  final List<QuizOption> options;
  final String correctAnswer;
  final String explanation;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'question': question,
        'options': options.map((o) => o.toJson()).toList(),
        'correct_answer': correctAnswer,
        'explanation': explanation,
      };

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? 'mcq';
    final type = typeStr == 'short_answer' ? QuestionType.shortAnswer : QuestionType.mcq;
    final rawOptions = json['options'] as List<dynamic>? ?? [];

    List<QuizOption> options = [];
    if (rawOptions.isNotEmpty && rawOptions.first is String) {
      final correctStr = json['correct_answer'] as String? ?? '';
      options = rawOptions
          .map((e) => QuizOption(text: e.toString(), isCorrect: e.toString() == correctStr))
          .toList();
    } else {
      options = rawOptions.map((e) => QuizOption.fromJson(e as Map<String, dynamic>)).toList();
    }

    return QuizQuestion(
      id: json['id'] as String? ?? UniqueKey().toString(),
      type: type,
      question: json['question'] as String? ?? '',
      options: options,
      correctAnswer: json['correct_answer'] as String? ?? '',
      explanation: json['explanation'] as String? ?? '',
    );
  }
}

class Quiz {
  const Quiz({
    required this.id,
    required this.lectureId,
    required this.questions,
    this.score,
    this.completed = false,
  });

  final String id;
  final String lectureId;
  final List<QuizQuestion> questions;
  final int? score;
  final bool completed;

  Quiz copyWith({
    String? id,
    String? lectureId,
    List<QuizQuestion>? questions,
    int? score,
    bool? completed,
  }) {
    return Quiz(
      id: id ?? this.id,
      lectureId: lectureId ?? this.lectureId,
      questions: questions ?? this.questions,
      score: score ?? this.score,
      completed: completed ?? this.completed,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'lecture_id': lectureId,
        'questions': questions.map((q) => q.toJson()).toList(),
        'score': score,
        'completed': completed,
      };

  factory Quiz.fromJson(Map<String, dynamic> json) => Quiz(
        id: json['id'] as String? ?? '',
        lectureId: json['lecture_id'] as String? ?? '',
        questions: (json['questions'] as List<dynamic>?)
                ?.map((e) => QuizQuestion.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        score: json['score'] as int?,
        completed: json['completed'] as bool? ?? false,
      );
}

class UniqueKey {
  static int _c = 0;
  @override
  String toString() => '${DateTime.now().millisecondsSinceEpoch}_${_c++}';
}
