import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared_models/chat_message.dart';
import '../../../../shared_widgets/velvet_glass_card.dart';
import '../../../../core/utils/bidi_text_helper.dart';
import '../../../../core/utils/app_haptics.dart';

/// Phase 2 — Midnight Velvet ChatGPT / Gemini style chat bubble.
///
/// User messages: glassmorphic pill aligned right with subtle crimson glow.
/// AI messages: frosted-glass full-width card with streaming shimmer cursor,
///              structured markdown blocks, neon code cards, and action bar.
class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isPlaying,
    required this.onToggleSpeech,
    this.onRate,
    this.isStreaming = false,
  });

  final ChatMessage message;
  final bool isPlaying;
  final VoidCallback onToggleSpeech;
  final void Function(bool isUp)? onRate;
  /// True while the AI is still streaming tokens into this message.
  final bool isStreaming;

  bool get _isUrdu => BidiTextHelper.isUrduDominant(message.content);

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatRole.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isUser) {
      return _UserBubble(message: message, isDark: isDark);
    }
    return _AiBubble(
      message: message,
      isDark: isDark,
      isUrdu: _isUrdu,
      isPlaying: isPlaying,
      onToggleSpeech: onToggleSpeech,
      onRate: onRate,
      isStreaming: isStreaming,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// User Bubble (Phase 2)
// ─────────────────────────────────────────────────────────────────────────────

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.message, required this.isDark});

  final ChatMessage message;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final isUrdu = BidiTextHelper.isUrduDominant(message.content);

    return Align(
      alignment: isUrdu ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 16,
          left: isUrdu ? 16 : 56,
          right: isUrdu ? 56 : 0,
        ),
        child: isDark
            ? ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 13),
                    decoration: BoxDecoration(
                      // Subtle crimson-tinted glass for user
                      color: AppVelvetTokens.neonCrimson.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            AppVelvetTokens.neonCrimson.withValues(alpha: 0.25),
                        width: 0.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppVelvetTokens.neonCrimson
                              .withValues(alpha: 0.12),
                          blurRadius: 14,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Text(
                      message.content,
                      textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
                      textAlign: isUrdu ? TextAlign.right : TextAlign.start,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        height: isUrdu
                            ? BidiTextHelper.nastaliqLineHeight
                            : BidiTextHelper.latinLineHeight,
                        letterSpacing: isUrdu ? 0.0 : 0.1,
                      ),
                    ),
                  ),
                ),
              )
            : Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 13),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF2F7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: const Color(0xFFD1D9E6), width: 0.8),
                ),
                child: Text(
                  message.content,
                  textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
                  textAlign: isUrdu ? TextAlign.right : TextAlign.start,
                  style: TextStyle(
                    color: const Color(0xFF0F172A),
                    fontSize: 14.5,
                    height: isUrdu
                        ? BidiTextHelper.nastaliqLineHeight
                        : BidiTextHelper.latinLineHeight,
                  ),
                ),
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AI Bubble (Phase 2) — frosted glass card with shimmer cursor
// ─────────────────────────────────────────────────────────────────────────────

class _AiBubble extends StatelessWidget {
  const _AiBubble({
    required this.message,
    required this.isDark,
    required this.isUrdu,
    required this.isPlaying,
    required this.onToggleSpeech,
    this.onRate,
    this.isStreaming = false,
  });

  final ChatMessage message;
  final bool isDark;
  final bool isUrdu;
  final bool isPlaying;
  final VoidCallback onToggleSpeech;
  final void Function(bool isUp)? onRate;
  final bool isStreaming;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Avatar + label row ─────────────────────────────────────────────
          Row(
            children: [
              // Neon-rimmed logo orb
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? AppVelvetTokens.glassPanel
                      : const Color(0xFFF3F4F6),
                  border: Border.all(
                    color: AppVelvetTokens.neonCrimson.withValues(alpha: 0.45),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          AppVelvetTokens.neonCrimson.withValues(alpha: 0.20),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/app-logoandicon.svg',
                    width: 14,
                    height: 14,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Text(
                'LectureMind AI',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.75)
                      : const Color(0xFF0F172A),
                ),
              ),
              if (isStreaming) ...[
                const SizedBox(width: 8),
                _StreamingPulse(),
              ],
            ],
          ),

          const SizedBox(height: 10),

          // ── Message body — frosted glass card ─────────────────────────────
          isDark
              ? VelvetGlassCard(
                  radius: 18,
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                  blur: 12,
                  fillOpacity: 0.05,
                  borderColor:
                      Colors.white.withValues(alpha: 0.09),
                  child: _messageContent(context),
                )
              : Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFE5E7EB),
                      width: 0.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _messageContent(context),
                ),

          const SizedBox(height: 8),

          // ── Action bar ────────────────────────────────────────────────────
          _ActionBar(
            message: message,
            isDark: isDark,
            isPlaying: isPlaying,
            onToggleSpeech: onToggleSpeech,
            onRate: onRate,
          ),
        ],
      ),
    );
  }

  Widget _messageContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StructuredAiMessageView(
          content: message.content,
          isDark: isDark,
          isUrdu: isUrdu,
        ),
        // Streaming cursor — shown while AI generates
        if (isStreaming) const _StreamingCursor(),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Streaming cursor & pulse
// ─────────────────────────────────────────────────────────────────────────────

class _StreamingPulse extends StatefulWidget {
  @override
  State<_StreamingPulse> createState() => _StreamingPulseState();
}

class _StreamingPulseState extends State<_StreamingPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppVelvetTokens.neonCrimson
              .withValues(alpha: 0.4 + _ctrl.value * 0.6),
          boxShadow: [
            BoxShadow(
              color: AppVelvetTokens.neonCrimson
                  .withValues(alpha: 0.2 + _ctrl.value * 0.4),
              blurRadius: 6,
            ),
          ],
        ),
      ),
    );
  }
}

class _StreamingCursor extends StatefulWidget {
  const _StreamingCursor();

  @override
  State<_StreamingCursor> createState() => _StreamingCursorState();
}

class _StreamingCursorState extends State<_StreamingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Container(
        margin: const EdgeInsets.only(top: 4),
        width: 2.5,
        height: 16,
        decoration: BoxDecoration(
          color: AppVelvetTokens.neonCrimson.withValues(alpha: _ctrl.value),
          borderRadius: BorderRadius.circular(2),
          boxShadow: [
            BoxShadow(
              color: AppVelvetTokens.neonCrimson
                  .withValues(alpha: _ctrl.value * 0.6),
              blurRadius: 6,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action Bar
// ─────────────────────────────────────────────────────────────────────────────

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.message,
    required this.isDark,
    required this.isPlaying,
    required this.onToggleSpeech,
    this.onRate,
  });

  final ChatMessage message;
  final bool isDark;
  final bool isPlaying;
  final VoidCallback onToggleSpeech;
  final void Function(bool isUp)? onRate;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ActionBtn(
          icon: Icons.copy_rounded,
          size: 15,
          color: isDark ? Colors.white30 : const Color(0xFF94A3B8),
          tooltip: 'Copy',
          onPressed: () {
            AppHaptics.light();
            Clipboard.setData(ClipboardData(text: message.content));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Copied to clipboard'),
                duration: const Duration(seconds: 1),
                backgroundColor: isDark
                    ? AppVelvetTokens.glassPanel
                    : null,
              ),
            );
          },
        ),
        _ActionBtn(
          icon: isPlaying
              ? Icons.stop_circle_rounded
              : Icons.volume_up_rounded,
          size: 16,
          color: isPlaying
              ? const Color(0xFF10B981)
              : (isDark ? Colors.white30 : const Color(0xFF94A3B8)),
          tooltip: isPlaying ? 'Stop' : 'Listen',
          onPressed: () {
            AppHaptics.selection();
            onToggleSpeech();
          },
        ),
        _ActionBtn(
          icon: message.rating == 'up'
              ? Icons.thumb_up_alt_rounded
              : Icons.thumb_up_alt_outlined,
          size: 15,
          color: message.rating == 'up'
              ? const Color(0xFF10B981)
              : (isDark ? Colors.white30 : const Color(0xFF94A3B8)),
          tooltip: 'Helpful',
          onPressed: () {
            AppHaptics.light();
            onRate?.call(true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Feedback saved'),
                duration: Duration(seconds: 1),
              ),
            );
          },
        ),
        _ActionBtn(
          icon: message.rating == 'down'
              ? Icons.thumb_down_alt_rounded
              : Icons.thumb_down_alt_outlined,
          size: 15,
          color: message.rating == 'down'
              ? AppVelvetTokens.neonCrimson
              : (isDark ? Colors.white30 : const Color(0xFF94A3B8)),
          tooltip: 'Needs improvement',
          onPressed: () {
            AppHaptics.light();
            onRate?.call(false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Feedback saved'),
                duration: Duration(seconds: 1),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.size,
    required this.color,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final double size;
  final Color color;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: size, color: color),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ThinkingBubble (Phase 2 upgrade)
// ─────────────────────────────────────────────────────────────────────────────

/// Animated thinking indicator — 3 pulsing orbs in a neon-rimmed frosted card.
class ThinkingBubble extends StatefulWidget {
  const ThinkingBubble({super.key});

  @override
  State<ThinkingBubble> createState() => _ThinkingBubbleState();
}

class _ThinkingBubbleState extends State<ThinkingBubble>
    with TickerProviderStateMixin {
  late final List<AnimationController> _ctrls;
  late final List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _ctrls = List.generate(3, (i) {
      final ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 700),
      )..repeat(reverse: true);
      // Offset each dot
      Future.delayed(Duration(milliseconds: i * 180), () {
        if (mounted) ctrl.repeat(reverse: true);
      });
      return ctrl;
    });
    _anims = _ctrls
        .map((c) => CurvedAnimation(parent: c, curve: Curves.easeInOut))
        .toList();
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 18, right: 60),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Neon-rimmed mini orb
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? AppVelvetTokens.glassPanel
                  : const Color(0xFFF3F4F6),
              border: Border.all(
                color: AppVelvetTokens.neonCrimson.withValues(alpha: 0.4),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppVelvetTokens.neonCrimson.withValues(alpha: 0.15),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/app-logoandicon.svg',
                width: 13,
                height: 13,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Frosted pill with 3-dot animation
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: isDark ? 0.05 : 0.7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(
                        alpha: isDark ? 0.10 : 0.40),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    return AnimatedBuilder(
                      animation: _anims[i],
                      builder: (_, __) => Container(
                        margin: EdgeInsets.only(right: i < 2 ? 5 : 0),
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppVelvetTokens.neonCrimson
                              .withValues(
                                  alpha: 0.3 + _anims[i].value * 0.7),
                          boxShadow: [
                            BoxShadow(
                              color: AppVelvetTokens.neonCrimson.withValues(
                                  alpha: _anims[i].value * 0.5),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'LectureMind is thinking…',
            style: TextStyle(
              fontSize: 12.5,
              fontStyle: FontStyle.italic,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.40)
                  : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick Follow-up Chips (Phase 2 upgrade)
// ─────────────────────────────────────────────────────────────────────────────

class QuickFollowupChips extends StatelessWidget {
  const QuickFollowupChips({super.key, required this.onChipSelected});

  final void Function(String prompt) onChipSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _VelvetChip(
              label: '📌 Key Takeaways',
              isDark: isDark,
              onTap: () => onChipSelected(
                'Please summarize the key takeaways into 3 concise bullet points in Urdu & English.',
              ),
            ),
            const SizedBox(width: 7),
            _VelvetChip(
              label: '🧠 Quiz Me (3 MCQs)',
              isDark: isDark,
              onTap: () => onChipSelected(
                'Create a 3-question multiple choice quiz with answers based on the topic we just discussed.',
              ),
            ),
            const SizedBox(width: 7),
            _VelvetChip(
              label: '🗣️ Roman Urdu Explain',
              isDark: isDark,
              onTap: () => onChipSelected(
                'Isi topic ko Roman Urdu mein aasan aur wazeh tareeqay se samjhayein.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VelvetChip extends StatelessWidget {
  const _VelvetChip({
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.10)
                : const Color(0xFFE2E8F0),
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark
                ? const Color(0xFFE2E8F0)
                : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// StructuredAiMessageView (Phase 2 — LaTeX block support added)
// ─────────────────────────────────────────────────────────────────────────────

/// Rich, structured renderer for ChatGPT & Gemini standard AI responses.
/// Parses Headings, Code Blocks, LaTeX Equations, Tables, Bullet Lists,
/// Callout Boxes, Numbered Lists, and Urdu text.
class StructuredAiMessageView extends StatelessWidget {
  const StructuredAiMessageView({
    super.key,
    required this.content,
    required this.isDark,
    required this.isUrdu,
  });

  final String content;
  final bool isDark;
  final bool isUrdu;

  @override
  Widget build(BuildContext context) {
    final blocks = _parseBlocks(content);

    return Column(
      crossAxisAlignment:
          isUrdu ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: blocks.map((b) => _buildBlock(context, b)).toList(),
    );
  }

  Widget _buildBlock(BuildContext context, _MessageBlock block) {
    switch (block.type) {
      case _BlockType.heading1:
        return Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 6),
          child: Text(
            block.text,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
        );
      case _BlockType.heading2:
        return Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Text(
            block.text,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: isDark
                  ? const Color(0xFFF8FAFC)
                  : const Color(0xFF1E293B),
            ),
          ),
        );
      case _BlockType.heading3:
        return Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 3),
          child: Text(
            block.text,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.crimsonRed,
            ),
          ),
        );
      case _BlockType.codeBlock:
        return _NeonCodeCard(
          code: block.text,
          language: block.extra ?? 'CODE',
          isDark: isDark,
        );
      case _BlockType.latexBlock:
        return _LaTeXCard(
          formula: block.text,
          isDark: isDark,
          isBlock: true,
        );
      case _BlockType.table:
        return _MarkdownTable(
          rows: block.lines,
          isDark: isDark,
        );
      case _BlockType.callout:
        return _CalloutCard(
          text: block.text,
          isDark: isDark,
        );
      case _BlockType.bulletItem:
        return Padding(
          padding: const EdgeInsets.only(bottom: 6, left: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8, right: 8),
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: AppColors.crimsonRed,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: _RichSpanText(
                  raw: block.text,
                  isDark: isDark,
                  isUrdu: isUrdu,
                ),
              ),
            ],
          ),
        );
      case _BlockType.numberedItem:
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 3, right: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.crimsonRed.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  block.extra ?? '•',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.crimsonRed,
                  ),
                ),
              ),
              Expanded(
                child: _RichSpanText(
                  raw: block.text,
                  isDark: isDark,
                  isUrdu: isUrdu,
                ),
              ),
            ],
          ),
        );
      case _BlockType.paragraph:
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _RichSpanText(
            raw: block.text,
            isDark: isDark,
            isUrdu: isUrdu,
          ),
        );
    }
  }

  List<_MessageBlock> _parseBlocks(String raw) {
    final blocks = <_MessageBlock>[];
    final lines = raw.split('\n');
    int i = 0;

    while (i < lines.length) {
      final line = lines[i];
      final trimmed = line.trim();

      // 1. Code Block
      if (trimmed.startsWith('```')) {
        final lang = trimmed.substring(3).trim();
        final codeLines = <String>[];
        i++;
        while (i < lines.length && !lines[i].trim().startsWith('```')) {
          codeLines.add(lines[i]);
          i++;
        }
        i++; // skip closing ```
        blocks.add(_MessageBlock(
          type: _BlockType.codeBlock,
          text: codeLines.join('\n'),
          extra: lang.isEmpty ? 'CODE' : lang.toUpperCase(),
        ));
        continue;
      }

      // 2. LaTeX block ($$...$$ style)
      if (trimmed.startsWith(r'$$')) {
        final latexLines = <String>[];
        final rest = trimmed.substring(2).trim();
        if (rest.endsWith(r'$$') && rest.length > 2) {
          // Single-line block: $$formula$$
          blocks.add(_MessageBlock(
              type: _BlockType.latexBlock,
              text: rest.substring(0, rest.length - 2).trim()));
          i++;
          continue;
        }
        if (rest.isNotEmpty) latexLines.add(rest);
        i++;
        while (i < lines.length &&
            !lines[i].trim().startsWith(r'$$')) {
          latexLines.add(lines[i]);
          i++;
        }
        i++; // skip closing $$
        blocks.add(_MessageBlock(
          type: _BlockType.latexBlock,
          text: latexLines.join('\n').trim(),
        ));
        continue;
      }

      // 3. Table Block (lines with pipes |)
      if (trimmed.startsWith('|') &&
          trimmed.endsWith('|') &&
          trimmed.contains('|')) {
        final tableLines = <String>[];
        while (i < lines.length &&
            lines[i].trim().startsWith('|') &&
            lines[i].trim().endsWith('|')) {
          tableLines.add(lines[i].trim());
          i++;
        }
        blocks.add(_MessageBlock(
          type: _BlockType.table,
          text: '',
          lines: tableLines,
        ));
        continue;
      }

      // 4. Headings
      if (trimmed.startsWith('### ')) {
        blocks.add(_MessageBlock(
            type: _BlockType.heading3,
            text: trimmed.substring(4)));
        i++;
        continue;
      }
      if (trimmed.startsWith('## ')) {
        blocks.add(_MessageBlock(
            type: _BlockType.heading2,
            text: trimmed.substring(3)));
        i++;
        continue;
      }
      if (trimmed.startsWith('# ')) {
        blocks.add(_MessageBlock(
            type: _BlockType.heading1,
            text: trimmed.substring(2)));
        i++;
        continue;
      }

      // 5. Callout Box (> or **Note:**)
      if (trimmed.startsWith('> ') ||
          trimmed.toLowerCase().startsWith('**note:**') ||
          trimmed.toLowerCase().startsWith('**important:**')) {
        final calloutText = trimmed.startsWith('> ')
            ? trimmed.substring(2)
            : trimmed;
        blocks.add(
            _MessageBlock(type: _BlockType.callout, text: calloutText));
        i++;
        continue;
      }

      // 6. Bullet List (- or *)
      if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
        blocks.add(_MessageBlock(
            type: _BlockType.bulletItem, text: trimmed.substring(2)));
        i++;
        continue;
      }

      // 7. Numbered List (1. 2. etc)
      final numMatch = RegExp(r'^(\d+)\.\s+(.*)$').firstMatch(trimmed);
      if (numMatch != null) {
        blocks.add(_MessageBlock(
          type: _BlockType.numberedItem,
          text: numMatch.group(2) ?? '',
          extra: '${numMatch.group(1)}.',
        ));
        i++;
        continue;
      }

      // 8. Regular paragraph
      if (trimmed.isNotEmpty) {
        blocks.add(
            _MessageBlock(type: _BlockType.paragraph, text: line));
      }
      i++;
    }

    return blocks;
  }
}

enum _BlockType {
  paragraph,
  heading1,
  heading2,
  heading3,
  codeBlock,
  latexBlock,
  table,
  callout,
  bulletItem,
  numberedItem,
}

class _MessageBlock {
  _MessageBlock({
    required this.type,
    required this.text,
    this.extra,
    this.lines = const [],
  });

  final _BlockType type;
  final String text;
  final String? extra;
  final List<String> lines;
}

// ─────────────────────────────────────────────────────────────────────────────
// Phase 2 — Neon Code Card
// ─────────────────────────────────────────────────────────────────────────────

class _NeonCodeCard extends StatefulWidget {
  const _NeonCodeCard({
    required this.code,
    required this.language,
    required this.isDark,
  });

  final String code;
  final String language;
  final bool isDark;

  @override
  State<_NeonCodeCard> createState() => _NeonCodeCardState();
}

class _NeonCodeCardState extends State<_NeonCodeCard> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        // Deep code canvas
        color: const Color(0xFF0A0F1E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppVelvetTokens.neonCrimson.withValues(alpha: 0.22),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: AppVelvetTokens.neonCrimson.withValues(alpha: 0.08),
            blurRadius: 16,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header bar
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(13)),
              border: Border(
                bottom: BorderSide(
                  color:
                      AppVelvetTokens.neonCrimson.withValues(alpha: 0.15),
                  width: 0.6,
                ),
              ),
            ),
            child: Row(
              children: [
                // Language pill
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppVelvetTokens.neonCrimson
                        .withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppVelvetTokens.neonCrimson
                          .withValues(alpha: 0.28),
                      width: 0.6,
                    ),
                  ),
                  child: Text(
                    widget.language,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppVelvetTokens.neonCrimson,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const Spacer(),
                // Copy button
                GestureDetector(
                  onTap: _copy,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _copied
                        ? const Row(
                            key: ValueKey('done'),
                            children: [
                              Icon(Icons.check_rounded,
                                  size: 13,
                                  color: Color(0xFF10B981)),
                              SizedBox(width: 4),
                              Text('Copied!',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF10B981),
                                    fontWeight: FontWeight.w600,
                                  )),
                            ],
                          )
                        : const Row(
                            key: ValueKey('copy'),
                            children: [
                              Icon(Icons.copy_rounded,
                                  size: 13,
                                  color: Color(0xFFCBD5E1)),
                              SizedBox(width: 4),
                              Text('Copy',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFFCBD5E1),
                                  )),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
          // Code content
          Padding(
            padding: const EdgeInsets.all(14),
            child: SelectableText(
              widget.code,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: Color(0xFFE2E8F0),
                height: 1.55,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LaTeX Card — renders formula in a styled math block
// ─────────────────────────────────────────────────────────────────────────────

class _LaTeXCard extends StatelessWidget {
  const _LaTeXCard({
    required this.formula,
    required this.isDark,
    this.isBlock = false,
  });

  final String formula;
  final bool isDark;
  final bool isBlock;

  @override
  Widget build(BuildContext context) {
    // NOTE: For proper LaTeX rendering, integrate `flutter_math_fork` package.
    // As it may not be installed, this renders a styled monospace fallback.
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0C1528)
            : const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF38BDF8).withValues(alpha: 0.28),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color:
                const Color(0xFF38BDF8).withValues(alpha: 0.06),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.functions_rounded,
                  size: 14, color: Color(0xFF38BDF8)),
              SizedBox(width: 6),
              Text(
                'FORMULA',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF38BDF8),
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            formula,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? const Color(0xFFE2E8F0)
                  : const Color(0xFF1E293B),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Callout Card
// ─────────────────────────────────────────────────────────────────────────────

class _CalloutCard extends StatelessWidget {
  const _CalloutCard({required this.text, required this.isDark});

  final String text;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: isDark
            ? AppVelvetTokens.neonCrimson.withValues(alpha: 0.07)
            : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10),
        border: const Border(
          left: BorderSide(color: AppColors.crimsonRed, width: 3.0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 15, color: AppColors.crimsonRed),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? const Color(0xFFF1F5F9)
                    : const Color(0xFF1F2937),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Markdown Table
// ─────────────────────────────────────────────────────────────────────────────

class _MarkdownTable extends StatelessWidget {
  const _MarkdownTable({required this.rows, required this.isDark});

  final List<String> rows;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final parsedRows = <List<String>>[];
    for (final r in rows) {
      if (r.contains('---')) continue;
      final cells = r
          .split('|')
          .map((c) => c.trim())
          .where((c) => c.isNotEmpty)
          .toList();
      if (cells.isNotEmpty) parsedRows.add(cells);
    }

    if (parsedRows.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Table(
            defaultColumnWidth: const IntrinsicColumnWidth(),
            children: List.generate(parsedRows.length, (rowIdx) {
              final isHeader = rowIdx == 0;
              final cells = parsedRows[rowIdx];
              return TableRow(
                decoration: BoxDecoration(
                  color: isHeader
                      ? (isDark
                          ? AppVelvetTokens.glassPanel
                          : const Color(0xFFF1F5F9))
                      : (rowIdx.isEven
                          ? (isDark
                              ? const Color(0xFF0E1520)
                              : Colors.white)
                          : (isDark
                              ? const Color(0xFF111827)
                              : const Color(0xFFF8FAFC))),
                ),
                children: cells.map((cell) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    child: Text(
                      cell,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: isHeader
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isDark
                            ? const Color(0xFFF1F5F9)
                            : const Color(0xFF1E293B),
                      ),
                    ),
                  );
                }).toList(),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Rich Span Text — inline bold + code + italic + LaTeX inline ($...$)
// ─────────────────────────────────────────────────────────────────────────────

class _RichSpanText extends StatelessWidget {
  const _RichSpanText({
    required this.raw,
    required this.isDark,
    required this.isUrdu,
  });

  final String raw;
  final bool isDark;
  final bool isUrdu;

  @override
  Widget build(BuildContext context) {
    if (isUrdu) {
      return SelectableText(
        raw,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        style: AppTextStyles.urduBody(
                isDark ? Colors.white : const Color(0xFF0F172A))
            .copyWith(
          fontSize: 16.5,
          height: BidiTextHelper.nastaliqLineHeight,
        ),
      );
    }

    final spans = <TextSpan>[];
    // Matches **bold**, `code`, *italic*, $latex$
    final regExp = RegExp(r'(\*\*.*?\*\*|`.*?`|\*.*?\*|\$[^$]+\$)');
    int lastMatchEnd = 0;

    for (final match in regExp.allMatches(raw)) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: raw.substring(lastMatchEnd, match.start),
          style: _bodyStyle,
        ));
      }
      final matchedText = match.group(0)!;
      if (matchedText.startsWith('**') && matchedText.endsWith('**')) {
        spans.add(TextSpan(
          text: matchedText.substring(2, matchedText.length - 2),
          style: _bodyStyle.copyWith(fontWeight: FontWeight.w800),
        ));
      } else if (matchedText.startsWith('`') &&
          matchedText.endsWith('`')) {
        spans.add(TextSpan(
          text: matchedText.substring(1, matchedText.length - 1),
          style: TextStyle(
            fontFamily: 'monospace',
            backgroundColor: isDark
                ? const Color(0xFF1E293B)
                : const Color(0xFFE2E8F0),
            color: isDark
                ? AppVelvetTokens.neonCrimson
                    .withValues(alpha: 0.9)
                : const Color(0xFF0F172A),
            fontSize: 13.5,
          ),
        ));
      } else if (matchedText.startsWith('*') &&
          matchedText.endsWith('*') &&
          !matchedText.startsWith('**')) {
        spans.add(TextSpan(
          text: matchedText.substring(1, matchedText.length - 1),
          style: _bodyStyle.copyWith(fontStyle: FontStyle.italic),
        ));
      } else if (matchedText.startsWith(r'$') &&
          matchedText.endsWith(r'$')) {
        // Inline LaTeX — render monospace sky-blue
        spans.add(TextSpan(
          text: matchedText.substring(1, matchedText.length - 1),
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 13.5,
            color: Color(0xFF38BDF8),
            fontWeight: FontWeight.w600,
          ),
        ));
      }
      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < raw.length) {
      spans.add(TextSpan(text: raw.substring(lastMatchEnd), style: _bodyStyle));
    }

    return SelectableText.rich(TextSpan(children: spans));
  }

  TextStyle get _bodyStyle => TextStyle(
        color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
        fontSize: 14.5,
        height: 1.58,
      );
}
