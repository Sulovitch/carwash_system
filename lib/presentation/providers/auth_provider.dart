// lib/presentation/providers/auth_provider.dart
import 'package:flutter/material.dart';
import '../../data/repositories/auth_repository.dart';
import '../../core/network/api_client.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthProvider with ChangeNotifier {
  final AuthRepository _authRepository;

  AuthStatus _status = AuthStatus.initial;
  String? _errorMessage;
  Map<String, dynamic>? _userData;

  AuthProvider({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepository(ApiClient());

  // Getters
  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get userData => _userData;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;

  /// تسجيل الدخول
  Future<bool> signIn({
    required String login,
    required String password,
    required String userType,
  }) async {
    _setStatus(AuthStatus.loading);

    try {
      final response = await _authRepository.signIn(
        login: login,
        password: password,
        userType: userType,
      );

      if (response.success && response.data != null) {
        _userData = response.data;
        _setStatus(AuthStatus.authenticated);
        return true;
      } else {
        _setError(response.message ?? 'فشل تسجيل الدخول');
        return false;
      }
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  /// تسجيل حساب جديد
  Future<bool> signUp({
    required String name,
    required String phone,
    required String email,
    required String password,
    required String userType,
  }) async {
    _setStatus(AuthStatus.loading);

    try {
      final response = await _authRepository.signUp(
        name: name,
        phone: phone,
        email: email,
        password: password,
        userType: userType,
      );

      if (response.success && response.data != null) {
        _userData = response.data;
        _setStatus(AuthStatus.authenticated);
        return true;
      } else {
        _setError(response.message ?? 'فشل إنشاء الحساب');
        return false;
      }
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  /// تسجيل الخروج
  Future<void> signOut() async {
    await _authRepository.signOut();
    _userData = null;
    _setStatus(AuthStatus.unauthenticated);
  }

  /// التحقق من Session محفوظ
  Future<void> checkAuthStatus() async {
    _setStatus(AuthStatus.loading);

    final isAuth = await _authRepository.isAuthenticated();

    if (isAuth) {
      _userData = await _authRepository.getCachedUserData();
      _setStatus(AuthStatus.authenticated);
    } else {
      _setStatus(AuthStatus.unauthenticated);
    }
  }

  /// مسح رسالة الخطأ
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setStatus(AuthStatus status) {
    _status = status;
    if (status != AuthStatus.error) {
      _errorMessage = null;
    }
    notifyListeners();
  }

  void _setError(String message) {
    _status = AuthStatus.error;
    _errorMessage = message;
    notifyListeners();
  }
}
