enum GdprStatus { safe, warning, unsafe }

class GdprChecker {
  // ── Common first names (UK/US/International) ──
  static const _commonFirstNames = {
    // Male names (UK/US)
    'john', 'james', 'robert', 'michael', 'william', 'david', 'richard',
    'joseph', 'thomas', 'charles', 'christopher', 'daniel', 'matthew',
    'anthony', 'mark', 'donald', 'steven', 'paul', 'andrew', 'joshua',
    'kenneth', 'kevin', 'brian', 'george', 'edward', 'ronald', 'timothy',
    'jason', 'jeffrey', 'ryan', 'jacob', 'gary', 'nicholas', 'eric',
    'jonathan', 'stephen', 'larry', 'justin', 'scott', 'brandon',
    'benjamin', 'samuel', 'raymond', 'gregory', 'frank', 'alexander',
    'patrick', 'jack', 'dennis', 'jerry', 'tyler', 'aaron', 'jose', 'adam',
    'henry', 'nathan', 'douglas', 'zachary', 'peter', 'kyle', 'walter',
    'ethan', 'jeremy', 'harold', 'keith', 'christian', 'roger', 'noah',
    'gerald', 'carl', 'terry', 'sean', 'austin', 'arthur', 'lawrence',
    'jesse', 'dylan', 'bryan', 'joe', 'jordan', 'billy', 'bruce', 'albert',
    'willie', 'gabriel', 'logan', 'alan', 'juan', 'wayne', 'elijah',
    'randy', 'roy', 'vincent', 'ralph', 'eugene', 'russell', 'bobby',
    'mason', 'philip', 'harry', 'oliver', 'charlie', 'leo', 'freddie',
    'oscar', 'archie', 'alfie', 'teddy', 'finley', 'liam', 'max',
    // Female names (UK/US)
    'mary', 'patricia', 'jennifer', 'linda', 'barbara', 'elizabeth',
    'susan', 'jessica', 'sarah', 'karen', 'nancy', 'lisa', 'betty',
    'margaret', 'sandra', 'ashley', 'kimberly', 'emily', 'donna',
    'michelle', 'dorothy', 'carol', 'amanda', 'melissa', 'deborah',
    'stephanie', 'rebecca', 'sharon', 'laura', 'cynthia', 'kathleen',
    'amy', 'angela', 'shirley', 'anna', 'brenda', 'pamela', 'emma',
    'nicole', 'helen', 'samantha', 'katherine', 'christine', 'debra',
    'rachel', 'catherine', 'carolyn', 'janet', 'ruth', 'maria', 'heather',
    'diane', 'virginia', 'julie', 'joyce', 'victoria', 'olivia', 'kelly',
    'christina', 'lauren', 'joan', 'evelyn', 'judith', 'megan', 'cheryl',
    'andrea', 'hannah', 'martha', 'jacqueline', 'frances', 'gloria', 'ann',
    'teresa', 'kathryn', 'sophie', 'charlotte', 'amelia', 'isla', 'ava',
    'mia', 'poppy', 'ella', 'lily', 'grace', 'rosie', 'freya', 'willow',
    'ivy', 'florence', 'millie', 'phoebe', 'daisy', 'ruby',
    // South Asian / Muslim names
    'mohammed', 'muhammad', 'ahmed', 'ali', 'omar', 'hassan', 'hussein',
    'yusuf', 'ibrahim', 'ismail', 'khalid', 'tariq', 'imran', 'farhan',
    'salman', 'salim', 'rashid', 'hamza', 'bilal', 'usman', 'zain',
    'adnan', 'kamran', 'shahid', 'asif', 'naveed', 'arif', 'sajid',
    'faisal', 'wasim', 'nasir', 'jamil', 'rafiq', 'iqbal', 'akbar',
    'waqar', 'saif', 'ikram', 'fahim', 'zahid', 'naeem', 'kashif',
    'tanveer', 'tahir', 'mazhar', 'shakeel', 'shabbir', 'pervaiz',
    'nadeem', 'aziz', 'habib', 'anwar', 'ehsan', 'farooq', 'ashraf',
    'altaf', 'aftab', 'javed', 'riaz', 'liaqat', 'manzoor', 'sarfraz',
    'shafiq', 'zarif', 'haider', 'abbas', 'noman', 'owais', 'muneeb',
    'talha', 'usama', 'saad', 'furqan', 'danish', 'shoaib', 'aamir',
    'mohsin', 'irfan', 'zubair', 'waheed', 'shakil', 'babar', 'rizwan',
    'munir', 'ghulam', 'aslam', 'shafqat', 'maqsood', 'masood',
    'qasim', 'haroon', 'suleman', 'dawood', 'idrees', 'younis',
    'mustafa', 'moeen', 'junaid', 'taimur', 'rehan', 'atif', 'basit',
    'fatima', 'aisha', 'maryam', 'zainab', 'khadija', 'amina', 'sofia',
    'layla', 'hana', 'nadia', 'sana', 'sara', 'hira', 'ayesha', 'ruqayyah',
    'sumaya', 'yasmin', 'shabana', 'nasreen', 'parveen', 'tahira',
    'samina', 'rubina', 'kulsum', 'bushra', 'rabia', 'asma', 'uzma',
    'farzana', 'shazia', 'sajida', 'nafisa', 'zubaida', 'rehana',
    'mehwish', 'madiha', 'iqra', 'kinza', 'nimra', 'arooj', 'sidra',
    // East Asian names
    'wei', 'ying', 'min', 'lei', 'jun', 'yan', 'jing', 'yun', 'chen',
    'wang', 'zhang', 'liu', 'li', 'zhao', 'huang', 'zhou', 'wu',
    'xiao', 'feng', 'lin', 'tang', 'deng', 'guo', 'han', 'ma',
    'liang', 'song', 'su', 'xu', 'hu', 'shen', 'peng', 'lu',
    // Indian subcontinent names
    'singh', 'kumar', 'raj', 'priya', 'anjali', 'divya', 'ravi', 'amit',
    'sanjay', 'deepak', 'suresh', 'ramesh', 'mahesh', 'ganesh', 'vijay',
    'anil', 'sunil', 'mukesh', 'rajesh', 'dinesh', 'naresh', 'harish',
    'girish', 'manish', 'ashish', 'neha', 'pooja', 'shreya', 'anita',
    'sunita', 'geeta', 'seema', 'rekha', 'meena', 'lata', 'kavita',
    'rahul', 'rohit', 'nitin', 'vikram', 'vishal', 'vivek', 'sachin',
    'gaurav', 'pankaj', 'sandeep', 'ajay', 'manoj', 'pramod', 'kamal',
    'neeraj', 'yogesh', 'devendra', 'arvind', 'vinod', 'kishore',
    'lakshmi', 'parvati', 'sarita', 'usha', 'asha', 'savita', 'radha',
    'jyoti', 'kiran', 'swati', 'ritu', 'shilpa', 'preeti', 'rani',
    // African names
    'kwame', 'kofi', 'ama', 'akua', 'yaw', 'abena', 'adjoa', 'chinua',
    'chioma', 'ngozi', 'emeka', 'obinna', 'chika', 'amara', 'zuri',
    'olu', 'tunde', 'segun', 'bola', 'funke', 'yemi', 'toyin',
    'adewale', 'olumide', 'adesola', 'chiamaka', 'nkechi', 'ifeanyi',
    'blessing', 'favour', 'patience', 'mercy', 'joy',
    // Polish / Eastern European
    'jan', 'piotr', 'tomasz', 'krzysztof', 'andrzej', 'marek', 'pawel',
    'grzegorz', 'zbigniew', 'jerzy', 'agnieszka', 'beata',
    'dorota', 'ewa', 'joanna', 'katarzyna', 'malgorzata', 'monika',
    'wojciech', 'dariusz', 'mariusz', 'artur', 'lukasz', 'marcin',
    'kamil', 'rafal', 'michal', 'jakub', 'mateusz', 'karolina',
    'magdalena', 'justyna', 'sylwia', 'izabela', 'aleksandra',
    // Caribbean names
    'marlon', 'winston', 'leroy', 'clive', 'trevor', 'beverly', 'pauline',
    'dwight', 'tyrone', 'desmond', 'cedric', 'delroy', 'errol',
    // Spanish / Portuguese
    'carlos', 'miguel', 'luis', 'pedro', 'pablo', 'diego', 'rafael',
    'fernando', 'sergio', 'alejandro', 'javier', 'ricardo', 'raul',
    'ana', 'rosa', 'carmen', 'lucia', 'isabel', 'elena', 'pilar',
    // Arabic / Middle Eastern
    'nasser', 'saeed', 'mansoor', 'sultan', 'majid', 'waleed', 'fahad',
    'abdullah', 'abdulrahman', 'mohanned', 'rashed', 'bader', 'fawaz',
    'noura', 'reem', 'dalal', 'maha', 'lama', 'ghada', 'abeer',
    // Turkish
    'mehmet', 'ahmet', 'kemal', 'emre', 'burak', 'serkan',
    'ayse', 'elif', 'zeynep', 'merve', 'fatma', 'esra', 'tugba',
    // Somali
    'abdi', 'abdirahman', 'abdullahi', 'mohamed', 'farah', 'adan',
    'hodan', 'halima', 'sahra', 'ayan', 'ifrah', 'hamdi', 'warsan',
    // Filipino
    'rosario', 'lourdes', 'concepcion',
    'renato', 'rolando', 'reynaldo', 'estrella', 'remedios',
  };

  // ── Words to EXCLUDE from name detection (common English words) ──
  static const _exclusions = {
    // Days / months / seasons
    'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday',
    'sunday', 'january', 'february', 'march', 'april', 'may', 'june',
    'july', 'august', 'september', 'october', 'november', 'december',
    'summer', 'winter', 'spring', 'autumn', 'fall',
    // Care-related words that could false-positive
    'god', 'lord', 'sir', 'madam', 'doctor', 'nurse', 'care', 'team',
    'staff', 'resident', 'patient', 'client', 'colleague', 'manager',
    'worker', 'carer', 'helper', 'support', 'above', 'beyond',
    'compassion', 'teamwork', 'excellence', 'reliability', 'leadership',
    'communication', 'dedication', 'kindness', 'respect', 'dignity',
    'thank', 'thanks', 'well', 'done', 'great', 'good', 'amazing',
    'fantastic', 'brilliant', 'wonderful', 'excellent', 'outstanding',
    'exceptional', 'helped', 'helping', 'today', 'yesterday', 'morning',
    'afternoon', 'evening', 'night', 'shift', 'ward', 'unit', 'home',
    'general', 'special', 'extra', 'really', 'very', 'just', 'also',
    'always', 'never', 'often', 'sometimes', 'during', 'after', 'before',
    'about', 'their', 'there', 'them', 'they', 'this', 'that', 'with',
    'from', 'have', 'been', 'being', 'were', 'will', 'would', 'could',
    'should', 'make', 'made', 'like', 'give', 'gave', 'take', 'took',
    'come', 'came', 'know', 'knew', 'feel', 'felt', 'safe', 'ensure',
    'witnessed', 'stepped', 'stepping', 'late', 'early', 'medication',
    'medicine', 'treatment', 'comfort', 'comfortable', 'rest',
    // App-specific
    'carekudos', 'post', 'recognition', 'shared', 'content',
  };

  // ── Common English words that are NOT names when capitalized at sentence start ──
  static const _commonEnglishWords = {
    'the', 'a', 'an', 'and', 'or', 'but', 'is', 'are', 'was', 'were',
    'be', 'been', 'being', 'have', 'has', 'had', 'do', 'does', 'did',
    'will', 'would', 'could', 'should', 'may', 'might', 'must', 'shall',
    'can', 'need', 'dare', 'ought', 'used', 'to', 'of', 'in', 'for',
    'on', 'with', 'at', 'by', 'from', 'up', 'about', 'into', 'over',
    'after', 'beneath', 'under', 'above', 'between', 'here', 'there',
    'when', 'where', 'why', 'how', 'all', 'each', 'every', 'both',
    'few', 'more', 'most', 'other', 'some', 'such', 'no', 'not', 'only',
    'own', 'same', 'so', 'than', 'too', 'very', 'just', 'because',
    'man', 'woman', 'person', 'people', 'child', 'boy', 'girl',
    'someone', 'anyone', 'everyone', 'nobody', 'somebody', 'anybody',
    'something', 'anything', 'everything', 'nothing', 'what', 'which',
    'who', 'whom', 'whose', 'this', 'that', 'these', 'those',
    'my', 'your', 'his', 'its', 'our', 'their',
    'me', 'you', 'him', 'her', 'it', 'us', 'them',
    'i', 'we', 'he', 'she', 'they',
    'also', 'always', 'never', 'often', 'sometimes', 'usually',
    'already', 'still', 'even', 'really', 'quite', 'rather',
    'helped', 'helping', 'went', 'going', 'came', 'coming',
    'said', 'told', 'asked', 'called', 'named', 'known',
    'feeling', 'looking', 'working', 'making', 'taking', 'giving',
    'showed', 'showing', 'stayed', 'staying', 'started', 'starting',
    'amazing', 'fantastic', 'brilliant', 'wonderful', 'excellent',
    'outstanding', 'exceptional', 'incredible', 'remarkable',
    'today', 'yesterday', 'tomorrow', 'morning', 'afternoon',
    'night', 'during', 'while', 'since', 'until', 'before',
  };

  // ── Main check method ──
  static GdprCheckResult check(String text) {
    if (text.trim().isEmpty) {
      return GdprCheckResult(
        status: GdprStatus.warning,
        issues: ['Post cannot be empty'],
      );
    }

    final issues = <String>[];
    int riskScore = 0;

    // ── CRITICAL RISK (auto-unsafe) ──
    if (_containsEmailAddresses(text)) {
      issues.add('Contains email addresses');
      riskScore += 5;
    }

    if (_containsNHSNumbers(text)) {
      issues.add('Contains NHS or ID numbers');
      riskScore += 5;
    }

    // ── HIGH RISK ──
    if (_containsPhoneNumbers(text)) {
      issues.add('Contains phone numbers');
      riskScore += 4;
    }

    if (_containsDatesOfBirth(text)) {
      issues.add('May contain dates of birth');
      riskScore += 4;
    }

    if (_containsPostcodes(text)) {
      issues.add('Contains UK postcodes');
      riskScore += 3;
    }

    if (_containsAddresses(text)) {
      issues.add('May contain address information');
      riskScore += 3;
    }

    // ── MEDIUM RISK ──
    if (_containsNamesWithTitles(text)) {
      issues.add('Contains names with titles (Mr/Mrs/Miss/Ms/Dr)');
      riskScore += 3;
    }

    if (_containsFullNames(text)) {
      issues.add('May contain personal names');
      riskScore += 3;
    }

    if (_containsNamedPhrase(text)) {
      issues.add('References a person by name');
      riskScore += 4;
    }

    if (_containsAgeReferences(text)) {
      issues.add('Contains age or date of birth references');
      riskScore += 2;
    }

    // ── LOW-MEDIUM RISK ──
    if (_containsCommonNames(text)) {
      issues.add('May contain personal names');
      riskScore += 2;
    }

    if (_containsRoomNumbers(text)) {
      issues.add('Contains room, bed, or ward numbers');
      riskScore += 2;
    }

    if (_containsMedicalIds(text)) {
      issues.add('Contains medical record or ID references');
      riskScore += 3;
    }

    if (_containsSurnamePatterns(text)) {
      issues.add('May contain surnames');
      riskScore += 2;
    }

    // ── Deduplicate similar issues ──
    final deduped = issues.toSet().toList();

    // ── Determine status ──
    if (riskScore >= 4) {
      return GdprCheckResult(status: GdprStatus.unsafe, issues: deduped);
    } else if (riskScore >= 2) {
      return GdprCheckResult(status: GdprStatus.warning, issues: deduped);
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

  // ═══════════════════════════════════════════════
  //  PATTERN CHECKS
  // ═══════════════════════════════════════════════

  /// Titles + name: "Mr Smith", "Mrs. Jones", "Dr Ahmed"
  static bool _containsNamesWithTitles(String text) {
    final pattern = RegExp(
      r'\b(Mr|Mrs|Miss|Ms|Dr|Prof|Cllr|Rev|Sr|Jr)\.?\s+[A-Z][a-z]+',
      caseSensitive: true,
    );
    return pattern.hasMatch(text);
  }

  /// "patient John", "resident Sarah Smith", or two capitalized words together
  static bool _containsFullNames(String text) {
    // Context-based: "patient/resident/client + Name"
    final contextPattern = RegExp(
      r'\b(patient|resident|client|person|man|woman|lady|gentleman|boy|girl|individual|service user)\s+[A-Z][a-z]{2,}',
      caseSensitive: false,
    );
    if (contextPattern.hasMatch(text)) return true;

    // Two consecutive capitalized words that look like first+last name
    // (not at start of sentence, and neither word is a common English word)
    final words = text.split(RegExp(r'\s+'));
    for (int i = 1; i < words.length - 1; i++) {
      final w1 = words[i].replaceAll(RegExp(r'[^\w]'), '');
      final w2 = words[i + 1].replaceAll(RegExp(r'[^\w]'), '');
      if (w1.length >= 3 && w2.length >= 3 &&
          _isCapitalized(w1) && _isCapitalized(w2) &&
          !_commonEnglishWords.contains(w1.toLowerCase()) &&
          !_commonEnglishWords.contains(w2.toLowerCase()) &&
          !_exclusions.contains(w1.toLowerCase()) &&
          !_exclusions.contains(w2.toLowerCase())) {
        return true;
      }
    }
    return false;
  }

  /// Catches phrases like "named Salman", "called John", "a man named X"
  static bool _containsNamedPhrase(String text) {
    final pattern = RegExp(
      r'\b(named|called|name is|name was|known as|goes by)\s+[A-Z][a-z]{2,}',
      caseSensitive: false,
    );
    return pattern.hasMatch(text);
  }

  /// Any word matching the common names dictionary (case-insensitive)
  static bool _containsCommonNames(String text) {
    final words = text.split(RegExp(r'\W+'));

    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      if (word.isEmpty || word.length < 2) continue;

      final lowerWord = word.toLowerCase();

      // Skip exclusions
      if (_exclusions.contains(lowerWord)) continue;
      if (_commonEnglishWords.contains(lowerWord)) continue;

      // Check if word is in common names list (regardless of capitalization)
      if (_commonFirstNames.contains(lowerWord)) {
        return true;
      }
    }

    return false;
  }

  /// Room/bed/ward numbers: "room 23", "room number 23", "room no 23",
  /// "bed 5", "ward 3B", "bay 2"
  static bool _containsRoomNumbers(String text) {
    final pattern = RegExp(
      r'\b(room|bed|ward|bay|unit)\s*(number|no\.?|num|#)?\s*\d+[A-Za-z]?\b',
      caseSensitive: false,
    );
    return pattern.hasMatch(text);
  }

  /// Street addresses: "12 Oak Street", "5 High Road"
  static bool _containsAddresses(String text) {
    final pattern = RegExp(
      r'\b\d+[A-Za-z]?\s+[A-Z][a-z]+\s+(Street|St|Road|Rd|Avenue|Ave|Lane|Ln|Drive|Dr|Way|Close|Cl|Crescent|Cr|Terrace|Place|Pl|Court|Ct|Gardens|Gdns|Grove|Gr|Park|Square|Sq|Mews|Rise|Hill|Row|Walk|View|Green|Gate|End|Parade|Circus)\b',
      caseSensitive: false,
    );
    return pattern.hasMatch(text);
  }

  /// UK phone numbers (mobile + landline)
  static bool _containsPhoneNumbers(String text) {
    final patterns = [
      RegExp(r'(\+44|0044)\s?\d[\d\s-]{8,12}\d'),           // international
      RegExp(r'\b0[1-9]\d{2,3}[\s-]?\d{3,4}[\s-]?\d{3,4}'), // landline
      RegExp(r'\b07\d{3}[\s-]?\d{3}[\s-]?\d{3}\b'),          // UK mobile
      RegExp(r'\b\d{3}[-.\s]\d{3,4}[-.\s]\d{4}\b'),          // US-style
    ];
    return patterns.any((p) => p.hasMatch(text));
  }

  /// Dates of birth or date patterns with context
  static bool _containsDatesOfBirth(String text) {
    final patterns = [
      RegExp(r'\b(dob|date of birth|born on|born)\b.*?\b\d{1,2}[/-]\d{1,2}[/-]\d{2,4}\b', caseSensitive: false),
      RegExp(r'\b(dob|date of birth)\s*[:=]?\s*\d', caseSensitive: false),
      RegExp(r'\bborn\s+(on\s+)?(the\s+)?\d{1,2}(st|nd|rd|th)?\s+(of\s+)?(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)', caseSensitive: false),
    ];
    return patterns.any((p) => p.hasMatch(text));
  }

  /// Age references: "aged 85", "82 years old", "age 90"
  static bool _containsAgeReferences(String text) {
    final pattern = RegExp(
      r'\b(aged?|age)\s*\d{1,3}\b|\b\d{1,3}\s*(years?\s*old|year-old|yr\s*old|y\.?o\.?)\b',
      caseSensitive: false,
    );
    return pattern.hasMatch(text);
  }

  /// Email addresses
  static bool _containsEmailAddresses(String text) {
    final pattern = RegExp(
      r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b',
    );
    return pattern.hasMatch(text);
  }

  /// NHS numbers (10 digits with optional spaces)
  static bool _containsNHSNumbers(String text) {
    final patterns = [
      RegExp(r'\b(nhs\s*(number|no\.?|num|#|id)?)\s*[:=]?\s*\d', caseSensitive: false),
      RegExp(r'\b\d{3}\s?\d{3}\s?\d{4}\b'),  // 10-digit with spaces
    ];
    return patterns.any((p) => p.hasMatch(text));
  }

  /// UK postcodes: "SW1A 1AA", "M1 1AA", etc.
  static bool _containsPostcodes(String text) {
    final pattern = RegExp(
      r'\b[A-Z]{1,2}\d[A-Z\d]?\s*\d[A-Z]{2}\b',
      caseSensitive: false,
    );
    return pattern.hasMatch(text);
  }

  /// Medical record / ID numbers
  static bool _containsMedicalIds(String text) {
    final pattern = RegExp(
      r'\b(medical record|mrn|patient id|care id|record number|ref|reference)\s*(number|no\.?|num|#)?\s*[:=]?\s*[A-Z0-9]{3,}',
      caseSensitive: false,
    );
    return pattern.hasMatch(text);
  }

  /// Surname-like patterns: "'s surname", "surname: X", "family name"
  static bool _containsSurnamePatterns(String text) {
    final pattern = RegExp(
      r'\b(surname|family name|last name)\s*[:=]?\s*[A-Z][a-z]+',
      caseSensitive: false,
    );
    return pattern.hasMatch(text);
  }

  // ── Helper ──
  static bool _isCapitalized(String word) {
    if (word.isEmpty) return false;
    return word[0] == word[0].toUpperCase() &&
        word.length > 1 &&
        word.substring(1) == word.substring(1).toLowerCase();
  }

  // ═══════════════════════════════════════════════
  //  SUGGESTIONS
  // ═══════════════════════════════════════════════
  static List<String> getSuggestions(String text) {
    final suggestions = <String>[];

    if (_containsNamesWithTitles(text) || _containsFullNames(text) ||
        _containsCommonNames(text) || _containsNamedPhrase(text)) {
      suggestions.add(
        'Replace names with "a colleague", "a resident", or "a team member"',
      );
    }

    if (_containsRoomNumbers(text)) {
      suggestions.add(
        'Remove room/bed/ward numbers — say "a resident on the unit" instead',
      );
    }

    if (_containsPhoneNumbers(text)) {
      suggestions.add('Remove phone numbers completely');
    }

    if (_containsEmailAddresses(text)) {
      suggestions.add('Remove email addresses');
    }

    if (_containsAddresses(text) || _containsPostcodes(text)) {
      suggestions.add('Remove address and postcode details');
    }

    if (_containsDatesOfBirth(text) || _containsAgeReferences(text)) {
      suggestions.add('Remove dates of birth and specific ages');
    }

    if (_containsNHSNumbers(text) || _containsMedicalIds(text)) {
      suggestions.add('Remove NHS numbers and medical record IDs');
    }

    if (_containsSurnamePatterns(text)) {
      suggestions.add('Remove surnames and family names');
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
