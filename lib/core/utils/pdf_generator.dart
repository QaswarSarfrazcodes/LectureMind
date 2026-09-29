import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../shared_models/lecture.dart';
import '../../shared_models/quiz.dart';

/// PDF Generator implementing FR-9.1 and TC-EXP-01.
/// Packages structured notes, mind map concepts, and quiz into a clean printable document.
class PdfExportService {
  const PdfExportService._();

  static const PdfColor brandCrimson = PdfColor.fromInt(0xFFE50914);
  static const PdfColor brandCharcoal = PdfColor.fromInt(0xFF1E293B);
  static const PdfColor brandSurface = PdfColor.fromInt(0xFFF8FAFC);

  static Future<pw.ThemeData> _buildBilingualTheme() async {
    final font = await PdfGoogleFonts.interRegular();
    final fontBold = await PdfGoogleFonts.interBold();
    pw.Font? fontUrdu;
    try {
      fontUrdu = await PdfGoogleFonts.notoNastaliqUrduRegular();
    } catch (_) {
      try {
        fontUrdu = await PdfGoogleFonts.notoSansArabicRegular();
      } catch (_) {}
    }
    return pw.ThemeData.withFont(
      base: font,
      bold: fontBold,
      fontFallback: fontUrdu != null ? [fontUrdu] : null,
    );
  }

  static Future<Uint8List> generateLecturePdf({
    required Lecture lecture,
    Quiz? quiz,
  }) async {
    final pdf = pw.Document();
    final theme = await _buildBilingualTheme();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: theme,
        header: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(bottom: 20),
          child: pw.Text(
            'LectureMind — Apna Lecture, Apni Zubaan',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
        ),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 20),
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ),
        build: (context) => [
          // Title Banner
          pw.Header(
            level: 0,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  lecture.title,
                  style: const pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.teal800),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Created: ${lecture.createdAt.toLocal().toString().split('.')[0]} | Language: ${lecture.language.name.toUpperCase()}',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
                pw.Divider(color: PdfColors.teal, thickness: 1.5),
              ],
            ),
          ),

          // Overview
          if (lecture.summary.isNotEmpty) ...[
            pw.Text(
              'Lecture Summary',
              style: const pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900),
            ),
            pw.SizedBox(height: 6),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.teal50,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: PdfColors.teal200),
              ),
              child: pw.Text(lecture.summary, style: const pw.TextStyle(fontSize: 10.5)),
            ),
            pw.SizedBox(height: 16),
          ],

          // Structured Notes Sections
          pw.Text(
            'Comprehensive Notes',
            style: const pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900),
          ),
          pw.SizedBox(height: 8),

          for (final section in lecture.sections) ...[
            pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 12),
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    section.title,
                    style: const pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(section.body, style: const pw.TextStyle(fontSize: 10)),
                  if (section.bulletItems.isNotEmpty) ...[
                    pw.SizedBox(height: 8),
                    for (final item in section.bulletItems) ...[
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(left: 4, bottom: 2),
                        child: pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('• ', style: const pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.red800)),
                            pw.Expanded(
                              child: pw.Text(
                                item.point,
                                style: const pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (item.explanation.isNotEmpty)
                        pw.Container(
                          margin: const pw.EdgeInsets.only(left: 14, bottom: 6, top: 2),
                          padding: const pw.EdgeInsets.all(6),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.grey100,
                            borderRadius: pw.BorderRadius.circular(3),
                            border: pw.Border.all(color: PdfColors.grey300),
                          ),
                          child: pw.Text(
                            item.explanation,
                            style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey800),
                          ),
                        ),
                    ],
                  ] else if (section.bullets.isNotEmpty) ...[
                    pw.SizedBox(height: 6),
                    for (final bullet in section.bullets)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(left: 8, bottom: 2),
                        child: pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('• ', style: const pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.red800)),
                            pw.Expanded(child: pw.Text(bullet, style: const pw.TextStyle(fontSize: 9.5))),
                          ],
                        ),
                      ),
                  ],
                  if (section.aiSynthesis != null && section.aiSynthesis!.isNotEmpty) ...[
                    pw.SizedBox(height: 6),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(6),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.red50,
                        borderRadius: pw.BorderRadius.circular(4),
                        border: pw.Border.all(color: PdfColors.red200),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'AI Pedagogical Synthesis:',
                            style: const pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.red900),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            section.aiSynthesis!,
                            style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey800),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (section.keyTerms.isNotEmpty) ...[
                    pw.SizedBox(height: 6),
                    pw.Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: section.keyTerms
                          .map(
                            (term) => pw.Container(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: pw.BoxDecoration(
                                color: PdfColors.amber100,
                                borderRadius: pw.BorderRadius.circular(4),
                              ),
                              child: pw.Text(term, style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.brown900)),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],

          // Quiz Section
          if (quiz != null && quiz.questions.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            pw.Text(
              'Quiz Assessment & Answer Key',
              style: const pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900),
            ),
            pw.SizedBox(height: 8),
            for (int i = 0; i < quiz.questions.length; i++) ...[
              pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 8),
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Q${i + 1}: ${quiz.questions[i].question}',
                      style: const pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Answer: ${quiz.questions[i].correctAnswer}',
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.green900, fontWeight: pw.FontWeight.bold),
                    ),
                    if (quiz.questions[i].explanation.isNotEmpty)
                      pw.Text(
                        'Explanation: ${quiz.questions[i].explanation}',
                        style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );

    return pdf.save();
  }

  static Future<void> shareOrPrintLecture({
    required Lecture lecture,
    Quiz? quiz,
  }) async {
    final bytes = await generateLecturePdf(
      lecture: lecture,
      quiz: quiz,
    );

    await Printing.sharePdf(
      bytes: bytes,
      filename: '${lecture.title.replaceAll(RegExp(r'[^\w\s]+'), '')}_LectureMind.pdf',
    );
  }

  /// Generates a dedicated student quiz results report PDF.
  static Future<Uint8List> generateQuizResultPdf({
    required String title,
    required Quiz quiz,
    required int score,
    required int total,
    required String userName,
    Map<int, int>? userAnswers,
  }) async {
    final pdf = pw.Document();
    final theme = await _buildBilingualTheme();

    final pct = total > 0 ? ((score / total) * 100).round() : 0;
    final isPass = pct >= 60;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: theme,
        header: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'LectureMind AI — Assessment Performance Report',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
            pw.Text(
              DateTime.now().toLocal().toString().split('.')[0],
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          ],
        ),
        build: (context) => [
          pw.SizedBox(height: 12),
          // Title banner
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: isPass ? PdfColors.green50 : PdfColors.red50,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: isPass ? PdfColors.green300 : PdfColors.red300),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Quiz Assessment Results',
                      style: const pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('Topic: $title', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                    pw.SizedBox(height: 2),
                    pw.Text('Student: $userName', style: const pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: pw.BoxDecoration(
                    color: isPass ? PdfColors.green700 : PdfColors.red700,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        '$pct%',
                        style: const pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                      ),
                      pw.Text(
                        '$score / $total Correct',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          pw.Text(
            'Question by Question Breakdown & Model Explanations',
            style: const pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
          ),
          pw.SizedBox(height: 10),

          for (int i = 0; i < quiz.questions.length; i++) ...[
            pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 10),
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.red800,
                          borderRadius: pw.BorderRadius.circular(3),
                        ),
                        child: pw.Text(
                          'Q${i + 1}',
                          style: const pw.TextStyle(color: PdfColors.white, fontSize: 9, fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.SizedBox(width: 8),
                      pw.Expanded(
                        child: pw.Text(
                          quiz.questions[i].question,
                          style: const pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 6),
                  if (quiz.questions[i].options.isNotEmpty)
                    for (final opt in quiz.questions[i].options)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(left: 16, bottom: 3),
                        child: pw.Row(
                          children: [
                            pw.Text(
                              opt.isCorrect ? '✓ ' : '○ ',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                color: opt.isCorrect ? PdfColors.green700 : PdfColors.grey600,
                              ),
                            ),
                            pw.Expanded(
                              child: pw.Text(
                                opt.text,
                                style: pw.TextStyle(
                                  fontSize: 9,
                                  color: opt.isCorrect ? PdfColors.green900 : PdfColors.grey800,
                                  fontWeight: opt.isCorrect ? pw.FontWeight.bold : pw.FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  pw.SizedBox(height: 4),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(6),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Correct Answer: ${quiz.questions[i].correctAnswer}',
                          style: const pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.green900),
                        ),
                        if (quiz.questions[i].explanation.isNotEmpty) ...[
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'AI Explanation: ${quiz.questions[i].explanation}',
                            style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );

    return pdf.save();
  }

  /// Exports and shares the Quiz results as a PDF document.
  static Future<void> shareOrPrintQuizResult({
    required String title,
    required Quiz quiz,
    required int score,
    required int total,
    required String userName,
    Map<int, int>? userAnswers,
  }) async {
    final bytes = await generateQuizResultPdf(
      title: title,
      quiz: quiz,
      score: score,
      total: total,
      userName: userName,
      userAnswers: userAnswers,
    );

    await Printing.sharePdf(
      bytes: bytes,
      filename: '${title.replaceAll(RegExp(r'[^\w\s]+'), '')}_Quiz_Score_Report.pdf',
    );
  }
}
