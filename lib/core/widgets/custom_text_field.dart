import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// Custom text field matching Figma design
class AppTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int maxLines;
  final int? maxLength;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final void Function(String)? onChanged;
  final bool enabled;
  final bool showCounter;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;

  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hintText,
    this.helperText,
    this.errorText,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.maxLength,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.enabled = true,
    this.showCounter = false,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: AppTypography.bodyB4.copyWith(
              color: hasError ? AppColors.error : AppColors.textSecondary,
            ),
          ),
          AppSpacing.verticalGap8,
        ],
        TextFormField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          decoration: InputDecoration(
            hintText: widget.hintText,
            helperText: widget.helperText,
            errorText: widget.errorText,
            prefixIcon: widget.prefixIcon != null
                ? Icon(widget.prefixIcon, size: 20, color: AppColors.textTertiary)
                : null,
            suffixIcon: widget.obscureText
                ? IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_off : Icons.visibility,
                      size: 20,
                      color: AppColors.textTertiary,
                    ),
                    onPressed: () => setState(() => _obscureText = !_obscureText),
                  )
                : widget.suffixIcon,
            filled: true,
            fillColor: hasError ? AppColors.errorLight : AppColors.neutral0,
            border: OutlineInputBorder(
              borderRadius: AppRadius.allLg,
              borderSide: BorderSide(
                color: hasError ? AppColors.error : AppColors.border,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.allLg,
              borderSide: BorderSide(
                color: hasError ? AppColors.error : AppColors.border,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.allLg,
              borderSide: BorderSide(
                color: hasError ? AppColors.error : AppColors.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: AppRadius.allLg,
              borderSide: const BorderSide(color: AppColors.error),
            ),
            counterText: widget.showCounter ? null : '',
          ),
          keyboardType: widget.keyboardType,
          obscureText: _obscureText,
          maxLines: widget.obscureText ? 1 : widget.maxLines,
          maxLength: widget.maxLength,
          validator: widget.validator,
          onChanged: widget.onChanged,
          enabled: widget.enabled,
          textInputAction: widget.textInputAction,
          onFieldSubmitted: widget.onSubmitted,
          style: AppTypography.bodyB2,
        ),
      ],
    );
  }
}

/// Checkbox with label
class AppCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?>? onChanged;
  final String label;
  final Widget? richLabel;
  final bool enabled;

  const AppCheckbox({
    super.key,
    required this.value,
    this.onChanged,
    this.label = '',
    this.richLabel,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? () => onChanged?.call(!value) : null,
      borderRadius: AppRadius.allSm,
      child: Padding(
        padding: AppSpacing.vertical4,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: value,
                onChanged: enabled ? onChanged : null,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                activeColor: AppColors.primary,
              ),
            ),
            AppSpacing.horizontalGap12,
            Expanded(
              child: richLabel ??
                  Text(
                    label,
                    style: AppTypography.bodyB4.copyWith(
                      color: enabled ? AppColors.textPrimary : AppColors.textDisabled,
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Category chip / tag selector
class AppChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color? selectedColor;
  final Color? selectedBgColor;

  const AppChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.icon,
    this.selectedColor,
    this.selectedBgColor,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isSelected
        ? (selectedBgColor ?? AppColors.primary)
        : AppColors.neutral0;
    final textColor = isSelected
        ? (selectedColor ?? AppColors.neutral0)
        : AppColors.textPrimary;
    final borderColor = isSelected ? Colors.transparent : AppColors.border;

    return Material(
      color: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.allLg,
        side: BorderSide(color: borderColor),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.allLg,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: textColor),
                AppSpacing.horizontalGap4,
              ],
              Text(
                label,
                style: AppTypography.bodyB4.copyWith(color: textColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Category tag (for display, like Compassion, Teamwork)
class CategoryTag extends StatelessWidget {
  final String label;
  final Color color;
  final Color backgroundColor;
  final IconData? icon;
  final bool showIcon;

  const CategoryTag({
    super.key,
    required this.label,
    required this.color,
    required this.backgroundColor,
    this.icon,
    this.showIcon = true,
  });

  factory CategoryTag.compassion({bool showIcon = true}) => CategoryTag(
        label: 'Compassion',
        color: AppColors.compassionTag,
        backgroundColor: AppColors.compassionTagBg,
        icon: Icons.favorite_outline,
        showIcon: showIcon,
      );

  factory CategoryTag.teamwork({bool showIcon = true}) => CategoryTag(
        label: 'Teamwork',
        color: AppColors.teamworkTag,
        backgroundColor: AppColors.teamworkTagBg,
        icon: Icons.groups_outlined,
        showIcon: showIcon,
      );

  factory CategoryTag.excellence({bool showIcon = true}) => CategoryTag(
        label: 'Excellence',
        color: AppColors.excellenceTag,
        backgroundColor: AppColors.excellenceTagBg,
        icon: Icons.star_outline,
        showIcon: showIcon,
      );

  factory CategoryTag.leadership({bool showIcon = true}) => CategoryTag(
        label: 'Leadership',
        color: AppColors.leadershipTag,
        backgroundColor: AppColors.leadershipTagBg,
        icon: Icons.workspace_premium_outlined,
        showIcon: showIcon,
      );

  factory CategoryTag.reliability({bool showIcon = true}) => CategoryTag(
        label: 'Reliability',
        color: AppColors.reliabilityTag,
        backgroundColor: AppColors.reliabilityTagBg,
        icon: Icons.verified_outlined,
        showIcon: showIcon,
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppRadius.allPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon && icon != null) ...[
            Icon(icon, size: 14, color: color),
            AppSpacing.horizontalGap4,
          ],
          Text(
            label,
            style: AppTypography.captionC1.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Legacy alias
typedef CustomTextField = AppTextField;
