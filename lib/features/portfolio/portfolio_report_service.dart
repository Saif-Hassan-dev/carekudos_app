import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'portfolio_data_service.dart';

/// Generates care worker portfolio PDFs (Reports 1–4).
class PortfolioReportService {
  static const _navy = PdfColor.fromInt(0xFF1E3A8A);
  static const _gold = PdfColor.fromInt(0xFFD4A843);
  static const _gray = PdfColor.fromInt(0xFF6B7280);
  static const _lightGray = PdfColor.fromInt(0xFFF3F4F6);
  static const _green = PdfColor.fromInt(0xFF16A34A);

  // ═══════════════════════════════════════════════════════
  // REPORT 2: Quick CV Summary (1 page)
  // ═══════════════════════════════════════════════════════

  static Future<void> exportCvSummary(PortfolioData data) async {
    final pdf = pw.Document();
    final now = DateTime.now();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(20),
              decoration: const pw.BoxDecoration(color: _navy),
              child: pw.Column(
                children: [
                  pw.Text('CAREKUDOS CV SUMMARY',
                      style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 6),
                  pw.Text(data.fullName,
                      style: pw.TextStyle(
                          color: _gold,
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Role & dates
            pw.Text(
              '${data.jobTitle ?? _roleLabel(data.role)} | ${data.organizationId ?? "CareKudos"}',
              style: pw.TextStyle(
                  fontSize: 12, fontWeight: pw.FontWeight.bold, color: _navy),
            ),
            if (data.memberSince != null)
              pw.Text(
                'Member since: ${DateFormat('MMMM yyyy').format(data.memberSince!)}',
                style: pw.TextStyle(fontSize: 10, color: _gray),
              ),
            pw.SizedBox(height: 16),
            pw.Divider(color: _navy, thickness: 1),
            pw.SizedBox(height: 12),

            // Key Stats
            _sectionTitle('KEY STATS'),
            pw.SizedBox(height: 8),
            pw.Row(children: [
              _statChip('${data.totalStars} stars received'),
              pw.SizedBox(width: 16),
              _statChip('${data.totalPosts} achievements posted'),
            ]),
            pw.SizedBox(height: 12),

            // Values Profile
            if (data.valuesBreakdown.isNotEmpty) ...[
              _sectionTitle('VALUES PROFILE'),
              pw.SizedBox(height: 8),
              pw.Wrap(
                spacing: 12,
                runSpacing: 4,
                children: data.valuesPercentages.entries.map((e) {
                  return pw.Text(
                    '${e.key}: ${e.value.toStringAsFixed(0)}%',
                    style: pw.TextStyle(fontSize: 10, color: _navy),
                  );
                }).toList(),
              ),
              pw.SizedBox(height: 12),
            ],

            // Top Achievements
            if (data.topPosts.isNotEmpty) ...[
              _sectionTitle('TOP ACHIEVEMENTS'),
              pw.SizedBox(height: 8),
              ...data.topPosts.take(4).map((post) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 4),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('• ', style: pw.TextStyle(fontSize: 10, color: _navy)),
                        pw.Expanded(
                          child: pw.Text(
                            _truncate(post.content, 80),
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  )),
              pw.SizedBox(height: 12),
            ],

            // Strengths (derived from top values)
            if (data.valuesBreakdown.isNotEmpty) ...[
              _sectionTitle('STRENGTHS'),
              pw.SizedBox(height: 8),
              pw.Wrap(
                spacing: 12,
                children: data.valuesBreakdown.keys.take(3).map((v) {
                  return pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: pw.BoxDecoration(
                      color: _lightGray,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(v, style: const pw.TextStyle(fontSize: 10)),
                  );
                }).toList(),
              ),
              pw.SizedBox(height: 12),
            ],

            // Recognition by source
            if (data.recognitionBySource.isNotEmpty) ...[
              _sectionTitle('RECOGNITION BY SOURCE'),
              pw.SizedBox(height: 8),
              pw.Wrap(
                spacing: 12,
                children: data.recognitionBySource.entries.map((e) {
                  return pw.Text(
                    '${e.key}: ${e.value}',
                    style: pw.TextStyle(fontSize: 10, color: _gray),
                  );
                }).toList(),
              ),
            ],

            pw.Spacer(),

            // Footer
            pw.Divider(color: _lightGray),
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('CareKudos - Making Exceptional Care Visible',
                    style: pw.TextStyle(fontSize: 8, color: _gray)),
                pw.Text(
                  'Generated: ${DateFormat('dd MMM yyyy').format(now)}',
                  style: pw.TextStyle(fontSize: 8, color: _gray),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    await _sharePdf(pdf, 'cv_summary_${data.fullName.replaceAll(' ', '_')}');
  }

  // ═══════════════════════════════════════════════════════
  // REPORT 1: Full Portfolio (multi-page)
  // ═══════════════════════════════════════════════════════

  static Future<void> exportFullPortfolio(PortfolioData data) async {
    final pdf = pw.Document();
    final now = DateTime.now();

    // ── Cover Page ──
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (ctx) => pw.Center(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Container(
                width: 80,
                height: 80,
                decoration: const pw.BoxDecoration(
                    color: _navy, shape: pw.BoxShape.circle),
                child: pw.Center(
                  child: pw.Text('CK',
                      style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 30,
                          fontWeight: pw.FontWeight.bold)),
                ),
              ),
              pw.SizedBox(height: 24),
              pw.Text('PROFESSIONAL PORTFOLIO',
                  style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: _navy)),
              pw.SizedBox(height: 16),
              pw.Text(data.fullName,
                  style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: _gold)),
              pw.SizedBox(height: 4),
              pw.Text(data.jobTitle ?? _roleLabel(data.role),
                  style: pw.TextStyle(fontSize: 14, color: _gray)),
              pw.SizedBox(height: 4),
              pw.Text(data.organizationId ?? '',
                  style: pw.TextStyle(fontSize: 12, color: _gray)),
              pw.SizedBox(height: 24),
              if (data.memberSince != null)
                pw.Text(
                  'Portfolio Period: ${DateFormat('MMM yyyy').format(data.memberSince!)} – ${DateFormat('MMM yyyy').format(now)}',
                  style: pw.TextStyle(fontSize: 11, color: _gray),
                ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Generated: ${DateFormat('dd MMMM yyyy').format(now)}',
                style: pw.TextStyle(fontSize: 11, color: _gray),
              ),
              pw.SizedBox(height: 32),
              pw.Text('Making Exceptional Care Visible',
                  style: pw.TextStyle(
                      fontSize: 12,
                      fontStyle: pw.FontStyle.italic,
                      color: _gold)),
            ],
          ),
        ),
      ),
    );

    // ── Page 1: Personal Summary ──
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _pageTitle('PERSONAL SUMMARY'),
            pw.SizedBox(height: 16),
            pw.Text(data.fullName,
                style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: _navy)),
            pw.Text(data.jobTitle ?? _roleLabel(data.role),
                style: pw.TextStyle(fontSize: 12, color: _gray)),
            if (data.memberSince != null)
              pw.Text(
                'Employed: ${DateFormat('MMMM yyyy').format(data.memberSince!)} – Present',
                style: pw.TextStyle(fontSize: 11, color: _gray),
              ),
            pw.SizedBox(height: 20),

            // Highlights boxes
            pw.Text('PORTFOLIO HIGHLIGHTS',
                style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                    color: _navy)),
            pw.SizedBox(height: 10),
            pw.Row(children: [
              _highlightBox('Total Stars', '${data.totalStars}'),
              pw.SizedBox(width: 12),
              _highlightBox('Posts Shared', '${data.totalPosts}'),
            ]),
            pw.SizedBox(height: 24),

            // Values Profile
            if (data.valuesBreakdown.isNotEmpty) ...[
              pw.Text('VALUES PROFILE',
                  style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                      color: _navy)),
              pw.SizedBox(height: 10),
              ...data.valuesPercentages.entries.map((e) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 6),
                    child: pw.Row(children: [
                      pw.SizedBox(
                        width: 100,
                        child: pw.Text('${e.key}:',
                            style: const pw.TextStyle(fontSize: 10)),
                      ),
                      pw.Text('${e.value.toStringAsFixed(0)}%',
                          style: pw.TextStyle(
                              fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(width: 8),
                      pw.Expanded(
                        child: pw.ClipRRect(
                          horizontalRadius: 3,
                          verticalRadius: 3,
                          child: pw.LinearProgressIndicator(
                            value: e.value / 100,
                            backgroundColor: _lightGray,
                            valueColor: _navy,
                          ),
                        ),
                      ),
                    ]),
                  )),
            ],
          ],
        ),
      ),
    );

    // ── Page 2: Achievement Highlights ──
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (ctx) => _buildHeader('Achievement Highlights', now),
        footer: (ctx) => _buildFooter(ctx),
        build: (ctx) => [
          pw.SizedBox(height: 8),
          pw.Text(
            'TOP ${data.topPosts.length > 10 ? 10 : data.topPosts.length} RECOGNISED ACHIEVEMENTS',
            style: pw.TextStyle(
                fontSize: 12, fontWeight: pw.FontWeight.bold, color: _navy),
          ),
          pw.Text('(Selected from ${data.totalPosts} posts)',
              style: pw.TextStyle(fontSize: 10, color: _gray)),
          pw.SizedBox(height: 12),
          ...data.topPosts.take(10).map((post) => pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 12),
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: _lightGray),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(post.category.toUpperCase(),
                            style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                                color: _gold)),
                        pw.Text(
                          DateFormat('MMMM yyyy').format(post.createdAt),
                          style: pw.TextStyle(fontSize: 9, color: _gray),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text('"${post.content}"',
                        style: pw.TextStyle(
                            fontSize: 10, fontStyle: pw.FontStyle.italic)),
                    pw.SizedBox(height: 4),
                    pw.Text('${post.stars} stars received',
                        style: pw.TextStyle(
                            fontSize: 9,
                            color: _navy,
                            fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              )),
        ],
      ),
    );

    // ── Page 3: Values Demonstration Evidence ──
    if (data.valuesBreakdown.isNotEmpty) {
      // Group posts by value
      final postsByValue = <String, List<PortfolioPost>>{};
      for (final post in data.topPosts) {
        postsByValue.putIfAbsent(post.category, () => []).add(post);
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          header: (ctx) => _buildHeader('Values Demonstration Evidence', now),
          footer: (ctx) => _buildFooter(ctx),
          build: (ctx) {
            final widgets = <pw.Widget>[];
            widgets.add(pw.SizedBox(height: 8));

            for (final entry in data.valuesPercentages.entries) {
              final count = data.valuesBreakdown[entry.key] ?? 0;
              widgets.add(pw.Text(
                '${entry.key.toUpperCase()} – ${entry.value.toStringAsFixed(0)}% of posts ($count examples)',
                style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: _navy),
              ));
              widgets.add(pw.SizedBox(height: 6));

              final examples = postsByValue[entry.key] ?? [];
              for (final post in examples.take(3)) {
                widgets.add(pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 12, bottom: 4),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('• ',
                          style: pw.TextStyle(fontSize: 10, color: _navy)),
                      pw.Expanded(
                        child: pw.Text(
                          '"${_truncate(post.content, 120)}"',
                          style: pw.TextStyle(
                              fontSize: 10, fontStyle: pw.FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                ));
              }
              widgets.add(pw.SizedBox(height: 14));
            }
            return widgets;
          },
        ),
      );
    }

    // ── Page 4: Recognition Summary ──
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildHeader('Recognition Summary', now),
            pw.SizedBox(height: 16),

            // Monthly bar chart
            if (data.monthlyStars.isNotEmpty) ...[
              pw.Text('RECOGNITION RECEIVED',
                  style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: _navy)),
              pw.SizedBox(height: 10),
              ..._buildBarChart(data.monthlyStars),
              pw.SizedBox(height: 20),
            ],

            // By source
            if (data.recognitionBySource.isNotEmpty) ...[
              pw.Text('RECOGNITION BY SOURCE',
                  style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: _navy)),
              pw.SizedBox(height: 8),
              ...data.recognitionBySource.entries.map((e) {
                final total = data.recognitionBySource.values
                    .fold<int>(0, (a, b) => a + b);
                final pct =
                    total > 0 ? (e.value / total * 100).toStringAsFixed(0) : '0';
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Text(
                    '${e.key} recognition: ${e.value} ($pct%)',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                );
              }),
              pw.SizedBox(height: 20),
            ],

            // Top recognisers
            if (data.topRecognisers.isNotEmpty) ...[
              pw.Text('TOP RECOGNISERS',
                  style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: _navy)),
              pw.SizedBox(height: 8),
              ...data.topRecognisers.entries.map((e) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 4),
                    child: pw.Text(
                      '${e.key}: ${e.value} recognitions',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  )),
            ],
          ],
        ),
      ),
    );

    await _sharePdf(
        pdf, 'portfolio_${data.fullName.replaceAll(' ', '_')}');
  }

  // ═══════════════════════════════════════════════════════
  // REPORT 3: Appraisal Evidence Pack
  // ═══════════════════════════════════════════════════════

  static Future<void> exportAppraisalPack(PortfolioData data) async {
    final pdf = pw.Document();
    final now = DateTime.now();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (ctx) => _buildHeader('Appraisal Evidence Pack', now),
        footer: (ctx) => _buildFooter(ctx),
        build: (ctx) => [
          // Section 1: Performance Summary
          pw.SizedBox(height: 8),
          _sectionTitle('1. PERFORMANCE SUMMARY'),
          pw.SizedBox(height: 8),
          pw.Text('Name: ${data.fullName}',
              style: const pw.TextStyle(fontSize: 11)),
          pw.Text(
              'Role: ${data.jobTitle ?? _roleLabel(data.role)}',
              style: const pw.TextStyle(fontSize: 11)),
          if (data.memberSince != null)
            pw.Text(
              'Appraisal Period: ${DateFormat('MMM yyyy').format(data.memberSince!)} – ${DateFormat('MMM yyyy').format(now)}',
              style: const pw.TextStyle(fontSize: 11),
            ),
          pw.SizedBox(height: 8),
          pw.Row(children: [
            _highlightBox('Stars Received', '${data.totalStars}'),
            pw.SizedBox(width: 12),
            _highlightBox('Posts Shared', '${data.totalPosts}'),
          ]),
          pw.SizedBox(height: 16),

          // Values alignment
          if (data.valuesBreakdown.isNotEmpty) ...[
            pw.Text('Values Alignment:',
                style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: _navy)),
            pw.SizedBox(height: 4),
            ...data.valuesPercentages.entries.map((e) => pw.Text(
                  '  ${e.key}: ${e.value.toStringAsFixed(0)}% of posts',
                  style: const pw.TextStyle(fontSize: 10),
                )),
            pw.SizedBox(height: 16),
          ],

          // Section 2: Achievement Examples
          _sectionTitle('2. ACHIEVEMENT EXAMPLES'),
          pw.SizedBox(height: 8),
          pw.Text('Top ${data.topPosts.take(10).length} posts by recognition:',
              style: pw.TextStyle(fontSize: 10, color: _gray)),
          pw.SizedBox(height: 6),
          ...data.topPosts.take(10).map((post) => pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 8),
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: _lightGray),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(post.category,
                            style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                                color: _gold)),
                        pw.Text('${post.stars} stars',
                            style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                                color: _navy)),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('"${post.content}"',
                        style: pw.TextStyle(
                            fontSize: 9, fontStyle: pw.FontStyle.italic)),
                    pw.Text(
                      DateFormat('dd MMM yyyy').format(post.createdAt),
                      style: pw.TextStyle(fontSize: 8, color: _gray),
                    ),
                  ],
                ),
              )),

          pw.SizedBox(height: 16),

          // Section 3: Manager Review Section
          _sectionTitle('3. MANAGER REVIEW'),
          pw.SizedBox(height: 8),
          pw.Container(
            width: double.infinity,
            height: 120,
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _gray),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text('Manager comments:',
                style: pw.TextStyle(fontSize: 10, color: _gray)),
          ),
          pw.SizedBox(height: 12),
          pw.Row(children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Manager Signature:',
                      style: pw.TextStyle(fontSize: 10, color: _gray)),
                  pw.SizedBox(height: 20),
                  pw.Container(
                      width: 200,
                      decoration: const pw.BoxDecoration(
                          border: pw.Border(
                              bottom: pw.BorderSide(color: _gray)))),
                ],
              ),
            ),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Date:',
                      style: pw.TextStyle(fontSize: 10, color: _gray)),
                  pw.SizedBox(height: 20),
                  pw.Container(
                      width: 200,
                      decoration: const pw.BoxDecoration(
                          border: pw.Border(
                              bottom: pw.BorderSide(color: _gray)))),
                ],
              ),
            ),
          ]),
        ],
      ),
    );

    await _sharePdf(
        pdf, 'appraisal_pack_${data.fullName.replaceAll(' ', '_')}');
  }

  // ═══════════════════════════════════════════════════════
  // Private helpers
  // ═══════════════════════════════════════════════════════

  static pw.Widget _buildHeader(String title, DateTime date) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Row(children: [
              pw.Container(
                width: 24,
                height: 24,
                decoration:
                    const pw.BoxDecoration(color: _navy, shape: pw.BoxShape.circle),
                child: pw.Center(
                  child: pw.Text('CK',
                      style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold)),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Text('CareKudos',
                  style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: _navy)),
            ]),
            pw.Text(
              'Generated: ${DateFormat('dd MMM yyyy').format(date)}',
              style: pw.TextStyle(fontSize: 9, color: _gray),
            ),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Divider(color: _navy, thickness: 2),
        pw.SizedBox(height: 6),
        pw.Text(title,
            style: pw.TextStyle(
                fontSize: 18, fontWeight: pw.FontWeight.bold, color: _navy)),
      ],
    );
  }

  static pw.Widget _buildFooter(pw.Context ctx) {
    return pw.Column(children: [
      pw.Divider(color: _lightGray),
      pw.SizedBox(height: 4),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('CareKudos - Confidential',
              style: pw.TextStyle(fontSize: 8, color: _gray)),
          pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
              style: pw.TextStyle(fontSize: 8, color: _gray)),
        ],
      ),
    ]);
  }

  static pw.Widget _pageTitle(String title) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const pw.BoxDecoration(color: _navy),
      child: pw.Text(title,
          style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 14,
              fontWeight: pw.FontWeight.bold)),
    );
  }

  static pw.Widget _sectionTitle(String title) {
    return pw.Text(title,
        style: pw.TextStyle(
            fontSize: 13, fontWeight: pw.FontWeight.bold, color: _navy));
  }

  static pw.Widget _highlightBox(String label, String value) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _navy, width: 1.5),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: pw.TextStyle(fontSize: 10, color: _gray)),
            pw.SizedBox(height: 4),
            pw.Text(value,
                style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: _navy)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _statChip(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: pw.BoxDecoration(
        color: _lightGray,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 10)),
    );
  }

  /// Build simple horizontal bar chart rows from monthly data.
  static List<pw.Widget> _buildBarChart(Map<String, int> monthlyData) {
    if (monthlyData.isEmpty) return [];
    final maxVal = monthlyData.values.reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) return [];

    // Sort by key (date) and take last 12 months
    final sorted = monthlyData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final recent = sorted.length > 12 ? sorted.sublist(sorted.length - 12) : sorted;

    return recent.map((e) {
      final fraction = e.value / maxVal;
      final monthLabel = _monthLabel(e.key);
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Row(children: [
          pw.SizedBox(
            width: 36,
            child: pw.Text(monthLabel,
                style: pw.TextStyle(fontSize: 9, color: _gray)),
          ),
          pw.Expanded(
            child: pw.ClipRRect(
              horizontalRadius: 2,
              verticalRadius: 2,
              child: pw.LinearProgressIndicator(
                value: fraction,
                backgroundColor: _lightGray,
                valueColor: _navy,
              ),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.SizedBox(
            width: 24,
            child: pw.Text('${e.value}',
                style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
          ),
        ]),
      );
    }).toList();
  }

  static String _monthLabel(String key) {
    // key is "2026-03" → "Mar"
    final parts = key.split('-');
    if (parts.length != 2) return key;
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final m = int.tryParse(parts[1]) ?? 0;
    return m > 0 && m <= 12 ? months[m] : key;
  }

  static String _roleLabel(String role) {
    switch (role) {
      case 'care_worker':
        return 'Care Worker';
      case 'senior_carer':
        return 'Senior Carer';
      case 'manager':
        return 'Manager';
      case 'family_member':
        return 'Family Member';
      default:
        return role;
    }
  }

  static String _truncate(String text, int maxLen) {
    if (text.length <= maxLen) return text;
    return '${text.substring(0, maxLen)}...';
  }

  static Future<void> _sharePdf(pw.Document pdf, String name) async {
    final bytes = await pdf.save();
    final ts = DateTime.now().millisecondsSinceEpoch;
    await Printing.sharePdf(bytes: bytes, filename: '${name}_$ts.pdf');
  }
}
