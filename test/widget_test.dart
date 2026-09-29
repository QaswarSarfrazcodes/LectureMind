// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lecturemind/core/config/app_providers.dart';
import 'package:lecturemind/core/storage/local_storage_service.dart';
import 'package:lecturemind/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('LectureMind app launches and renders root screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    const secureStorage = FlutterSecureStorage();
    final storageService = LocalStorageService(prefs, secureStorage);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageServiceProvider.overrideWithValue(storageService),
        ],
        child: const LectureMindApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify that the title or initial greetings render on home screen (or age prompt dialog)
    expect(find.textContaining('Student Profile & Age'), findsOneWidget);
  });
}


