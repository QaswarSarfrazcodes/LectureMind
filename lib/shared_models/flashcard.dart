class Flashcard {
  const Flashcard({
    required this.id,
    required this.sourceLectureId,
    required this.front,
    required this.back,
    this.intervalDays = 1,
    this.repetitions = 0,
    this.easeFactor = 2.5,
    required this.dueDate,
  });

  final String id;
  final String sourceLectureId;
  final String front;
  final String back;
  final int intervalDays;
  final int repetitions;
  final double easeFactor;
  final DateTime dueDate;

  Flashcard copyWith({
    String? id,
    String? sourceLectureId,
    String? front,
    String? back,
    int? intervalDays,
    int? repetitions,
    double? easeFactor,
    DateTime? dueDate,
  }) {
    return Flashcard(
      id: id ?? this.id,
      sourceLectureId: sourceLectureId ?? this.sourceLectureId,
      front: front ?? this.front,
      back: back ?? this.back,
      intervalDays: intervalDays ?? this.intervalDays,
      repetitions: repetitions ?? this.repetitions,
      easeFactor: easeFactor ?? this.easeFactor,
      dueDate: dueDate ?? this.dueDate,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'source_lecture_id': sourceLectureId,
        'front': front,
        'back': back,
        'interval_days': intervalDays,
        'repetitions': repetitions,
        'ease_factor': easeFactor,
        'due_date': dueDate.toIso8601String(),
      };

  factory Flashcard.fromJson(Map<String, dynamic> json) => Flashcard(
        id: json['id'] as String? ?? '',
        sourceLectureId: json['source_lecture_id'] as String? ?? '',
        front: json['front'] as String? ?? '',
        back: json['back'] as String? ?? '',
        intervalDays: json['interval_days'] as int? ?? 1,
        repetitions: json['repetitions'] as int? ?? 0,
        easeFactor: (json['ease_factor'] as num?)?.toDouble() ?? 2.5,
        dueDate: json['due_date'] != null
            ? DateTime.parse(json['due_date'] as String)
            : DateTime.now(),
      );
}
