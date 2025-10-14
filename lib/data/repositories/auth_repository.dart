// lib/data/repositories/auth_repository.dart
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/api_client.dart';
import 'base_repository.dart';

class AuthRepository extends BaseRepository {
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _userTypeKey = 'user_type';

  AuthRepository(super.apiClient);

  /// تسجيل الدخول
  Future<ApiResponse<Map<String, dynamic>>> signIn({
    required String login,
    required String password,
    required String userType,
  }) async {
    try {
      final response = await apiClient.postFormData<Map<String, dynamic>>(
        '/signin.php',
        fields: {
          'login': login,
          'password': password,
          'user_type': userType,
        },
        fromJson: (data) => data as Map<String, dynamic>,
      );

      // حفظ البيانات محلياً في حالة النجاح
      if (response.success && response.data != null) {
        await _saveAuthData(response.data!);
      }

      return response;
    } catch (e) {
      return handleError(e);
    }
  }

  /// تسجيل حساب جديد
  Future<ApiResponse<Map<String, dynamic>>> signUp({
    required String name,
    required String phone,
    required String email,
    required String password,
    required String userType,
  }) async {
    try {
      final response = await apiClient.postFormData<Map<String, dynamic>>(
        '/signup.php',
        fields: {
          'name': name,
          'phone': phone,
          'email': email,
          'password': password,
          'user_type': userType,
        },
        fromJson: (data) => data as Map<String, dynamic>,
      );

      // حفظ البيانات محلياً في حالة النجاح
      if (response.success && response.data != null) {
        await _saveAuthData(response.data!);
      }

      return response;
    } catch (e) {
      return handleError(e);
    }
  }

  /// تسجيل الخروج
  Future<void> signOut() async {
    apiClient.clearAuthToken();
    await _clearAuthData();
  }

  /// التحقق من وجود session محفوظ
  Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final userId = prefs.getString(_userIdKey);

    if (token != null && userId != null) {
      apiClient.setAuthToken(token);
      return true;
    }

    return false;
  }

  /// الحصول على معلومات المستخدم المحفوظة
  Future<Map<String, String?>?> getCachedUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_userIdKey);
    final userType = prefs.getString(_userTypeKey);

    if (userId == null) return null;

    return {
      'userId': userId,
      'userType': userType,
    };
  }

  /// حفظ بيانات التوثيق محلياً
  Future<void> _saveAuthData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();

    // حفظ الـ Token
    final token = data['token']?.toString();
    if (token != null) {
      await prefs.setString(_tokenKey, token);
      apiClient.setAuthToken(token);
    }

    // حفظ معرف المستخدم
    final userId = data['id']?.toString();
    if (userId != null) {
      await prefs.setString(_userIdKey, userId);
    }

    // حفظ نوع المستخدم
    final userType = data['user_type']?.toString();
    if (userType != null) {
      await prefs.setString(_userTypeKey, userType);
    }
  }

  /// مسح بيانات التوثيق المحفوظة
  Future<void> _clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userTypeKey);
  }
}
