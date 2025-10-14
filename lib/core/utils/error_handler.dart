import 'dart:io';
import 'package:flutter/material.dart';
import '../config/app_constants.dart';

class ErrorHandler {
  static String getErrorMessage(dynamic error) {
    if (error is SocketException) {
      return AppStrings.networkError;
    } else if (error is HttpException) {
      return AppStrings.serverError;
    } else if (error is FormatException) {
      return 'خطأ في تنسيق البيانات';
    } else if (error is String) {
      return error;
    } else {
      return AppStrings.unknownError;
    }
  }

  static void showErrorSnackBar(BuildContext context, dynamic error) {
    final message = getErrorMessage(error);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'موافق',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  static void showInfoSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.info,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  static Future<bool> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String content,
    String confirmText = 'نعم',
    String cancelText = 'لا',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              confirmText,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    return result ?? false;
  }
}
