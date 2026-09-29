import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared_models/ai_feedback_record.dart';

class AiFeedbackStats {
  const AiFeedbackStats({
    required this.totalRatings,
    required this.thumbsUpCount,
    required this.thumbsDownCount,
    required this.satisfactionPercentage,
  });

  final int totalRatings;
  final int thumbsUpCount;
  final int thumbsDownCount;
  final double satisfactionPercentage;

  factory AiFeedbackStats.fromRecords(List<AiFeedbackRecord> records) {
    if (records.isEmpty) {
      return const AiFeedbackStats(
        totalRatings: 0,
        thumbsUpCount: 0,
        thumbsDownCount: 0,
        satisfactionPercentage: 100.0,
      );
    }
    int up = 0;
    int down = 0;
    for (final r in records) {
      if (r.isPositive) {
        up++;
      } else {
        down++;
      }
    }
    final total = up + down;
    final rate = total > 0 ? (up / total) * 100.0 : 100.0;
    return AiFeedbackStats(
      totalRatings: total,
      thumbsUpCount: up,
      thumbsDownCount: down,
      satisfactionPercentage: double.parse(rate.toStringAsFixed(1)),
    );
  }
}

class AiFeedbackService {
  AiFeedbackService(this._prefs);

  final SharedPreferences _prefs;
  static const _kFeedbackListKey = 'lm_ai_feedback_records_v1';

  List<AiFeedbackRecord> getAllFeedback() {
    final raw = _prefs.getString(_kFeedbackListKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map((e) => AiFeedbackRecord.fromJson(e))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> recordFeedback(AiFeedbackRecord record) async {
    final list = getAllFeedback();
    // Update existing record if messageId matches, otherwise append
    final idx = list.indexWhere((r) => r.messageId == record.messageId);
    if (idx != -1) {
      list[idx] = record;
    } else {
      list.insert(0, record);
    }

    // Keep up to latest 500 feedback items
    final trimmed = list.length > 500 ? list.sublist(0, 500) : list;
    await _prefs.setString(
      _kFeedbackListKey,
      jsonEncode(trimmed.map((e) => e.toJson()).toList()),
    );
  }

  AiFeedbackStats getStats() {
    return AiFeedbackStats.fromRecords(getAllFeedback());
  }

  String exportFeedbackJson() {
    final records = getAllFeedback();
    return jsonEncode(records.map((r) => r.toJson()).toList());
  }

  Future<void> clearAllFeedback() async {
    await _prefs.remove(_kFeedbackListKey);
  }
}
