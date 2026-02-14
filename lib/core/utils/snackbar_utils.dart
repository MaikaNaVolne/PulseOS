import 'package:flutter/material.dart';
import '../theme/pulse_theme.dart';

class SnackBarUtils {
  static void showUndo({
    required BuildContext context,
    required String message,
    required VoidCallback onUndo,
    int durationSeconds = 5,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1E202C),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: durationSeconds),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Row(
          children: [
            const Icon(Icons.delete_outline, color: PulseColors.red, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: "ОТМЕНИТЬ",
          textColor: PulseColors.primary,
          onPressed: onUndo,
        ),
      ),
    );
  }
}
