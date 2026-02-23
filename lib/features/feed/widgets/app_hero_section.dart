import 'package:flutter/material.dart';

/// Hero/features banner for the top of the feed.
/// Shows a prominent card highlighting the app value proposition
/// and key features.
class AppHeroSection extends StatefulWidget {
  final VoidCallback? onDismiss;
  final VoidCallback? onCreatePost;

  const AppHeroSection({
    super.key,
    this.onDismiss,
    this.onCreatePost,
  });

  @override
  State<AppHeroSection> createState() => _AppHeroSectionState();
}

class _AppHeroSectionState extends State<AppHeroSection> {
  int _currentPage = 0;
  late final PageController _pageController;

  static const _features = [
    _FeatureSlide(
      icon: Icons.star_rounded,
      iconColor: Color(0xFFD4AF37),
      iconBgColor: Color(0xFFFFF8E0),
      title: 'Recognise Great Care',
      description:
          'Give stars to colleagues who go above and beyond. Choose from Peer, Manager, or Family stars.',
    ),
    _FeatureSlide(
      icon: Icons.groups_rounded,
      iconColor: Color(0xFF0A2C6B),
      iconBgColor: Color(0xFFEEF3FB),
      title: 'Build a Caring Community',
      description:
          'Share stories of compassion, teamwork, and excellence. Inspire others with your experiences.',
    ),
    _FeatureSlide(
      icon: Icons.emoji_events_rounded,
      iconColor: Color(0xFF00BCD4),
      iconBgColor: Color(0xFFE0F7FA),
      title: 'Earn Achievements',
      description:
          'Collect stars and unlock badges from Rising Star to Sector Influencer. Track your progress!',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0A2C6B),
            Color(0xFF163D7F),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A2C6B).withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dismiss button row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (widget.onDismiss != null)
                GestureDetector(
                  onTap: widget.onDismiss,
                  child: const Padding(
                    padding: EdgeInsets.only(top: 12, right: 14),
                    child: Icon(Icons.close, color: Colors.white54, size: 20),
                  ),
                ),
            ],
          ),

          // Page view for feature slides
          SizedBox(
            height: 140,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _features.length,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemBuilder: (_, i) {
                final f = _features[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Icon
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: f.iconBgColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(f.icon, color: f.iconColor, size: 30),
                      ),
                      const SizedBox(width: 16),
                      // Text
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              f.title,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              f.description,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: Colors.white70,
                                height: 1.4,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Dots indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _features.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == i ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _currentPage == i
                      ? const Color(0xFFD4AF37)
                      : Colors.white30,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),

          // CTA
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
            child: SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton(
                onPressed: widget.onCreatePost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Share an Achievement',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
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
}

class _FeatureSlide {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String description;

  const _FeatureSlide({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    required this.description,
  });
}
