enum GdprStatus { safe, warning, unsafe }

class GdprChecker {
  // Main check method
  static GdprCheckResult check(String text) {
    if (text.isEmpty) {
      return GdprCheckResult(
        status: GdprStatus.warning,
        issues: ['Post cannot be empty'],
      );
    }

    final issues = <String>[];

    // Check for names with titles
    if (_containsNamesWithTitles(text)) {
      issues.add('Contains names with titles (Mr/Mrs/Miss/Ms/Dr)');
    }

    // Check for full names
    if (_containsFullNames(text)) {
      issues.add('May contain full names');
    }

    // Check for room/bed numbers
    if (_containsRoomNumbers(text)) {
      issues.add('Contains room or bed numbers');
    }

    // Check for addresses
    if (_containsAddresses(text)) {
      issues.add('May contain address information');
    }

    // Check for phone numbers
    if (_containsPhoneNumbers(text)) {
      issues.add('Contains phone numbers');
    }

    // Check for dates of birth
    if (_containsDatesOfBirth(text)) {
      issues.add('May contain dates of birth');
    }

    // Determine status
    if (issues.isEmpty && text.length >= 50) {
      return GdprCheckResult(status: GdprStatus.safe, issues: []);
    } else if (issues.isNotEmpty) {
      return GdprCheckResult(status: GdprStatus.unsafe, issues: issues);
    } else {
      return GdprCheckResult(
        status: GdprStatus.warning,
        issues: ['Post must be at least 50 characters (${text.length}/50)'],
      );
    }
  }

  // Pattern checks
  static bool _containsNamesWithTitles(String text) {
    final pattern = RegExp(
      r'\b(Mr|Mrs|Miss|Ms|Dr)\.?\s+[A-Z][a-z]+',
      caseSensitive: false,
    );
    return pattern.hasMatch(text);
  }

  static bool _containsFullNames(String text) {
    final pattern = RegExp(r'\b[A-Z][a-z]+\s+[A-Z][a-z]+\b');
    return pattern.hasMatch(text);
  }

  static bool _containsRoomNumbers(String text) {
    final pattern = RegExp(r'\b(room|bed|ward)\s+\d+', caseSensitive: false);
    return pattern.hasMatch(text);
  }

  static bool _containsAddresses(String text) {
    final pattern = RegExp(
      r'\b\d+\s+[A-Z][a-z]+\s+(Street|Road|Avenue|Lane|Drive|Way)',
      caseSensitive: false,
    );
    return pattern.hasMatch(text);
  }

  static bool _containsPhoneNumbers(String text) {
    final pattern = RegExp(r'\b\d{3}[-.\s]?\d{3}[-.\s]?\d{4}\b');
    return pattern.hasMatch(text);
  }

  static bool _containsDatesOfBirth(String text) {
    final pattern = RegExp(r'\b\d{1,2}[/-]\d{1,2}[/-]\d{2,4}\b');
    return pattern.hasMatch(text);
  }

  // Get suggestions for fixing issues
  static List<String> getSuggestions(String text) {
    final suggestions = <String>[];

    if (_containsNamesWithTitles(text)) {
      suggestions.add(
        'Replace "Mr Smith" with "a gentleman" or "the resident"',
      );
    }

    if (_containsRoomNumbers(text)) {
      suggestions.add('Replace "room 12" with "their room"');
    }

    if (_containsFullNames(text)) {
      suggestions.add('Use general terms instead of specific names');
    }

    return suggestions;
  }
}

class GdprCheckResult {
  final GdprStatus status;
  final List<String> issues;

  GdprCheckResult({required this.status, required this.issues});

  bool get isSafe => status == GdprStatus.safe;
  bool get hasWarnings => status == GdprStatus.warning;
  bool get isUnsafe => status == GdprStatus.unsafe;
}
