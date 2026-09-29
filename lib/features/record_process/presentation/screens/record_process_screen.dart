import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/app_providers.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_neumorphic.dart';
import '../../../../shared_models/connectivity_status.dart';
import '../../../../shared_models/language.dart';
import '../../../../shared_widgets/app_button.dart';
import '../../../../shared_widgets/connectivity_banner.dart';
import '../controllers/record_session_controller.dart';
import '../widgets/mic_button.dart';
import '../widgets/processing_steps.dart';
import '../widgets/live_soundwave_visualizer.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../core/utils/bidi_text_helper.dart';

class RecordProcessScreen extends ConsumerStatefulWidget {
  const RecordProcessScreen({super.key});
  @override
  ConsumerState<RecordProcessScreen> createState() => _RecordProcessScreenState();
}

class _RecordProcessScreenState extends ConsumerState<RecordProcessScreen> {
  final _scroll = ScrollController();

  @override
  void dispose() { _scroll.dispose(); super.dispose(); }

  void _snack(String msg, {Color? bg}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: bg),
    );
  }

  Future<void> _toggle() async {
    final ctrl  = ref.read(recordSessionControllerProvider.notifier);
    final state = ref.read(recordSessionControllerProvider);
    await AppHaptics.medium();
    if (state.isRecording) {
      await ctrl.stopRecording();
    } else {
      await ctrl.startRecording();
    }
  }

  Future<void> _upload() async {
    await AppHaptics.light();
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'm4a', 'wav', 'aac', 'ogg', 'opus', 'flac'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.size > 200 * 1024 * 1024) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('File Too Large (فائل بہت بڑی ہے)'),
            content: const Text(
              'Selected audio exceeds the 200MB limit.\n\n'
              'منتخب کردہ فائل 200MB کی حد سے زیادہ ہے۔'),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
          ),
        );
        return;
      }

      final bytes = file.bytes;

      if (bytes == null || bytes.isEmpty) {
        _snack('Could not read the audio file data. Please select the file again.', bg: AppColors.error);
        return;
      }

      _snack('Uploading & transcribing ${file.name}…');
      final res = await ref.read(assemblyAiClientProvider)
          .transcribeFile(fileBytes: bytes, fileName: file.name);
      if (!mounted) return;

      if (res.isSuccess && res.data != null) {
        final ctrl = ref.read(recordSessionControllerProvider.notifier);
        _snack('✨ AI Refining and polishing lecture transcript…');
        final refined = await ctrl.refineTranscriptWithAi(res.data!);
        final lec = await ctrl.processUploadedText(
          refined,
          customTitle: file.name.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), ''),
        );
        if (mounted && lec != null) context.go(AppRoutes.notesQuiz);
      } else {
        _snack(res.failure?.message ?? 'Failed to transcribe audio file',
            bg: AppColors.error);
      }
    } catch (e) {
      _snack('File error: $e', bg: AppColors.error);
    }
  }

  static String _fmt(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final state  = ref.watch(recordSessionControllerProvider);
    final online = ref.watch(connectivityStatusProvider) == ConnectivityStatus.online;

    ref.listen<RecordSessionState>(recordSessionControllerProvider, (_, next) {
      if (next.status == RecordStatus.completed && next.createdLecture != null) {
        context.go(AppRoutes.notesQuiz);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Record & Process'),
        actions: [
          if (state.isRecording || state.isProcessing)
            TextButton(
              onPressed: () => ref.read(recordSessionControllerProvider.notifier).cancelSession(),
              child: const Text('Cancel', style: TextStyle(color: AppColors.error)),
            ),
        ],
      ),
      body: Column(children: [
        const ConnectivityBanner(),
        if (state.errorMessage != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimens.space12),
            color: AppColors.error.withValues(alpha: 0.1),
            child: Text(state.errorMessage!, textAlign: TextAlign.center,
                style: AppTextStyles.caption(AppColors.error)),
          ),
        Expanded(
          child: state.isProcessing
              ? ProcessingSteps(currentStep: state.processingStepIndex)
              : state.isReviewing
                  ? _TranscriptReviewBody(
                      initialText: state.fullTranscript,
                      duration: _fmt(state.elapsedSeconds),
                      onSaveAndProcess: (text) {
                        final ctrl =
                            ref.read(recordSessionControllerProvider.notifier);
                        ctrl.updateTranscript(text);
                        ctrl.processReviewedTranscript();
                      },
                      onCancel: () => ref
                          .read(recordSessionControllerProvider.notifier)
                          .cancelSession(),
                    )
                  : _RecordBody(
                      state: state,
                      isOnline: online,
                      currentLang: ref.watch(activeLanguageProvider),
                      onLanguageChanged: (l) =>
                          ref.read(activeLanguageProvider.notifier).state = l,
                      scrollController: _scroll,
                      onToggle: _toggle,
                      onUpload: _upload,
                      timer: _fmt(state.elapsedSeconds),
                    ),
        ),
      ]),
    );
  }
}

// ── Idle / Recording body ─────────────────────────────────────────────────────
class _RecordBody extends StatelessWidget {
  const _RecordBody({
    required this.state,
    required this.isOnline,
    required this.currentLang,
    required this.onLanguageChanged,
    required this.scrollController,
    required this.onToggle,
    required this.onUpload,
    required this.timer,
  });
  final RecordSessionState state;
  final bool isOnline;
  final Language currentLang;
  final ValueChanged<Language> onLanguageChanged;
  final ScrollController scrollController;
  final VoidCallback onToggle, onUpload;
  final String timer;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rec    = state.isRecording;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.space24),
      child: Column(children: [
        const SizedBox(height: AppDimens.space24),
        if (rec)
          _TimerChip(timer: timer),
        const SizedBox(height: AppDimens.space16),
        // Neumorphic Language Selector Pills
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            NeuPill(
              label: 'English 🇬🇧',
              isSelected: currentLang == Language.english,
              onTap: rec
                  ? null
                  : () {
                      AppHaptics.selection();
                      onLanguageChanged(Language.english);
                    },
            ),
            const SizedBox(width: 8),
            NeuPill(
              label: 'اردو 🇵🇰',
              isSelected: currentLang == Language.urdu,
              onTap: rec
                  ? null
                  : () {
                      AppHaptics.selection();
                      onLanguageChanged(Language.urdu);
                    },
            ),
            const SizedBox(width: 8),
            NeuPill(
              label: 'Roman Urdu 🌐',
              isSelected: currentLang == Language.romanUrdu,
              onTap: rec
                  ? null
                  : () {
                      AppHaptics.selection();
                      onLanguageChanged(Language.romanUrdu);
                    },
            ),
          ],
        ),
        const SizedBox(height: AppDimens.space24),
        MicButton(isRecording: rec, isEnabled: true, onPressed: onToggle),
        const SizedBox(height: AppDimens.space20),
        Text(
          rec ? 'Listening live… (Tap button to finish)' : 'Tap to start recording lecture',
          style: AppTextStyles.title(scheme.onSurface),
        ),
        const SizedBox(height: 6),
        Text(
          rec
              ? 'Universal-3 Pro Realtime Speech-to-Text streaming • Mode: ${currentLang.label}'
              : 'Apna Lecture, Apni Zubaan — Urdu & English code-switch supported',
          style: AppTextStyles.caption(scheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppDimens.space20),
        if (rec) ...[
          const LiveSoundwaveVisualizer(isRecording: true, height: 72),
          const SizedBox(height: AppDimens.space16),
          Expanded(child: _TranscriptView(state: state, ctrl: scrollController)),
        ] else ...[
          const Spacer(),
          AppButton(
            label: 'Upload audio file instead', icon: AppIcons.upload,
            isOutlined: true, onPressed: onUpload,
          ),
          const SizedBox(height: AppDimens.space32),
        ],
      ]),
    );
  }
}

class _TimerChip extends StatelessWidget {
  const _TimerChip({required this.timer});
  final String timer;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: NeuDecorations.raised(isDark: isDark, radius: 24, withRedGlow: true),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppColors.crimsonRed,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: NeuColors.crimsonGlow, blurRadius: 6, spreadRadius: 1),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          timer,
          style: AppTextStyles.button(AppColors.crimsonRed),
        ),
      ]),
    );
  }
}

class _TranscriptView extends StatelessWidget {
  const _TranscriptView({required this.state, required this.ctrl});
  final RecordSessionState state;
  final ScrollController ctrl;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimens.space20),
      decoration: NeuDecorations.sunken(isDark: isDark, radius: 20),
      child: SingleChildScrollView(
        controller: ctrl,
        reverse: true,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (state.fullTranscript.isNotEmpty)
            BidiTextHelper.autoText(
              state.fullTranscript,
              style: AppTextStyles.body(scheme.onSurface).copyWith(fontSize: 15),
            ),
          if (state.partialTranscript.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: BidiTextHelper.autoText(
                '${state.partialTranscript} …',
                style: AppTextStyles.body(AppColors.crimsonRed).copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (state.fullTranscript.isEmpty && state.partialTranscript.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'Listening for professor\'s speech…\nگفتگو شروع کیجیے، یہاں براہ راست تحریر نمودار ہوگی۔',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption(scheme.onSurfaceVariant),
                ),
              ),
            ),
        ]),
      ),
    );
  }
}

/// Intermediate Review & Refinement Studio for lecture transcripts.
/// Allows students to review, edit, correct terms, and select AI synthesis actions.
class _TranscriptReviewBody extends ConsumerStatefulWidget {
  const _TranscriptReviewBody({
    required this.initialText,
    required this.duration,
    required this.onSaveAndProcess,
    required this.onCancel,
  });

  final String initialText;
  final String duration;
  final ValueChanged<String> onSaveAndProcess;
  final VoidCallback onCancel;

  @override
  ConsumerState<_TranscriptReviewBody> createState() => _TranscriptReviewBodyState();
}

class _TranscriptReviewBodyState extends ConsumerState<_TranscriptReviewBody> {
  late final TextEditingController _controller;
  bool _isPolishing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int get _wordCount {
    final text = _controller.text.trim();
    if (text.isEmpty) return 0;
    return text.split(RegExp(r'\s+')).length;
  }

  Future<void> _handleAiPolish() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isPolishing) return;
    setState(() => _isPolishing = true);
    try {
      final ctrl = ref.read(recordSessionControllerProvider.notifier);
      final polished = await ctrl.refineTranscriptWithAi(text);
      if (mounted) {
        setState(() {
          _controller.text = polished;
          _isPolishing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✨ Speech transcript polished & academic terms normalized!'),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _isPolishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(AppDimens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header strip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Review & Edit Transcript',
                    style: AppTextStyles.title(scheme.onSurface).copyWith(fontSize: 17),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Refine professor\'s words before AI synthesis',
                    style: AppTextStyles.caption(scheme.onSurfaceVariant),
                  ),
                ],
              ),
              Row(
                children: [
                  // AI Polish Button
                  InkWell(
                    onTap: _isPolishing ? null : _handleAiPolish,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.crimsonRed.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.crimsonRed.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isPolishing)
                            const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.crimsonRed),
                            )
                          else
                            const Icon(Icons.auto_awesome, size: 13, color: AppColors.crimsonRed),
                          const SizedBox(width: 5),
                          Text(
                            _isPolishing ? 'Polishing…' : '✨ AI Polish & Fix Terms',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.crimsonRed,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '⏱ ${widget.duration}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '📝 $_wordCount words',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Neumorphic Editable Transcript Box
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: NeuDecorations.sunken(isDark: isDark, radius: 20),
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                onChanged: (_) => setState(() {}),
                style: TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: isDark ? NeuColors.pureWhite : const Color(0xFF0F172A),
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Transcript will appear here for review…',
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              SizedBox(
                height: 52,
                child: NeuButton(
                  label: 'Discard',
                  isPrimary: false,
                  icon: Icons.delete_outline_rounded,
                  onPressed: widget.onCancel,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: NeuButton(
                  label: 'Generate Notes, Mind Map & Quiz',
                  icon: Icons.auto_awesome_rounded,
                  onPressed: () {
                    final text = _controller.text.trim();
                    if (text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter or record some lecture text first.'),
                        ),
                      );
                      return;
                    }
                    widget.onSaveAndProcess(text);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

