import 'package:flutter/material.dart';
import '../theme/theme.dart';

enum AppButtonVariant { primary, secondary, text, ghost }
enum AppButtonSize { small, medium, large }

/// Primary button component matching Figma design
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final AppButtonVariant variant;
  final AppButtonSize size;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.leadingIcon,
    this.trailingIcon,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.large,
  });

  // Convenience constructors
  const AppButton.primary({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.leadingIcon,
    this.trailingIcon,
    this.size = AppButtonSize.large,
  }) : variant = AppButtonVariant.primary;

  const AppButton.secondary({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.leadingIcon,
    this.trailingIcon,
    this.size = AppButtonSize.large,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.text({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = false,
    this.leadingIcon,
    this.trailingIcon,
    this.size = AppButtonSize.medium,
  }) : variant = AppButtonVariant.text;

  const AppButton.ghost({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = false,
    this.leadingIcon,
    this.trailingIcon,
    this.size = AppButtonSize.medium,
  }) : variant = AppButtonVariant.ghost;

  @override
  Widget build(BuildContext context) {
    return switch (variant) {
      AppButtonVariant.primary => _buildPrimaryButton(),
      AppButtonVariant.secondary => _buildSecondaryButton(),
      AppButtonVariant.text => _buildTextButton(),
      AppButtonVariant.ghost => _buildGhostButton(),
    };
  }

  Widget _buildPrimaryButton() {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.neutral0,
        disabledBackgroundColor: AppColors.neutral300,
        disabledForegroundColor: AppColors.neutral500,
        minimumSize: isFullWidth ? const Size(double.infinity, 56) : null,
        padding: _getPadding(),
        shape: AppRadius.shapeLg,
        elevation: 0,
      ),
      child: _buildContent(AppColors.neutral0),
    );
  }

  Widget _buildSecondaryButton() {
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: BorderSide(
          color: onPressed == null ? AppColors.neutral300 : AppColors.primary,
          width: 1.5,
        ),
        minimumSize: isFullWidth ? const Size(double.infinity, 56) : null,
        padding: _getPadding(),
        shape: AppRadius.shapeLg,
      ),
      child: _buildContent(AppColors.primary),
    );
  }

  Widget _buildTextButton() {
    return TextButton(
      onPressed: isLoading ? null : onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        minimumSize: isFullWidth ? const Size(double.infinity, 48) : null,
        padding: _getPadding(),
      ),
      child: _buildContent(AppColors.primary),
    );
  }

  Widget _buildGhostButton() {
    return TextButton(
      onPressed: isLoading ? null : onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.textSecondary,
        minimumSize: isFullWidth ? const Size(double.infinity, 48) : null,
        padding: _getPadding(),
      ),
      child: _buildContent(AppColors.textSecondary),
    );
  }

  EdgeInsets _getPadding() {
    return switch (size) {
      AppButtonSize.small => const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      AppButtonSize.medium => const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      AppButtonSize.large => const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    };
  }

  Widget _buildContent(Color color) {
    if (isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      );
    }

    final children = <Widget>[];
    
    if (leadingIcon != null) {
      children.add(Icon(leadingIcon, size: 20));
      children.add(AppSpacing.horizontalGap8);
    }
    
    children.add(Text(text, style: _getTextStyle()));
    
    if (trailingIcon != null) {
      children.add(AppSpacing.horizontalGap8);
      children.add(Icon(trailingIcon, size: 20));
    }

    return Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: children,
    );
  }

  TextStyle _getTextStyle() {
    return switch (size) {
      AppButtonSize.small => AppTypography.actionA3,
      AppButtonSize.medium => AppTypography.actionA2,
      AppButtonSize.large => AppTypography.actionA1,
    };
  }
}

/// Icon button component
class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;
  final bool hasBorder;

  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.size = 40,
    this.hasBorder = false,
  });

  const AppIconButton.filled({
    super.key,
    required this.icon,
    this.onPressed,
    this.backgroundColor = AppColors.primary,
    this.iconColor = AppColors.neutral0,
    this.size = 40,
  }) : hasBorder = false;

  const AppIconButton.outlined({
    super.key,
    required this.icon,
    this.onPressed,
    this.backgroundColor = Colors.transparent,
    this.iconColor = AppColors.primary,
    this.size = 40,
  }) : hasBorder = true;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor ?? Colors.transparent,
      shape: CircleBorder(
        side: hasBorder
            ? const BorderSide(color: AppColors.border)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            icon,
            color: iconColor ?? AppColors.textPrimary,
            size: size * 0.5,
          ),
        ),
      ),
    );
  }
}

/// Quiz action button (Yes/No style)
class QuizActionButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isSelected;
  final bool isCorrect;
  final bool showResult;

  const QuizActionButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isSelected = false,
    this.isCorrect = false,
    this.showResult = false,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    Color borderColor;

    if (showResult && isSelected) {
      backgroundColor = isCorrect ? AppColors.success : AppColors.error;
      textColor = AppColors.neutral0;
      borderColor = backgroundColor;
    } else if (isSelected) {
      backgroundColor = AppColors.neutral100;
      textColor = AppColors.textPrimary;
      borderColor = AppColors.primary;
    } else {
      backgroundColor = AppColors.neutral0;
      textColor = AppColors.textPrimary;
      borderColor = AppColors.border;
    }

    return Material(
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.allLg,
        side: BorderSide(color: borderColor, width: 1.5),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: AppRadius.allLg,
        child: Container(
          width: 100,
          height: 100,
          alignment: Alignment.center,
          child: Text(
            text,
            style: AppTypography.headingH4.copyWith(color: textColor),
          ),
        ),
      ),
    );
  }
}

/// Legacy alias for backward compatibility
typedef CustomButton = AppButton;
