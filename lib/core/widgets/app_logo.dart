import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Logo sizes as defined in Figma design system
enum LogoSize {
  /// Small size - 16x16
  sm,
  /// Medium size - 24x24
  md,
  /// Large size - 48x48
  lg,
  /// Extra large size - 64x64
  xl,
  /// Display/hero size - 120x120
  display,
}

/// CareKudos logo widget matching the Figma design system.
/// 
/// Supports multiple sizes: sm (16), md (24), lg (48), xl (64)
/// 
/// Example:
/// ```dart
/// AppLogo(size: LogoSize.md)
/// ```
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = LogoSize.md,
    this.showText = false,
  });

  /// The size of the logo
  final LogoSize size;

  /// Whether to show "CareKudos" text next to logo
  final bool showText;

  double get _dimension {
    switch (size) {
      case LogoSize.sm:
        return 16;
      case LogoSize.md:
        return 24;
      case LogoSize.lg:
        return 48;
      case LogoSize.xl:
        return 64;
      case LogoSize.display:
        return 120;
    }
  }

  @override
  Widget build(BuildContext context) {
    final logo = _buildLogoIcon();

    if (!showText) {
      return logo;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        logo,
        const SizedBox(width: 8),
        Text(
          'CareKudos',
          style: TextStyle(
            fontSize: _dimension * 0.6,
            fontWeight: FontWeight.w700,
            color: AppColors.navy500,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildLogoIcon() {
    // Use appropriate logo size based on dimension
    final logoAsset = _dimension <= 24 
        ? 'assets/images/smallLogo.png' 
        : 'assets/images/bigLogo.png';
    
    return Image.asset(
      logoAsset,
      width: _dimension,
      height: _dimension,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Fallback to placeholder icon if asset not found
        return _buildPlaceholderLogo();
      },
    );
  }

  /// Placeholder logo displayed when asset is not available.
  /// This is a shield with a heart icon in the brand's sky color.
  Widget _buildPlaceholderLogo() {
    return Container(
      width: _dimension,
      height: _dimension,
      decoration: BoxDecoration(
        color: AppColors.sky500,
        borderRadius: BorderRadius.circular(_dimension * 0.2),
      ),
      child: Icon(
        Icons.favorite,
        size: _dimension * 0.55,
        color: AppColors.neutral0,
      ),
    );
  }
}

/// Logo with settings variant (used in settings navigation)
class AppLogoSettings extends StatelessWidget {
  const AppLogoSettings({
    super.key,
    this.size = LogoSize.md,
  });

  final LogoSize size;

  double get _dimension {
    switch (size) {
      case LogoSize.sm:
        return 16;
      case LogoSize.md:
        return 24;
      case LogoSize.lg:
        return 48;
      case LogoSize.xl:
        return 64;
      case LogoSize.display:
        return 120;
    }
  }

  @override
  Widget build(BuildContext context) {
    final logoAsset = _dimension <= 24 
        ? 'assets/images/smallLogo.png' 
        : 'assets/images/bigLogo.png';
    
    return SizedBox(
      width: _dimension,
      height: _dimension,
      child: Stack(
        children: [
          // Main logo
          Image.asset(
            logoAsset,
            width: _dimension,
            height: _dimension,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: _dimension,
                height: _dimension,
                decoration: BoxDecoration(
                  color: AppColors.sky500,
                  borderRadius: BorderRadius.circular(_dimension * 0.2),
                ),
                child: Icon(
                  Icons.favorite,
                  size: _dimension * 0.55,
                  color: AppColors.neutral0,
                ),
              );
            },
          ),
          // Settings gear overlay
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: _dimension * 0.45,
              height: _dimension * 0.45,
              decoration: BoxDecoration(
                color: AppColors.navy500,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.neutral0,
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.settings,
                size: _dimension * 0.28,
                color: AppColors.neutral0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
