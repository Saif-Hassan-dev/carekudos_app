// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

/// Branded CareKudos PDF export utility.
/// Generates downloadable PDFs with consistent branding.
class PdfExport {
  static const _navy = PdfColor.fromInt(0xFF1E3A8A);
  static const _gray = PdfColor.fromInt(0xFF6B7280);
  static const _lightGray = PdfColor.fromInt(0xFFF3F4F6);
  static const _green = PdfColor.fromInt(0xFF16A34A);
  static const _red = PdfColor.fromInt(0xFFDC2626);
  static const _amber = PdfColor.fromInt(0xFFF59E0B);

  /// Generate and download an Engagement Report PDF.
  static Future<void> exportEngagementReport({
    required List<Map<String, String>> users,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (ctx) => _buildHeader('Engagement Report', now),
        footer: (ctx) => _buildFooter(ctx),
        build: (ctx) => [
          pw.SizedBox(height: 20),
          pw.Text('User Activity & Kudos Metrics',
              style: pw.TextStyle(fontSize: 14, color: _gray)),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: _navy),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            headerPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            headers: ['Name', 'Role', 'Organisation', 'Status', 'Kudos'],
            data: users.map((u) => [
              u['name'] ?? '',
              u['role'] ?? '',
              u['org'] ?? '',
              u['status'] ?? '',
              u['kudos'] ?? '0',
            ]).toList(),
          ),
          pw.SizedBox(height: 20),
          pw.Text('Total Users: ${users.length}',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );

    await _download(pdf, 'engagement_report_${_ts(now)}.pdf');
  }

  /// Generate and download a Training Compliance Report PDF.
  static Future<void> exportComplianceReport({
    required List<Map<String, String>> users,
    required double gdprPercent,
    required double onboardingPercent,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (ctx) => _buildHeader('Training & Compliance Report', now),
        footer: (ctx) => _buildFooter(ctx),
        build: (ctx) => [
          pw.SizedBox(height: 20),
          pw.Text('GDPR Training & Certification Status',
              style: pw.TextStyle(fontSize: 14, color: _gray)),
          pw.SizedBox(height: 16),
          // Summary boxes
          pw.Row(children: [
            _summaryBox('GDPR Completion', '${gdprPercent.toStringAsFixed(1)}%',
                gdprPercent >= 80 ? _green : gdprPercent >= 50 ? _amber : _red),
            pw.SizedBox(width: 16),
            _summaryBox('Onboarding Completion', '${onboardingPercent.toStringAsFixed(1)}%',
                onboardingPercent >= 80 ? _green : onboardingPercent >= 50 ? _amber : _red),
          ]),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: _navy),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            headerPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            headers: ['Name', 'Role', 'Organisation', 'GDPR Training', 'Onboarding', 'Status'],
            data: users.map((u) => [
              u['name'] ?? '',
              u['role'] ?? '',
              u['org'] ?? '',
              u['gdpr'] ?? '',
              u['onboarding'] ?? '',
              u['status'] ?? '',
            ]).toList(),
          ),
        ],
      ),
    );

    await _download(pdf, 'compliance_report_${_ts(now)}.pdf');
  }

  /// Generate and download a Feedback & Recognition Report PDF.
  static Future<void> exportRecognitionReport({
    required List<Map<String, String>> users,
    required int totalKudos,
    required int totalPosts,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (ctx) => _buildHeader('Feedback & Recognition Report', now),
        footer: (ctx) => _buildFooter(ctx),
        build: (ctx) => [
          pw.SizedBox(height: 20),
          pw.Text('Recognition Patterns & Team Engagement',
              style: pw.TextStyle(fontSize: 14, color: _gray)),
          pw.SizedBox(height: 16),
          pw.Row(children: [
            _summaryBox('Total Kudos', '$totalKudos', _navy),
            pw.SizedBox(width: 16),
            _summaryBox('Total Posts', '$totalPosts', _navy),
          ]),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: _navy),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            headerPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            headers: ['Name', 'Role', 'Stars Received', 'Posts', 'Status'],
            data: users.map((u) => [
              u['name'] ?? '',
              u['role'] ?? '',
              u['stars'] ?? '0',
              u['posts'] ?? '0',
              u['status'] ?? '',
            ]).toList(),
          ),
        ],
      ),
    );

    await _download(pdf, 'recognition_report_${_ts(now)}.pdf');
  }

  // ─── Private helpers ───

  static pw.Widget _buildHeader(String title, DateTime date) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Row(children: [
              pw.Container(
                width: 28,
                height: 28,
                decoration: const pw.BoxDecoration(
                  color: _navy,
                  shape: pw.BoxShape.circle,
                ),
                child: pw.Center(
                  child: pw.Text('CK',
                      style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold)),
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Text('CareKudos',
                  style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: _navy)),
            ]),
            pw.Text(
              'Generated: ${DateFormat('dd MMM yyyy, HH:mm').format(date)}',
              style: pw.TextStyle(fontSize: 10, color: _gray),
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Divider(color: _navy, thickness: 2),
        pw.SizedBox(height: 8),
        pw.Text(title,
            style: pw.TextStyle(
                fontSize: 20, fontWeight: pw.FontWeight.bold, color: _navy)),
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
          pw.Text('CareKudos — Confidential',
              style: pw.TextStyle(fontSize: 8, color: _gray)),
          pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
              style: pw.TextStyle(fontSize: 8, color: _gray)),
        ],
      ),
    ]);
  }

  static pw.Widget _summaryBox(String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: color, width: 1.5),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: pw.TextStyle(fontSize: 10, color: _gray)),
            pw.SizedBox(height: 4),
            pw.Text(value,
                style: pw.TextStyle(
                    fontSize: 22, fontWeight: pw.FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  static String _ts(DateTime d) => d.millisecondsSinceEpoch.toString();

  static Future<void> _download(pw.Document pdf, String filename) async {
    final bytes = await pdf.save();
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}
