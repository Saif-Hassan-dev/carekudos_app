import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? icon;
  final Color? backgroundColor;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.icon,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final button = icon != null
        ? ElevatedButton.icon(
            onPressed: isLoading ? null : onPressed,
            icon: Icon(icon),
            label: _buildChild(),
            style: _buildStyle(),
          )
        : ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: _buildStyle(),
            child: _buildChild(),
          );

    return button;
  }

  Widget _buildChild() {
    return isLoading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        : Text(text);
  }

  ButtonStyle _buildStyle() {
    return ElevatedButton.styleFrom(
      minimumSize: isFullWidth ? const Size(double.infinity, 56) : null,
      padding: isFullWidth
          ? null
          : const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      backgroundColor: backgroundColor,
    );
  }
}
