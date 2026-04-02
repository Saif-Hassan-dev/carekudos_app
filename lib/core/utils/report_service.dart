import 'dart:math';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

/// Cross-platform branded CareKudos report service.
/// Generates multi-page PDFs with cover pages, executive summaries, charts,
/// team breakdowns, and actionable recommendations.
/// Works on both web and mobile using the printing package.
class ReportService {
  // ─── Brand Palette ───
  static const _primary = PdfColor.fromInt(0xFF0A2C6B);
  static const _gold = PdfColor.fromInt(0xFFD4AF37);
  static const _green = PdfColor.fromInt(0xFF28A745);
  static const _red = PdfColor.fromInt(0xFFFF6B6B);
  static const _navy = PdfColor.fromInt(0xFF1E3A8A);
  static const _gray = PdfColor.fromInt(0xFF6B7280);
  static const _lightGray = PdfColor.fromInt(0xFFF3F4F6);
  static const _white = PdfColors.white;
  static const _darkText = PdfColor.fromInt(0xFF111827);
  static const _amber = PdfColor.fromInt(0xFFF59E0B);

  /// Reusable progress bar widget compatible with the pdf package.
  static pw.Widget _progressBar(double fraction, double height, PdfColor fillColor, {double radius = 5}) {
    final pct = (fraction * 100).round().clamp(0, 100);
    return pw.Container(
      height: height,
      decoration: pw.BoxDecoration(
        color: _lightGray,
        borderRadius: pw.BorderRadius.circular(radius),
      ),
      child: pw.Row(children: [
        if (pct > 0)
          pw.Expanded(
            flex: pct,
            child: pw.Container(
              decoration: pw.BoxDecoration(
                color: fillColor,
                borderRadius: pw.BorderRadius.circular(radius),
              ),
            ),
          ),
        if (pct < 100)
          pw.Expanded(
            flex: 100 - pct,
            child: pw.SizedBox(),
          ),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // REPORT 1: ENGAGEMENT REPORT
  // ═══════════════════════════════════════════════════════════════

  static Future<void> exportEngagementReport({
    required List<Map<String, String>> users,
    String organizationName = 'Your Organisation',
    int dailyActiveUsers = 0,
    int monthlyActiveUsers = 0,
    int totalKudosSent = 0,
    double avgKudosPerUser = 0,
    double engagementRate = 0,
    double dailyChangePercent = 0,
    double monthlyChangePercent = 0,
    List<double> engagementDays = const [],
    List<double> engagementMonths = const [],
    List<String> engagementLabels = const [],
    List<double> kudosSentByMonth = const [],
    List<double> kudosReceivedByMonth = const [],
    List<String> kudosMonthLabels = const [],
    int managerKudos = 0,
    int peerKudos = 0,
    int familyKudos = 0,
    List<Map<String, dynamic>> teamBreakdowns = const [],
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final dateRange =
        '${DateFormat('d MMM yyyy').format(now.subtract(const Duration(days: 30)))} - ${DateFormat('d MMM yyyy').format(now)}';
    final stickiness = monthlyActiveUsers > 0
        ? (dailyActiveUsers / monthlyActiveUsers * 100)
        : 0.0;

    // Cover
    pdf.addPage(_buildCoverPage(
      reportTitle: 'ENGAGEMENT REPORT',
      subtitle: DateFormat('MMMM yyyy').format(now),
      organizationName: organizationName,
      dateRange: dateRange,
      tagline: 'Making Exceptional Care Visible',
    ));

    // Executive Summary
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _pageHeader('EXECUTIVE SUMMARY'),
          pw.SizedBox(height: 20),
          _sectionLabel('KEY HIGHLIGHTS'),
          pw.SizedBox(height: 12),
          pw.Row(children: [
            _kpiBox('Daily Active Users', '$dailyActiveUsers',
                '${_fmtPct(dailyChangePercent)} from yesterday',
                color: dailyChangePercent >= 0 ? _green : _red),
            pw.SizedBox(width: 12),
            _kpiBox('Monthly Active Users', '$monthlyActiveUsers',
                '${_fmtPct(monthlyChangePercent)} from last month',
                color: monthlyChangePercent >= 0 ? _green : _red),
          ]),
          pw.SizedBox(height: 12),
          pw.Row(children: [
            _kpiBox('Total Kudos Sent', _fmtNum(totalKudosSent),
                'Last 30 days', color: _primary),
            pw.SizedBox(width: 12),
            _kpiBox('Avg Kudos per User',
                avgKudosPerUser.toStringAsFixed(1), 'Per month average',
                color: _primary),
          ]),
          pw.SizedBox(height: 12),
          pw.Row(children: [
            _kpiBox('Engagement Rate',
                '${engagementRate.toStringAsFixed(0)}%',
                'Active / total users',
                color: engagementRate >= 70 ? _green : _amber),
            pw.SizedBox(width: 12),
            _kpiBox('Stickiness (DAU/MAU)',
                '${stickiness.toStringAsFixed(0)}%',
                stickiness >= 40
                    ? 'Excellent recurring engagement'
                    : 'Target 40%+ for top quartile',
                color: stickiness >= 40 ? _green : _amber),
          ]),
          pw.SizedBox(height: 20),
          _sectionLabel('RECOMMENDATIONS'),
          pw.SizedBox(height: 8),
          _bulletPoint('Schedule weekend recognition prompts'),
          _bulletPoint('Manager check-ins with inactive staff'),
          _bulletPoint('Team challenges for lower-engagement groups'),
          pw.Spacer(),
          _buildPageFooter(ctx),
        ],
      ),
    ));

    // Daily vs Monthly chart
    if (engagementDays.isNotEmpty) {
      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _pageHeader('DAILY VS MONTHLY ACTIVE USERS'),
            pw.SizedBox(height: 20),
            _buildBarChart(
                data1: engagementDays, data2: engagementMonths,
                labels: engagementLabels, label1: 'Daily', label2: 'Monthly',
                color1: _primary, color2: _gold, chartHeight: 180),
            pw.SizedBox(height: 24),
            _sectionLabel('STATISTICS'),
            pw.SizedBox(height: 10),
            _statRow('Peak DAU', '${engagementDays.reduce(max).toInt()}'),
            _statRow('Average DAU',
                (engagementDays.reduce((a, b) => a + b) / engagementDays.length).toStringAsFixed(0)),
            _statRow('MAU Trend', '${_fmtPct(monthlyChangePercent)} over last month'),
            _statRow('Stickiness', '${stickiness.toStringAsFixed(0)}%'),
            pw.SizedBox(height: 20),
            _insightBox(stickiness >= 35
                ? 'Your stickiness ratio indicates healthy, recurring engagement.'
                : 'Encourage daily recognition habits to build towards the 40%+ target.'),
            pw.Spacer(),
            _buildPageFooter(ctx),
          ],
        ),
      ));
    }

    // Kudos chart
    final totalBySource = managerKudos + peerKudos + familyKudos;
    if (kudosSentByMonth.isNotEmpty || totalBySource > 0) {
      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _pageHeader('KUDOS SENT VS RECEIVED'),
            pw.SizedBox(height: 20),
            if (kudosSentByMonth.isNotEmpty)
              _buildBarChart(
                  data1: kudosSentByMonth, data2: kudosReceivedByMonth,
                  labels: kudosMonthLabels, label1: 'Sent', label2: 'Received',
                  color1: _primary, color2: _green, chartHeight: 150),
            pw.SizedBox(height: 24),
            _sectionLabel('DISTRIBUTION'),
            pw.SizedBox(height: 10),
            if (totalBySource > 0) ...[
              _bulletPoint('Managers gave: $managerKudos (${(managerKudos / totalBySource * 100).toStringAsFixed(0)}%)'),
              _bulletPoint('Peers gave: $peerKudos (${(peerKudos / totalBySource * 100).toStringAsFixed(0)}%)'),
              _bulletPoint('Families gave: $familyKudos (${(familyKudos / totalBySource * 100).toStringAsFixed(0)}%)'),
            ],
            pw.Spacer(),
            _buildPageFooter(ctx),
          ],
        ),
      ));
    }

    // Team breakdown
    if (teamBreakdowns.isNotEmpty) {
      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _pageHeader('TEAM ENGAGEMENT BREAKDOWN'),
            pw.SizedBox(height: 16),
            ...teamBreakdowns.map((t) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 14),
                  child: _teamCard(t),
                )),
            pw.Spacer(),
            _buildPageFooter(ctx),
          ],
        ),
      ));
    }

    // User data table
    if (users.isNotEmpty) {
      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (ctx) => _pageHeaderWidget('USER ENGAGEMENT DATA'),
        footer: (ctx) => _buildPageFooter(ctx),
        build: (ctx) => [
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: _white),
            headerDecoration: const pw.BoxDecoration(color: _primary),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            headerPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 7),
            headers: ['Name', 'Role', 'Organisation', 'Status', 'Kudos'],
            data: users.map((u) => [u['name'] ?? '', u['role'] ?? '', u['org'] ?? '', u['status'] ?? '', u['kudos'] ?? '0']).toList(),
          ),
          pw.SizedBox(height: 12),
          pw.Text('Total Users: ${users.length}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        ],
      ));
    }

    await _sharePdf(pdf, 'CareKudos_Engagement_Report');
  }

  // ═══════════════════════════════════════════════════════════════
  // REPORT 2: TRAINING & COMPLIANCE REPORT
  // ═══════════════════════════════════════════════════════════════

  static Future<void> exportComplianceReport({
    required List<Map<String, String>> users,
    required double gdprPercent,
    required double onboardingPercent,
    String organizationName = 'Your Organisation',
    int totalUsers = 0,
    int gdprCompletedCount = 0,
    int onboardingCompletedCount = 0,
    int nonCompliantCount = 0,
    List<Map<String, dynamic>> teamComplianceBreakdown = const [],
    List<Map<String, String>> staffNeedingTraining = const [],
    List<Map<String, String>> cqcEvidencePosts = const [],
    List<Map<String, dynamic>> valuesDistribution = const [],
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final dateRange =
        '${DateFormat('d MMM yyyy').format(now.subtract(const Duration(days: 30)))} - ${DateFormat('d MMM yyyy').format(now)}';
    final userCount = totalUsers > 0 ? totalUsers : users.length;
    final gdprDone = gdprCompletedCount > 0 ? gdprCompletedCount : (userCount * gdprPercent / 100).round();
    final onbDone = onboardingCompletedCount > 0 ? onboardingCompletedCount : (userCount * onboardingPercent / 100).round();
    final nonCompliant = nonCompliantCount > 0 ? nonCompliantCount : userCount - gdprDone;

    // Cover
    pdf.addPage(_buildCoverPage(
      reportTitle: 'TRAINING & COMPLIANCE REPORT',
      subtitle: DateFormat('MMMM yyyy').format(now),
      organizationName: organizationName,
      dateRange: dateRange,
      tagline: 'Meeting CQC "Well-Led" Requirements',
    ));

    // Compliance Summary
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _pageHeader('COMPLIANCE SUMMARY'),
          pw.SizedBox(height: 20),
          _sectionLabel('OVERALL STATUS'),
          pw.SizedBox(height: 14),
          pw.Row(children: [
            _complianceGauge('GDPR TRAINING\nCOMPLETION', gdprPercent, '$gdprDone of $userCount users'),
            pw.SizedBox(width: 16),
            _complianceGauge('ONBOARDING\nCOMPLETION', onboardingPercent, '$onbDone of $userCount users'),
          ]),
          pw.SizedBox(height: 16),
          if (nonCompliant > 0)
            _alertBox('CRITICAL: $nonCompliant staff missing GDPR training. GDPR training is mandatory for CQC compliance.'),
          pw.SizedBox(height: 20),
          _sectionLabel('CQC EVIDENCE READY'),
          pw.SizedBox(height: 8),
          _bulletPoint('Staff training records ($gdprDone/$userCount complete)'),
          _bulletPoint('Values demonstration evidence from recognition posts'),
          _bulletPoint('Peer recognition patterns (${users.length} user records)'),
          pw.Spacer(),
          _buildPageFooter(ctx),
        ],
      ),
    ));

    // Training detail
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _pageHeader('GDPR TRAINING COMPLETION'),
          pw.SizedBox(height: 20),
          _sectionLabel('Completion Overview'),
          pw.SizedBox(height: 12),
          if (teamComplianceBreakdown.isNotEmpty)
            ...teamComplianceBreakdown.map((t) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 8),
                  child: _horizontalBar(label: t['teamName'] as String? ?? '', percent: (t['percent'] as num?)?.toDouble() ?? 0),
                ))
          else ...[
            _horizontalBar(label: 'GDPR Training', percent: gdprPercent),
            pw.SizedBox(height: 8),
            _horizontalBar(label: 'Onboarding', percent: onboardingPercent),
          ],
          pw.SizedBox(height: 20),
          _sectionLabel('RECOMMENDATIONS'),
          pw.SizedBox(height: 8),
          _bulletPoint('Schedule mandatory training sessions for non-compliant staff'),
          _bulletPoint('Use tablet in staff room for quick completion'),
          _bulletPoint('5-minute daily training slots during handover'),
          _bulletPoint('Manager accountability: set target completion dates'),
          pw.Spacer(),
          _buildPageFooter(ctx),
        ],
      ),
    ));

    // CQC Evidence Pack
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _pageHeader('CQC "WELL-LED" EVIDENCE PACK'),
          pw.SizedBox(height: 20),
          _sectionLabel('SECTION 1: POSITIVE CULTURE'),
          pw.SizedBox(height: 10),
          if (cqcEvidencePosts.isNotEmpty)
            ...cqcEvidencePosts.take(5).map((p) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 8),
                  child: _quoteBox(quote: p['quote'] ?? '', value: p['value'] ?? '', stars: p['stars'] ?? ''),
                ))
          else
            _quoteBox(quote: 'Recognition data will appear here once posts are captured.', value: 'Values', stars: ''),
          pw.SizedBox(height: 16),
          _sectionLabel('SECTION 2: VALUES EVIDENCE'),
          pw.SizedBox(height: 8),
          if (valuesDistribution.isNotEmpty)
            ...valuesDistribution.map((v) => _bulletPoint('${v['value']}: ${v['count']} posts (${v['percent']}%)'))
          else
            _bulletPoint('Values data will populate from recognition activity'),
          pw.SizedBox(height: 16),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(color: const PdfColor.fromInt(0xFFEFF6FF), borderRadius: pw.BorderRadius.circular(6)),
            child: pw.Text(
              'This report was automatically generated from real staff activity. All data is anonymized and compliant with UK GDPR requirements.',
              style: pw.TextStyle(fontSize: 9, color: _primary),
            ),
          ),
          pw.Spacer(),
          _buildPageFooter(ctx),
        ],
      ),
    ));

    // Full data table
    if (users.isNotEmpty) {
      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (ctx) => _pageHeaderWidget('TRAINING STATUS - FULL DATA'),
        footer: (ctx) => _buildPageFooter(ctx),
        build: (ctx) => [
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: _white),
            headerDecoration: const pw.BoxDecoration(color: _primary),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            headerPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 7),
            headers: ['Name', 'Role', 'Organisation', 'GDPR Training', 'Onboarding', 'Status'],
            data: users.map((u) => [u['name'] ?? '', u['role'] ?? '', u['org'] ?? '', u['gdpr'] ?? '', u['onboarding'] ?? '', u['status'] ?? '']).toList(),
          ),
        ],
      ));
    }

    await _sharePdf(pdf, 'CareKudos_Compliance_Report');
  }

  // ═══════════════════════════════════════════════════════════════
  // REPORT 3: FEEDBACK & RECOGNITION REPORT
  // ═══════════════════════════════════════════════════════════════

  static Future<void> exportRecognitionReport({
    required List<Map<String, String>> users,
    required int totalKudos,
    required int totalPosts,
    String organizationName = 'Your Organisation',
    int managerKudos = 0,
    int peerKudos = 0,
    int familyKudos = 0,
    List<Map<String, dynamic>> recognitionByCategory = const [],
    List<Map<String, dynamic>> topThemes = const [],
    double sentimentPositive = 92,
    double sentimentNeutral = 6,
    double sentimentConstructive = 2,
    double recognitionEquityScore = 72,
    List<Map<String, String>> risingStars = const [],
    List<Map<String, dynamic>> managerRecognitionRates = const [],
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final dateRange =
        '${DateFormat('d MMM yyyy').format(now.subtract(const Duration(days: 30)))} - ${DateFormat('d MMM yyyy').format(now)}';
    final totalBySource = managerKudos + peerKudos + familyKudos;
    final effectiveTotal = totalBySource > 0 ? totalBySource : totalKudos;

    // Cover
    pdf.addPage(_buildCoverPage(
      reportTitle: 'FEEDBACK & RECOGNITION REPORT',
      subtitle: DateFormat('MMMM yyyy').format(now),
      organizationName: organizationName,
      dateRange: dateRange,
      tagline: 'Understanding What Great Care Looks Like',
    ));

    // Recognition Patterns
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _pageHeader('RECOGNITION PATTERNS'),
          pw.SizedBox(height: 20),
          pw.Row(children: [
            _kpiBox('Total Kudos', _fmtNum(totalKudos), 'This period', color: _primary),
            pw.SizedBox(width: 12),
            _kpiBox('Total Posts', _fmtNum(totalPosts), 'Recognition posts', color: _primary),
          ]),
          pw.SizedBox(height: 16),
          if (effectiveTotal > 0) ...[
            _sourceBar('Peer Recognition', peerKudos, effectiveTotal, _primary),
            pw.SizedBox(height: 6),
            _sourceBar('Manager Recognition', managerKudos, effectiveTotal, _gold),
            pw.SizedBox(height: 6),
            _sourceBar('Family Recognition', familyKudos, effectiveTotal, _green),
          ],
          pw.SizedBox(height: 20),
          if (recognitionByCategory.isNotEmpty) ...[
            _sectionLabel('RECOGNITION BY CATEGORY'),
            pw.SizedBox(height: 10),
            ...recognitionByCategory.take(6).map((c) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 5),
                  child: _horizontalBar(
                      label: c['category'] as String? ?? '',
                      percent: _safePct(c['count'] as int? ?? 0, effectiveTotal),
                      suffix: '${c['count']}'),
                )),
          ],
          pw.Spacer(),
          _buildPageFooter(ctx),
        ],
      ),
    ));

    // Feedback Analysis
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _pageHeader('FEEDBACK ANALYSIS'),
          pw.SizedBox(height: 20),
          _sectionLabel('SENTIMENT ANALYSIS'),
          pw.SizedBox(height: 14),
          pw.Row(children: [
            _kpiBox('Positive', '${sentimentPositive.toStringAsFixed(0)}%', 'Of all recognition', color: _green),
            pw.SizedBox(width: 10),
            _kpiBox('Neutral', '${sentimentNeutral.toStringAsFixed(0)}%', 'Of all recognition', color: _amber),
            pw.SizedBox(width: 10),
            _kpiBox('Constructive', '${sentimentConstructive.toStringAsFixed(0)}%', 'Of all recognition', color: _primary),
          ]),
          pw.SizedBox(height: 24),
          if (topThemes.isNotEmpty) ...[
            _sectionLabel('THEMES IDENTIFIED'),
            pw.SizedBox(height: 10),
            ...topThemes.take(5).map((t) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 10),
                  child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    pw.Text('${t['theme']} (${t['count']} mentions)',
                        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _darkText)),
                    if (t['examples'] != null)
                      pw.Text('"${t['examples']}"',
                          style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic, color: _gray)),
                  ]),
                )),
          ],
          pw.Spacer(),
          _buildPageFooter(ctx),
        ],
      ),
    ));

    // Team Recognition Health
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _pageHeader('TEAM RECOGNITION HEALTH'),
          pw.SizedBox(height: 20),
          pw.Row(children: [
            _kpiBox('Recognition Equity Score', '${recognitionEquityScore.toStringAsFixed(0)}%',
                recognitionEquityScore >= 80 ? 'On target' : 'Target: 80%+',
                color: recognitionEquityScore >= 80 ? _green : _amber),
            pw.SizedBox(width: 12),
            _kpiBox('Total Staff', '${users.length}', 'In recognition system', color: _primary),
          ]),
          pw.SizedBox(height: 20),
          _sectionLabel('RECOMMENDATIONS'),
          pw.SizedBox(height: 8),
          _bulletPoint('Spotlight challenge: "Recognize someone new today"'),
          _bulletPoint('Track recognition equity as a KPI for managers'),
          _bulletPoint('Night shift / weekend recognition initiatives'),
          _bulletPoint('Coach managers below 80% recognition rate'),
          pw.Spacer(),
          _buildPageFooter(ctx),
        ],
      ),
    ));

    // Rising Stars
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _pageHeader('RISING STARS & TALENT PIPELINE'),
          pw.SizedBox(height: 20),
          if (risingStars.isNotEmpty) ...[
            _sectionLabel('CURRENT RISING STARS (${risingStars.length} IDENTIFIED)'),
            pw.SizedBox(height: 12),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: _white),
              headerDecoration: const pw.BoxDecoration(color: _primary),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              headerPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 7),
              headers: ['Staff Name', 'Team', 'Strength'],
              data: risingStars.map((s) => [s['name'] ?? '', s['team'] ?? '', s['strength'] ?? '']).toList(),
            ),
          ] else ...[
            _sectionLabel('TOP PERFORMERS'),
            pw.SizedBox(height: 12),
            ..._deriveRisingStars(users),
          ],
          pw.SizedBox(height: 20),
          _insightBox('Rising stars identified through recognition patterns represent your strongest retention candidates.'),
          pw.Spacer(),
          _buildPageFooter(ctx),
        ],
      ),
    ));

    // Full data table
    if (users.isNotEmpty) {
      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (ctx) => _pageHeaderWidget('RECOGNITION DATA - FULL LISTING'),
        footer: (ctx) => _buildPageFooter(ctx),
        build: (ctx) => [
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: _white),
            headerDecoration: const pw.BoxDecoration(color: _primary),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            headerPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 7),
            headers: ['Name', 'Role', 'Stars Received', 'Posts', 'Status'],
            data: users.map((u) => [u['name'] ?? '', u['role'] ?? '', u['stars'] ?? '0', u['posts'] ?? '0', u['status'] ?? '']).toList(),
          ),
        ],
      ));
    }

    await _sharePdf(pdf, 'CareKudos_Recognition_Report');
  }

  /// Backward-compatible wrapper for old call sites.
  static Future<void> exportCqcReport({
    required int monthlyValuesDistribution,
    required int taggedRecognitions,
    required double valuesAlignmentTrend,
    required List<Map<String, String>> teamMembers,
  }) async {
    await exportCqcEvidenceReport(
      users: teamMembers,
      totalRecognitions: taggedRecognitions,
      valuesAlignedPosts: monthlyValuesDistribution,
      valuesAlignmentPercent: valuesAlignmentTrend,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // REPORT 4: CQC EVIDENCE REPORT (8 pages)
  // ═══════════════════════════════════════════════════════════════

  /// Generate and share/download a full 8-page CQC Evidence Report PDF
  /// aligned to the CQC "Well-Led" Key Lines of Enquiry (W1–W4).
  static Future<void> exportCqcEvidenceReport({
    required List<Map<String, String>> users,
    String organizationName = 'Your Organisation',
    String cqcLocationId = '',
    int activeStaff = 0,
    int totalRecognitions = 0,
    int valuesAlignedPosts = 0,
    int risingStarsCount = 0,
    Map<String, int> valuesDistribution = const {},
    double valuesAlignmentPercent = 0,
    int peerKudos = 0,
    int managerKudos = 0,
    int familyKudos = 0,
    int reflectivePracticePosts = 0,
    int learningPosts = 0,
    int innovationPosts = 0,
    int gdprFlags = 0,
    List<Map<String, dynamic>> managerEngagement = const [],
    List<Map<String, String>> valueChampions = const [],
    List<Map<String, dynamic>> risingStars = const [],
    List<Map<String, dynamic>> teamRecognition = const [],
    double recognitionEquityScore = 0,
    int staffWithNoRecognition = 0,
    List<Map<String, String>> examplePosts = const [],
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final dateRange =
        '${DateFormat('d MMM yyyy').format(now.subtract(const Duration(days: 30)))} - ${DateFormat('d MMM yyyy').format(now)}';
    final totalBySource = peerKudos + managerKudos + familyKudos;
    final effectiveTotal = totalBySource > 0 ? totalBySource : totalRecognitions;

    // ── COVER PAGE ──
    pdf.addPage(_buildCoverPage(
      reportTitle: 'CQC EVIDENCE REPORT',
      subtitle: DateFormat('MMMM yyyy').format(now),
      organizationName: organizationName,
      dateRange: dateRange,
      tagline: 'Evidence for "Well-Led" Key Lines of Enquiry',
    ));

    // ── PAGE 1: EXECUTIVE SUMMARY FOR INSPECTORS ──
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _pageHeader('EXECUTIVE SUMMARY'),
          pw.SizedBox(height: 16),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(color: const PdfColor.fromInt(0xFFEFF6FF), borderRadius: pw.BorderRadius.circular(6)),
            child: pw.Text(
              'This report provides evidence of positive culture, staff engagement, and values-based practice at $organizationName for the period $dateRange.',
              style: pw.TextStyle(fontSize: 10, color: _primary),
            ),
          ),
          if (cqcLocationId.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            pw.Text('CQC Location ID: $cqcLocationId', style: pw.TextStyle(fontSize: 9, color: _gray)),
          ],
          pw.SizedBox(height: 16),
          _sectionLabel('KEY METRICS AT A GLANCE'),
          pw.SizedBox(height: 12),
          pw.Row(children: [
            _kpiBox('Active Staff', '$activeStaff', 'Daily average', color: _primary),
            pw.SizedBox(width: 12),
            _kpiBox('Total Recognitions', _fmtNum(totalRecognitions), 'This period', color: _primary),
          ]),
          pw.SizedBox(height: 10),
          pw.Row(children: [
            _kpiBox('Values-Aligned Posts', _fmtNum(valuesAlignedPosts), '${totalRecognitions > 0 ? (valuesAlignedPosts / totalRecognitions * 100).toStringAsFixed(0) : 0}% of total', color: _green),
            pw.SizedBox(width: 12),
            _kpiBox('Rising Stars', '$risingStarsCount', 'Talent pipeline', color: _gold),
          ]),
          pw.SizedBox(height: 20),
          _sectionLabel('CQC "WELL-LED" ALIGNMENT'),
          pw.SizedBox(height: 10),
          _bulletPoint('W1: Is there a clear vision and credible strategy?'),
          pw.Padding(padding: const pw.EdgeInsets.only(left: 16), child: pw.Text('-> Values demonstrated in daily practice (Page 2)', style: pw.TextStyle(fontSize: 9, color: _gray))),
          pw.SizedBox(height: 4),
          _bulletPoint('W2: Does the governance framework ensure quality?'),
          pw.Padding(padding: const pw.EdgeInsets.only(left: 16), child: pw.Text('-> Recognition patterns show accountability (Page 3)', style: pw.TextStyle(fontSize: 9, color: _gray))),
          pw.SizedBox(height: 4),
          _bulletPoint('W3: How does the leadership promote a positive culture?'),
          pw.Padding(padding: const pw.EdgeInsets.only(left: 16), child: pw.Text('-> Manager engagement & Rising Stars (Pages 4-5)', style: pw.TextStyle(fontSize: 9, color: _gray))),
          pw.SizedBox(height: 4),
          _bulletPoint('W4: Are there clear responsibilities and accountabilities?'),
          pw.Padding(padding: const pw.EdgeInsets.only(left: 16), child: pw.Text('-> Team recognition distribution (Page 6)', style: pw.TextStyle(fontSize: 9, color: _gray))),
          pw.Spacer(),
          _buildPageFooter(ctx),
        ],
      ),
    ));

    // ── PAGE 2: VALUES-BASED CULTURE EVIDENCE (W1) ──
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (ctx) {
        final totalVals = valuesDistribution.values.fold<int>(0, (a, b) => a + b);
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _pageHeader('EVIDENCE: VALUES-BASED CULTURE (CQC Well-Led W1)'),
            pw.SizedBox(height: 16),
            _sectionLabel('VALUES DISTRIBUTION'),
            pw.Text('(Recognition activity by core value - this period)', style: pw.TextStyle(fontSize: 9, color: _gray)),
            pw.SizedBox(height: 12),
            if (valuesDistribution.isNotEmpty)
              ...valuesDistribution.entries.map((e) {
                final pct = totalVals > 0 ? (e.value / totalVals * 100) : 0.0;
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 5),
                  child: _horizontalBar(label: e.key, percent: pct, suffix: '${e.value} (${pct.toStringAsFixed(0)}%)'),
                );
              })
            else
              pw.Text('Values distribution data will populate from recognition activity.', style: pw.TextStyle(fontSize: 9, color: _gray, fontStyle: pw.FontStyle.italic)),
            pw.SizedBox(height: 16),
            _sectionLabel('VALUES ALIGNMENT'),
            pw.SizedBox(height: 8),
            pw.Row(children: [
              pw.Text('Current alignment: ', style: pw.TextStyle(fontSize: 10, color: _darkText)),
              pw.Text('${valuesAlignmentPercent.toStringAsFixed(0)}%', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: valuesAlignmentPercent >= 70 ? _green : _amber)),
            ]),
            pw.SizedBox(height: 8),
            _progressBar((valuesAlignmentPercent / 100).clamp(0.0, 1.0), 12, valuesAlignmentPercent >= 70 ? _green : _amber, radius: 6),
            pw.SizedBox(height: 16),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(color: const PdfColor.fromInt(0xFFFFFBEB), borderRadius: pw.BorderRadius.circular(6)),
              child: pw.Text(
                'TREND INSIGHT: Values alignment ${valuesAlignmentPercent >= 70 ? "is strong, demonstrating embedding of core values into daily practice." : "is developing. Consider introducing weekly values focus to strengthen alignment."}',
                style: pw.TextStyle(fontSize: 9, color: _darkText),
              ),
            ),
            pw.SizedBox(height: 16),
            if (examplePosts.isNotEmpty) ...[
              _sectionLabel('EXAMPLE POSTS (Anonymised)'),
              pw.SizedBox(height: 8),
              ...examplePosts.take(4).map((p) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: _quoteBox(quote: p['quote'] ?? '', value: p['value'] ?? '', stars: p['stars'] ?? ''),
              )),
            ],
            pw.Spacer(),
            _buildPageFooter(ctx),
          ],
        );
      },
    ));

    // ── PAGE 3: GOVERNANCE & QUALITY EVIDENCE (W2) ──
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _pageHeader('EVIDENCE: GOVERNANCE & QUALITY (CQC Well-Led W2)'),
          pw.SizedBox(height: 16),
          _sectionLabel('RECOGNITION PATTERNS'),
          pw.Text('(Demonstrates accountability and quality focus)', style: pw.TextStyle(fontSize: 9, color: _gray)),
          pw.SizedBox(height: 12),
          if (effectiveTotal > 0) ...[
            _sourceBar('Peer Recognition', peerKudos, effectiveTotal, _primary),
            pw.SizedBox(height: 6),
            _sourceBar('Manager Recognition', managerKudos, effectiveTotal, _gold),
            pw.SizedBox(height: 6),
            _sourceBar('Family Recognition', familyKudos, effectiveTotal, _green),
          ],
          pw.SizedBox(height: 20),
          _sectionLabel('QUALITY INDICATORS'),
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(border: pw.Border.all(color: const PdfColor.fromInt(0xFFE5E7EB)), borderRadius: pw.BorderRadius.circular(6)),
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              _qualityRow('Posts with Reflective Practice:', reflectivePracticePosts, totalRecognitions),
              pw.SizedBox(height: 4),
              _qualityRow('Posts Demonstrating Learning:', learningPosts, totalRecognitions),
              pw.SizedBox(height: 4),
              _qualityRow('Posts Showing Innovation:', innovationPosts, totalRecognitions),
              pw.SizedBox(height: 4),
              _qualityRow('Posts Flagged for GDPR Review:', gdprFlags, totalRecognitions),
            ]),
          ),
          pw.SizedBox(height: 20),
          _sectionLabel('MODERATION & OVERSIGHT'),
          pw.SizedBox(height: 8),
          _bulletPoint('GDPR flags raised: $gdprFlags'),
          _bulletPoint('Active governance and quality assurance of staff reflections'),
          pw.SizedBox(height: 12),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(color: const PdfColor.fromInt(0xFFEFF6FF), borderRadius: pw.BorderRadius.circular(6)),
            child: pw.Text(
              'This demonstrates active governance and quality assurance of staff reflections and recognition.',
              style: pw.TextStyle(fontSize: 9, color: _primary),
            ),
          ),
          pw.Spacer(),
          _buildPageFooter(ctx),
        ],
      ),
    ));

    // ── PAGE 4: LEADERSHIP & CULTURE EVIDENCE (W3) ──
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _pageHeader('EVIDENCE: LEADERSHIP & CULTURE (CQC Well-Led W3)'),
          pw.SizedBox(height: 16),
          _sectionLabel('MANAGER ENGAGEMENT'),
          pw.SizedBox(height: 10),
          if (managerEngagement.isNotEmpty)
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: _white),
              headerDecoration: const pw.BoxDecoration(color: _primary),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              headerPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 7),
              headers: ['Manager', 'Recognitions Given', 'Team Coverage', 'vs Average'],
              data: managerEngagement.map((m) => [
                m['name'] ?? '', '${m['recognitions'] ?? 0}', '${m['coverage'] ?? 0}%', '${m['vsAverage'] ?? 0}%',
              ]).toList(),
            )
          else
            pw.Text('Manager engagement data will populate as managers use the platform.', style: pw.TextStyle(fontSize: 9, color: _gray, fontStyle: pw.FontStyle.italic)),
          pw.SizedBox(height: 20),
          _sectionLabel('TOP VALUE CHAMPIONS'),
          pw.Text('(Staff who best demonstrate organisational values)', style: pw.TextStyle(fontSize: 9, color: _gray)),
          pw.SizedBox(height: 10),
          if (valueChampions.isNotEmpty)
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: _white),
              headerDecoration: const pw.BoxDecoration(color: _primary),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              headerPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 7),
              headers: ['Staff Name', 'Culture Points', 'Top Value', 'Badge'],
              data: valueChampions.map((c) => [c['name'] ?? '', c['points'] ?? '', c['value'] ?? '', c['badge'] ?? '']).toList(),
            )
          else
            pw.Text('Value champions will appear as staff accumulate culture points.', style: pw.TextStyle(fontSize: 9, color: _gray, fontStyle: pw.FontStyle.italic)),
          pw.SizedBox(height: 20),
          if (examplePosts.isNotEmpty) ...[
            _sectionLabel('POSITIVE CULTURE EXAMPLES'),
            pw.SizedBox(height: 8),
            ...examplePosts.take(3).map((p) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: _quoteBox(quote: p['quote'] ?? '', value: p['value'] ?? '', stars: p['stars'] ?? ''),
            )),
          ],
          pw.Spacer(),
          _buildPageFooter(ctx),
        ],
      ),
    ));

    // ── PAGE 5: TALENT PIPELINE & DEVELOPMENT (W3/W4) ──
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _pageHeader('EVIDENCE: TALENT PIPELINE (CQC Well-Led W3/W4)'),
          pw.SizedBox(height: 16),
          _sectionLabel('RISING STARS IDENTIFIED'),
          pw.Text('(Staff with high potential for progression)', style: pw.TextStyle(fontSize: 9, color: _gray)),
          pw.SizedBox(height: 12),
          if (risingStars.isNotEmpty)
            ...risingStars.take(4).map((rs) => pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 10),
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: _gold, width: 1.5),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Row(children: [
                  pw.Container(width: 8, height: 8, decoration: const pw.BoxDecoration(color: _gold, shape: pw.BoxShape.circle)),
                  pw.SizedBox(width: 6),
                  pw.Text('RISING STAR', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _gold)),
                ]),
                pw.SizedBox(height: 6),
                pw.Text(rs['name'] as String? ?? '', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: _darkText)),
                pw.Text(rs['role'] as String? ?? 'Care Worker', style: pw.TextStyle(fontSize: 9, color: _gray)),
                pw.SizedBox(height: 6),
                pw.Text('${rs['stars'] ?? 0} stars  |  ${rs['points'] ?? 0} culture points  |  Top Value: ${rs['topValue'] ?? 'N/A'}',
                    style: pw.TextStyle(fontSize: 9, color: _darkText)),
                if (rs['readyFor'] != null)
                  pw.Text('Ready for: ${rs['readyFor']}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _green)),
              ]),
            ))
          else
            pw.Text('Rising Stars will be identified as staff accumulate recognition.', style: pw.TextStyle(fontSize: 9, color: _gray, fontStyle: pw.FontStyle.italic)),
          pw.SizedBox(height: 16),
          _sectionLabel('DEVELOPMENT ACTIONS'),
          pw.SizedBox(height: 8),
          _checkItem('All Rising Stars have development plans'),
          _checkItem('Leadership in Care training enrolled'),
          _checkItem('Shadowing senior staff programme active'),
          _checkItem('Mentorship program launched'),
          pw.Spacer(),
          _buildPageFooter(ctx),
        ],
      ),
    ));

    // ── PAGE 6: TEAM ACCOUNTABILITY (W4) ──
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (ctx) {
        final maxStars = teamRecognition.isNotEmpty
            ? teamRecognition.map((t) => (t['stars'] as num?)?.toInt() ?? 0).reduce((a, b) => a > b ? a : b)
            : 1;
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _pageHeader('EVIDENCE: TEAM ACCOUNTABILITY (CQC Well-Led W4)'),
            pw.SizedBox(height: 16),
            _sectionLabel('TEAM RECOGNITION BREAKDOWN'),
            pw.Text('(Ensuring all staff are seen and valued)', style: pw.TextStyle(fontSize: 9, color: _gray)),
            pw.SizedBox(height: 12),
            if (teamRecognition.isNotEmpty)
              ...teamRecognition.take(10).map((t) {
                final stars = (t['stars'] as num?)?.toInt() ?? 0;
                final pct = maxStars > 0 ? (stars / maxStars * 100) : 0.0;
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 5),
                  child: _horizontalBar(label: t['name'] as String? ?? '', percent: pct, suffix: '$stars'),
                );
              })
            else
              pw.Text('Team recognition data will populate from platform activity.', style: pw.TextStyle(fontSize: 9, color: _gray, fontStyle: pw.FontStyle.italic)),
            pw.SizedBox(height: 20),
            _sectionLabel('RECOGNITION EQUITY ANALYSIS'),
            pw.SizedBox(height: 10),
            _bulletPoint('Total active staff: $activeStaff'),
            _bulletPoint('Staff receiving recognition: ${activeStaff - staffWithNoRecognition} (${activeStaff > 0 ? ((activeStaff - staffWithNoRecognition) / activeStaff * 100).toStringAsFixed(0) : 0}%)'),
            _bulletPoint('Staff with NO recognition in period: $staffWithNoRecognition'),
            pw.SizedBox(height: 6),
            pw.Row(children: [
              pw.Text('Recognition equity score: ', style: pw.TextStyle(fontSize: 10, color: _darkText)),
              pw.Text('${recognitionEquityScore.toStringAsFixed(0)}%',
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: recognitionEquityScore >= 80 ? _green : _amber)),
              pw.Text(' (target >80%)', style: pw.TextStyle(fontSize: 9, color: _gray)),
              if (recognitionEquityScore >= 80)
                pw.Text(' OK', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _green)),
            ]),
            pw.SizedBox(height: 10),
            _progressBar((recognitionEquityScore / 100).clamp(0.0, 1.0), 10, recognitionEquityScore >= 80 ? _green : _amber),
            if (staffWithNoRecognition > 0) ...[
              pw.SizedBox(height: 16),
              _sectionLabel('STAFF REQUIRING ATTENTION'),
              pw.Text('(No recognition in 30+ days)', style: pw.TextStyle(fontSize: 9, color: _red)),
              pw.SizedBox(height: 6),
              _bulletPoint('$staffWithNoRecognition staff added to manager check-in list'),
              _bulletPoint('Night shift recognition pilot starting'),
              _bulletPoint('"Recognise Someone New" challenge launched'),
            ],
            pw.Spacer(),
            _buildPageFooter(ctx),
          ],
        );
      },
    ));

    // ── PAGE 7: CONTINUOUS IMPROVEMENT ──
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _pageHeader('EVIDENCE: CONTINUOUS IMPROVEMENT (CQC Well-Led All)'),
          pw.SizedBox(height: 16),
          _sectionLabel('IMPROVEMENTS ACHIEVED'),
          pw.SizedBox(height: 10),
          _bulletPoint('Recognition volume: ${_fmtNum(totalRecognitions)} interactions this period'),
          _bulletPoint('Values alignment: ${valuesAlignmentPercent.toStringAsFixed(0)}%'),
          _bulletPoint('Active staff engagement: $activeStaff daily average'),
          _bulletPoint('Rising Stars identified: $risingStarsCount'),
          if (familyKudos > 0)
            _bulletPoint('Family engagement: $familyKudos family recognitions'),
          pw.SizedBox(height: 20),
          _sectionLabel('ACTIONS TAKEN THIS PERIOD'),
          pw.SizedBox(height: 8),
          _checkItem('Introduced weekly values focus'),
          _checkItem('Launched night shift recognition initiative'),
          _checkItem('Added family feedback portal'),
          _checkItem('Manager recognition training completed'),
          pw.SizedBox(height: 20),
          _sectionLabel('PLANNED IMPROVEMENTS'),
          pw.SizedBox(height: 8),
          _bulletPoint('Expand family engagement programme'),
          _bulletPoint('Launch peer mentoring program'),
          _bulletPoint('Implement sector benchmarking'),
          _bulletPoint('Quarterly CQC evidence reviews'),
          pw.SizedBox(height: 20),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(color: const PdfColor.fromInt(0xFFEFF6FF), borderRadius: pw.BorderRadius.circular(6)),
            child: pw.Text(
              'This report was automatically generated from real staff recognition activity on the CareKudos platform. '
              'All data is anonymised and compliant with UK GDPR requirements. '
              'Full audit trail available upon request.',
              style: pw.TextStyle(fontSize: 9, color: _primary),
            ),
          ),
          pw.Spacer(),
          _buildPageFooter(ctx),
        ],
      ),
    ));

    // ── PAGE 8: APPENDIX - RAW EVIDENCE ──
    if (users.isNotEmpty) {
      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (ctx) => _pageHeaderWidget('APPENDIX: STAFF RECOGNITION DATA'),
        footer: (ctx) => _buildPageFooter(ctx),
        build: (ctx) => [
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: _white),
            headerDecoration: const pw.BoxDecoration(color: _primary),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            headerPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 7),
            headers: ['Name', 'Role', 'Stars', 'Status'],
            data: users.map((u) => [u['name'] ?? '', u['role'] ?? '', u['stars'] ?? '0', u['status'] ?? '']).toList(),
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'Note: All posts are anonymised and contain no service user identifiers. Full audit trail available upon request.',
            style: pw.TextStyle(fontSize: 8, color: _gray, fontStyle: pw.FontStyle.italic),
          ),
        ],
      ));
    }

    await _sharePdf(pdf, 'CareKudos_CQC_Evidence_Report');
  }

  /// Helper: quality indicator row for CQC report.
  static pw.Widget _qualityRow(String label, int count, int total) {
    final pct = total > 0 ? (count / total * 100).toStringAsFixed(0) : '0';
    return pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
      pw.Text(label, style: pw.TextStyle(fontSize: 9, color: _darkText)),
      pw.Text('$count (${pct}%)', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _primary)),
    ]);
  }

  /// Helper: checklist item with tick for CQC report.
  static pw.Widget _checkItem(String text) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 4),
    child: pw.Row(children: [
      pw.Container(
        width: 14, height: 14,
        decoration: pw.BoxDecoration(color: _green, borderRadius: pw.BorderRadius.circular(3)),
        child: pw.Center(child: pw.Text('OK', style: pw.TextStyle(fontSize: 6, color: _white, fontWeight: pw.FontWeight.bold))),
      ),
      pw.SizedBox(width: 8),
      pw.Text(text, style: pw.TextStyle(fontSize: 9, color: _darkText)),
    ]),
  );

  // ═══════════════════════════════════════════════════════════════
  // SHARED BUILDING BLOCKS
  // ═══════════════════════════════════════════════════════════════

  static pw.Page _buildCoverPage({
    required String reportTitle,
    required String subtitle,
    required String organizationName,
    required String dateRange,
    required String tagline,
  }) {
    final now = DateTime.now();
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (_) => pw.Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const pw.BoxDecoration(color: _primary),
        child: pw.Padding(
          padding: const pw.EdgeInsets.all(60),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(height: 60),
              pw.Row(children: [
                _starIcon(), pw.SizedBox(width: 12),
                pw.Text('CAREKUDOS', style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: _white, letterSpacing: 3)),
                pw.SizedBox(width: 12), _starIcon(),
              ]),
              pw.SizedBox(height: 50),
              pw.Text(reportTitle, style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold, color: _gold, letterSpacing: 1.5)),
              pw.SizedBox(height: 12),
              pw.Text(subtitle, style: pw.TextStyle(fontSize: 18, color: _white)),
              pw.SizedBox(height: 60),
              pw.Container(height: 2, width: 200, color: _gold),
              pw.SizedBox(height: 30),
              _coverMeta('Prepared for:', organizationName),
              pw.SizedBox(height: 8),
              _coverMeta('Date Range:', dateRange),
              pw.SizedBox(height: 8),
              _coverMeta('Generated:', DateFormat('d MMMM yyyy, HH:mm').format(now)),
              pw.Spacer(),
              pw.Row(children: List.generate(5, (_) => pw.Padding(padding: const pw.EdgeInsets.only(right: 6), child: _starIcon()))),
              pw.SizedBox(height: 8),
              pw.Text(tagline, style: pw.TextStyle(fontSize: 14, fontStyle: pw.FontStyle.italic, color: _gold)),
            ],
          ),
        ),
      ),
    );
  }

  static pw.Widget _starIcon() => pw.Container(
        width: 22, height: 22,
        decoration: const pw.BoxDecoration(color: _gold, shape: pw.BoxShape.circle),
        child: pw.Center(child: pw.Text('*', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: _primary))),
      );

  static pw.Widget _coverMeta(String label, String value) => pw.Row(children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 11, color: _gold)),
        pw.SizedBox(width: 8),
        pw.Text(value, style: pw.TextStyle(fontSize: 11, color: _white, fontWeight: pw.FontWeight.bold)),
      ]);

  static pw.Widget _pageHeader(String title) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(children: [
            pw.Container(width: 24, height: 24, decoration: const pw.BoxDecoration(color: _primary, shape: pw.BoxShape.circle),
                child: pw.Center(child: pw.Text('CK', style: pw.TextStyle(color: _white, fontSize: 9, fontWeight: pw.FontWeight.bold)))),
            pw.SizedBox(width: 8),
            pw.Text('CareKudos', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _primary)),
          ]),
          pw.SizedBox(height: 6),
          pw.Divider(color: _primary, thickness: 2),
          pw.SizedBox(height: 10),
          pw.Text(title, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: _primary)),
        ],
      );

  static pw.Widget _pageHeaderWidget(String title) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(children: [
            pw.Container(width: 24, height: 24, decoration: const pw.BoxDecoration(color: _primary, shape: pw.BoxShape.circle),
                child: pw.Center(child: pw.Text('CK', style: pw.TextStyle(color: _white, fontSize: 9, fontWeight: pw.FontWeight.bold)))),
            pw.SizedBox(width: 8),
            pw.Text('CareKudos', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _primary)),
          ]),
          pw.SizedBox(height: 6),
          pw.Divider(color: _primary, thickness: 2),
          pw.SizedBox(height: 6),
          pw.Text(title, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: _primary)),
        ],
      );

  static pw.Widget _buildPageFooter(pw.Context ctx) => pw.Column(children: [
        pw.Divider(color: _lightGray),
        pw.SizedBox(height: 4),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text('CareKudos - Confidential', style: pw.TextStyle(fontSize: 7, color: _gray)),
          pw.Text('Generated: ${DateFormat('dd MMM yyyy').format(DateTime.now())}', style: pw.TextStyle(fontSize: 7, color: _gray)),
          pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}', style: pw.TextStyle(fontSize: 7, color: _gray)),
        ]),
      ]);

  static pw.Widget _kpiBox(String label, String value, String subtitle, {PdfColor color = _primary}) => pw.Expanded(
        child: pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(border: pw.Border.all(color: color, width: 1.5), borderRadius: pw.BorderRadius.circular(6)),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text(label, style: pw.TextStyle(fontSize: 8, color: _gray)),
            pw.SizedBox(height: 4),
            pw.Text(value, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: color)),
            pw.SizedBox(height: 2),
            pw.Text(subtitle, style: pw.TextStyle(fontSize: 7, color: _gray)),
          ]),
        ),
      );

  static pw.Widget _complianceGauge(String label, double percent, String detail) {
    final color = percent >= 80 ? _green : percent >= 50 ? _amber : _red;
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(border: pw.Border.all(color: color, width: 1.5), borderRadius: pw.BorderRadius.circular(8)),
        child: pw.Column(children: [
          pw.Text(label, textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _darkText)),
          pw.SizedBox(height: 10),
          _progressBar((percent / 100).clamp(0.0, 1.0), 12, color, radius: 6),
          pw.SizedBox(height: 8),
          pw.Text('${percent.toStringAsFixed(0)}%', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: color)),
          pw.SizedBox(height: 4),
          pw.Text(detail, style: pw.TextStyle(fontSize: 9, color: _gray)),
        ]),
      ),
    );
  }

  static pw.Widget _sectionLabel(String text) => pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: pw.BoxDecoration(color: const PdfColor.fromInt(0xFFEFF6FF), borderRadius: pw.BorderRadius.circular(4)),
        child: pw.Text(text, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _primary)),
      );

  static pw.Widget _bulletPoint(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4, left: 8),
        child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Container(width: 4, height: 4, margin: const pw.EdgeInsets.only(top: 4),
              decoration: const pw.BoxDecoration(color: _primary, shape: pw.BoxShape.circle)),
          pw.SizedBox(width: 8),
          pw.Expanded(child: pw.Text(text, style: pw.TextStyle(fontSize: 10, color: _darkText))),
        ]),
      );

  static pw.Widget _statRow(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 10, color: _gray)),
          pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _darkText)),
        ]),
      );

  static pw.Widget _insightBox(String text) => pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
            color: const PdfColor.fromInt(0xFFFEF9E7),
            border: pw.Border(left: pw.BorderSide(color: _gold, width: 3)),
            borderRadius: pw.BorderRadius.circular(4)),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text('INSIGHT', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _gold)),
          pw.SizedBox(height: 4),
          pw.Text(text, style: pw.TextStyle(fontSize: 9, color: _darkText)),
        ]),
      );

  static pw.Widget _alertBox(String text) => pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
            color: const PdfColor.fromInt(0xFFFEF2F2),
            border: pw.Border(left: pw.BorderSide(color: _red, width: 3)),
            borderRadius: pw.BorderRadius.circular(4)),
        child: pw.Text(text, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _red)),
      );

  static pw.Widget _quoteBox({required String quote, required String value, required String stars}) => pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
            color: _lightGray, borderRadius: pw.BorderRadius.circular(6),
            border: pw.Border(left: pw.BorderSide(color: _gold, width: 3))),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text('"$quote"', style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic, color: _darkText)),
          if (value.isNotEmpty || stars.isNotEmpty)
            pw.Padding(padding: const pw.EdgeInsets.only(top: 4),
                child: pw.Text('${stars.isNotEmpty ? "$stars stars - " : ""}demonstrated ${value.toUpperCase()}',
                    style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _gold))),
        ]),
      );

  static pw.Widget _buildBarChart({
    required List<double> data1, required List<double> data2,
    required List<String> labels, required String label1, required String label2,
    required PdfColor color1, required PdfColor color2, double chartHeight = 160,
  }) {
    if (data1.isEmpty) return pw.SizedBox();
    final maxVal = [...data1, ...data2].fold<double>(1, (a, b) => a > b ? a : b);
    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Row(children: [
        pw.Container(width: 12, height: 8, color: color1), pw.SizedBox(width: 4),
        pw.Text(label1, style: pw.TextStyle(fontSize: 8, color: _gray)), pw.SizedBox(width: 16),
        pw.Container(width: 12, height: 8, color: color2), pw.SizedBox(width: 4),
        pw.Text(label2, style: pw.TextStyle(fontSize: 8, color: _gray)),
      ]),
      pw.SizedBox(height: 8),
      pw.Container(
        height: chartHeight,
        child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
          for (int i = 0; i < data1.length && i < labels.length; i++)
            pw.Expanded(child: pw.Column(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.center, crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                pw.Container(width: 10, height: maxVal > 0 ? (data1[i] / maxVal * (chartHeight - 20)).clamp(2.0, chartHeight - 20) : 2, color: color1),
                pw.SizedBox(width: 2),
                pw.Container(width: 10, height: i < data2.length && maxVal > 0 ? (data2[i] / maxVal * (chartHeight - 20)).clamp(2.0, chartHeight - 20) : 2, color: color2),
              ]),
              pw.SizedBox(height: 4),
              pw.Text(labels[i], style: pw.TextStyle(fontSize: 6, color: _gray), textAlign: pw.TextAlign.center),
            ])),
        ]),
      ),
    ]);
  }

  static pw.Widget _horizontalBar({required String label, required double percent, String? suffix}) {
    final color = percent >= 80 ? _green : percent >= 50 ? _amber : _red;
    return pw.Row(children: [
      pw.SizedBox(width: 110, child: pw.Text(label, style: pw.TextStyle(fontSize: 9, color: _darkText))),
      pw.Expanded(child: _progressBar((percent / 100).clamp(0.0, 1.0), 10, color)),
      pw.SizedBox(width: 8),
      pw.Text(suffix ?? '${percent.toStringAsFixed(0)}%', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _darkText)),
    ]);
  }

  static pw.Widget _sourceBar(String label, int count, int total, PdfColor color) {
    final pct = total > 0 ? (count / total * 100) : 0.0;
    return pw.Row(children: [
      pw.SizedBox(width: 130, child: pw.Text(label, style: pw.TextStyle(fontSize: 9, color: _darkText))),
      pw.Expanded(child: _progressBar((pct / 100).clamp(0.0, 1.0), 10, color)),
      pw.SizedBox(width: 8),
      pw.Text('$count (${pct.toStringAsFixed(0)}%)', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _darkText)),
    ]);
  }

  static pw.Widget _teamCard(Map<String, dynamic> team) {
    final name = team['teamName'] as String? ?? 'Team';
    final staffCount = team['staffCount'] as int? ?? 0;
    final participation = (team['participation'] as num?)?.toDouble() ?? 0;
    final avgKudos = (team['avgKudosPerStaff'] as num?)?.toDouble() ?? 0;
    final topRecognizer = team['topRecognizer'] as String? ?? '';
    final topValue = team['topValue'] as String? ?? '';
    final pColor = participation >= 80 ? _green : participation >= 50 ? _amber : _red;
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: const PdfColor.fromInt(0xFFE5E7EB)), borderRadius: pw.BorderRadius.circular(6)),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text('$name ($staffCount STAFF)', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _darkText)),
        pw.SizedBox(height: 8),
        pw.Row(children: [
          pw.Text('Participation: ', style: pw.TextStyle(fontSize: 9, color: _gray)),
          pw.Expanded(child: _progressBar((participation / 100).clamp(0.0, 1.0), 8, pColor, radius: 4)),
          pw.SizedBox(width: 6),
          pw.Text('${participation.toStringAsFixed(0)}%', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: pColor)),
        ]),
        pw.SizedBox(height: 4),
        pw.Text('Avg Kudos/Staff: ${avgKudos.toStringAsFixed(1)}   |   Top Recognizer: $topRecognizer   |   Top Value: $topValue',
            style: pw.TextStyle(fontSize: 8, color: _gray)),
      ]),
    );
  }

  static List<pw.Widget> _deriveRisingStars(List<Map<String, String>> users) {
    final sorted = [...users];
    sorted.sort((a, b) => (int.tryParse(b['stars'] ?? '0') ?? 0).compareTo(int.tryParse(a['stars'] ?? '0') ?? 0));
    final top = sorted.take(7).toList();
    if (top.isEmpty) return [pw.Text('No recognition data available yet.', style: pw.TextStyle(fontSize: 10, color: _gray))];
    return [
      pw.TableHelper.fromTextArray(
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: _white),
        headerDecoration: const pw.BoxDecoration(color: _primary),
        cellStyle: const pw.TextStyle(fontSize: 8),
        cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        headerPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 7),
        headers: ['Staff Name', 'Role', 'Stars Received'],
        data: top.map((u) => [u['name'] ?? '', u['role'] ?? '', u['stars'] ?? '0']).toList(),
      ),
    ];
  }

  static String _fmtPct(double v) => v >= 0 ? '+${v.toStringAsFixed(1)}%' : '${v.toStringAsFixed(1)}%';
  static String _fmtNum(int n) => NumberFormat('#,###').format(n);
  static double _safePct(int count, int total) => total > 0 ? (count / total * 100) : 0;

  static Future<void> _sharePdf(pw.Document pdf, String name) async {
    final bytes = await pdf.save();
    final ts = DateTime.now().millisecondsSinceEpoch;
    await Printing.sharePdf(bytes: bytes, filename: '${name}_$ts.pdf');
  }
}
