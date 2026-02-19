enum GdprStatus { safe, warning, unsafe }

class GdprChecker {
  // Common first names dictionary (UK/US/International)
  static const _commonFirstNames = {
    // Male names
    'john', 'james', 'robert', 'michael', 'william', 'david', 'richard', 'joseph',
    'thomas', 'charles', 'christopher', 'daniel', 'matthew', 'anthony', 'mark',
    'donald', 'steven', 'paul', 'andrew', 'joshua', 'kenneth', 'kevin', 'brian',
    'george', 'edward', 'ronald', 'timothy', 'jason', 'jeffrey', 'ryan', 'jacob',
    'gary', 'nicholas', 'eric', 'jonathan', 'stephen', 'larry', 'justin', 'scott',
    'brandon', 'benjamin', 'samuel', 'raymond', 'gregory', 'frank', 'alexander',
    'patrick', 'jack', 'dennis', 'jerry', 'tyler', 'aaron', 'jose', 'adam',
    'henry', 'nathan', 'douglas', 'zachary', 'peter', 'kyle', 'walter', 'ethan',
    'jeremy', 'harold', 'keith', 'christian', 'roger', 'noah', 'gerald', 'carl',
    // Female names
    'mary', 'patricia', 'jennifer', 'linda', 'barbara', 'elizabeth', 'susan',
    'jessica', 'sarah', 'karen', 'nancy', 'lisa', 'betty', 'margaret', 'sandra',
    'ashley', 'kimberly', 'emily', 'donna', 'michelle', 'dorothy', 'carol',
    'amanda', 'melissa', 'deborah', 'stephanie', 'rebecca', 'sharon', 'laura',
    'cynthia', 'kathleen', 'amy', 'angela', 'shirley', 'anna', 'brenda', 'pamela',
    'emma', 'nicole', 'helen', 'samantha', 'katherine', 'christine', 'debra',
    'rachel', 'catherine', 'carolyn', 'janet', 'ruth', 'maria', 'heather',
    'diane', 'virginia', 'julie', 'joyce', 'victoria', 'olivia', 'kelly', 'christina',
    'lauren', 'joan', 'evelyn', 'judith', 'megan', 'cheryl', 'andrea', 'hannah',
    'martha', 'jacqueline', 'frances', 'gloria', 'ann', 'teresa', 'kathryn',
    // International/diverse names
    'mohammed', 'muhammad', 'ahmed', 'ali', 'omar', 'hassan', 'hussein', 'yusuf',
    'fatima', 'aisha', 'maryam', 'zainab', 'khadija', 'amina', 'sofia', 'layla',
    'wei', 'ying', 'min', 'lei', 'jun', 'yan', 'jing', 'yun', 'singh', 'kumar',
    'raj', 'priya', 'anjali', 'divya', 'ravi', 'amit', 'sanjay', 'deepak',
  };

  // Exclusions to avoid false positives
  static const _exclusions = {
    // Days of the week
    'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday',
    // Months (some overlap with names)
    'january', 'february', 'march', 'april', 'may', 'june', 'july', 'august',
    'september', 'october', 'november', 'december',
    // Seasons
    'summer', 'winter', 'spring', 'autumn', 'fall',
    // Common UK places
    'london', 'manchester', 'birmingham', 'liverpool', 'bristol', 'york',
    'bath', 'cambridge', 'oxford', 'exeter', 'chester', 'leeds', 'nottingham',
    // Common words that might be capitalized
    'god', 'lord', 'sir', 'madam', 'doctor', 'nurse', 'care', 'team',
  };

  // Main check method
  static GdprCheckResult check(String text) {
    if (text.trim().isEmpty) {
      return GdprCheckResult(
        status: GdprStatus.warning,
        issues: ['Post cannot be empty'],
      );
    }

    final issues = <String>[];
    int riskScore = 0;

    // High risk
    if (_containsPhoneNumbers(text)) {
      issues.add('Contains phone numbers');
      riskScore += 3;
    }

    if (_containsDatesOfBirth(text)) {
      issues.add('May contain dates of birth');
      riskScore += 3;
    }

    // Medium risk
    if (_containsNamesWithTitles(text)) {
      issues.add('Contains names with titles (Mr/Mrs/Miss/Ms/Dr)');
      riskScore += 2;
    }

    if (_containsFullNames(text)) {
      issues.add('May contain full names');
      riskScore += 2;
    }

    // Low-medium risk - standalone common names
    if (_containsCommonNames(text)) {
      issues.add('May contain common first names');
      riskScore += 1;
    }

    // Low risk
    if (_containsRoomNumbers(text)) {
      issues.add('Contains room or bed numbers');
      riskScore += 1;
    }

    if (_containsAddresses(text)) {
      issues.add('May contain address information');
      riskScore += 2;
    }

    // Determine status using risk score

    if (riskScore >= 5) {
      return GdprCheckResult(status: GdprStatus.unsafe, issues: issues);
    } else if (riskScore >= 2) {
      return GdprCheckResult(status: GdprStatus.warning, issues: issues);
    }

    // Content quality warning (NOT GDPR)
    if (text.length < 50) {
      return GdprCheckResult(
        status: GdprStatus.warning,
        issues: ['Post should be more descriptive (${text.length}/50)'],
      );
    }

    return GdprCheckResult(status: GdprStatus.safe, issues: []);
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
    // Reduced false positives by requiring context words
    final pattern = RegExp(
      r'\b(patient|resident|client)\s+[A-Z][a-z]+\s+[A-Z][a-z]+\b',
      caseSensitive: false,
    );
    return pattern.hasMatch(text);
  }

  static bool _containsCommonNames(String text) {
    // Split text into words, preserving capitalization
    final words = text.split(RegExp(r'\W+'));
    
    for (final word in words) {
      if (word.isEmpty || word.length < 2) continue;
      
      final lowerWord = word.toLowerCase();
      
      // Skip if it's in the exclusion list
      if (_exclusions.contains(lowerWord)) continue;
      
      // Check if word is capitalized AND in common names list
      if (word[0] == word[0].toUpperCase() && 
          word.substring(1) == word.substring(1).toLowerCase() &&
          _commonFirstNames.contains(lowerWord)) {
        return true;
      }
    }
    
    return false;
  }

  static bool _containsRoomNumbers(String text) {
    final pattern = RegExp(r'\b(room|bed|ward)\s+\d+\b', caseSensitive: false);
    return pattern.hasMatch(text);
  }

  static bool _containsAddresses(String text) {
    final pattern = RegExp(
      r'\b\d+\s+[A-Z][a-z]+\s+(Street|Road|Avenue|Lane|Drive|Way)\b',
      caseSensitive: false,
    );
    return pattern.hasMatch(text);
  }

  static bool _containsPhoneNumbers(String text) {
    final pattern = RegExp(r'(\+\d{1,3}\s?)?\d{3,4}[-.\s]?\d{3,4}[-.\s]?\d{4}');
    return pattern.hasMatch(text);
  }

  static bool _containsDatesOfBirth(String text) {
    final pattern = RegExp(
      r'\b(dob|date of birth|born)\b.*\b\d{1,2}[/-]\d{1,2}[/-]\d{2,4}\b',
      caseSensitive: false,
    );
    return pattern.hasMatch(text);
  }

  // Suggestions
  static List<String> getSuggestions(String text) {
    final suggestions = <String>[];

    if (_containsNamesWithTitles(text) || _containsFullNames(text) || _containsCommonNames(text)) {
      suggestions.add(
        'Replace specific names with general terms like "the colleague" or "the team member"',
      );
    }

    if (_containsRoomNumbers(text)) {
      suggestions.add(
        'Replace room numbers with non-identifiable descriptions',
      );
    }

    if (_containsPhoneNumbers(text)) {
      suggestions.add(
        'Remove phone numbers or replace with "[contact removed]"',
      );
    }

    if (_containsAddresses(text)) {
      suggestions.add('Avoid sharing exact address details');
    }

    if (_containsDatesOfBirth(text)) {
      suggestions.add('Remove dates of birth to protect identity');
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
