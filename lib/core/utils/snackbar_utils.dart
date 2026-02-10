import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class SnackbarUtils {
  static void showSuccess(BuildContext context, String message) {
    _showSnackBar(
      context,
      message,
      AppColors.primary,
      const Icon(Icons.check_circle, color: Colors.black),
      Colors.black,
    );
  }

  static void showError(BuildContext context, String message) {
    _showSnackBar(
      context,
      message,
      AppColors.error,
      const Icon(Icons.error_outline, color: Colors.white),
      Colors.white,
    );
  }

  static void showInfo(BuildContext context, String message) {
    _showSnackBar(
      context,
      message,
      const Color(0xFF333333), // Dark Grey for Info
      const Icon(Icons.info_outline, color: Colors.white),
      Colors.white,
    );
  }

  static void _showSnackBar(
    BuildContext context,
    String message,
    Color bgColor,
    Icon icon,
    Color textColor,
  ) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            icon,
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        showCloseIcon: true,
        closeIconColor: textColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
