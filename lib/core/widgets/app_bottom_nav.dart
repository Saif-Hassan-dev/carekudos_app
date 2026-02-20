import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// Custom bottom navigation bar matching Figma design
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int notificationCount;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.notificationCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Home',
                isActive: currentIndex == 0,
                onTap: () => onTap(0),
                activeColor: const Color(0xFF0A7AFF),
              ),
              _NavItem(
                icon: Icons.edit_note_outlined,
                activeIcon: Icons.edit_note,
                label: 'Create',
                isActive: currentIndex == 1,
                onTap: () => onTap(1),
                activeColor: const Color(0xFF0A7AFF),
              ),
              _NavItem(
                icon: Icons.notifications_none_rounded,
                activeIcon: Icons.notifications_rounded,
                label: 'Alerts',
                isActive: currentIndex == 2,
                onTap: () => onTap(2),
                badgeCount: notificationCount,
                activeColor: const Color(0xFF0A7AFF),
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Profile',
                isActive: currentIndex == 3,
                onTap: () => onTap(3),
                activeColor: const Color(0xFF0A7AFF),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final int badgeCount;
  final Color activeColor;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.badgeCount = 0,
    this.activeColor = const Color(0xFF0A7AFF),
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? activeColor : const Color(0xFFADB5BD);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Badge(
              isLabelVisible: badgeCount > 0,
              label: Text(
                badgeCount > 99 ? '99+' : badgeCount.toString(),
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
              ),
              backgroundColor: const Color(0xFFEF4444),
              child: Icon(
                isActive ? activeIcon : icon,
                color: color,
                size: 26,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Main scaffold with bottom navigation
class AppScaffold extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onNavigate;
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final int notificationCount;

  const AppScaffold({
    super.key,
    required this.currentIndex,
    required this.onNavigate,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.notificationCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: body,
      bottomNavigationBar: AppBottomNav(
        currentIndex: currentIndex,
        onTap: onNavigate,
        notificationCount: notificationCount,
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}
