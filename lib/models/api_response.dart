class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      message: json['message'],
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'] as T?,
    );
  }

  factory ApiResponse.error(String message) {
    return ApiResponse<T>(
      success: false,
      message: message,
      data: null,
    );
  }

  factory ApiResponse.success(T data, [String? message]) {
    return ApiResponse<T>(
      success: true,
      message: message,
      data: data,
    );
  }
}
