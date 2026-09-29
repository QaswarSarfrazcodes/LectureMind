import 'dart:math' as math;
import '../../shared_models/lecture.dart';

/// Semantic unit of a lecture transcript for RAG grounding.
class LectureChunk {
  const LectureChunk({
    required this.id,
    required this.lectureId,
    required this.index,
    required this.text,
    required this.sectionTitle,
    required this.estimatedTimestamp,
    this.score = 0.0,
  });

  final String id;
  final String lectureId;
  final int index;
  final String text;
  final String sectionTitle;
  final String estimatedTimestamp;
  final double score;

  LectureChunk copyWith({
    String? id,
    String? lectureId,
    int? index,
    String? text,
    String? sectionTitle,
    String? estimatedTimestamp,
    double? score,
  }) {
    return LectureChunk(
      id: id ?? this.id,
      lectureId: lectureId ?? this.lectureId,
      index: index ?? this.index,
      text: text ?? this.text,
      sectionTitle: sectionTitle ?? this.sectionTitle,
      estimatedTimestamp: estimatedTimestamp ?? this.estimatedTimestamp,
      score: score ?? this.score,
    );
  }
}

/// Elite RAG (Retrieval-Augmented Generation) & Semantic Chunking Engine.
/// Provides sub-document indexing, token-overlap BM25-style scoring,
/// and hallucination-free citation context assembly.
class LectureChunkService {
  const LectureChunkService();

  static const int _targetWordsPerChunk = 180;
  static const int _overlapWords = 35;

  /// Splits a lecture into semantically bounded chunks with timestamp approximations.
  List<LectureChunk> chunkLecture(Lecture lecture) {
    final transcript = lecture.transcript.trim();
    if (transcript.isEmpty) return const [];

    // Break down by paragraphs or double newlines first
    final rawParagraphs = transcript.split(RegExp(r'\n{2,}|\r\n{2,}'));
    final wordsWithMeta = <_WordToken>[];

    int wordCounter = 0;
    for (final para in rawParagraphs) {
      final tokens = para.split(RegExp(r'\s+')).where((s) => s.isNotEmpty);
      for (final t in tokens) {
        wordsWithMeta.add(_WordToken(t, wordCounter++));
      }
    }

    if (wordsWithMeta.isEmpty) return const [];

    final totalWords = wordsWithMeta.length;
    final totalDurationSec = lecture.audioDurationSeconds > 0
        ? lecture.audioDurationSeconds
        : (totalWords * 0.45).round(); // ~130-140 words per minute average speech rate

    final chunks = <LectureChunk>[];
    int startIdx = 0;
    int chunkIndex = 0;

    while (startIdx < totalWords) {
      final endIdx = math.min(startIdx + _targetWordsPerChunk, totalWords);
      final chunkTokens = wordsWithMeta.sublist(startIdx, endIdx);
      final chunkText = chunkTokens.map((w) => w.word).join(' ');

      // Compute estimated timestamp based on position in lecture
      final startWord = chunkTokens.first.index;
      final progressFraction = totalWords > 0 ? (startWord / totalWords) : 0.0;
      final elapsedSec = (progressFraction * totalDurationSec).round();
      final minutes = (elapsedSec ~/ 60).toString().padLeft(2, '0');
      final seconds = (elapsedSec % 60).toString().padLeft(2, '0');
      final timestampStr = '$minutes:$seconds';

      // Correlate with nearest section title if available
      String sectionTitle = 'General Lecture';
      if (lecture.sections.isNotEmpty) {
        final secIdx = math.min(
          (progressFraction * lecture.sections.length).floor(),
          lecture.sections.length - 1,
        );
        sectionTitle = lecture.sections[secIdx].title;
      }

      chunks.add(LectureChunk(
        id: '${lecture.id}_chunk_$chunkIndex',
        lectureId: lecture.id,
        index: chunkIndex,
        text: chunkText,
        sectionTitle: sectionTitle,
        estimatedTimestamp: timestampStr,
      ));

      chunkIndex++;
      if (endIdx >= totalWords) break;
      startIdx += (_targetWordsPerChunk - _overlapWords);
    }

    return chunks;
  }

  /// Retrieves the top-K most relevant chunks for a user query using BM25-style keyword matching.
  List<LectureChunk> retrieveRelevantChunks(
    Lecture lecture,
    String query, {
    int topK = 3,
  }) {
    final chunks = chunkLecture(lecture);
    if (chunks.isEmpty) return const [];

    final queryTerms = _tokenize(query);
    if (queryTerms.isEmpty) {
      return chunks.take(topK).toList();
    }

    final scoredChunks = <LectureChunk>[];

    for (final chunk in chunks) {
      final chunkTextTokens = _tokenize(chunk.text);
      final sectionTokens = _tokenize(chunk.sectionTitle);

      double score = 0.0;
      final chunkLength = chunkTextTokens.length;
      if (chunkLength == 0) continue;

      for (final term in queryTerms) {
        // Term frequency in chunk text
        final termFreq = chunkTextTokens.where((t) => t == term).length;
        if (termFreq > 0) {
          // Normalized TF
          final tf = termFreq / (termFreq + 1.2 * (0.25 + 0.75 * (chunkLength / 180.0)));
          score += tf * 2.5;
        }

        // Section title boost
        if (sectionTokens.contains(term)) {
          score += 3.0;
        }
      }

      // Exact query substring bonus
      final cleanChunk = chunk.text.toLowerCase();
      final cleanQuery = query.toLowerCase().trim();
      if (cleanQuery.length > 4 && cleanChunk.contains(cleanQuery)) {
        score += 6.0;
      }

      if (score > 0.0) {
        scoredChunks.add(chunk.copyWith(score: score));
      }
    }

    scoredChunks.sort((a, b) => b.score.compareTo(a.score));

    if (scoredChunks.isEmpty) {
      return chunks.take(topK).toList();
    }

    return scoredChunks.take(topK).toList();
  }

  /// Builds a structured, citation-annotated RAG context ready for PromptBuilder.
  String buildRAGContext(Lecture lecture, String query, {int topK = 3}) {
    final relevantChunks = retrieveRelevantChunks(lecture, query, topK: topK);

    final sb = StringBuffer();
    sb.writeln('LECTURE METADATA:');
    sb.writeln('• Title: ${lecture.title}');
    if (lecture.summary.trim().isNotEmpty) {
      sb.writeln('• Summary: ${lecture.summary.trim()}');
    }
    sb.writeln();

    if (relevantChunks.isEmpty) {
      sb.writeln('TRANSCRIPT EXCERPT:');
      final fallback = lecture.transcript.length > 2500
          ? '${lecture.transcript.substring(0, 2500)}…'
          : lecture.transcript;
      sb.writeln(fallback);
      return sb.toString();
    }

    sb.writeln('RETRIEVED GROUNDED LECTURE EXCERPTS (Ranked by Query Relevance):');
    for (int i = 0; i < relevantChunks.length; i++) {
      final chunk = relevantChunks[i];
      sb.writeln('---');
      sb.writeln('Excerpt ${i + 1} [Section: "${chunk.sectionTitle}" | Timestamp: ~${chunk.estimatedTimestamp}]:');
      sb.writeln('"${chunk.text}"');
    }
    sb.writeln('---');

    return sb.toString();
  }

  List<String> _tokenize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), ' ')
        .split(RegExp(r'\s+'))
        .where((t) => t.length > 1)
        .toList();
  }
}

class _WordToken {
  const _WordToken(this.word, this.index);
  final String word;
  final int index;
}
