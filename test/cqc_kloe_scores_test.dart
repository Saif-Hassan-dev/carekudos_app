import 'package:flutter_test/flutter_test.dart';
import 'package:carekudos_app/features/manager/providers/manager_dashboard_provider.dart';

void main() {
  group('CqcKloeScores', () {
    test('default values are all zero', () {
      const scores = CqcKloeScores();
      expect(scores.wellLedScore, 0);
      expect(scores.caringScore, 0);
      expect(scores.staffParticipationRate, 0);
      expect(scores.managerEngagementRate, 0);
      expect(scores.recognitionFrequency, 0);
      expect(scores.valuesAlignmentPercent, 0);
      expect(scores.compassionTagPercent, 0);
      expect(scores.peerRecognitionRate, 0);
      expect(scores.recognitionPerStaff, 0);
      expect(scores.moraleTrendScore, 0);
    });

    test('stores custom values correctly', () {
      const scores = CqcKloeScores(
        wellLedScore: 75.5,
        caringScore: 82.3,
        staffParticipationRate: 60.0,
        managerEngagementRate: 100.0,
        recognitionFrequency: 45.0,
        valuesAlignmentPercent: 80.0,
        compassionTagPercent: 35.0,
        peerRecognitionRate: 70.0,
        recognitionPerStaff: 5.2,
        moraleTrendScore: 55.0,
      );
      expect(scores.wellLedScore, 75.5);
      expect(scores.caringScore, 82.3);
      expect(scores.staffParticipationRate, 60.0);
      expect(scores.managerEngagementRate, 100.0);
    });
  });

  group('CqcReportData', () {
    test('default values are zero', () {
      const report = CqcReportData();
      expect(report.monthlyValuesDistribution, 0);
      expect(report.taggedRecognitions, 0);
      expect(report.valuesAlignmentTrend, 0);
    });
  });

  group('CultureHealthData', () {
    test('default values', () {
      const data = CultureHealthData();
      expect(data.score, 0);
      expect(data.participationRate, 0);
      expect(data.avgStarsPerStaff, 0);
      expect(data.gdprCleanRate, 100);
    });
  });

  group('DashboardStats', () {
    test('default values', () {
      const stats = DashboardStats();
      expect(stats.pendingReviews, 0);
      expect(stats.gdprFlags, 0);
      expect(stats.activeStaffToday, 0);
      expect(stats.totalRecognitionsWeek, 0);
    });
  });
}
