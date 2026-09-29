import '../../../../core/error/failures.dart';
import '../entities/app_user.dart';

abstract class AuthRepository {
  Stream<AppUser?> get authStateChanges;
  AppUser? get currentUser;

  Future<Result<AppUser, AuthFailure>> signInWithEmail({
    required String email,
    required String password,
  });

  Future<Result<AppUser, AuthFailure>> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  });

  Future<Result<AppUser, AuthFailure>> signInWithGoogle();

  Future<Result<AppUser, AuthFailure>> signInAsGuest();

  Future<Result<void, AuthFailure>> sendPasswordResetEmail(String email);

  Future<void> signOut();
}
