import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final _platformKey = GlobalKey();
  final _solutionsKey = GlobalKey();
  final _roiKey = GlobalKey();
  final _pricingKey = GlobalKey();
  final _contactKey = GlobalKey();

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SelectionArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 900;
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _Navbar(
                    isWide: isWide,
                    onPlatform: () => _scrollTo(_platformKey),
                    onSolutions: () => _scrollTo(_solutionsKey),
                    onRoi: () => _scrollTo(_roiKey),
                    onPricing: () => _scrollTo(_pricingKey),
                    onRequestDemo: () => _scrollTo(_contactKey),
                  ),
                ),
                SliverToBoxAdapter(child: _HeroSection(isWide: isWide)),
                SliverToBoxAdapter(
                  child: _RoiCalculatorSection(key: _roiKey),
                ),
                SliverToBoxAdapter(
                  child: _ChallengeAndSolution(key: _solutionsKey),
                ),
                SliverToBoxAdapter(
                  child: _PlatformFeatures(key: _platformKey),
                ),
                const SliverToBoxAdapter(child: _StarStorySection()),
                const SliverToBoxAdapter(child: _TestimonialsSection()),
                SliverToBoxAdapter(
                  child: _PricingSection(key: _pricingKey),
                ),
                SliverToBoxAdapter(
                  child: _ContactSection(key: _contactKey),
                ),
                const SliverToBoxAdapter(child: _FooterSection()),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// NAVBAR
// ═══════════════════════════════════════════════════════════════

class _Navbar extends StatelessWidget {
  final bool isWide;
  final VoidCallback onPlatform;
  final VoidCallback onSolutions;
  final VoidCallback onRoi;
  final VoidCallback onPricing;
  final VoidCallback onRequestDemo;

  const _Navbar({
    required this.isWide,
    required this.onPlatform,
    required this.onSolutions,
    required this.onRoi,
    required this.onPricing,
    required this.onRequestDemo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: Row(
        children: [
          // Logo
          SvgPicture.asset('assets/images/smallLogo.svg',
              width: 150, fit: BoxFit.contain),

          const Spacer(),

          // Nav links (only on wide screens)
          if (isWide) ...[
            _NavLink(label: 'Platform', onTap: onPlatform),
            const SizedBox(width: 32),
            _NavLink(label: 'Solutions', onTap: onSolutions),
            const SizedBox(width: 32),
            _NavLink(label: 'ROI', onTap: onRoi),
            const SizedBox(width: 32),
            _NavLink(label: 'Pricing', onTap: onPricing),
          ],

          const Spacer(),

          // CTA buttons
          TextButton(
            onPressed: () => context.go('/admin/login'),
            child: Text(
              'Log In',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF374151),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: onRequestDemo,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Request Demo',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavLink extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _NavLink({required this.label, required this.onTap});

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Text(
          widget.label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _hovered ? const Color(0xFF1E3A8A) : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// HERO SECTION
// ═══════════════════════════════════════════════════════════════

class _HeroSection extends StatelessWidget {
  final bool isWide;
  const _HeroSection({required this.isWide});

  @override
  Widget build(BuildContext context) {
    if (!isWide) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Column(
          children: [
            _HeroLeft(),
            const SizedBox(height: 40),
            SizedBox(
              height: 420,
              child: _HeroRight(),
            ),
          ],
        ),
      );
    }

    // Desktop: text left, mockups right
    return Container(
      height: 620,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.centerRight,
          radius: 1.0,
          colors: [
            const Color(0xFFEBF0FF).withValues(alpha: 0.4),
            Colors.white,
          ],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Left text content
          Positioned(
            left: 80,
            top: 70,
            width: MediaQuery.of(context).size.width * 0.38,
            child: _HeroLeft(),
          ),
          // Right mockups — centered in right half with proper margins
          Positioned(
            right: 40,
            top: 20,
            bottom: 0,
            width: MediaQuery.of(context).size.width * 0.50,
            child: _HeroRight(),
          ),
        ],
      ),
    );
  }
}

class _HeroLeft extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // CQC Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F4FF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFDBE4FF)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF16A34A),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'CQC READY 2024',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E3A8A),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // Main heading
        Text(
          'Recognise Care.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 48,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF111827),
            height: 1.15,
          ),
        ),
        Text(
          'Build Care.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 48,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF111827),
            height: 1.15,
          ),
        ),
        Text(
          'Stay Compliant.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 48,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1E3A8A),
            height: 1.15,
          ),
        ),
        const SizedBox(height: 20),

        // Subtitle
        Text(
          'The intelligent recognition platform that\nturns daily appreciation into compliance data\nfor healthcare organisations',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF6B7280),
            height: 1.6,
          ),
        ),
        const SizedBox(height: 32),

        // CTA buttons
        Row(
          children: [
            Builder(
              builder: (context) {
                return OutlinedButton.icon(
                  onPressed: () => GoRouter.of(context).go('/admin/login'),
                  icon: const Icon(Icons.language, size: 16),
                  label: Text(
                    'Log In',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF374151),
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    final state = context.findAncestorStateOfType<_LandingPageState>();
                    if (state != null) state._scrollTo(state._contactKey);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Request Demo',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, size: 16),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Trust badges
        Row(
          children: [
            _TrustBadge(icon: Icons.shield_outlined, label: 'GDPR-ready'),
            const SizedBox(width: 24),
            _TrustBadge(icon: Icons.people_outline, label: '20k+ Healthcare Staff'),
            const SizedBox(width: 24),
            _TrustBadge(icon: Icons.dashboard_outlined, label: 'Dashboards'),
          ],
        ),
      ],
    );
  }
}

class _TrustBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _TrustBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }
}

// ─── Hero Right: Phone + iPad mockup images from assets ───

class _HeroRight extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final containerWidth = constraints.maxWidth;
        final containerHeight = constraints.maxHeight;

        // iPad dimensions — larger, sits behind
        final ipadHeight = containerHeight * 0.88;
        // iPhone dimensions — smaller, sits in front
        final iphoneHeight = containerHeight * 0.85;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // ── iPad (background, shifted right, partially hidden behind iPhone) ──
            Positioned(
              right: 0,
              top: containerHeight * 0.05,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/images/ipad_mockup.png',
                    height: ipadHeight,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),

            // ── iPhone (foreground, slightly left of center, overlaps iPad ~30%) ──
            Positioned(
              left: containerWidth * 0.10,
              top: containerHeight * 0.08,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Image.asset(
                    'assets/images/imockup_iphone_15_pro_max.png',
                    height: iphoneHeight,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// THE CHALLENGE & THE SOLUTION
// ═══════════════════════════════════════════════════════════════

class _ChallengeAndSolution extends StatelessWidget {
  const _ChallengeAndSolution({super.key});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 80 : 24,
        vertical: 80,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.2,
          colors: [
            const Color(0xFFEBF0FF).withValues(alpha: 0.45),
            Colors.white,
          ],
        ),
        border: const Border(top: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _ChallengeColumn()),
                const SizedBox(width: 48),
                Expanded(child: _SolutionCard()),
              ],
            )
          : Column(
              children: [
                _ChallengeColumn(),
                const SizedBox(height: 40),
                _SolutionCard(),
              ],
            ),
    );
  }
}

class _ChallengeColumn extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'THE CHALLENGE',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF6B7FAA),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Healthcare Teams are\nBurning Out.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF111827),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 32),
        _ChallengeItem(
          icon: Icons.visibility_off_outlined,
          iconBg: const Color(0xFFF0F4FF),
          title: 'Recognition is invisible',
          subtitle:
              'Efforts go unnoticed, morale drops, and turnover rises.',
        ),
        const SizedBox(height: 24),
        _ChallengeItem(
          icon: Icons.assignment_outlined,
          iconBg: const Color(0xFFF0F4FF),
          title: 'Compliance is overwhelming',
          subtitle:
              'Spreadsheets fail. Deadlines are missed. Audits create anxiety.',
        ),
        const SizedBox(height: 24),
        _ChallengeItem(
          icon: Icons.sentiment_dissatisfied_outlined,
          iconBg: const Color(0xFFF0F4FF),
          title: 'Engagement feels impossible',
          subtitle:
              'No time, no tools, no structure to build culture that lasts.',
        ),
      ],
    );
  }
}

class _ChallengeItem extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String title;
  final String subtitle;

  const _ChallengeItem({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: iconBg,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 22, color: const Color(0xFF1E3A8A)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SolutionCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'THE SOLUTION',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF16A34A),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              style: GoogleFonts.plusJakartaSans(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF111827),
                height: 1.2,
              ),
              children: [
                const TextSpan(text: 'The '),
                TextSpan(
                  text: 'CareKudos',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E3A8A),
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const TextSpan(text: ' Effect'),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _SolutionItem(
            icon: Icons.visibility_outlined,
            title: 'Recognition is invisible',
            subtitle:
                'Efforts go unnoticed, morale drops, and turnover rises.',
          ),
          const SizedBox(height: 20),
          _SolutionItem(
            icon: Icons.assignment_turned_in_outlined,
            title: 'Compliance is overwhelming',
            subtitle: 'Spreadsheets fail. Deadlines are missed.',
          ),
          const SizedBox(height: 20),
          _SolutionItem(
            icon: Icons.emoji_emotions_outlined,
            title: 'Engagement feels impossible',
            subtitle:
                'No time, no tools, no structure to build culture that lasts.',
          ),
        ],
      ),
    );
  }
}

class _SolutionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SolutionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: Color(0xFF1E3A8A),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 22, color: Colors.white),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PLATFORM FEATURES
// ═══════════════════════════════════════════════════════════════

class _PlatformFeatures extends StatelessWidget {
  const _PlatformFeatures({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 900;
    final isMedium = screenWidth > 600;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 80 : 24,
        vertical: 80,
      ),
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topCenter,
          radius: 1.4,
          colors: [
            const Color(0xFFEBF0FF).withValues(alpha: 0.5),
            const Color(0xFFF9FAFB),
          ],
        ),
      ),
      child: Column(
        children: [
          // Section label
          Text(
            'Platform Features',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF3B82F6),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          // Main heading
          Text(
            'Complete Care Visibility',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: isWide ? 36 : 28,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF111827),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          // Subtitle
          Text(
            'Everything you need to manage culture and compliance in one unified view.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: const Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 48),
          // Cards grid — row 1
          if (isMedium)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _FeatureCard.frontlineFirst()),
                const SizedBox(width: 24),
                Expanded(child: _FeatureCard.regulatoryMapping()),
              ],
            )
          else ...[
            _FeatureCard.frontlineFirst(),
            const SizedBox(height: 24),
            _FeatureCard.regulatoryMapping(),
          ],
          const SizedBox(height: 24),
          // Cards grid — row 2
          if (isMedium)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _FeatureCard.meaningfulRewards()),
                const SizedBox(width: 24),
                Expanded(child: _FeatureCard.engagementAnalytics()),
              ],
            )
          else ...[
            _FeatureCard.meaningfulRewards(),
            const SizedBox(height: 24),
            _FeatureCard.engagementAnalytics(),
          ],
        ],
      ),
    );
  }
}

class _FeatureCard extends StatefulWidget {
  final String title;
  final String description;
  final String imagePath;

  const _FeatureCard({
    required this.title,
    required this.description,
    required this.imagePath,
  });

  factory _FeatureCard.frontlineFirst() => const _FeatureCard(
        title: 'Frontline First',
        description: 'Mobile app designed for busy shifts.',
        imagePath: 'assets/images/frontline_first.png',
      );

  factory _FeatureCard.regulatoryMapping() => const _FeatureCard(
        title: 'Regulatory Mapping',
        description:
            'Everything you need to manage culture and compliance in one view.',
        imagePath: 'assets/images/regulatory_mapping.png',
      );

  factory _FeatureCard.meaningfulRewards() => const _FeatureCard(
        title: 'Meaningful Rewards',
        description: 'From vouchers to extra leave.',
        imagePath: 'assets/images/meaningful_rewards.png',
      );

  factory _FeatureCard.engagementAnalytics() => const _FeatureCard(
        title: 'Engagement Analytics',
        description: 'Track engagement analytics through our dashboard.',
        imagePath: 'assets/images/engagement_analytics.png',
      );

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hovered ? -4 : 0, 0),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovered
                ? const Color(0xFFDBE4FF)
                : const Color(0xFFE5E7EB),
          ),
          boxShadow: [
            BoxShadow(
              color: _hovered
                  ? Colors.black.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: _hovered ? 20 : 12,
              offset: Offset(0, _hovered ? 8 : 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.description,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  widget.imagePath,
                  height: 220,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 220,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.image_outlined,
                          size: 48,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// STAR STORY SECTION
// ═══════════════════════════════════════════════════════════════

class _StarStorySection extends StatelessWidget {
  const _StarStorySection();

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 80 : 24,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF152D6B),
      ),
      child: Column(
        children: [
          const SizedBox(height: 64),
          // Star icon from meaningful rewards asset
          Image.asset(
            'assets/images/meaningful_rewards.png',
            height: 56,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 24),
          // Heading
          Text(
            'Every star tells a story of care.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: isWide ? 36 : 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          // Description
          SizedBox(
            width: isWide ? 560 : double.infinity,
            child: Text(
              'Recognition shouldn\'t be a generic "good job." Our Star System allows staff to collect recognition that compounds over time, building a career portfolio of empathy and excellence.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.7),
                height: 1.7,
              ),
            ),
          ),
          const SizedBox(height: 48),
          // Stars and numbers timeline image
          Image.asset(
            'assets/images/start-and-numbers.png',
            width: double.infinity,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ROI CALCULATOR SECTION
// ═══════════════════════════════════════════════════════════════

class _RoiCalculatorSection extends StatefulWidget {
  const _RoiCalculatorSection({super.key});

  @override
  State<_RoiCalculatorSection> createState() => _RoiCalculatorSectionState();
}

class _RoiCalculatorSectionState extends State<_RoiCalculatorSection> {
  final _staffController = TextEditingController(text: '250');
  final _salaryController = TextEditingController(text: '28000');
  final _turnoverController = TextEditingController(text: '32');

  int get _staff => int.tryParse(_staffController.text) ?? 250;
  double get _salary => double.tryParse(_salaryController.text) ?? 28000;
  double get _turnover => double.tryParse(_turnoverController.text) ?? 32;

  double get _costPerHire => _salary * 0.3;
  double get _currentTurnoverCost => _staff * (_turnover / 100) * _costPerHire;
  double get _newTurnoverRate => (_turnover * 0.59).clamp(5.0, 100.0);
  double get _projectedSavings =>
      _currentTurnoverCost - (_staff * (_newTurnoverRate / 100) * _costPerHire);
  int get _positionsRetained =>
      ((_staff * (_turnover / 100)) - (_staff * (_newTurnoverRate / 100))).round();
  double get _roi => _projectedSavings / (_staff * 8);

  String _formatCurrency(double value) {
    if (value >= 1000000) {
      return '£${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '£${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
    }
    return '£${value.toStringAsFixed(0)}';
  }

  @override
  void dispose() {
    _staffController.dispose();
    _salaryController.dispose();
    _turnoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 80 : 24,
        vertical: 100,
      ),
      color: Colors.white,
      child: Column(
        children: [
          Text(
            'RETURN ON INVESTMENT',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E3A8A),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'The Business Case for Recognition',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: isWide ? 36 : 28,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF111827),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: isWide ? 560 : double.infinity,
            child: Text(
              'Investing in your team\'s wellbeing isn\'t just the right thing to do—it\'s financially smart.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: const Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 56),
          if (isWide)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _buildInputCard()),
                  const SizedBox(width: 28),
                  Expanded(child: _buildResultsColumn()),
                ],
              ),
            )
          else
            Column(
              children: [
                _buildInputCard(),
                const SizedBox(height: 28),
                _buildResultsColumn(),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildInputCard() {
    return Container(
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withValues(alpha: 0.06),
            blurRadius: 40,
            spreadRadius: 0,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.business_outlined, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Text(
                'Your Organisation',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildInputField('No. of Care Staff', _staffController, Icons.people_outline),
          const SizedBox(height: 22),
          _buildInputField('Average salary (£)', _salaryController, Icons.currency_pound),
          const SizedBox(height: 22),
          _buildInputField(
              'Current annual turnover rate', _turnoverController, Icons.sync_outlined),
          const SizedBox(height: 28),
          Container(height: 1, color: const Color(0xFFF3F4F6)),
          const SizedBox(height: 20),
          _buildCalcRow('Cost per Hire', _formatCurrency(_costPerHire)),
          const SizedBox(height: 14),
          _buildCalcRow('Current turnover cost:', '${_formatCurrency(_currentTurnoverCost)}/yr',
              valueColor: const Color(0xFFDC2626)),
        ],
      ),
    );
  }

  Widget _buildInputField(
      String label, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF111827),
          ),
          decoration: InputDecoration(
            suffixIcon: Icon(icon, size: 18, color: const Color(0xFF9CA3AF)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            filled: true,
            fillColor: const Color(0xFFFAFAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalcRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF6B7280),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: valueColor ?? const Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  Widget _buildResultsColumn() {
    final reductionPct =
        _turnover > 0 ? ((_turnover - _newTurnoverRate) / _turnover * 100).round() : 0;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E3A8A), Color(0xFF152D6B)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E3A8A).withValues(alpha: 0.3),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Projected Annual Savings',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      _formatCurrency(_projectedSavings),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_outline,
                              size: 14, color: Color(0xFF4ADE80)),
                          const SizedBox(width: 4),
                          Text(
                            '$reductionPct% reduction',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF4ADE80),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                      child: _buildMetricBox(
                          '${_newTurnoverRate.toStringAsFixed(0)}%', 'New turnover rate')),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _buildMetricBox('$_positionsRetained', 'Positions retained')),
                  const SizedBox(width: 10),
                  Expanded(
                      child:
                          _buildMetricBox('${_roi.toStringAsFixed(1)}x', 'ROI in year 1')),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E3A8A).withValues(alpha: 0.06),
                blurRadius: 40,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Engagement Growth Over Time',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Based on industry benchmarks and CareKudos customer data',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF9CA3AF),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 200,
                child: _EngagementBarChart(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricBox(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _EngagementBarChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final months = ['Month 1', 'Month 3', 'Month 6', 'Month 12'];
    final values = [15.0, 35.0, 58.0, 85.0];
    final colors = [
      const Color(0xFF38BDF8),
      const Color(0xFF06B6D4),
      const Color(0xFFFBBF24),
      const Color(0xFF1E3A8A),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox(
          width: 28,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('100', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF9CA3AF))),
              Text('75', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF9CA3AF))),
              Text('50', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF9CA3AF))),
              Text('25', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF9CA3AF))),
              Text('0', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF9CA3AF))),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(4, (i) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 14,
                            height: values[i] * 1.1,
                            decoration: BoxDecoration(
                              color: colors[i].withValues(alpha: 0.5),
                              borderRadius:
                                  const BorderRadius.vertical(top: Radius.circular(3)),
                            ),
                          ),
                          const SizedBox(width: 2),
                          Container(
                            width: 14,
                            height: values[i] * 1.3,
                            decoration: BoxDecoration(
                              color: colors[i].withValues(alpha: 0.75),
                              borderRadius:
                                  const BorderRadius.vertical(top: Radius.circular(3)),
                            ),
                          ),
                          const SizedBox(width: 2),
                          Container(
                            width: 14,
                            height: values[i] * 1.5,
                            decoration: BoxDecoration(
                              color: colors[i],
                              borderRadius:
                                  const BorderRadius.vertical(top: Radius.circular(3)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        months[i],
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// TESTIMONIALS SECTION
// ═══════════════════════════════════════════════════════════════

class _TestimonialsSection extends StatefulWidget {
  const _TestimonialsSection();

  @override
  State<_TestimonialsSection> createState() => _TestimonialsSectionState();
}

class _TestimonialsSectionState extends State<_TestimonialsSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const _defaultTestimonial = _Testimonial(
    name: 'Johnathan',
    role: 'Care Manager',
    stars: 4,
    quote:
        '"Our CQC inspector specifically mentioned the staff recognition evidence we downloaded from CareKudos. It turned a gap into a strength."',
  );

  static final _testimonials = List.generate(9, (_) => _defaultTestimonial);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 100),
      color: const Color(0xFFFAFAFB),
      child: Column(
        children: [
          Text(
            'TESTIMONIALS',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E3A8A),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isWide ? 80 : 24),
            child: Text(
              'Trusted by Leaders in Care.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: isWide ? 36 : 28,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF111827),
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 56),
          // Scrolling testimonial columns
          ClipRect(
            child: SizedBox(
              height: 600,
              child: ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.white,
                    Colors.white,
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.08, 0.92, 1.0],
                ).createShader(bounds),
                blendMode: BlendMode.dstIn,
                child: isWide
                  ? Row(
                      children: [
                        const SizedBox(width: 40),
                        Expanded(
                          child: _buildScrollColumn(
                            _testimonials.sublist(0, 3),
                            scrollUp: true,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _buildScrollColumn(
                            _testimonials.sublist(3, 6),
                            scrollUp: false,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _buildScrollColumn(
                            _testimonials.sublist(6, 9),
                            scrollUp: true,
                          ),
                        ),
                        const SizedBox(width: 40),
                      ],
                    )
                  : Row(
                      children: [
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildScrollColumn(
                            _testimonials.sublist(0, 5),
                            scrollUp: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildScrollColumn(
                            _testimonials.sublist(5, 9),
                            scrollUp: false,
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                    ),
            ),
          ),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollColumn(List<_Testimonial> items, {required bool scrollUp}) {
    final loopedItems = [...items, ...items, ...items];

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;
        final columnWidget = Column(
          mainAxisSize: MainAxisSize.min,
          children: loopedItems
              .map((t) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _TestimonialCard(testimonial: t),
                  ))
              .toList(),
        );

        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final totalHeight = items.length * 220.0;
            final offset = (_controller.value * totalHeight) % totalHeight;
            final dy = scrollUp ? -offset : -(totalHeight - offset);

            return Transform.translate(
              offset: Offset(0, dy),
              child: OverflowBox(
                maxHeight: totalHeight * 3,
                alignment: Alignment.topCenter,
                child: columnWidget,
              ),
            );
          },
        );
      },
    );
  }
}

class _Testimonial {
  final String name;
  final String role;
  final int stars;
  final String quote;

  const _Testimonial({
    required this.name,
    required this.role,
    required this.stars,
    required this.quote,
  });
}

class _TestimonialCard extends StatelessWidget {
  final _Testimonial testimonial;

  const _TestimonialCard({required this.testimonial});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile row + stars at top
          Row(
            children: [
              // Circular photo avatar
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFE5E7EB),
                    width: 2,
                  ),
                  image: const DecorationImage(
                    image: NetworkImage(
                      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Name & role
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      testimonial.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      testimonial.role,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Stars
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  return Icon(
                    i < testimonial.stars
                        ? Icons.star_rounded
                        : Icons.star_rounded,
                    size: 22,
                    color: i < testimonial.stars
                        ? const Color(0xFFFBBF24)
                        : const Color(0xFFD1D5DB),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Divider
          Container(
            height: 1,
            color: const Color(0xFFF3F4F6),
          ),
          const SizedBox(height: 18),
          // Quote
          Text(
            testimonial.quote,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF4B5563),
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PRICING SECTION
// ═══════════════════════════════════════════════════════════════

class _PricingSection extends StatelessWidget {
  const _PricingSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        vertical: 100,
        horizontal: isWide ? 80 : 24,
      ),
      child: Column(
        children: [
          Text(
            'Simple, Transparent Pricing',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E3A8A),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Choose the plan that fits your team.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: isWide ? 40 : 30,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF111827),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No hidden fees. No surprises. Just honest pricing for honest care.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: const Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 60),
          isWide
              ? IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: _buildStarterCard()),
                      const SizedBox(width: 24),
                      Expanded(child: _buildProfessionalCard()),
                      const SizedBox(width: 24),
                      Expanded(child: _buildEnterpriseCard()),
                    ],
                  ),
                )
              : Column(
                  children: [
                    _buildStarterCard(),
                    const SizedBox(height: 24),
                    _buildProfessionalCard(),
                    const SizedBox(height: 24),
                    _buildEnterpriseCard(),
                  ],
                ),
          const SizedBox(height: 48),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF6B7280),
                height: 1.6,
              ),
              children: [
                const TextSpan(text: 'All plans include a '),
                TextSpan(
                  text: '14-day free trial',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E3A8A),
                  ),
                ),
                const TextSpan(text: ' with no credit card required. Cancel anytime.\n'),
                const TextSpan(text: 'Volume discounts available for multi-site organisations.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarterCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Starter',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Perfect for small care teams getting started',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '\$199',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF9CA3AF),
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '\$149',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '/month',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          ...[
            'Up to 50 care workers',
            'Unlimited recognition',
            'Basic compliance tracking',
            'Team dashboards',
            'Email Support',
          ].map((f) => _featureRow(f, const Color(0xFF1E3A8A))),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Start Free Trial',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalCard() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E3A8A), Color(0xFF152D6B)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E3A8A).withValues(alpha: 0.3),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Professional',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBBF24),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '25% OFF',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E3A8A),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'For growing healthcare organisations',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '\$349',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.5),
                      decoration: TextDecoration.lineThrough,
                      decorationColor: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '\$279',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '/month',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              ...[
                'Up to 250 care workers',
                'Everything in Starter, plus:',
                'Advanced analytics & reporting',
                'CQC audit workflows',
                'Appraisal management',
                'Custom badges & awards',
                'Priority support',
              ].map((f) => _featureRow(f, Colors.white, isLight: true)),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1E3A8A),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Request Demo',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: -14,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFBBF24).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_awesome, size: 14, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    'Most Popular',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnterpriseCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enterprise',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'For large healthcare networks',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '\$599',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF9CA3AF),
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '\$499',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '/month',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          ...[
            'Unlimited care workers',
            'Everything in Professional, plus:',
            'Dedicated account manager',
            'Custom integrations',
            'White-label options',
            'Advanced security (SSO, SAML)',
            'SLA guarantees',
            'Onboarding & training',
          ].map((f) => _featureRow(f, const Color(0xFF1E3A8A))),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Contact Sales',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureRow(String text, Color checkColor, {bool isLight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Image.asset(
            isLight ? 'assets/images/white_tick.png' : 'assets/images/blue_tick.png',
            width: 20,
            height: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isLight
                    ? Colors.white.withValues(alpha: 0.9)
                    : const Color(0xFF374151),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CONTACT / REQUEST DEMO SECTION
// ═══════════════════════════════════════════════════════════════

class _ContactSection extends StatefulWidget {
  const _ContactSection({super.key});

  @override
  State<_ContactSection> createState() => _ContactSectionState();
}

class _ContactSectionState extends State<_ContactSection> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _orgController = TextEditingController();
  final _teamSizeController = TextEditingController();
  bool _submitting = false;
  bool _submitted = false;

  Future<void> _submitForm() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final org = _orgController.text.trim();
    final teamSize = _teamSizeController.text.trim();

    if (name.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name and email.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await FirebaseFirestore.instance.collection('demo_requests').add({
        'name': name,
        'email': email,
        'organisation': org,
        'teamSize': teamSize,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'new',
      });
      _nameController.clear();
      _emailController.clear();
      _orgController.clear();
      _teamSizeController.clear();
      setState(() => _submitted = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demo request submitted! We\'ll be in touch soon.'),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Something went wrong: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _orgController.dispose();
    _teamSizeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;

    return Container(
      color: const Color(0xFF152D6B),
      padding: EdgeInsets.only(
        top: isWide ? 60 : 50,
        bottom: isWide ? 60 : 50,
        left: isWide ? 80 : 24,
        right: isWide ? 80 : 24,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: isWide
              ? IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 4,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: _buildLeftContent(isWide),
                        ),
                      ),
                      const Spacer(),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: _buildForm(),
                      ),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLeftContent(isWide),
                    const SizedBox(height: 40),
                    _buildForm(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildLeftContent(bool isWide) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          'CONTACT US',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF93C5FD),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Ready to transform your healthcare culture?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: isWide ? 38 : 32,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'No hidden fees. No surprises. Just honest pricing for honest care.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.55),
            height: 1.6,
          ),
        ),
        if (isWide) const Spacer(),
        if (!isWide) const SizedBox(height: 40),
        Text(
          'Your data is safe with us. We never spam, and we respect your privacy.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.35),
            fontStyle: FontStyle.italic,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Request a Demo',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'See CareKudos in action. No pressure, just possibilities.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 24),
          _buildLabel('Full Name'),
          const SizedBox(height: 6),
          _buildTextField(_nameController, 'Your Name', Icons.person_outline_rounded),
          const SizedBox(height: 16),
          _buildLabel('Work Email'),
          const SizedBox(height: 6),
          _buildTextField(_emailController, 'Your Email Address', Icons.email_outlined),
          const SizedBox(height: 16),
          _buildLabel('Organisation Name'),
          const SizedBox(height: 6),
          _buildTextField(_orgController, 'Your Organisation Name', Icons.business_outlined),
          const SizedBox(height: 16),
          _buildLabel('Team Size'),
          const SizedBox(height: 6),
          _buildTextField(_teamSizeController, 'Enter Team Size', Icons.groups_outlined),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF1E3A8A).withValues(alpha: 0.6),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _submitted ? 'Submitted!' : 'Request Demo',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(_submitted ? Icons.check : Icons.arrow_forward, size: 16),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _trustBadge(Icons.shield_outlined, 'GDPR-ready'),
              const SizedBox(width: 16),
              _trustBadge(Icons.person_outline, 'No credit card required'),
              const SizedBox(width: 16),
              _trustBadge(Icons.access_time_rounded, '14-day free trial'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF374151),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon) {
    return TextField(
      controller: controller,
      style: GoogleFonts.inter(
        fontSize: 14,
        color: const Color(0xFF374151),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: const Color(0xFF9CA3AF),
        ),
        suffixIcon: Icon(icon, size: 20, color: const Color(0xFF9CA3AF)),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 1.5),
        ),
        isDense: true,
      ),
    );
  }

  Widget _trustBadge(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 5),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// FOOTER SECTION
// ═══════════════════════════════════════════════════════════════

class _FooterSection extends StatelessWidget {
  const _FooterSection();

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;

    return Container(
      color: const Color(0xFF0A0A0A),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 80 : 24,
              vertical: 48,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  children: [
                    // Main footer content
                    isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Logo + tagline
                              Expanded(
                                flex: 4,
                                child: _buildBrandColumn(),
                              ),
                              const SizedBox(width: 40),
                              // Product
                              Expanded(
                                flex: 2,
                                child: _buildLinkColumn(context, 'Product', [
                                  'Features',
                                  'Integrations',
                                  'Pricing',
                                  'Security',
                                ]),
                              ),
                              // Company
                              Expanded(
                                flex: 2,
                                child: _buildLinkColumn(context, 'Company', [
                                  'About Us',
                                  'Careers',
                                  'Blog',
                                  'Contact',
                                ]),
                              ),
                              // Legal
                              Expanded(
                                flex: 2,
                                child: _buildLinkColumn(context, 'Legal', [
                                  'Privacy Policy',
                                  'Terms of Service',
                                  'Cookie Policy',
                                ]),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildBrandColumn(),
                              const SizedBox(height: 32),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _buildLinkColumn(context, 'Product', [
                                      'Features',
                                      'Integrations',
                                      'Pricing',
                                      'Security',
                                    ]),
                                  ),
                                  Expanded(
                                    child: _buildLinkColumn(context, 'Company', [
                                      'About Us',
                                      'Careers',
                                      'Blog',
                                      'Contact',
                                    ]),
                                  ),
                                  Expanded(
                                    child: _buildLinkColumn(context, 'Legal', [
                                      'Privacy Policy',
                                      'Terms of Service',
                                      'Cookie Policy',
                                    ]),
                                  ),
                                ],
                              ),
                            ],
                          ),
                    const SizedBox(height: 40),
                    // Divider
                    Container(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    const SizedBox(height: 24),
                    // Bottom bar
                    isWide
                        ? Row(
                            children: [
                              Text(
                                '© 2024 CareKudos Ltd. All rights reserved.',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.4),
                                ),
                              ),
                              const Spacer(),
                              _buildSocialIcons(),
                            ],
                          )
                        : Column(
                            children: [
                              _buildSocialIcons(),
                              const SizedBox(height: 16),
                              Text(
                                '© 2024 CareKudos Ltd. All rights reserved.',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.4),
                                ),
                              ),
                            ],
                          ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SvgPicture.asset(
          'assets/images/smallLogo.svg',
          width: 150,
          fit: BoxFit.contain,
          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
        ),
        const SizedBox(height: 16),
        Text(
          'The #1 employee recognition platform built\nexclusively for the healthcare sector.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.45),
            height: 1.6,
          ),
        ),
      ],
    );
  }

  void _handleFooterLink(BuildContext context, String link) {
    final state = context.findAncestorStateOfType<_LandingPageState>();
    if (state == null) return;

    switch (link) {
      case 'Features':
        state._scrollTo(state._platformKey);
      case 'Pricing':
        state._scrollTo(state._pricingKey);
      case 'Contact':
        state._scrollTo(state._contactKey);
      case 'Security':
      case 'Integrations':
      case 'About Us':
      case 'Careers':
      case 'Blog':
      case 'Privacy Policy':
      case 'Terms of Service':
      case 'Cookie Policy':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$link — Coming soon')),
        );
    }
  }

  Widget _buildLinkColumn(BuildContext ctx, String title, List<String> links) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        ...links.map((link) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => _handleFooterLink(ctx, link),
                  child: Text(
                    link,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                  ),
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildSocialIcons() {
    final socials = [
      (FontAwesomeIcons.facebookF, 'https://facebook.com/carekudos'),
      (FontAwesomeIcons.youtube, 'https://youtube.com/@carekudos'),
      (FontAwesomeIcons.instagram, 'https://instagram.com/carekudos'),
      (FontAwesomeIcons.xTwitter, 'https://x.com/carekudos'),
      (FontAwesomeIcons.linkedinIn, 'https://linkedin.com/company/carekudos'),
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < socials.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          InkWell(
            onTap: () => launchUrl(Uri.parse(socials[i].$2)),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
              child: Center(
                child: FaIcon(
                  socials[i].$1,
                  size: 14,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
