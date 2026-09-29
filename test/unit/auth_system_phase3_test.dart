import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lecturemind/features/auth/domain/entities/app_user.dart';
import 'package:lecturemind/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:lecturemind/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:lecturemind/features/auth/presentation/controllers/auth_controller.dart';

void main() {
  group('Phase 3 — Authentication & Identity System Tests', () {
    late SharedPreferences prefs;
    late AuthLocalDataSource localDataSource;
    late AuthRepositoryImpl authRepository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      localDataSource = AuthLocalDataSource(prefs);
      authRepository = AuthRepositoryImpl(localDataSource);
    });

    tearDown(() {
      authRepository.dispose();
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 3.1 AppUser Entity Tests
    // ─────────────────────────────────────────────────────────────────────────
    group('AppUser Entity', () {
      test('serializes to and from JSON accurately', () {
        final now = DateTime.now();
        final user = AppUser(
          id: 'usr_test_101',
          email: 'fatima@nu.edu.pk',
          displayName: 'Fatima Ali',
          photoUrl: 'https://example.com/avatar.png',
          preferredLanguage: 'ur',
          createdAt: now,
          isAnonymous: false,
        );

        final json = user.toJson();
        expect(json['id'], 'usr_test_101');
        expect(json['email'], 'fatima@nu.edu.pk');
        expect(json['display_name'], 'Fatima Ali');
        expect(json['photo_url'], 'https://example.com/avatar.png');
        expect(json['preferred_language'], 'ur');
        expect(json['is_anonymous'], isFalse);

        final deserialized = AppUser.fromJson(json);
        expect(deserialized.id, user.id);
        expect(deserialized.email, user.email);
        expect(deserialized.displayName, user.displayName);
        expect(deserialized.photoUrl, user.photoUrl);
        expect(deserialized.preferredLanguage, user.preferredLanguage);
        expect(deserialized.isAnonymous, isFalse);
      });

      test('copyWith creates modified copy correctly', () {
        final user = AppUser(
          id: 'usr_guest_01',
          email: '',
          displayName: 'Guest Scholar',
          createdAt: DateTime.now(),
          isAnonymous: true,
        );

        final updated = user.copyWith(
          displayName: 'Registered Scholar',
          email: 'scholar@uni.edu',
          isAnonymous: false,
        );

        expect(updated.id, 'usr_guest_01');
        expect(updated.displayName, 'Registered Scholar');
        expect(updated.email, 'scholar@uni.edu');
        expect(updated.isAnonymous, isFalse);
      });
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 3.2 AuthLocalDataSource Tests
    // ─────────────────────────────────────────────────────────────────────────
    group('AuthLocalDataSource', () {
      test('saves user account and finds it by email', () async {
        final user = AppUser(
          id: 'usr_ds_1',
          email: 'zain@fast.edu.pk',
          displayName: 'Zain Ul Abideen',
          createdAt: DateTime.now(),
        );

        await localDataSource.saveUserAccount(
          user: user,
          passwordHash: 'hash_test_123',
        );

        final retrieved = localDataSource.findAccountByEmail('zain@fast.edu.pk');
        expect(retrieved, isNotNull);
        expect(retrieved!['password_hash'], 'hash_test_123');
        expect(retrieved['user']['display_name'], 'Zain Ul Abideen');

        // Case insensitivity
        final retrievedUpper = localDataSource.findAccountByEmail('ZAIN@FAST.EDU.PK');
        expect(retrievedUpper, isNotNull);
      });

      test('manages active session persistence', () async {
        expect(localDataSource.getCurrentUser(), isNull);

        final user = AppUser(
          id: 'usr_session_1',
          email: 'scholar@nust.edu.pk',
          displayName: 'NUST Scholar',
          createdAt: DateTime.now(),
        );

        await localDataSource.setCurrentUser(user);
        final active = localDataSource.getCurrentUser();
        expect(active, isNotNull);
        expect(active!.email, 'scholar@nust.edu.pk');

        await localDataSource.setCurrentUser(null);
        expect(localDataSource.getCurrentUser(), isNull);
      });
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 3.3 AuthRepositoryImpl Tests
    // ─────────────────────────────────────────────────────────────────────────
    group('AuthRepositoryImpl', () {
      test('signUpWithEmail registers new user, persists session, and broadcasts auth state', () async {
        final emittedUsers = <AppUser?>[];
        final sub = authRepository.authStateChanges.listen((u) => emittedUsers.add(u));

        final result = await authRepository.signUpWithEmail(
          email: 'ali.khan@lums.edu.pk',
          password: 'LumsPassword123',
          displayName: 'Ali Khan',
        );

        expect(result.isSuccess, isTrue);
        final user = result.data!;
        expect(user.email, 'ali.khan@lums.edu.pk');
        expect(user.displayName, 'Ali Khan');
        expect(user.isAnonymous, isFalse);
        expect(authRepository.currentUser?.id, user.id);

        // Duplicate signup rejection
        final dupResult = await authRepository.signUpWithEmail(
          email: 'ali.khan@lums.edu.pk',
          password: 'AnotherPassword',
        );
        expect(dupResult.isFailure, isTrue);
        expect(dupResult.failure?.message, contains('already exists'));

        await sub.cancel();
      });

      test('signInWithEmail validates credentials and handles failure gracefully', () async {
        // Register an account first
        final regResult = await authRepository.signUpWithEmail(
          email: 'ayesha@iba.edu.pk',
          password: 'IbaPassword456',
          displayName: 'Ayesha Tariq',
        );
        expect(regResult.isSuccess, isTrue);

        // Sign out to test sign in
        await authRepository.signOut();
        expect(authRepository.currentUser, isNull);

        // Invalid password
        final badPass = await authRepository.signInWithEmail(
          email: 'ayesha@iba.edu.pk',
          password: 'WrongPassword',
        );
        expect(badPass.isFailure, isTrue);
        expect(badPass.failure?.message, contains('Incorrect password'));

        // Unregistered email
        final unknownEmail = await authRepository.signInWithEmail(
          email: 'nobody@iba.edu.pk',
          password: 'SomePassword',
        );
        expect(unknownEmail.isFailure, isTrue);
        expect(unknownEmail.failure?.message, contains('No account found'));

        // Valid sign in
        final successLogin = await authRepository.signInWithEmail(
          email: 'ayesha@iba.edu.pk',
          password: 'IbaPassword456',
        );
        expect(successLogin.isSuccess, isTrue);
        expect(successLogin.data!.displayName, 'Ayesha Tariq');
        expect(authRepository.currentUser?.email, 'ayesha@iba.edu.pk');
      });

      test('signInWithGoogle signs in or registers Google Scholar session', () async {
        final result = await authRepository.signInWithGoogle();
        expect(result.isSuccess, isTrue);
        final googleUser = result.data!;
        expect(googleUser.email, 'scholar.google@lecturemind.ai');
        expect(googleUser.displayName, 'Google Scholar');
        expect(authRepository.currentUser?.id, googleUser.id);
      });

      test('signInAsGuest creates anonymous guest scholar session', () async {
        final result = await authRepository.signInAsGuest();
        expect(result.isSuccess, isTrue);
        final guest = result.data!;
        expect(guest.isAnonymous, isTrue);
        expect(guest.displayName, contains('Guest Scholar'));
        expect(authRepository.currentUser?.isAnonymous, isTrue);
      });

      test('sendPasswordResetEmail succeeds for registered user and fails for unknown user', () async {
        await authRepository.signUpWithEmail(
          email: 'hamza@giki.edu.pk',
          password: 'GikiPassword789',
        );

        // Valid reset request
        final okReset = await authRepository.sendPasswordResetEmail('hamza@giki.edu.pk');
        expect(okReset.isSuccess, isTrue);

        // Unregistered reset request
        final unknownReset = await authRepository.sendPasswordResetEmail('unknown@giki.edu.pk');
        expect(unknownReset.isFailure, isTrue);
        expect(unknownReset.failure?.message, contains('No registered account'));
      });

      test('signOut clears current session and emits null', () async {
        await authRepository.signInAsGuest();
        expect(authRepository.currentUser, isNotNull);

        await authRepository.signOut();
        expect(authRepository.currentUser, isNull);
      });
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 3.4 AuthController StateNotifier Tests
    // ─────────────────────────────────────────────────────────────────────────
    group('AuthController', () {
      test('manages loading, authentication, and error states correctly', () async {
        final controller = AuthController(authRepository);
        expect(controller.state.isAuthenticated, isFalse);

        // Successful Sign Up
        final signUpOk = await controller.signUpWithEmail(
          email: 'sara@pieas.edu.pk',
          password: 'PieasPassword101',
          displayName: 'Sara Ahmed',
        );
        expect(signUpOk, isTrue);
        expect(controller.state.isAuthenticated, isTrue);
        expect(controller.state.user?.displayName, 'Sara Ahmed');
        expect(controller.state.errorMessage, isNull);

        // Sign Out
        await controller.signOut();
        expect(controller.state.isAuthenticated, isFalse);
        expect(controller.state.user, isNull);

        // Failed Sign In
        final loginFail = await controller.signInWithEmail(
          email: 'sara@pieas.edu.pk',
          password: 'WrongPassword',
        );
        expect(loginFail, isFalse);
        expect(controller.state.isAuthenticated, isFalse);
        expect(controller.state.errorMessage, isNotNull);

        // Successful Sign In
        final loginOk = await controller.signInWithEmail(
          email: 'sara@pieas.edu.pk',
          password: 'PieasPassword101',
        );
        expect(loginOk, isTrue);
        expect(controller.state.isAuthenticated, isTrue);
        expect(controller.state.errorMessage, isNull);

        // Password Reset
        await controller.sendPasswordReset('sara@pieas.edu.pk');
        expect(controller.state.successMessage, isNotNull);
        expect(controller.state.successMessage, contains('Password reset instructions'));

        controller.dispose();
      });
    });
  });
}
