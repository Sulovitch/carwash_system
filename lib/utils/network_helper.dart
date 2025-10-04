import 'dart:async';
import 'package:http/http.dart' as http;

/// مساعد الشبكة لتحسين الأداء
class NetworkHelper {
  static final NetworkHelper _instance = NetworkHelper._internal();
  factory NetworkHelper() => _instance;
  NetworkHelper._internal();

  // تتبع الطلبات الجارية لتجنب التكرار
  final Map<String, Future<http.Response>> _ongoingRequests = {};

  /// إرسال طلب GET مع منع التكرار
  Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final key = 'GET:${url.toString()}';

    // إذا كان هناك طلب جاري، ننتظره بدلاً من إرسال طلب جديد
    if (_ongoingRequests.containsKey(key)) {
      return _ongoingRequests[key]!;
    }

    final request = http
        .get(url, headers: headers)
        .timeout(timeout)
        .whenComplete(() => _ongoingRequests.remove(key));

    _ongoingRequests[key] = request;
    return request;
  }

  /// إرسال طلب POST مع منع التكرار
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final key = 'POST:${url.toString()}:${body.hashCode}';

    if (_ongoingRequests.containsKey(key)) {
      return _ongoingRequests[key]!;
    }

    final request = http
        .post(url, headers: headers, body: body)
        .timeout(timeout)
        .whenComplete(() => _ongoingRequests.remove(key));

    _ongoingRequests[key] = request;
    return request;
  }

  /// مسح الطلبات الجارية
  void clearOngoingRequests() {
    _ongoingRequests.clear();
  }
}
