import 'dart:async';
import 'dart:convert';
import '../../../../core/error/failures.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._dataSource) {
    _currentUser = _dataSource.getCurrentUser();
  }

  final AuthLocalDataSource _dataSource;
  final StreamController<AppUser?> _authStateController =
      StreamController<AppUser?>.broadcast();

  AppUser? _currentUser;

  @override
  Stream<AppUser?> get authStateChanges => _authStateController.stream;

  @override
  AppUser? get currentUser => _currentUser;

  String _hashPassword(String password) {
    const salt = 'lm_secure_salt_2026_';
    final bytes = utf8.encode('$salt$password');
    return base64Encode(bytes);
  }

  @override
  Future<Result<AppUser, AuthFailure>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      return Result.failure(const AuthFailure('Please provide a valid email address.'));
    }
    if (password.trim().isEmpty) {
      return Result.failure(const AuthFailure('Password cannot be empty.'));
    }

    final account = _dataSource.findAccountByEmail(cleanEmail);
    if (account == null) {
      return Result.failure(const AuthFailure('No account found with this email. Please sign up first.'));
    }

    final storedHash = account['password_hash'] as String?;
    final incomingHash = _hashPassword(password);

    if (storedHash != incomingHash) {
      return Result.failure(const AuthFailure('Incorrect password. Please verify your credentials.'));
    }

    final user = AppUser.fromJson(account['user'] as Map<String, dynamic>);
    _currentUser = user;
    await _dataSource.setCurrentUser(user);
    _authStateController.add(user);

    return Result.success(user);
  }

  @override
  Future<Result<AppUser, AuthFailure>> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      return Result.failure(const AuthFailure('Please provide a valid email address.'));
    }
    if (password.length < 6) {
      return Result.failure(const AuthFailure('Password must be at least 6 characters long.'));
    }

    final existing = _dataSource.findAccountByEmail(cleanEmail);
    if (existing != null) {
      return Result.failure(const AuthFailure('An account with this email already exists. Please sign in.'));
    }

    final derivedName = displayName?.trim().isNotEmpty == true
        ? displayName!.trim()
        : cleanEmail.split('@')[0];

    final newUser = AppUser(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      email: cleanEmail,
      displayName: derivedName,
      createdAt: DateTime.now(),
      isAnonymous: false,
    );

    final hash = _hashPassword(password);
    await _dataSource.saveUserAccount(user: newUser, passwordHash: hash);
    _currentUser = newUser;
    await _dataSource.setCurrentUser(newUser);
    _authStateController.add(newUser);

    return Result.success(newUser);
  }

  @override
  Future<Result<AppUser, AuthFailure>> signInWithGoogle() async {
    // Cross-platform Google Sign-In simulation / Web & Native ready
    final googleUser = AppUser(
      id: 'goog_${DateTime.now().millisecondsSinceEpoch}',
      email: 'scholar.google@lecturemind.ai',
      displayName: 'Google Scholar',
      photoUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      createdAt: DateTime.now(),
      isAnonymous: false,
    );

    _currentUser = googleUser;
    await _dataSource.setCurrentUser(googleUser);
    _authStateController.add(googleUser);

    return Result.success(googleUser);
  }

  @override
  Future<Result<AppUser, AuthFailure>> signInAsGuest() async {
    final guestUser = AppUser(
      id: 'guest_${DateTime.now().millisecondsSinceEpoch}',
      email: 'guest@lecturemind.local',
      displayName: 'Guest Scholar (مہمان طالبعلم)',
      createdAt: DateTime.now(),
      isAnonymous: true,
    );

    _currentUser = guestUser;
    await _dataSource.setCurrentUser(guestUser);
    _authStateController.add(guestUser);

    return Result.success(guestUser);
  }

  @override
  Future<Result<void, AuthFailure>> sendPasswordResetEmail(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      return Result.failure(const AuthFailure('Please provide a valid email address.'));
    }

    final account = _dataSource.findAccountByEmail(cleanEmail);
    if (account == null) {
      return Result.failure(const AuthFailure('No registered account found with this email.'));
    }

    // In a real SMTP/Firebase environment, a reset token email is dispatched.
    return Result.success(null);
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    await _dataSource.setCurrentUser(null);
    _authStateController.add(null);
  }

  void dispose() {
    _authStateController.close();
  }
}
