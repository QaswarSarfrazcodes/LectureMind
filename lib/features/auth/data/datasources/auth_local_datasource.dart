import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/app_user.dart';

class AuthLocalDataSource {
  AuthLocalDataSource(this._prefs);

  final SharedPreferences _prefs;

  static const _kCurrentUserKey = 'lm_auth_current_user_v1';
  static const _kUserAccountsKey = 'lm_auth_user_accounts_v1';

  AppUser? getCurrentUser() {
    final raw = _prefs.getString(_kCurrentUserKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> setCurrentUser(AppUser? user) async {
    if (user == null) {
      await _prefs.remove(_kCurrentUserKey);
    } else {
      await _prefs.setString(_kCurrentUserKey, jsonEncode(user.toJson()));
    }
  }

  Map<String, dynamic> _getUserAccounts() {
    final raw = _prefs.getString(_kUserAccountsKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  Future<void> saveUserAccount({
    required AppUser user,
    required String passwordHash,
  }) async {
    final accounts = _getUserAccounts();
    accounts[user.email.toLowerCase().trim()] = {
      'user': user.toJson(),
      'password_hash': passwordHash,
    };
    await _prefs.setString(_kUserAccountsKey, jsonEncode(accounts));
  }

  Map<String, dynamic>? findAccountByEmail(String email) {
    final accounts = _getUserAccounts();
    final data = accounts[email.trim().toLowerCase()];
    if (data is Map<String, dynamic>) return data;
    return null;
  }
}
