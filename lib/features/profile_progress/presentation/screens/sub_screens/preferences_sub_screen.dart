import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/config/app_providers.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_dimens.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../shared_models/language.dart';

class PreferencesSubScreen extends ConsumerWidget {
  const PreferencesSubScreen({super.key});

  void _showProfileEditDialog(BuildContext context, WidgetRef ref) {
    final settings = ref.read(userSettingsProvider);
    final nameCtrl = TextEditingController(text: settings.userName);
    final ageCtrl = TextEditingController(text: settings.userAge.toString());
    String? errorMsg;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final s = Theme.of(context).colorScheme;
          return AlertDialog(
            backgroundColor: s.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Edit Student Profile',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Customize your name and age for personalized AI academic coaching.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ageCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Age / Grade Level',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                if (errorMsg != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    errorMsg!,
                    style: const TextStyle(
                        color: AppColors.crimsonRed,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.crimsonRed,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  final name = nameCtrl.text.trim();
                  final age = int.tryParse(ageCtrl.text.trim()) ?? 20;
                  if (name.isEmpty) {
                    setModalState(() => errorMsg = 'Please enter a name.');
                    return;
                  }
                  ref.read(userSettingsProvider.notifier).updateProfile(
                        userName: name,
                        userAge: age,
                      );
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile updated successfully!')),
                  );
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final settings = ref.watch(userSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Preferences & Appearance'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimens.space16),
        children: [
          // Student Profile Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              border: Border.all(color: scheme.outline),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.crimsonRed,
                  child: Text(
                    settings.userName.isNotEmpty
                        ? settings.userName[0].toUpperCase()
                        : 'S',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(settings.userName,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.jetBlack)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFFBBF7D0)),
                            ),
                            child: Text(
                              'Age ${settings.userAge} • Academic Scholar',
                              style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF15803D)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                  ),
                  onPressed: () => _showProfileEditDialog(context, ref),
                  child: const Text('Edit', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Theme Settings
          Text('Appearance & Theme', style: AppTextStyles.title(scheme.onSurface)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              border: Border.all(color: scheme.outline),
            ),
            child: SwitchListTile(
              secondary: Icon(
                settings.isDarkMode
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded,
                color: AppColors.crimsonRed,
              ),
              title: const Text('Dark Mode',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: const Text('Pure White and Crimson Red or Obsidian Dark',
                  style: TextStyle(fontSize: 12)),
              value: settings.isDarkMode,
              activeThumbColor: AppColors.crimsonRed,
              onChanged: (val) =>
                  ref.read(userSettingsProvider.notifier).setDarkMode(val),
            ),
          ),
          const SizedBox(height: 24),

          // Preferred Language
          Text('Preferred AI Study Language',
              style: AppTextStyles.title(scheme.onSurface)),
          const SizedBox(height: 4),
          Text(
            'The AI adapts notes, quizzes, and chat replies into this primary format.',
            style: AppTextStyles.caption(scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),

          _LanguageOptionTile(
            title: 'Urdu (اردو رسم الخط)',
            subtitle: 'Native Nastaliq script with natural rawani & authentic grammar.',
            isSelected: settings.preferredLanguage == Language.urdu,
            onTap: () =>
                ref.read(userSettingsProvider.notifier).setLanguage(Language.urdu),
          ),
          const SizedBox(height: 8),
          _LanguageOptionTile(
            title: 'English',
            subtitle: 'Clear, international academic English for university revision.',
            isSelected: settings.preferredLanguage == Language.english,
            onTap: () => ref
                .read(userSettingsProvider.notifier)
                .setLanguage(Language.english),
          ),
          const SizedBox(height: 8),
          _LanguageOptionTile(
            title: 'Roman Urdu (Pakistani Student Dialect)',
            subtitle: 'Urdu written in Latin letters for conversational ease.',
            isSelected: settings.preferredLanguage == Language.romanUrdu,
            onTap: () => ref
                .read(userSettingsProvider.notifier)
                .setLanguage(Language.romanUrdu),
          ),
        ],
      ),
    );
  }
}

class _LanguageOptionTile extends StatelessWidget {
  const _LanguageOptionTile({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.crimsonRed : const Color(0xFFE5E7EB),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 13.5,
                          fontWeight:
                              isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: AppColors.jetBlack)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.grey.shade600,
                          height: 1.3)),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.crimsonRed, size: 20),
          ],
        ),
      ),
    );
  }
}
