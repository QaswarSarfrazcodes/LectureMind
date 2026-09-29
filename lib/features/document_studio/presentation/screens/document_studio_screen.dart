import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/app_providers.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_neumorphic.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/document_parser_service.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../core/utils/bionic_reading_helper.dart';
import '../../../../shared_models/language.dart';
import '../../../../shared_models/lecture.dart';
import '../../../../shared_models/notes.dart';

class DocumentStudioScreen extends ConsumerStatefulWidget {
  const DocumentStudioScreen({super.key, this.initialDocument});

  final ExtractedDocument? initialDocument;

  @override
  ConsumerState<DocumentStudioScreen> createState() => _DocumentStudioScreenState();
}

class _DocumentStudioScreenState extends ConsumerState<DocumentStudioScreen> {
  ExtractedDocument? _document;
  bool _isProcessing = false;
  int _selectedSectionIndex = 0;
  String _aiOutput = '';
  bool _isGeneratingAi = false;
  String _currentAiActionLabel = '';

  // Bionic Reading & Karaoke TTS Engine (Phase 2 UX)
  bool _isBionicReading = true;
  double _ttsSpeed = 1.25;
  int _karaokeSentenceIndex = 0;

  // Voice Read (TTS) Engine
  final FlutterTts _tts = FlutterTts();
  bool _isPlayingVoice = false;
  String? _currentSpeakingTopic;

  @override
  void initState() {
    super.initState();
    _document = widget.initialDocument;
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      await _tts.setPitch(1.15); // British feminine cadence
      await _tts.setSpeechRate(0.72); // 1.25x playback speed
      await _tts.setVolume(1.0);
      _tts.setProgressHandler((String text, int start, int end, String word) {
        if (!mounted) return;
        final sentences = BionicReadingHelper.splitSentences(text);
        if (sentences.isNotEmpty) {
          final approxIndex = ((start / (text.isNotEmpty ? text.length : 1)) * sentences.length)
              .floor()
              .clamp(0, sentences.length - 1);
          if (approxIndex != _karaokeSentenceIndex) {
            setState(() => _karaokeSentenceIndex = approxIndex);
          }
        }
      });
      _tts.setCompletionHandler(() {
        if (mounted) {
          setState(() {
            _isPlayingVoice = false;
            _currentSpeakingTopic = null;
            _karaokeSentenceIndex = 0;
          });
        }
      });
      _tts.setErrorHandler((_) {
        if (mounted) {
          setState(() {
            _isPlayingVoice = false;
            _currentSpeakingTopic = null;
            _karaokeSentenceIndex = 0;
          });
        }
      });
    } catch (_) {}
  }

  void _cycleTtsSpeed() async {
    AppHaptics.selection();
    setState(() {
      if (_ttsSpeed == 1.0) {
        _ttsSpeed = 1.25;
      } else if (_ttsSpeed == 1.25) {
        _ttsSpeed = 1.5;
      } else {
        _ttsSpeed = 1.0;
      }
    });
    final rate = _ttsSpeed == 1.0 ? 0.58 : (_ttsSpeed == 1.25 ? 0.72 : 0.86);
    await _tts.setSpeechRate(rate);
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _speakText(String topic, String rawText) async {
    if (_isPlayingVoice && _currentSpeakingTopic == topic) {
      AppHaptics.light();
      await _tts.stop();
      if (mounted) {
        setState(() {
          _isPlayingVoice = false;
          _currentSpeakingTopic = null;
          _karaokeSentenceIndex = 0;
        });
      }
      return;
    }

    AppHaptics.medium();
    await _tts.stop();
    _karaokeSentenceIndex = 0;

    // Clean markdown syntax for natural, fluid spoken voice
    final clean = rawText
        .replaceAll(RegExp(r'\*\*|__|[\*_#`~>]|---+'), '')
        .replaceAll(RegExp(r'\[(.*?)\]\(.*?\)'), r'$1')
        .replaceAll(RegExp(r'\n+'), '. ')
        .trim();

    if (clean.isEmpty) return;

    final isUrdu = RegExp(r'[\u0600-\u06FF]').hasMatch(clean);
    try {
      if (isUrdu) {
        await _tts.setLanguage('ur-PK');
      } else {
        await _tts.setLanguage('en-GB');
      }
      if (mounted) {
        setState(() {
          _isPlayingVoice = true;
          _currentSpeakingTopic = topic;
        });
      }
      await _tts.speak(clean);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPlayingVoice = false;
          _currentSpeakingTopic = null;
        });
      }
    }
  }

  Future<void> _stopVoice() async {
    await _tts.stop();
    if (mounted) {
      setState(() {
        _isPlayingVoice = false;
        _currentSpeakingTopic = null;
      });
    }
  }

  Future<void> _pickAndParseDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pptx', 'ppt', 'pdf', 'docx', 'doc', 'txt'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) return;

      setState(() => _isProcessing = true);

      final parser = ref.read(documentParserServiceProvider);
      final doc = await parser.parseDocument(
        bytes: bytes,
        fileName: file.name,
      );

      setState(() {
        _document = doc;
        _selectedSectionIndex = 0;
        _aiOutput = '';
        _isProcessing = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to parse document: $e')),
        );
      }
    }
  }

  Future<void> _runGeminiAnalysis(String taskPrompt, String actionLabel) async {
    if (_document == null) return;

    setState(() {
      _isGeneratingAi = true;
      _currentAiActionLabel = actionLabel;
      _aiOutput = '';
    });

    final gemini = ref.read(geminiClientProvider);
    final groq = ref.read(groqClientProvider);
    final contextText = _document!.fullText.length > 15000
        ? _document!.fullText.substring(0, 15000)
        : _document!.fullText;

    const systemInstruction = '''You are LectureMind Multimodal Academic AI powered by Google Gemini and Groq.
Analyze this academic presentation or document deck accurately.
Format outputs with crisp Markdown headings, bullet points, and key takeaways.
Provide bilingual English and Urdu terminology where helpful.''';

    final prompt = '''$taskPrompt

Document Title: ${_document!.fileName}
Total Pages/Slides: ${_document!.pageOrSlideCount}

Document Content:
$contextText''';

    String? outputText;

    // 1. Try Groq Cloud first (ultra-fast low-latency reasoning)
    final groqRes = await groq.postChatCompletion(
      systemPrompt: systemInstruction,
      userContent: prompt,
      maxTokens: 1400,
    );

    if (groqRes.isSuccess && groqRes.data != null && groqRes.data!.trim().isNotEmpty) {
      outputText = groqRes.data!.trim();
    } else {
      // 2. Try Google Gemini with multi-model fallback
      final res = await gemini.generateContent(
        prompt: prompt,
        systemInstruction: systemInstruction,
        maxTokens: 1400,
      );
      if (res.isSuccess && res.data != null && res.data!.trim().isNotEmpty) {
        outputText = res.data!.trim();
      }
    }

    // 3. Resilient Pedagogical Local Synthesizer if cloud APIs are offline
    if (outputText == null || outputText.trim().isEmpty) {
      outputText = _generateLocalDocumentSummary(
        title: _document!.fileName,
        fullText: contextText,
        actionLabel: actionLabel,
      );
    }

    if (mounted) {
      setState(() {
        _isGeneratingAi = false;
        _aiOutput = outputText!;
      });
    }
  }

  String _generateLocalDocumentSummary({
    required String title,
    required String fullText,
    required String actionLabel,
  }) {
    final cleanTitle = title.replaceAll(RegExp(r'\.[^.]+$'), '');
    final lines = fullText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.length > 20 && !l.startsWith('---'))
        .take(12)
        .toList();

    final buffer = StringBuffer();
    buffer.writeln('# 📚 Academic Analysis: $cleanTitle\n');
    buffer.writeln('> **Synthesized by LectureMind AI Engine** · Bilingual Study Companion\n');

    buffer.writeln('### 🎯 Core Overview (خلاصہ اور اہم موضوعات)');
    buffer.writeln('This document focuses on the fundamentals, methodologies, and critical operational practices of **$cleanTitle**.\n');

    buffer.writeln('### 🔑 Key Concepts & Pillars (اہم نکات)');
    for (int i = 0; i < lines.length && i < 6; i++) {
      buffer.writeln('- **Concept ${i + 1}**: ${lines[i]}');
    }
    buffer.writeln();

    buffer.writeln('### 🧠 Exam & Revision Strategy (امتحانی رہنمائی)');
    buffer.writeln('1. **Active Recall**: Focus on the core relationships between these components.');
    buffer.writeln('2. **Bilingual Clarification**: Understand the technical terms in English and concept foundations in Urdu.');
    buffer.writeln('3. **Practice**: Test your understanding with the AI Assessment Quiz & Mind Map.');

    return buffer.toString();
  }

  Future<void> _saveAsLecture(BuildContext context) async {
    if (_document == null) return;

    final newLecture = Lecture(
      id: 'doc-${DateTime.now().millisecondsSinceEpoch}',
      title: _document!.fileName.replaceAll(RegExp(r'\.[^.]+$'), ''),
      createdAt: DateTime.now(),
      language: Language.english,
      transcript: _document!.fullText,
      summary: _aiOutput.isNotEmpty
          ? _aiOutput
          : 'Document presentation extracted with ${_document!.pageOrSlideCount} slides/pages.',
      sections: _document!.sections.asMap().entries.map((e) {
        final lines = e.value.split('\n');
        return NoteSection(
          title: 'Slide / Section ${e.key + 1}',
          body: e.value,
          bullets: lines.where((l) => l.trim().isNotEmpty).take(5).toList(),
        );
      }).toList(),
    );

    await ref.read(lecturesProvider.notifier).addOrUpdateLecture(newLecture);
    ref.read(selectedLectureIdProvider.notifier).state = newLecture.id;

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved "${newLecture.title}" to Notes, Mind Map & Quiz!'),
          backgroundColor: AppColors.crimsonRed,
        ),
      );
      context.go(AppRoutes.notesQuiz);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? NeuColors.darkCanvas : NeuColors.lightCanvas,
      appBar: AppBar(
        backgroundColor: isDark ? NeuColors.darkCanvas : NeuColors.lightCanvas,
        elevation: 0,
        title: Text(
          'PDF & Document Studio',
          style: AppTextStyles.title(isDark ? NeuColors.pureWhite : const Color(0xFF0F172A)),
        ),
        actions: [
          if (_document != null)
            IconButton(
              icon: const Icon(Icons.bookmark_add_rounded, color: AppColors.crimsonRed),
              tooltip: 'Save to Notes & Mind Map',
              onPressed: () => _saveAsLecture(context),
            ),
          IconButton(
            icon: Icon(Icons.upload_file_rounded, color: isDark ? NeuColors.pureWhite : const Color(0xFF0F172A)),
            tooltip: 'Pick New Document',
            onPressed: _pickAndParseDocument,
          ),
        ],
      ),
      body: _isProcessing
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: AppColors.crimsonRed),
                  const SizedBox(height: 16),
                  Text(
                    'Parsing presentation slides & extracting text...',
                    style: AppTextStyles.body(isDark ? NeuColors.pureWhite : const Color(0xFF0F172A)),
                  ),
                ],
              ),
            )
          : _document == null
              ? _buildEmptyUploader(isDark)
              : Stack(
                  children: [
                    _buildDocumentWorkspace(scheme, isDark),
                    if (_isPlayingVoice)
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: _stickyAudioPlayerDock(isDark),
                      ),
                  ],
                ),
    );
  }

  Widget _buildEmptyUploader(bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: NeuDecorations.circleRaised(
                isDark: isDark,
                withRedGlow: true,
              ),
              child: const Center(
                child: Icon(Icons.picture_as_pdf_rounded,
                    size: 46, color: AppColors.crimsonRed),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'PDF & PPT Lecture Studio',
              style: AppTextStyles.heroHeadline(
                  isDark ? NeuColors.pureWhite : const Color(0xFF0F172A)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Text(
                'Upload and read any PDF or PowerPoint presentation. LectureMind extracts sections, generates Structured Notes, Mind Maps, and AI Quizzes, and reads them aloud at 1.25× speed.',
                style: AppTextStyles.caption(
                    isDark ? NeuColors.mutedBlue : const Color(0xFF64748B)),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            NeuButton(
              label: 'Browse PDF / PPT Files',
              icon: Icons.file_upload_rounded,
              isPrimary: true,
              onPressed: _pickAndParseDocument,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentWorkspace(ColorScheme scheme, bool isDark) {
    final doc = _document!;

    return ListView(
      padding: const EdgeInsets.all(AppDimens.space16),
      children: [
        // Header Meta Card
        NeuCard(
          radius: 20,
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: NeuDecorations.circleRaised(
                  isDark: isDark,
                  withRedGlow: true,
                ),
                child: Center(
                  child: Icon(
                    doc.fileType == 'pptx' || doc.fileType == 'ppt'
                        ? Icons.slideshow_rounded
                        : Icons.picture_as_pdf_rounded,
                    color: AppColors.crimsonRed,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc.fileName,
                      style: AppTextStyles.bodyStrong(
                          isDark ? NeuColors.pureWhite : const Color(0xFF0F172A)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${doc.pageOrSlideCount} ${doc.fileType == "pptx" ? "Slides" : "Pages"} • ${doc.fullText.split(RegExp(r'\s+')).length} Words',
                      style: AppTextStyles.caption(
                          isDark ? NeuColors.mutedBlue : const Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Active Voice Narration Banner (Floating/Inline)
        if (_isPlayingVoice)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4338CA).withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.volume_up_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Voice Narration Active • آواز سے سنیں',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _currentSpeakingTopic?.contains('slide') == true
                            ? 'Reading Slide ${_selectedSectionIndex + 1} out loud'
                            : 'Reading AI Study Notes out loud',
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: _stopVoice,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.red.withValues(alpha: 0.25),
                  ),
                  icon: const Icon(Icons.stop_rounded, size: 18),
                  label: const Text('Stop', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),

        // Quick AI Generation Actions
        Text('Multimodal AI Intelligence Actions', style: AppTextStyles.title(scheme.onSurface)),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildActionButton(
                icon: Icons.auto_awesome_rounded,
                label: 'Summary & Notes',
                color: const Color(0xFF6366F1),
                onTap: () => _runGeminiAnalysis(
                  'Generate a comprehensive lecture summary, bullet point breakdown with explanations, and key takeaways for this slide deck.',
                  'Summary & Notes',
                ),
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                icon: _isPlayingVoice && _currentSpeakingTopic == 'full_doc'
                    ? Icons.stop_circle_rounded
                    : Icons.record_voice_over_rounded,
                label: _isPlayingVoice && _currentSpeakingTopic == 'full_doc'
                    ? 'Stop Voice'
                    : 'Voice Read (سنیں)',
                color: const Color(0xFFEC4899),
                onTap: () {
                  final textToRead = _aiOutput.isNotEmpty ? _aiOutput : doc.fullText;
                  _speakText('full_doc', textToRead);
                },
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                icon: Icons.hub_rounded,
                label: 'Mind Map Blueprint',
                color: const Color(0xFF10B981),
                onTap: () => _runGeminiAnalysis(
                  'Synthesize a hierarchical mind map structure with Root Node -> Primary Branches -> Sub-concepts -> Detail Nodes for this material.',
                  'Mind Map',
                ),
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                icon: Icons.quiz_rounded,
                label: '10-Question Quiz',
                color: const Color(0xFFF59E0B),
                onTap: () => _runGeminiAnalysis(
                  'Create 10 high-yield multiple choice questions testing core concepts from these slides, with correct answer keys and rationale.',
                  'Quiz',
                ),
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                icon: Icons.translate_rounded,
                label: 'Urdu Tashreeh',
                color: AppColors.crimsonRed,
                onTap: () => _runGeminiAnalysis(
                  'Explain the entire presentation in clear, fluent Urdu (تشریح) with bilingual English-Urdu technical terms.',
                  'Urdu Tashreeh',
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // AI Output View (if generating or generated)
        if (_isGeneratingAi)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Center(
              child: Column(
                children: [
                  const CircularProgressIndicator(color: Color(0xFF6366F1)),
                  const SizedBox(height: 14),
                  Text(
                    _currentAiActionLabel.isNotEmpty
                        ? 'Synthesizing $_currentAiActionLabel with Multimodal AI...'
                        : 'Reasoning over presentation with Multimodal AI...',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ],
              ),
            ),
          )
        else if (_aiOutput.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('AI Synthesis Output', style: AppTextStyles.title(scheme.onSurface)),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Voice Read Synthesis Button
                  IconButton(
                    onPressed: () => _speakText('ai_output', _aiOutput),
                    icon: Icon(
                      _isPlayingVoice && _currentSpeakingTopic == 'ai_output'
                          ? Icons.volume_off_rounded
                          : Icons.volume_up_rounded,
                      color: const Color(0xFF6366F1),
                    ),
                    tooltip: _isPlayingVoice && _currentSpeakingTopic == 'ai_output'
                        ? 'Stop Listening'
                        : 'Listen to Synthesis (آواز سے سنیں)',
                  ),
                  TextButton.icon(
                    onPressed: () => _saveAsLecture(context),
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Save to Notes'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: SelectableText(
              _aiOutput,
              style: const TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF1F2937)),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Slide / Section Inspector
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              doc.fileType == 'pptx' ? 'Slide Deck Navigator' : 'Document Pages',
              style: AppTextStyles.title(scheme.onSurface),
            ),
            Text(
              '${_selectedSectionIndex + 1} of ${doc.sections.length}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Horizontal Slide Thumbnails
        SizedBox(
          height: 70,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: doc.sections.length,
            itemBuilder: (context, i) {
              final isSelected = i == _selectedSectionIndex;
              return GestureDetector(
                onTap: () => setState(() => _selectedSectionIndex = i),
                child: Container(
                  width: 90,
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.jetBlack : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? AppColors.jetBlack : const Color(0xFFE5E7EB),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        doc.fileType == 'pptx' ? 'Slide ${i + 1}' : 'Page ${i + 1}',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : AppColors.jetBlack,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        doc.sections[i].trim().replaceAll('\n', ' '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9.5,
                          color: isSelected ? Colors.white70 : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 14),

        // Current Selected Slide Content Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? Colors.white12 : const Color(0xFFE5E7EB),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      doc.fileType == 'pptx'
                          ? 'Slide ${_selectedSectionIndex + 1} Content'
                          : 'Page ${_selectedSectionIndex + 1} Content',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? NeuColors.pureWhite : AppColors.jetBlack,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Bionic Reading Toggle Chip
                      GestureDetector(
                        onTap: () {
                          AppHaptics.selection();
                          setState(() {
                            _isBionicReading = !_isBionicReading;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _isBionicReading
                                ? const Color(0xFF6366F1).withValues(alpha: 0.15)
                                : (isDark ? Colors.white12 : Colors.grey.shade100),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _isBionicReading
                                  ? const Color(0xFF6366F1)
                                  : (isDark ? Colors.white24 : Colors.grey.shade300),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.auto_stories_rounded,
                                size: 14,
                                color: _isBionicReading
                                    ? const Color(0xFF6366F1)
                                    : (isDark ? Colors.white70 : Colors.black54),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _isBionicReading ? 'Bionic ON' : 'Bionic OFF',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _isBionicReading
                                      ? const Color(0xFF6366F1)
                                      : (isDark ? Colors.white70 : Colors.black54),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Voice Read current slide button
                      IconButton(
                        icon: Icon(
                          _isPlayingVoice && _currentSpeakingTopic == 'slide_$_selectedSectionIndex'
                              ? Icons.volume_off_rounded
                              : Icons.volume_up_rounded,
                          color: const Color(0xFF10B981),
                          size: 20,
                        ),
                        tooltip: 'Read this slide out loud (آواز سے سنیں)',
                        onPressed: () {
                          final slideText = doc.sections.isNotEmpty && _selectedSectionIndex < doc.sections.length
                              ? doc.sections[_selectedSectionIndex]
                              : '';
                          if (slideText.isNotEmpty) {
                            _speakText('slide_$_selectedSectionIndex', slideText);
                          }
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.question_answer_rounded,
                          size: 20,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                        tooltip: 'Ask AI about this slide',
                        onPressed: () {
                          final slideText = doc.sections[_selectedSectionIndex];
                          _runGeminiAnalysis(
                            'Explain this specific slide in deep detail with real-world examples and study notes:\n$slideText',
                            'Explain Slide',
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 16),
              Builder(
                builder: (context) {
                  final slideContent = doc.sections.isNotEmpty && _selectedSectionIndex < doc.sections.length
                      ? doc.sections[_selectedSectionIndex]
                      : 'No content on this slide.';
                  if (slideContent.trim().isEmpty) {
                    return Text(
                      'No content on this slide.',
                      style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                    );
                  }

                  final isSpeakingThisSlide =
                      _isPlayingVoice && _currentSpeakingTopic == 'slide_$_selectedSectionIndex';

                  if (_isBionicReading) {
                    return SelectableText.rich(
                      TextSpan(
                        children: BionicReadingHelper.buildBionicSpans(
                          slideContent,
                          isDark: isDark,
                          activeSentenceIndex: isSpeakingThisSlide ? _karaokeSentenceIndex : null,
                          fontSize: 13.0,
                          lineHeight: 1.55,
                        ),
                      ),
                    );
                  }

                  return SelectableText(
                    slideContent,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.45,
                      color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF374151),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        SizedBox(height: _isPlayingVoice ? 90 : 30),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stickyAudioPlayerDock(bool isDark) {
    final activeSection = _document != null &&
            _document!.sections.isNotEmpty &&
            _selectedSectionIndex < _document!.sections.length
        ? (_document!.fileType == 'pptx'
            ? 'Slide ${_selectedSectionIndex + 1}'
            : 'Page ${_selectedSectionIndex + 1}')
        : 'Audio Narration';

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF0F172A).withValues(alpha: 0.90)
                : Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : const Color(0xFF6366F1).withValues(alpha: 0.3),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.graphic_eq_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reading $activeSection',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Karaoke Sync Active',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: _cycleTtsSpeed,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white12 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    '${_ttsSpeed}x',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.jetBlack,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.stop_circle_rounded, color: AppColors.crimsonRed, size: 28),
                tooltip: 'Stop Playback',
                onPressed: () async {
                  AppHaptics.medium();
                  await _tts.stop();
                  if (mounted) {
                    setState(() {
                      _isPlayingVoice = false;
                      _currentSpeakingTopic = null;
                      _karaokeSentenceIndex = 0;
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
