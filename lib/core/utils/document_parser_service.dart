import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class ExtractedDocument {
  const ExtractedDocument({
    required this.fileName,
    required this.fileType,
    required this.fullText,
    required this.sections,
    required this.pageOrSlideCount,
  });

  final String fileName;
  final String fileType; // 'pdf', 'pptx', 'docx', 'txt'
  final String fullText;
  final List<String> sections; // per page or per slide text
  final int pageOrSlideCount;
}

class DocumentParserService {
  const DocumentParserService();

  /// Parses bytes of PDF, PPTX, DOCX, or TXT into structured readable text.
  Future<ExtractedDocument> parseDocument({
    required List<int> bytes,
    required String fileName,
  }) async {
    final lowerName = fileName.toLowerCase();

    if (lowerName.endsWith('.pdf')) {
      return _parsePdf(bytes, fileName);
    } else if (lowerName.endsWith('.pptx') || lowerName.endsWith('.ppt')) {
      return _parsePptx(bytes, fileName);
    } else if (lowerName.endsWith('.docx') || lowerName.endsWith('.doc')) {
      return _parseDocx(bytes, fileName);
    } else {
      // Plain text or markdown
      final text = utf8.decode(bytes, allowMalformed: true);
      return ExtractedDocument(
        fileName: fileName,
        fileType: 'txt',
        fullText: text,
        sections: [text],
        pageOrSlideCount: 1,
      );
    }
  }

  ExtractedDocument _parsePdf(List<int> bytes, String fileName) {
    final document = PdfDocument(inputBytes: bytes);
    final extractor = PdfTextExtractor(document);
    final count = document.pages.count;
    final pagesText = <String>[];
    final buffer = StringBuffer();

    for (int i = 0; i < count; i++) {
      final pageContent = extractor.extractText(startPageIndex: i, endPageIndex: i);
      final clean = pageContent.trim();
      if (clean.isNotEmpty) {
        pagesText.add('--- Page ${i + 1} ---\n$clean');
        buffer.writeln(clean);
        buffer.writeln();
      }
    }

    document.dispose();

    return ExtractedDocument(
      fileName: fileName,
      fileType: 'pdf',
      fullText: buffer.toString().trim(),
      sections: pagesText,
      pageOrSlideCount: count,
    );
  }

  ExtractedDocument _parsePptx(List<int> bytes, String fileName) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final slideEntries = archive.files.where((f) {
        final n = f.name.toLowerCase();
        return n.startsWith('ppt/slides/slide') && n.endsWith('.xml');
      }).toList();

      // Sort slides by slide index number
      slideEntries.sort((a, b) {
        final numA = _extractSlideNumber(a.name);
        final numB = _extractSlideNumber(b.name);
        return numA.compareTo(numB);
      });

      final slidesText = <String>[];
      final buffer = StringBuffer();

      for (int i = 0; i < slideEntries.length; i++) {
        final entry = slideEntries[i];
        final rawXml = utf8.decode(entry.content as List<int>, allowMalformed: true);
        final slideText = _extractTextFromXml(rawXml).trim();

        if (slideText.isNotEmpty) {
          final header = '--- Slide ${i + 1} ---';
          slidesText.add('$header\n$slideText');
          buffer.writeln('$header\n$slideText\n');
        }
      }

      final count = slideEntries.isEmpty ? 1 : slideEntries.length;
      final full = buffer.toString().trim();

      return ExtractedDocument(
        fileName: fileName,
        fileType: 'pptx',
        fullText: full.isNotEmpty ? full : 'PowerPoint Slide Deck: $fileName',
        sections: slidesText,
        pageOrSlideCount: count,
      );
    } catch (_) {
      // Fallback
      return ExtractedDocument(
        fileName: fileName,
        fileType: 'pptx',
        fullText: 'Presentation slides attached: $fileName',
        sections: ['Presentation slides: $fileName'],
        pageOrSlideCount: 1,
      );
    }
  }

  ExtractedDocument _parseDocx(List<int> bytes, String fileName) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final docFile = archive.findFile('word/document.xml');
      if (docFile != null) {
        final xml = utf8.decode(docFile.content as List<int>, allowMalformed: true);
        final text = _extractTextFromXml(xml).trim();
        return ExtractedDocument(
          fileName: fileName,
          fileType: 'docx',
          fullText: text,
          sections: [text],
          pageOrSlideCount: 1,
        );
      }
    } catch (_) {}

    return ExtractedDocument(
      fileName: fileName,
      fileType: 'docx',
      fullText: 'Document attached: $fileName',
      sections: ['Document content: $fileName'],
      pageOrSlideCount: 1,
    );
  }

  int _extractSlideNumber(String path) {
    final match = RegExp(r'slide(\d+)\.xml').firstMatch(path);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '0') ?? 0;
    }
    return 0;
  }

  String _extractTextFromXml(String xml) {
    // Extract XML tags text and join spaces
    return xml
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
