import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Custom switch widget matching the Figma design system.
/// 
/// Example:
/// ```dart
/// AppSwitch(
///   value: isEnabled,
///   onChanged: (value) => setState(() => isEnabled = value),
/// )
/// ```
class AppSwitch extends StatelessWidget {
  const AppSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.inactiveColor,
    this.disabled = false,
  });

  /// Whether the switch is on or off
  final bool value;

  /// Callback when the switch is toggled
  final ValueChanged<bool>? onChanged;

  /// Color when switch is active (defaults to sky500)
  final Color? activeColor;

  /// Color when switch is inactive (defaults to neutral300)
  final Color? inactiveColor;

  /// Whether the switch is disabled
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final effectiveActiveColor = activeColor ?? AppColors.primary;
    final effectiveInactiveColor = inactiveColor ?? AppColors.neutral300;

    return GestureDetector(
      onTap: disabled ? null : () => onChanged?.call(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 50,
        height: 28,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: disabled
              ? AppColors.neutral200
              : (value ? effectiveActiveColor : effectiveInactiveColor),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: disabled ? AppColors.neutral400 : AppColors.neutral0,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Switch with label text - matches Figma "switch" component variant
class AppSwitchTile extends StatelessWidget {
  const AppSwitchTile({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.disabled = false,
  });

  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : () => onChanged?.call(!value),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: disabled ? AppColors.neutral400 : AppColors.neutral800,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 14,
                        color: disabled ? AppColors.neutral400 : AppColors.neutral600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            AppSwitch(
              value: value,
              onChanged: onChanged,
              disabled: disabled,
            ),
          ],
        ),
      ),
    );
  }
}
