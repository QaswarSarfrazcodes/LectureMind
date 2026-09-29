import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../core/router/app_router.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_neumorphic.dart';

/// Persistent bottom navigation shell.
/// Core flows: Home (Studio Hub), Record (Voice STT),
/// PDF Read (Document Studio), Notes (Mind Map & Quiz), Settings.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  static const _destinations = [
    AppRoutes.home,
    AppRoutes.record,
    AppRoutes.documentStudio,
    AppRoutes.notesQuiz,
    AppRoutes.profile,
  ];

  static const _labels = ['Home', 'Record', 'PDF Read', 'Notes', 'Settings'];

  static const _icons = [
    'assets/app-logoandicon.svg',
    'assets/icon-mic-transcribe.svg',
    null, // PDF Read uses Material icon
    'assets/icon-summary-notes.svg',
    null, // Settings uses Material icon
  ];

  int _indexForLocation(String location) {
    final index = _destinations.indexWhere((p) => location.startsWith(p));
    return index == -1 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _indexForLocation(location);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: NeuDecorations.raised(
          isDark: isDark,
          radius: 30,
          withRim: true,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_destinations.length, (i) {
            final isSelected = currentIndex == i;
            final asset = _icons[i];
            final isLogo = i == 0;
            final isPdf = i == 2;
            final isSettings = i == 4;

            IconData? iconData;
            if (isPdf) {
              iconData = Icons.picture_as_pdf_rounded;
            } else if (isSettings) {
              iconData = isSelected ? Icons.tune_rounded : Icons.tune_outlined;
            }

            return GestureDetector(
              onTap: () => context.go(_destinations[i]),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: isSelected
                    ? BoxDecoration(
                        color: AppColors.crimsonRed,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: const [
                          BoxShadow(
                            color: NeuColors.crimsonGlow,
                            blurRadius: 10,
                            offset: Offset(0, 3),
                          ),
                        ],
                      )
                    : null,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _NavIcon(
                      assetPath: asset,
                      iconData: iconData,
                      selected: isSelected,
                      isLogo: isLogo,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? NeuColors.mutedBlue : const Color(0xFF6B7280)),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 6),
                      Text(
                        _labels[i],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({
    this.assetPath,
    this.iconData,
    required this.selected,
    required this.isLogo,
    required this.color,
  });

  final String? assetPath;
  final IconData? iconData;
  final bool selected;
  final bool isLogo;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (isLogo && assetPath != null) {
      return SvgPicture.asset(assetPath!, width: 22, height: 22);
    }
    if (assetPath != null) {
      return SvgPicture.asset(
        assetPath!,
        width: 22,
        height: 22,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      );
    }
    return Icon(iconData ?? Icons.circle, size: 22, color: color);
  }
}
