import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/theme.dart';

/// In-app GDPR posting guidelines — the "Golden Rules" from the compliance doc.
class GdprGuidelinesScreen extends StatelessWidget {
  const GdprGuidelinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 24, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new,
                        size: 20, color: AppColors.textPrimary),
                    onPressed: () => context.pop(),
                  ),
                  const Text(
                    'GDPR Posting Guidelines',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            // ── Content ──
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                children: [
                  // ── Policy Position ──
                  _PolicyBanner(),
                  const SizedBox(height: 20),

                  // ── The Simple Rule ──
                  _SimpleRuleBanner(),
                  const SizedBox(height: 24),

                  // ── Golden Rules: DO ──
                  _SectionTitle(
                    icon: Icons.check_circle_outline,
                    title: 'DO',
                    color: const Color(0xFF16A34A),
                  ),
                  const SizedBox(height: 12),
                  _RuleCard(
                    color: const Color(0xFFDCFCE7),
                    borderColor: const Color(0xFF86EFAC),
                    rules: const [
                      'Post about your own work and achievements',
                      'Use generic terms: "a resident," "a gentleman," "a lady"',
                      'Focus on what YOU did and what happened',
                      'Share reflections that inspire others',
                      'Include positive outcomes ("smiled," "engaged")',
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Golden Rules: DON'T ──
                  _SectionTitle(
                    icon: Icons.cancel_outlined,
                    title: "DON'T",
                    color: const Color(0xFFDC2626),
                  ),
                  const SizedBox(height: 12),
                  _RuleCard(
                    color: const Color(0xFFFEF2F2),
                    borderColor: const Color(0xFFFCA5A5),
                    rules: const [
                      'Post information that identifies service users',
                      'Use names, initials, or room numbers',
                      'Focus on details about the service user',
                      'Share clinical information or diagnoses',
                      'Include private moments or distress without anonymisation',
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── What Can NEVER Be Posted ──
                  _SectionTitle(
                    icon: Icons.block,
                    title: 'Absolute Prohibitions',
                    color: const Color(0xFFDC2626),
                  ),
                  const SizedBox(height: 12),
                  _InfoCard(
                    items: const [
                      'Names (first name, last name, initials)',
                      'Location details (room numbers, floor numbers, addresses)',
                      'Dates of significance (date of birth, admission dates)',
                      'Identifiable characteristics (unique physical descriptions)',
                      'NHS numbers, care numbers, or any unique identifiers',
                      'Specific medical conditions linked to an identifiable person',
                      'Photos or videos of service users',
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Acceptable Examples ──
                  _SectionTitle(
                    icon: Icons.lightbulb_outline,
                    title: 'Acceptable Examples',
                    color: const Color(0xFF0A2C6B),
                  ),
                  const SizedBox(height: 12),
                  _ExampleCard(
                    examples: const [
                      '"Helped a gentleman enjoy gardening for the first time in months"',
                      '"Supported a resident through a difficult transition"',
                      '"A lady smiled when we played her favourite music"',
                      '"A resident engaged with activities for the first time this week"',
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── The "Singling Out" Risk ──
                  _SectionTitle(
                    icon: Icons.warning_amber_rounded,
                    title: 'The "Singling Out" Risk',
                    color: const Color(0xFFEA580C),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: const Color(0xFFFED7AA)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Even without direct identifiers, a post that allows someone to "single out" an individual from context is still a breach.',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF9A3412),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'The Test:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF9A3412),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Ask: "Could anyone reading this identify who it\'s about?"',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF9A3412),
                            fontStyle: FontStyle.italic,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.5,
                            ),
                            children: [
                              TextSpan(
                                text: '• If yes → ',
                                style: TextStyle(
                                    color: Color(0xFF9A3412),
                                    fontWeight: FontWeight.w600),
                              ),
                              TextSpan(
                                text: 'Do not post',
                                style: TextStyle(
                                    color: Color(0xFFDC2626),
                                    fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                        RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.5,
                            ),
                            children: [
                              TextSpan(
                                text: '• If no → ',
                                style: TextStyle(
                                    color: Color(0xFF9A3412),
                                    fontWeight: FontWeight.w600),
                              ),
                              TextSpan(
                                text: 'Safe to post',
                                style: TextStyle(
                                    color: Color(0xFF16A34A),
                                    fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Your Rights ──
                  _SectionTitle(
                    icon: Icons.gavel_outlined,
                    title: 'Service User Rights',
                    color: const Color(0xFF0A2C6B),
                  ),
                  const SizedBox(height: 12),
                  _InfoCard(
                    items: const [
                      'Right to object to being referenced (even anonymously)',
                      'Right to be informed about how their information is used',
                      'Right to complain to ICO if they believe data protection has been breached',
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Legal Framework ──
                  _SectionTitle(
                    icon: Icons.policy_outlined,
                    title: 'Legal Framework',
                    color: const Color(0xFF0A2C6B),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Primary Legislation:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          '• UK GDPR (retained EU law) — Articles 6, 9\n'
                          '• Data Protection Act 2018 — Schedule 1\n'
                          '• Common law duty of confidentiality',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                            height: 1.6,
                          ),
                        ),
                        SizedBox(height: 14),
                        Text(
                          'Regulatory Guidance:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          '• ICO: Health and social care transparency guidance\n'
                          '• NHS Digital: Data Security and Protection Toolkit\n'
                          '• CQC: Expectations on information governance',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//  HELPER WIDGETS
// ═══════════════════════════════════════════════

class _PolicyBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF0A2C6B).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined,
                  size: 20, color: const Color(0xFF0A2C6B)),
              const SizedBox(width: 8),
              const Text(
                'CareKudos Policy',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0A2C6B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'CareKudos posts are professional reflections by staff about their own work. '
            'All content must be fully anonymised with no information that could identify '
            'a service user — directly or indirectly. Staff are trained to recognise '
            'identifiers and use our automated scanning tools.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF374151),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleRuleBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A2C6B), Color(0xFF1E40AF)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Posts are about the carer\'s work, not the service user\'s life.',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _RuleCard extends StatelessWidget {
  final Color color;
  final Color borderColor;
  final List<String> rules;

  const _RuleCard({
    required this.color,
    required this.borderColor,
    required this.rules,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rules
            .map((rule) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('•  ',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                      Expanded(
                        child: Text(
                          rule,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF374151),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<String> items;

  const _InfoCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items
            .map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.remove_circle_outline,
                          size: 16, color: Color(0xFFEF4444)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF374151),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _ExampleCard extends StatelessWidget {
  final List<String> examples;

  const _ExampleCard({required this.examples});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: examples
            .map((ex) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle,
                          size: 16, color: Color(0xFF16A34A)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          ex,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF374151),
                            height: 1.4,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}
