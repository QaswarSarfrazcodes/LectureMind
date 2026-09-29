import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/app_providers.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_neumorphic.dart';
import '../../../../shared_models/chat_message.dart';
import '../controllers/home_chat_controller.dart';
import '../../../record_process/presentation/controllers/record_session_controller.dart';
import '../widgets/chat_message_bubble.dart';
import '../widgets/home_navigation_drawer.dart';
import '../../../../core/utils/app_haptics.dart';

/// State-of-the-Art ChatGPT & Gemini Inspired Conversational Interface.
/// Cross-platform (Android · iOS · Web) with responsive layout, AssemblyAI voice agent,
/// and document ingestion.
class HomeChatScreen extends ConsumerStatefulWidget {
  const HomeChatScreen({super.key});

  @override
  ConsumerState<HomeChatScreen> createState() => _HomeChatScreenState();
}

class _HomeChatScreenState extends ConsumerState<HomeChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FlutterTts _tts = FlutterTts();
  String? _currentlyPlayingMsgId;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _showJumpToBottom = false;

  @override
  void initState() {
    super.initState();
    _initTts();
    _scrollController.addListener(_onChatScroll);
  }

  void _onChatScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    final current = _scrollController.offset;
    final shouldShow = (max - current) > 300;
    if (shouldShow != _showJumpToBottom) {
      setState(() => _showJumpToBottom = shouldShow);
    }
  }

  Future<void> _initTts() async {
    try {
      await _tts.setPitch(1.15);        // Feminine voice pitch
      await _tts.setSpeechRate(0.72);   // 1.25× speed
      await _tts.setVolume(1.0);
      await _tts.setLanguage('en-GB');  // British English — natural female cadence
      _tts.setCompletionHandler(() {
        if (mounted) setState(() => _currentlyPlayingMsgId = null);
      });
      _tts.setErrorHandler((_) {
        if (mounted) setState(() => _currentlyPlayingMsgId = null);
      });
    } catch (_) {}
  }

  Future<void> _speakText(String msgId, String text) async {
    if (_currentlyPlayingMsgId == msgId) {
      await _tts.stop();
      setState(() => _currentlyPlayingMsgId = null);
      return;
    }
    await _tts.stop();
    setState(() => _currentlyPlayingMsgId = msgId);

    final isUrdu = RegExp(r'[\u0600-\u06FF]').hasMatch(text);
    await _tts.setLanguage(isUrdu ? 'ur-PK' : 'en-US');
    await _tts.speak(text);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onChatScroll);
    _tts.stop();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _jumpToLatest() {
    AppHaptics.light();
    _scrollToBottom();
  }




  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage([String? textOverride]) {
    final query = (textOverride ?? _textController.text).trim();
    if (query.isEmpty) return;

    AppHaptics.medium();
    _textController.clear();
    ref.read(homeChatControllerProvider.notifier).sendMessage(query);
    _scrollToBottom();
  }

  void _openVoiceAgent() {
    final lecture = ref.read(homeChatControllerProvider).selectedLecture;
    context.push(AppRoutes.voiceAgent, extra: lecture?.transcript);
  }

  void _showAttachmentSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.navyBorder : const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              _attachmentOption(
                icon: Icons.slideshow_rounded,
                iconColor: const Color(0xFFF97316),
                title: 'PowerPoint (.pptx) or PDF Slides',
                subtitle: 'AI slide summarizer & interactive mind map',
                onTap: () {
                  Navigator.pop(ctx);
                  context.push(AppRoutes.documentStudio);
                },
              ),
              _attachmentOption(
                icon: Icons.audio_file_rounded,
                iconColor: const Color(0xFF10B981),
                title: 'Upload Audio Lecture (.mp3, .m4a, .wav)',
                subtitle: 'Transcribe with AssemblyAI Universal-3 Pro',
                onTap: () {
                  Navigator.pop(ctx);
                  _handleUploadAudio();
                },
              ),
              _attachmentOption(
                icon: Icons.mic_rounded,
                iconColor: const Color(0xFF6366F1),
                title: 'AssemblyAI Voice Agent (Live Conversation)',
                subtitle: 'Voice-to-voice with speech barge-in & Urdu support',
                onTap: () {
                  Navigator.pop(ctx);
                  _openVoiceAgent();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _attachmentOption({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : AppColors.jetBlack,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : const Color(0xFF6B7280)),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF9CA3AF)),
      onTap: onTap,
    );
  }

  Future<void> _handleUploadAudio() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'm4a', 'wav', 'aac', 'ogg', 'opus', 'flac'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final bytes = file.bytes;

      if (bytes == null || bytes.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not read audio file data. Please try again.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Transcribing ${file.name} with AssemblyAI…')),
        );
      }

      final res = await ref.read(assemblyAiClientProvider).transcribeFile(
            fileBytes: bytes,
            fileName: file.name,
          );

      if (!mounted) return;

      if (res.isSuccess && res.data != null) {
        final cleanName = file.name.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');
        final lec = await ref
            .read(recordSessionControllerProvider.notifier)
            .processUploadedText(
              res.data!,
              customTitle: cleanName,
            );
        if (mounted && lec != null) {
          ref.read(homeChatControllerProvider.notifier).selectLecture(lec);
          context.go(AppRoutes.notesQuiz);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.failure?.message ?? 'Failed to transcribe audio'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(homeChatControllerProvider);
    final userSettings = ref.watch(userSettingsProvider);
    final messages = chatState.filteredMessages;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: HomeNavigationDrawer(
        userSettings: userSettings,
        onEditProfile: () => context.push(AppRoutes.profile),
      ),
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.menu_rounded, color: isDark ? Colors.white : const Color(0xFF1F2937), size: 24),
          tooltip: 'Open Menu',
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        centerTitle: true,
        title: _modelSelectorPill(context, chatState, isDark),
        actions: [
          IconButton(
            icon: const Icon(Icons.graphic_eq_rounded, color: Color(0xFF10B981), size: 24),
            tooltip: 'AssemblyAI Voice Agent',
            onPressed: _openVoiceAgent,
          ),
          IconButton(
            icon: Icon(Icons.edit_square, color: isDark ? Colors.white : const Color(0xFF1F2937), size: 20),
            tooltip: 'New Chat',
            onPressed: () => ref.read(homeChatControllerProvider.notifier).startNewChat(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Column(
              children: [
                Expanded(
                  child: messages.isEmpty
                      ? _emptyState(context, isDark)
                      : Stack(
                          children: [
                            ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              itemCount: messages.length,
                              itemBuilder: (context, index) {
                                final msg = messages[index];
                                final isLastMessage = index == messages.length - 1;
                                final isPlayingThis = _currentlyPlayingMsgId == msg.id;

                                // If assistant message is still waiting for first token while sending, show ThinkingBubble
                                if (msg.role == ChatRole.assistant &&
                                    msg.content.isEmpty &&
                                    chatState.isSending) {
                                  return const ThinkingBubble();
                                }

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ChatMessageBubble(
                                      message: msg,
                                      isPlaying: isPlayingThis,
                                      onToggleSpeech: () => _speakText(msg.id, msg.content),
                                      onRate: (isUp) => ref
                                          .read(homeChatControllerProvider.notifier)
                                          .rateMessage(msg.id, isUp ? 'up' : 'down'),
                                    ),
                                    if (isLastMessage &&
                                        msg.role == ChatRole.assistant &&
                                        !chatState.isSending)
                                      QuickFollowupChips(
                                        onChipSelected: (prompt) => _sendMessage(prompt),
                                      ),
                                  ],
                                );
                              },
                            ),
                            if (_showJumpToBottom)
                              Positioned(
                                bottom: 12,
                                right: 16,
                                child: _jumpToBottomPill(isDark),
                              ),
                          ],
                        ),
                ),
                _inputCapsuleDock(context, chatState, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _modelSelectorPill(BuildContext context, HomeChatState state, bool isDark) {
    return PopupMenuButton<String>(
      tooltip: 'Select AI Engine or Subject Folder',
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      offset: const Offset(0, 42),
      onSelected: (val) {
        if (val == '__new_folder__') {
          _showNewFolderDialog();
        } else {
          ref.read(homeChatControllerProvider.notifier).setActiveFolder(val);
        }
      },
      itemBuilder: (ctx) {
        final folders = ref.read(userSettingsProvider).subjectFolders;
        return [
          const PopupMenuItem(
            enabled: false,
            child: Text(
              'ACTIVE AI ENGINE',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF9CA3AF)),
            ),
          ),
          const PopupMenuItem(
            value: 'All',
            child: Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: Color(0xFF10B981), size: 18),
                SizedBox(width: 10),
                Text('LectureMind AI (Dual-Core)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem(
            enabled: false,
            child: Text(
              'SUBJECT FOLDERS',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF9CA3AF)),
            ),
          ),
          ...folders.map(
            (f) => PopupMenuItem(
              value: f,
              child: Row(
                children: [
                  const Icon(Icons.folder_outlined, color: Color(0xFF4B5563), size: 18),
                  const SizedBox(width: 10),
                  Text(f, style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: '__new_folder__',
            child: Row(
              children: [
                Icon(Icons.create_new_folder_outlined, color: AppColors.crimsonRed, size: 18),
                SizedBox(width: 10),
                Text('+ New Subject Folder',
                    style: TextStyle(color: AppColors.crimsonRed, fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
          ),
        ];
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? AppColors.navyLight : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              state.activeSubjectFolder == 'All' ? 'LectureMind AI' : state.activeSubjectFolder,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: isDark ? Colors.white70 : const Color(0xFF6B7280)),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context, bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Neumorphic Logo Dial
            Container(
              width: 76,
              height: 76,
              decoration: NeuDecorations.circleRaised(
                isDark: isDark,
                withRedGlow: true,
              ),
              child: Center(
                child: SvgPicture.asset(
                  'assets/app-logoandicon.svg',
                  width: 40,
                  height: 40,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'LectureMind AI Studio',
              style: AppTextStyles.heroHeadline(isDark ? NeuColors.pureWhite : const Color(0xFF0F172A)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Apna Lecture, Apni Zubaan — Voice to Structured Notes, PDF, Mind Map & Quiz',
              style: AppTextStyles.caption(isDark ? NeuColors.mutedBlue : const Color(0xFF64748B)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // ── Socratic Academic Starter Bento Grid (Phase 1 UX Upgrade) ───
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '⚡ SOCRATIC ACADEMIC PROMPTS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: isDark ? AppColors.crimsonRed : const Color(0xFFDC2626),
                ),
              ),
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 580;
                return GridView.count(
                  crossAxisCount: isWide ? 2 : 1,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: isWide ? 3.6 : 3.8,
                  children: [
                    _socraticPromptTile(
                      emoji: '💡',
                      prompt: "Explain Dijkstra's algorithm using a Lahore traffic analogy",
                      isDark: isDark,
                    ),
                    _socraticPromptTile(
                      emoji: '📝',
                      prompt: 'Extract the 5 most testable concepts from my last lecture',
                      isDark: isDark,
                    ),
                    _socraticPromptTile(
                      emoji: '🎯',
                      prompt: 'Create a 3-question rapid quiz on Operating Systems',
                      isDark: isDark,
                    ),
                    _socraticPromptTile(
                      emoji: '🇵🇰',
                      prompt: 'Explain OOP Polymorphism in pure Nastaliq Urdu',
                      isDark: isDark,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'STUDIO CAPABILITIES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: isDark ? NeuColors.mutedBlue : const Color(0xFF64748B),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // 6 Core Features in Neumorphic Cards
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 580;
                return GridView.count(
                  crossAxisCount: isWide ? 2 : 1,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: isWide ? 2.6 : 3.4,
                  children: [
                    _neuFeatureCard(
                      icon: Icons.mic_rounded,
                      iconColor: AppColors.crimsonRed,
                      title: 'Live Voice Input (STT)',
                      subtitle: 'Record lecture speech with live transcription',
                      onTap: () => context.go(AppRoutes.record),
                      isDark: isDark,
                    ),
                    _neuFeatureCard(
                      icon: Icons.picture_as_pdf_rounded,
                      iconColor: const Color(0xFFF97316),
                      title: 'PDF Reader (Read PDF)',
                      subtitle: 'Upload & read PDF, extract notes, mind map & quiz',
                      onTap: () => context.go(AppRoutes.documentStudio),
                      isDark: isDark,
                    ),
                    _neuFeatureCard(
                      icon: Icons.article_rounded,
                      iconColor: const Color(0xFF3B82F6),
                      title: 'Structured Notes & Headings',
                      subtitle: 'Pedagogical breakdowns with H1, H2 & subheadings',
                      onTap: () => context.go(AppRoutes.notesQuiz),
                      isDark: isDark,
                    ),
                    _neuFeatureCard(
                      icon: Icons.download_rounded,
                      iconColor: const Color(0xFFEF4444),
                      title: 'Export Notes as PDF',
                      subtitle: 'One-click styled PDF generation & download',
                      onTap: () => context.go(AppRoutes.notesQuiz),
                      isDark: isDark,
                    ),
                    _neuFeatureCard(
                      icon: Icons.hub_rounded,
                      iconColor: const Color(0xFF10B981),
                      title: 'Mind Map & JPG Image Export',
                      subtitle: 'Interactive concept graph with 1-tap JPG download',
                      onTap: () => context.go(AppRoutes.notesQuiz),
                      isDark: isDark,
                    ),
                    _neuFeatureCard(
                      icon: Icons.record_voice_over_rounded,
                      iconColor: const Color(0xFF8B5CF6),
                      title: 'AI Voice Assistant',
                      subtitle: 'Real-time conversational speech & lecture replay',
                      onTap: _openVoiceAgent,
                      isDark: isDark,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _neuFeatureCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return NeuCard(
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: NeuDecorations.circleRaised(
              isDark: isDark,
              withRedGlow: iconColor == AppColors.crimsonRed,
            ),
            child: Center(
              child: Icon(icon, color: iconColor, size: 22),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: isDark ? NeuColors.pureWhite : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: isDark ? NeuColors.mutedBlue : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 13,
            color: isDark ? NeuColors.subtleSlate : const Color(0xFF94A3B8),
          ),
        ],
      ),
    );
  }

  Widget _socraticPromptTile({
    required String emoji,
    required String prompt,
    required bool isDark,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        AppHaptics.light();
        _sendMessage(prompt);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFE2E8F0),
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                prompt,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                  color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_upward_rounded,
              size: 15,
              color: isDark ? AppColors.crimsonRed : const Color(0xFFDC2626),
            ),
          ],
        ),
      ),
    );
  }

  Widget _jumpToBottomPill(bool isDark) {
    return GestureDetector(
      onTap: _jumpToLatest,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2430) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.crimsonRed.withValues(alpha: 0.35),
            width: 0.9,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: AppColors.crimsonRed,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Jump to Latest',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(width: 5),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: AppColors.crimsonRed,
            ),
          ],
        ),
      ),
    );
  }

  // ── Phase 2: Floating Frosted Glass Input Dock ────────────────────────────
  Widget _inputCapsuleDock(
      BuildContext context, HomeChatState chatState, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.white.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark
                    ? AppVelvetTokens.neonCrimson.withValues(alpha: 0.18)
                    : const Color(0xFFE5E7EB),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? AppVelvetTokens.neonCrimson.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.06),
                  blurRadius: 24,
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Attach button
                _DockIconBtn(
                  icon: Icons.add_rounded,
                  tooltip: 'Upload slides or audio',
                  onPressed: _showAttachmentSheet,
                  isDark: isDark,
                ),
                const SizedBox(width: 6),
                // Text field
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: TextField(
                      controller: _textController,
                      maxLines: 5,
                      minLines: 1,
                      textInputAction: TextInputAction.send,
                      textCapitalization: TextCapitalization.sentences,
                      style: TextStyle(
                        fontSize: 14.5,
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        hintText: chatState.activeSubjectFolder == 'All'
                            ? 'Message LectureMind…'
                            : 'Ask in ${chatState.activeSubjectFolder}…',
                        hintStyle: TextStyle(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.30)
                              : const Color(0xFF94A3B8),
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 8),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // Voice agent button (neon mic)
                _DockIconBtn(
                  icon: Icons.mic_rounded,
                  tooltip: 'Voice Agent',
                  onPressed: _openVoiceAgent,
                  isDark: isDark,
                  accentColor: AppVelvetTokens.neonCrimson,
                ),
                const SizedBox(width: 6),
                // Send / stop button
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _textController,
                  builder: (context, value, _) {
                    final hasText = value.text.trim().isNotEmpty;
                    final isSending = chatState.isSending;
                    final active = hasText || isSending;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: active
                            ? AppVelvetTokens.neonCrimson
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : const Color(0xFFF3F4F6)),
                        boxShadow: active
                            ? AppVelvetTokens.neonGlowShadow(
                                AppVelvetTokens.neonCrimson,
                                blur: 14,
                                spread: 0)
                            : const [],
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          isSending
                              ? Icons.stop_rounded
                              : Icons.arrow_upward_rounded,
                          size: 18,
                          color: active
                              ? Colors.white
                              : (isDark
                                  ? Colors.white30
                                  : const Color(0xFF9CA3AF)),
                        ),
                        tooltip: isSending
                            ? 'Stop generation'
                            : 'Send message',
                        onPressed: active ? () => _sendMessage() : null,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  void _showNewFolderDialog() {
    final folderCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Create Subject Folder',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: folderCtrl,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Subject / Course Name',
            hintText: 'e.g. Data Structures, Physics',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.crimsonRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final val = folderCtrl.text.trim();
              if (val.isNotEmpty) {
                ref.read(homeChatControllerProvider.notifier).addSubjectFolder(val);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Create Folder'),
          ),
        ],
      ),
    );
  }
}

// \u2500\u2500 Phase 2 Dock Icon Button \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
class _DockIconBtn extends StatelessWidget {
  const _DockIconBtn({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.isDark,
    this.accentColor,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool isDark;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final iconColor = accentColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.55)
            : const Color(0xFF64748B));

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : const Color(0xFFF3F4F6),
            boxShadow: accentColor != null
                ? AppVelvetTokens.neonGlowShadow(accentColor!, blur: 8, spread: 0)
                : const [],
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
      ),
    );
  }
}
