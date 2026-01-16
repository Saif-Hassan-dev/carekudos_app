import 'package:flutter/material.dart';

// String extensions
extension StringExtensions on String {
  // Capitalize first letter
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }

  // Check if email is valid
  bool get isValidEmail {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(this);
  }

  // Remove extra whitespace
  String removeExtraSpaces() {
    return replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}

// DateTime extensions
extension DateTimeExtensions on DateTime {
  // Check if date is today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  // Check if date is yesterday
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  // Start of day
  DateTime get startOfDay {
    return DateTime(year, month, day);
  }

  // End of day
  DateTime get endOfDay {
    return DateTime(year, month, day, 23, 59, 59);
  }
}

// BuildContext extensions
extension ContextExtensions on BuildContext {
  // Quick access to theme
  ThemeData get theme => Theme.of(this);

  // Quick access to text theme
  TextTheme get textTheme => Theme.of(this).textTheme;

  // Quick access to color scheme
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  // Screen size helpers
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;

  // Show snackbar shortcut
  void showSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(SnackBar(content: Text(message)));
  }

  // Show error snackbar
  void showErrorSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
