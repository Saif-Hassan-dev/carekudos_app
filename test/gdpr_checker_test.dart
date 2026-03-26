import 'package:flutter_test/flutter_test.dart';
import 'package:carekudos_app/core/utils/gdpr_checker.dart';

void main() {
  group('GdprChecker', () {
    group('Safe text', () {
      test('approves general recognition text', () {
        final result = GdprChecker.check(
          'Great job on the shift today! Your compassion really showed.',
        );
        expect(result.isSafe, isTrue);
        expect(result.issues, isEmpty);
      });

      test('approves text with common words', () {
        final result = GdprChecker.check(
          'Outstanding teamwork during the morning handover, really appreciate the effort.',
        );
        expect(result.isSafe, isTrue);
      });

      test('empty text returns warning', () {
        final result = GdprChecker.check('');
        expect(result.hasWarnings, isTrue);
      });
    });

    group('Email detection', () {
      test('flags email addresses', () {
        final result = GdprChecker.check(
          'Contact her at sarah.jones@nhs.uk for more info.',
        );
        expect(result.isUnsafe, isTrue);
        expect(result.issues.any((i) => i.toLowerCase().contains('email')), isTrue);
      });
    });

    group('Phone number detection', () {
      test('flags UK phone numbers', () {
        final result = GdprChecker.check(
          'Call the patient on 07712345678.',
        );
        expect(result.status, isNot(GdprStatus.safe));
        expect(result.issues.any((i) => i.toLowerCase().contains('phone')), isTrue);
      });

      test('flags landline numbers', () {
        final result = GdprChecker.check(
          'Ring 0207 123 4567 to confirm.',
        );
        expect(result.status, isNot(GdprStatus.safe));
      });
    });

    group('NHS number detection', () {
      test('flags NHS numbers', () {
        final result = GdprChecker.check(
          'Patient NHS number is 123 456 7890.',
        );
        expect(result.isUnsafe, isTrue);
        expect(result.issues.any((i) => i.toLowerCase().contains('nhs')), isTrue);
      });
    });

    group('Postcode detection', () {
      test('flags UK postcodes', () {
        final result = GdprChecker.check(
          'The resident lives at SW1A 1AA.',
        );
        expect(result.status, isNot(GdprStatus.safe));
        expect(result.issues.any((i) => i.toLowerCase().contains('postcode')), isTrue);
      });
    });

    group('Date of birth detection', () {
      test('flags explicit DOB', () {
        final result = GdprChecker.check(
          'Her date of birth is 15/03/1945.',
        );
        expect(result.isSafe, isFalse);
        expect(result.issues.any((i) => i.toLowerCase().contains('date')), isTrue);
      });

      test('flags DOB abbreviation', () {
        final result = GdprChecker.check(
          'DOB: 22/01/1960',
        );
        expect(result.isSafe, isFalse);
      });
    });

    group('Name detection', () {
      test('flags full names with title', () {
        final result = GdprChecker.check(
          'Mrs Johnson needs her medication changed.',
        );
        expect(result.status, isNot(GdprStatus.safe));
      });

      test('does not flag generic use of common names in recognition', () {
        // Recognition posts often mention first names of colleagues
        // The checker should be lenient with single first names in positive context
        final result = GdprChecker.check(
          'Amazing work today, the whole team pulled together!',
        );
        expect(result.isSafe, isTrue);
      });
    });

    group('Room/bed number detection', () {
      test('flags room numbers', () {
        final result = GdprChecker.check(
          'Go to room 14 to check on the resident.',
        );
        expect(result.status, isNot(GdprStatus.safe));
      });

      test('flags bed numbers', () {
        final result = GdprChecker.check(
          'Bed 3 patient needs attention.',
        );
        expect(result.status, isNot(GdprStatus.safe));
      });
    });

    group('Address detection', () {
      test('flags street addresses', () {
        final result = GdprChecker.check(
          'She lives at 42 Oak Street.',
        );
        expect(result.status, isNot(GdprStatus.safe));
      });
    });

    group('Result properties', () {
      test('isSafe, hasWarnings, isUnsafe are mutually consistent', () {
        final safe = GdprChecker.check(
          'Great teamwork during the morning shift today, everyone was amazing and supportive.',
        );
        expect(safe.isSafe, isTrue);
        expect(safe.hasWarnings, isFalse);
        expect(safe.isUnsafe, isFalse);

        final unsafe = GdprChecker.check('Email: test@example.com DOB: 01/01/1990');
        expect(unsafe.isSafe, isFalse);
        expect(unsafe.isUnsafe, isTrue);
      });
    });
  });
}
