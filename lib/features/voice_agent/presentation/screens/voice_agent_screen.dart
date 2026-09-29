import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_providers.dart';
import '../../../../core/services/voice_agent_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared_models/language.dart';

// ──────────────────────────────────────────────────────────────────────────────
// VoiceAgentScreen — LectureMind Conversational Voice UI
//
// Design principles (MD3 + minimal):
//  • Single focal point: the animated orb in the center.
//  • Status colour transitions communicate state without text overload.
//  • Flat dark background with subtle radial glow — no competing gradients.
//  • Controls are reduced to exactly 3 actions: mute/interrupt, toggle, done.
//  • History and language in a compact top bar — hidden until needed.
// ──────────────────────────────────────────────────────────────────────────────

class VoiceAgentScreen extends ConsumerStatefulWidget {
  const VoiceAgentScreen({super.key, this.lectureContext});

  final String? lectureContext;

  @override
  ConsumerState<VoiceAgentScreen> createState() => _VoiceAgentScreenState();
}

class _VoiceAgentScreenState extends ConsumerState<VoiceAgentScreen>
    with TickerProviderStateMixin {
  // Animation controllers
  late final AnimationController _pulseCtrl;
  late final AnimationController _rotateCtrl;
  late final AnimationController _glowCtrl;

  // Service
  late final VoiceAgentService _voice;

  // State
  VoiceAgentStatus _status = VoiceAgentStatus.idle;
  String _userText = '';
  String _aiText = '';
  String? _error;
  Language _lang = Language.english;
  bool _showHistory = false;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _rotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 7000),
    )..repeat();

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _voice = ref.read(voiceAgentServiceProvider);
    if (widget.lectureContext != null && widget.lectureContext!.isNotEmpty) {
      _voice.setLectureContext(widget.lectureContext);
    }

    _voice.onStatusChanged = (s) {
      if (!mounted) return;
      setState(() {
        _status = s;
        // Speed up pulse for active states
        _pulseCtrl.duration = switch (s) {
          VoiceAgentStatus.thinking => const Duration(milliseconds: 600),
          VoiceAgentStatus.speaking => const Duration(milliseconds: 900),
          _ => const Duration(milliseconds: 1800),
        };
      });
    };
    _voice.onUserTranscript = (t) {
      if (mounted) setState(() => _userText = t);
    };
    _voice.onAiSpeaking = (t) {
      if (mounted) setState(() => _aiText = t);
    };
    _voice.onError = (e) {
      if (mounted) setState(() => _error = e);
    };

    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    setState(() => _error = null);
    final selectedId = ref.read(selectedLectureIdProvider);
    final lectures = ref.read(lecturesProvider);
    final currentLecture = lectures.where((l) => l.id == selectedId).firstOrNull ??
        (lectures.isNotEmpty ? lectures.first : null);
    if (currentLecture != null) {
      _voice.setLectureContext(
        'Title: ${currentLecture.title}\nSummary: ${currentLecture.summary}\nKey Sections: ${currentLecture.sections.map((s) => s.title).join(", ")}',
      );
    }
    await _voice.startSession(language: _lang);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _rotateCtrl.dispose();
    _glowCtrl.dispose();
    _voice.stopSession();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Color get _stateColor => switch (_status) {
        VoiceAgentStatus.idle     => AppVelvetTokens.bioIdle,
        VoiceAgentStatus.listening => AppVelvetTokens.bioListening,
        VoiceAgentStatus.thinking => AppVelvetTokens.bioThinking,
        VoiceAgentStatus.speaking => AppVelvetTokens.bioSpeaking,
        VoiceAgentStatus.error    => AppVelvetTokens.bioError,
      };

  IconData get _orbIcon => switch (_status) {
        VoiceAgentStatus.idle => Icons.graphic_eq_rounded,
        VoiceAgentStatus.listening => Icons.mic_rounded,
        VoiceAgentStatus.thinking => Icons.auto_awesome_rounded,
        VoiceAgentStatus.speaking => Icons.volume_up_rounded,
        VoiceAgentStatus.error => Icons.error_outline_rounded,
      };

  String get _statusLabel => switch (_status) {
        VoiceAgentStatus.idle => 'Tap orb to start',
        VoiceAgentStatus.listening => 'Listening…',
        VoiceAgentStatus.thinking => 'Thinking…',
        VoiceAgentStatus.speaking => 'Speaking — tap to interrupt',
        VoiceAgentStatus.error => _error ?? 'Connection error',
      };

  void _showTextQueryDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.keyboard_alt_rounded, color: Color(0xFF818CF8), size: 20),
            SizedBox(width: 8),
            Text(
              'Speak / Type to AI',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: TextField(
          controller: textController,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: _lang == Language.urdu ? 'یہاں سوال لکھیں...' : 'e.g. Hello AI, how are you?',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF0F172A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF334155)),
            ),
          ),
          onSubmitted: (val) {
            Navigator.of(ctx).pop();
            if (val.trim().isNotEmpty) {
              _voice.triggerUserSpokenQuery(val.trim(), language: _lang);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.send_rounded, size: 16),
            label: const Text('Send'),
            onPressed: () {
              Navigator.of(ctx).pop();
              final val = textController.text.trim();
              if (val.isNotEmpty) {
                _voice.triggerUserSpokenQuery(val, language: _lang);
              }
            },
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final selectedId = ref.watch(selectedLectureIdProvider);
    final lectures = ref.watch(lecturesProvider);
    final currentLecture = lectures.where((l) => l.id == selectedId).firstOrNull ??
        (lectures.isNotEmpty ? lectures.first : null);
    final activeLectureTitle = currentLecture?.title;

    return Scaffold(
      backgroundColor: const Color(0xFF0C0E13),
      body: SafeArea(
        child: Stack(
          children: [
            // Background ambient glow
            _AmbientGlow(color: _stateColor, controller: _glowCtrl),

            // Main layout
            Column(
              children: [
                _TopBar(
                  lang: _lang,
                  historyCount: _voice.history.length,
                  onLangChange: (l) {
                    setState(() => _lang = l);
                    _start();
                  },
                  onHistoryTap: () =>
                      setState(() => _showHistory = !_showHistory),
                  onClose: () {
                    _voice.stopSession();
                    Navigator.of(context).pop();
                  },
                ),

                // Pipeline badge with active lecture viva indicator
                _PipelineBadge(
                  color: _stateColor,
                  activeLectureTitle: activeLectureTitle,
                ),
                const SizedBox(height: 6),

                // Center area scrollable to guarantee zero RenderFlex overflow on small screens
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.lectureContext != null &&
                              widget.lectureContext!.isNotEmpty) ...[
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.4),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.auto_awesome_rounded,
                                      color: Color(0xFF10B981), size: 14),
                                  SizedBox(width: 6),
                                  Text(
                                    'Lecture Grounded (Oral Exam Mode)',
                                    style: TextStyle(
                                      color: Color(0xFF10B981),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          _VoiceOrb(
                            status: _status,
                            stateColor: _stateColor,
                            orbIcon: _orbIcon,
                            pulseCtrl: _pulseCtrl,
                            rotateCtrl: _rotateCtrl,
                            onTap: () => switch (_status) {
                              VoiceAgentStatus.speaking => _voice.interrupt(),
                              VoiceAgentStatus.idle ||
                              VoiceAgentStatus.error =>
                                _start(),
                              VoiceAgentStatus.listening => _voice.stopSession(),
                              _ => null,
                            },
                          ),

                          const SizedBox(height: 18),

                          // Status label
                          _StatusLabel(label: _statusLabel, color: _stateColor),
                          if (_status == VoiceAgentStatus.error) ...[
                            const SizedBox(height: 8),
                            _RetryButton(onTap: _start),
                          ],

                          const SizedBox(height: 14),

                          // Live subtitles
                          _SubtitlesCard(
                            userText: _userText,
                            aiText: _aiText,
                            stateColor: _stateColor,
                          ),

                          const SizedBox(height: 12),

                          // Quick prompt chips
                          _PromptChips(
                            lang: _lang,
                            onChip: (p) =>
                                _voice.triggerUserSpokenQuery(p, language: _lang),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Controls dock
                _ControlsDock(
                  status: _status,
                  stateColor: _stateColor,
                  onTextQuery: _showTextQueryDialog,
                  onMic: () => switch (_status) {
                    VoiceAgentStatus.speaking => _voice.interrupt(),
                    VoiceAgentStatus.listening => _voice.stopSession(),
                    _ => _start(),
                  },
                  onToggle: () => switch (_status) {
                    VoiceAgentStatus.idle => _start(),
                    _ => _voice.stopSession(),
                  },
                  onDone: () {
                    _voice.stopSession();
                    Navigator.of(context).pop();
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),

            // History overlay
            if (_showHistory)
              _HistorySheet(
                turns: _voice.history,
                onClose: () => setState(() => _showHistory = false),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

// Phase 2 — Bioluminescent Ambient Glow
class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow({
    required this.color,
    required this.controller,
  });
  final Color color;
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
      child: AnimatedBuilder(
        animation: controller,
        builder: (_, __) => CustomPaint(
          painter: _GlowPainter(
            color: color,
            progress: controller.value,
          ),
        ),
      ),
    );
  }
}

class _GlowPainter extends CustomPainter {
  _GlowPainter({required this.color, required this.progress});
  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    // Two layered radial glows centered at top-half
    final center = Offset(size.width / 2, size.height * 0.42);
    final maxRadius = size.width * 0.75;

    // Outer diffused halo
    canvas.drawCircle(
      center,
      maxRadius * (0.85 + progress * 0.15),
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: 0.07 + progress * 0.04),
            color.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: maxRadius)),
    );

    // Inner concentrated glow
    canvas.drawCircle(
      center,
      maxRadius * 0.35 * (0.9 + progress * 0.1),
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: 0.18 + progress * 0.10),
            color.withValues(alpha: 0.0),
          ],
        ).createShader(
            Rect.fromCircle(center: center, radius: maxRadius * 0.35)),
    );
  }

  @override
  bool shouldRepaint(_GlowPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.lang,
    required this.historyCount,
    required this.onLangChange,
    required this.onHistoryTap,
    required this.onClose,
  });
  final Language lang;
  final int historyCount;
  final ValueChanged<Language> onLangChange;
  final VoidCallback onHistoryTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded,
                color: Colors.white60, size: 24),
            tooltip: 'Close',
          ),
          const Spacer(),
          // Language toggle pill
          _LangPill(current: lang, onChanged: onLangChange),
          const Spacer(),
          IconButton(
            onPressed: onHistoryTap,
            tooltip: 'Spoken history',
            icon: Badge(
              isLabelVisible: historyCount > 0,
              label: Text('$historyCount',
                  style: const TextStyle(fontSize: 9)),
              child: const Icon(Icons.history_rounded,
                  color: Colors.white60, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}

class _LangPill extends StatelessWidget {
  const _LangPill({required this.current, required this.onChanged});
  final Language current;
  final ValueChanged<Language> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LangLabel(
            text: 'EN',
            selected: current == Language.english,
            onTap: () => onChanged(Language.english),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Container(
              width: 1,
              height: 14,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          _LangLabel(
            text: 'اردو',
            selected: current == Language.urdu,
            onTap: () => onChanged(Language.urdu),
            isUrdu: true,
          ),
        ],
      ),
    );
  }
}

class _LangLabel extends StatelessWidget {
  const _LangLabel({
    required this.text,
    required this.selected,
    required this.onTap,
    this.isUrdu = false,
  });
  final String text;
  final bool selected;
  final VoidCallback onTap;
  final bool isUrdu;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        text,
        style: TextStyle(
          fontSize: isUrdu ? 13 : 12,
          fontFamily: isUrdu ? 'Jameel' : null,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
          color: selected ? Colors.white : Colors.white38,
        ),
      ),
    );
  }
}

class _PipelineBadge extends StatelessWidget {
  const _PipelineBadge({required this.color, this.activeLectureTitle});
  final Color color;
  final String? activeLectureTitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: color.withValues(alpha: 0.7),
                      blurRadius: 5,
                      spreadRadius: 1)
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              'AssemblyAI Universal-3 Pro · Groq & Gemini',
              style: TextStyle(
                fontSize: 10.5,
                color: Colors.white38,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        if (activeLectureTitle != null && activeLectureTitle!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF818CF8).withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.school_rounded, size: 12, color: Color(0xFF818CF8)),
                const SizedBox(width: 5),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 240),
                  child: Text(
                    'Viva / Exam: $activeLectureTitle',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFC7D2FE),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// Phase 2 — Bioluminescent Voice Orb
// 5 breathing rings + rotating sweep + particle sparkles + frosted core
class _VoiceOrb extends StatelessWidget {
  const _VoiceOrb({
    required this.status,
    required this.stateColor,
    required this.orbIcon,
    required this.pulseCtrl,
    required this.rotateCtrl,
    required this.onTap,
  });
  final VoiceAgentStatus status;
  final Color stateColor;
  final IconData orbIcon;
  final AnimationController pulseCtrl;
  final AnimationController rotateCtrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([pulseCtrl, rotateCtrl]),
        builder: (_, __) {
          final pulse = pulseCtrl.value;          // 0.0 → 1.0
          final angle = rotateCtrl.value * 2 * math.pi;

          return SizedBox(
            width: 220,
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // ── Ring 5 (outermost) — ultra-faint breathing ring ────────
                Transform.scale(
                  scale: 1.0 + pulse * 0.18,
                  child: Container(
                    width: 210,
                    height: 210,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: stateColor.withValues(alpha: 0.06 + pulse * 0.05),
                        width: 1.0,
                      ),
                    ),
                  ),
                ),
                // ── Ring 4 — diffused halo ────────────────────────────────
                Transform.scale(
                  scale: 1.0 + pulse * 0.12,
                  child: Container(
                    width: 186,
                    height: 186,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: stateColor.withValues(alpha: 0.12 + pulse * 0.08),
                        width: 1.0,
                      ),
                    ),
                  ),
                ),
                // ── Ring 3 — mid pulse ────────────────────────────────────
                Transform.scale(
                  scale: 1.0 + pulse * 0.09,
                  child: Container(
                    width: 162,
                    height: 162,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: stateColor.withValues(alpha: 0.22 + pulse * 0.12),
                        width: 1.2,
                      ),
                    ),
                  ),
                ),
                // ── Ring 2 — inner glow ring ──────────────────────────────
                Transform.scale(
                  scale: 1.0 + pulse * 0.06,
                  child: Container(
                    width: 138,
                    height: 138,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: stateColor.withValues(alpha: 0.38 + pulse * 0.18),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: stateColor.withValues(alpha: 0.15 + pulse * 0.15),
                          blurRadius: 16 + pulse * 12,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                  ),
                ),
                // ── Rotating sweep gradient orb body ──────────────────────
                Transform.rotate(
                  angle: angle,
                  child: Container(
                    width: 118,
                    height: 118,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: [
                          stateColor,
                          stateColor.withValues(alpha: 0.3),
                          const Color(0xFF0C1122),
                          stateColor.withValues(alpha: 0.6),
                          stateColor,
                        ],
                        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: stateColor.withValues(alpha: 0.55 + pulse * 0.15),
                          blurRadius: 28 + pulse * 14,
                          spreadRadius: 2 + pulse * 2,
                        ),
                        BoxShadow(
                          color: stateColor.withValues(alpha: 0.20),
                          blurRadius: 50,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                  ),
                ),
                // ── Particle sparkles (4 dots orbiting orb) ───────────────
                ..._buildSparkles(angle, stateColor, pulse),
                // ── Frosted glass core (BackdropFilter) ───────────────────
                ClipOval(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF090E1A).withValues(alpha: 0.82),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.16),
                          width: 1.2,
                        ),
                      ),
                      child: Icon(
                        orbIcon,
                        color: Colors.white,
                        size: 34,
                        shadows: [
                          Shadow(
                            color: stateColor.withValues(alpha: 0.8),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static const List<_OrbParticle> _particles = [
    _OrbParticle(angle: 0,       orbitRadius: 76, size: 4.5),
    _OrbParticle(angle: math.pi / 2,   orbitRadius: 72, size: 3.5),
    _OrbParticle(angle: math.pi,       orbitRadius: 78, size: 5.0),
    _OrbParticle(angle: math.pi * 1.5, orbitRadius: 70, size: 3.0),
  ];

  List<Widget> _buildSparkles(
      double angle, Color color, double pulse) {
    return _particles.map((p) {
      final a = angle + p.angle;
      final x = math.cos(a) * p.orbitRadius;
      final y = math.sin(a) * p.orbitRadius;
      return Positioned(
        left: 110 + x - p.size / 2,  // 110 = half of 220
        top:  110 + y - p.size / 2,
        child: Container(
          width:  p.size + pulse * 1.5,
          height: p.size + pulse * 1.5,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5 + pulse * 0.4),
                blurRadius: 6 + pulse * 4,
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}

// Simple data class for orb particle definition
class _OrbParticle {
  const _OrbParticle({
    required this.angle,
    required this.orbitRadius,
    required this.size,
  });
  final double angle;
  final double orbitRadius;
  final double size;
}


class _StatusLabel extends StatelessWidget {
  const _StatusLabel({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 0.15,
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _RetryButton extends StatelessWidget {
  const _RetryButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.refresh_rounded, size: 15, color: Colors.white),
      label: const Text('Retry',
          style: TextStyle(color: Colors.white, fontSize: 12)),
      style: TextButton.styleFrom(
        backgroundColor: Colors.white10,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

class _SubtitlesCard extends StatelessWidget {
  const _SubtitlesCard({
    required this.userText,
    required this.aiText,
    required this.stateColor,
  });
  final String userText;
  final String aiText;
  final Color stateColor;

  @override
  Widget build(BuildContext context) {
    final hasContent = userText.isNotEmpty || aiText.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      constraints: const BoxConstraints(maxHeight: 160),
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: hasContent ? 14 : 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: hasContent ? 0.06 : 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasContent
              ? stateColor.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: hasContent
          ? SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (userText.isNotEmpty)
                    _TranscriptRow(
                      prefix: 'You',
                      text: userText,
                      prefixColor: const Color(0xFF10B981),
                    ),
                  if (userText.isNotEmpty && aiText.isNotEmpty)
                    const SizedBox(height: 8),
                  if (aiText.isNotEmpty)
                    _TranscriptRow(
                      prefix: 'AI',
                      text: aiText,
                      prefixColor: const Color(0xFF38BDF8),
                    ),
                ],
              ),
            )
          : const Center(
              child: Text(
                '"Ask about your lecture, request an Urdu explanation, or say: Quiz me."',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.white30,
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),
            ),
    );
  }
}

class _TranscriptRow extends StatelessWidget {
  const _TranscriptRow({
    required this.prefix,
    required this.text,
    required this.prefixColor,
  });
  final String prefix;
  final String text;
  final Color prefixColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$prefix: ',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: prefixColor,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white,
              height: 1.38,
            ),
          ),
        ),
      ],
    );
  }
}

class _PromptChips extends StatelessWidget {
  const _PromptChips({required this.lang, required this.onChip});
  final Language lang;
  final ValueChanged<String> onChip;

  static const _enPrompts = [
    'Hello AI, how are you?',
    'Summarise the key concept',
    'Explain in simple terms',
    'Give exam tips',
    'Quiz me now',
  ];

  static const _urPrompts = [
    'ہیلو، آپ کیسے ہیں؟',
    'آج کے سبق کا خلاصہ',
    'آسان الفاظ میں سمجھائیں',
    'امتحان کے اہم نکات',
    'سوال پوچھیں',
  ];

  @override
  Widget build(BuildContext context) {
    final prompts = lang == Language.urdu ? _urPrompts : _enPrompts;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: prompts
            .map((p) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onChip(p),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF334155),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.bolt_rounded,
                              size: 14,
                              color: Color(0xFFFBBF24),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              p,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFFF8FAFC),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _ControlsDock extends StatelessWidget {
  const _ControlsDock({
    required this.status,
    required this.stateColor,
    required this.onMic,
    required this.onToggle,
    required this.onDone,
    this.onTextQuery,
  });
  final VoiceAgentStatus status;
  final Color stateColor;
  final VoidCallback onMic;
  final VoidCallback onToggle;
  final VoidCallback onDone;
  final VoidCallback? onTextQuery;

  @override
  Widget build(BuildContext context) {
    final isListening = status == VoiceAgentStatus.listening;
    final isSpeaking = status == VoiceAgentStatus.speaking;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Keyboard / Text Query
          if (onTextQuery != null)
            _DockButton(
              icon: Icons.keyboard_alt_outlined,
              color: Colors.white70,
              onTap: onTextQuery!,
              tooltip: 'Type / Query AI',
            ),

          // Mic / interrupt
          _DockButton(
            icon: isSpeaking
                ? Icons.stop_circle_rounded
                : isListening
                    ? Icons.mic_rounded
                    : Icons.mic_off_rounded,
            color: isSpeaking ? AppColors.crimsonRed : Colors.white70,
            onTap: onMic,
            tooltip: isSpeaking ? 'Interrupt' : 'Toggle mic',
          ),

          // Central action button
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: status == VoiceAgentStatus.idle
                  ? const Color(0xFF6366F1)
                  : stateColor,
            ),
            child: _DockButton(
              icon: status == VoiceAgentStatus.idle
                  ? Icons.play_arrow_rounded
                  : Icons.pause_rounded,
              color: Colors.white,
              onTap: onToggle,
              tooltip: status == VoiceAgentStatus.idle
                  ? 'Start session'
                  : 'Pause session',
            ),
          ),

          // Done
          _DockButton(
            icon: Icons.check_rounded,
            color: Colors.white60,
            onTap: onDone,
            tooltip: 'Done',
          ),
        ],
      ),
    );
  }
}

class _DockButton extends StatelessWidget {
  const _DockButton({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.tooltip,
  });
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: color, size: 26),
      tooltip: tooltip,
      padding: const EdgeInsets.all(10),
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
    );
  }
}

class _HistorySheet extends StatelessWidget {
  const _HistorySheet({required this.turns, required this.onClose});
  final List<VoiceAgentTurn> turns;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.88),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
              child: Row(
                children: [
                  const Text(
                    'Session History',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close_rounded,
                        color: Colors.white60, size: 22),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white10, height: 1),
            Expanded(
              child: turns.isEmpty
                  ? const Center(
                      child: Text(
                        'No conversation turns yet.',
                        style: TextStyle(color: Colors.white38, fontSize: 13),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: turns.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final t = turns[i];
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'You: ${t.userSpeech}',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF10B981),
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'AI: ${t.aiSpeech}',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: Colors.white60,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
