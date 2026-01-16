import 'package:flutter/material.dart';

class EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionText;
  final VoidCallback? onAction;
  final IconData? actionIcon;
  final String? secondaryActionText;
  final VoidCallback? onSecondaryAction;

  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionText,
    this.onAction,
    this.actionIcon,
    this.secondaryActionText,
    this.onSecondaryAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 120, color: Colors.grey[300]),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 32),
              actionIcon != null
                  ? ElevatedButton.icon(
                      onPressed: onAction,
                      icon: Icon(actionIcon),
                      label: Text(actionText!),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                    )
                  : ElevatedButton(
                      onPressed: onAction,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                      child: Text(actionText!),
                    ),
            ],
            if (secondaryActionText != null && onSecondaryAction != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: onSecondaryAction,
                child: Text(secondaryActionText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
