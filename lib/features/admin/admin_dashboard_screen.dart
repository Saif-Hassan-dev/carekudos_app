// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/auth/auth_notifier.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/app_logo.dart';
import '../../../core/utils/pdf_export.dart';
import 'providers/admin_dashboard_provider.dart';

/// Comma-format a number (e.g. 2547 → "2,547")
String _fmt(int n) => NumberFormat('#,###').format(n);

// ═══════════════════════════════════════════════════════════════
// ADMIN DASHBOARD SCREEN
// ═══════════════════════════════════════════════════════════════

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  final _navItems = const [
    _NavItem(icon: Icons.dashboard_rounded, label: 'Dashboard Home'),
    _NavItem(icon: Icons.people_alt_outlined, label: 'User Management'),
    _NavItem(icon: Icons.school_outlined, label: 'Training & Compliance'),
    _NavItem(icon: Icons.bar_chart_rounded, label: 'Analytics & Reports'),
    _NavItem(icon: Icons.settings_outlined, label: 'System Settings'),
    _NavItem(icon: Icons.rate_review_outlined, label: 'Moderation Queue'),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 900;
    final selectedIndex = ref.watch(adminNavIndexProvider);

    return Title(
      title: 'Dashboard — CareKudos Admin',
      color: AppColors.primary,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6F8),
        body: Column(
          children: [
            _TopNavBar(),
            Expanded(
              child: Row(
                children: [
                  if (!isCompact)
                    _Sidebar(
                      items: _navItems,
                      selectedIndex: selectedIndex,
                      onTap: (i) => ref.read(adminNavIndexProvider.notifier).state = i,
                    ),
                  Expanded(child: _buildContent(isCompact, selectedIndex)),
                ],
              ),
            ),
          ],
        ),
        drawer: isCompact
            ? Drawer(
                child: _Sidebar(
                  items: _navItems,
                  selectedIndex: selectedIndex,
                  onTap: (i) {
                    ref.read(adminNavIndexProvider.notifier).state = i;
                    Navigator.pop(context);
                  },
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildContent(bool isCompact, int selectedIndex) {
    switch (selectedIndex) {
      case 1:
        return const _UserManagementContent();
      case 2:
        return _TrainingComplianceContent(isCompact: isCompact);
      case 3:
        return _AnalyticsContent(isCompact: isCompact);
      case 4:
        return const _SystemSettingsContent();
      case 5:
        return const _ModerationQueueContent();
      case 6:
        return const _QuizQuestionsContent();
      case 7:
        return const _TrainingContentAdminPage();
      case 0:
      default:
        return _DashboardContent(isCompact: isCompact);
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// NAV ITEM MODEL
// ═══════════════════════════════════════════════════════════════

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

// ═══════════════════════════════════════════════════════════════
// TOP NAVIGATION BAR
// ═══════════════════════════════════════════════════════════════

class _TopNavBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCompact = MediaQuery.of(context).size.width < 900;

    return Container(
      height: 60,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          if (isCompact)
            IconButton(
              icon: const Icon(Icons.menu, color: Color(0xFF374151)),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          const AppLogo(size: LogoSize.md, showText: true),
          const Spacer(),
          PopupMenuButton<String>(
            offset: const Offset(0, 44),
            onSelected: (value) async {
              if (value == 'logout') {
                await ref
                    .read(authNotifierProvider.notifier)
                    .logout();
                if (context.mounted) {
                  context.go('/admin/login');
                }
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    const Icon(Icons.logout,
                        size: 18, color: Color(0xFF374151)),
                    const SizedBox(width: 10),
                    Text(
                      'Sign Out',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF374151),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            child: const CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFFE5E7EB),
              child: Icon(Icons.person, size: 20, color: Color(0xFF6B7280)),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// LEFT SIDEBAR
// ═══════════════════════════════════════════════════════════════

class _Sidebar extends ConsumerWidget {
  final List<_NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _Sidebar({
    required this.items,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingCount = ref.watch(adminPendingCountProvider).valueOrNull ?? 0;
    return Container(
      width: 240,
      color: const Color(0xFFF7F8FA),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _SidebarItem(
              icon: items[i].icon,
              label: items[i].label,
              isActive: i == selectedIndex,
              badge: i == 5 && pendingCount > 0 ? '$pendingCount' : null,
              onTap: () => onTap(i),
            ),
            if (i < items.length - 1) const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final String? badge;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isActive,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isActive ? const Color(0xFFE8F0FE) : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isActive
                    ? const Color(0xFF1E3A8A)
                    : const Color(0xFF6B7280),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive
                        ? const Color(0xFF1E3A8A)
                        : const Color(0xFF374151),
                  ),
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(badge!,
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// DASHBOARD CONTENT
// ═══════════════════════════════════════════════════════════════

class _DashboardContent extends ConsumerStatefulWidget {
  final bool isCompact;
  const _DashboardContent({required this.isCompact});

  @override
  ConsumerState<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends ConsumerState<_DashboardContent> {
  String _searchQuery = '';
  String _orgFilter = 'All Organisations';
  String _roleFilter = 'All Roles';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Page Title ──
          Text(
            'Dashboard Home',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 20),

          // ── Stats Cards ──
          _StatsRow(isCompact: widget.isCompact),
          const SizedBox(height: 20),

          // ── Filter Bar ──
          _FilterBar(
            searchQuery: _searchQuery,
            orgFilter: _orgFilter,
            roleFilter: _roleFilter,
            onSearchChanged: (v) => setState(() => _searchQuery = v),
            onOrgChanged: (v) => setState(() => _orgFilter = v),
            onRoleChanged: (v) => setState(() => _roleFilter = v),
          ),
          const SizedBox(height: 24),

          // ── User Management Overview ──
          _UserManagementSection(
            searchQuery: _searchQuery,
            orgFilter: _orgFilter,
            roleFilter: _roleFilter,
          ),
          const SizedBox(height: 24),

          // ── Engagement & Compliance Row ──
          _TwoColumnSection(
            isCompact: widget.isCompact,
            left: const _EngagementCard(),
            right: const _ComplianceTrainingCard(),
          ),
          const SizedBox(height: 24),

          // ── Content & Reports Row ──
          _TwoColumnSection(
            isCompact: widget.isCompact,
            left: const _ContentSystemCard(),
            right: const _ReportsCard(),
          ),
          const SizedBox(height: 24),

          // ── Platform Health ──
          const _PlatformHealthCard(),
          const SizedBox(height: 24),

          // ── Notifications & Alerts ──
          const _NotificationsSection(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// USER MANAGEMENT PAGE
// ═══════════════════════════════════════════════════════════════

class _UserManagementContent extends ConsumerStatefulWidget {
  const _UserManagementContent();

  @override
  ConsumerState<_UserManagementContent> createState() =>
      _UserManagementContentState();
}

class _UserManagementContentState
    extends ConsumerState<_UserManagementContent> {
  String _searchQuery = '';
  String _roleFilter = 'All Roles';
  String _orgFilter = 'All Organisations';
  String _statusFilter = 'All Statuses';

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title row ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User Management',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Manage users, roles, organisations, and access',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => const _AddUserDialog(),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: Text(
                  'Add User',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Filter bar ──
          Row(
            children: [
              // Search field
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 44,
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: GoogleFonts.inter(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search by name or email',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF9CA3AF),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                            color: Color(0xFF1E3A8A), width: 1.5),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Role filter
              Expanded(
                child: _UserMgmtDropdown(
                  value: _roleFilter,
                  items: const [
                    'All Roles',
                    'Care Worker',
                    'Senior Carer',
                    'Manager',
                    'Family Member',
                    'Admin',
                  ],
                  onChanged: (v) => setState(() => _roleFilter = v!),
                ),
              ),
              const SizedBox(width: 16),
              // Org filter — real data
              Expanded(
                child: _UserMgmtDropdown(
                  value: _orgFilter,
                  items: [
                    'All Organisations',
                    ...ref
                            .watch(adminOrganizationsProvider)
                            .valueOrNull ??
                        [],
                  ],
                  onChanged: (v) => setState(() => _orgFilter = v!),
                ),
              ),
              const SizedBox(width: 16),
              // Status filter
              Expanded(
                child: _UserMgmtDropdown(
                  value: _statusFilter,
                  items: const [
                    'All Statuses',
                    'Current',
                    'Pending',
                    'Incomplete',
                  ],
                  onChanged: (v) => setState(() => _statusFilter = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Users table ──
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: usersAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Error loading users: $e'),
              ),
              data: (allUsers) {
                // Apply filters
                var filtered = allUsers;

                if (_searchQuery.isNotEmpty) {
                  final q = _searchQuery.toLowerCase();
                  filtered = filtered
                      .where((u) =>
                          u.fullName.toLowerCase().contains(q) ||
                          u.email.toLowerCase().contains(q))
                      .toList();
                }

                if (_roleFilter != 'All Roles') {
                  filtered = filtered
                      .where((u) => u.displayRole == _roleFilter)
                      .toList();
                }

                if (_statusFilter != 'All Statuses') {
                  filtered = filtered
                      .where((u) => u.statusLabel == _statusFilter)
                      .toList();
                }

                if (filtered.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(48),
                    child: Center(
                      child: Text(
                        'No users found',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  );
                }

                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    children: [
                      // Header
                      Container(
                        width: double.infinity,
                        color: const Color(0xFFF9FAFB),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                                flex: 3,
                                child: Text('Name',
                                    style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF6B7280)))),
                            Expanded(
                                flex: 2,
                                child: Text('Role',
                                    style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF6B7280)))),
                            Expanded(
                                flex: 2,
                                child: Text('Organisation',
                                    style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF6B7280)))),
                            Expanded(
                                flex: 2,
                                child: Text('Status',
                                    style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF6B7280)))),
                            const SizedBox(width: 48),
                          ],
                        ),
                      ),
                      // Rows
                      ...filtered.map((user) => Container(
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                    color: Color(0xFFE5E7EB)),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 14),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    user.fullName,
                                    style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF111827)),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    user.displayRole,
                                    style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: const Color(0xFF374151)),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    user.organizationId ?? '—',
                                    style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: const Color(0xFF374151)),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: _StatusBadge(
                                        label: user.statusLabel),
                                  ),
                                ),
                                SizedBox(
                                  width: 48,
                                  child: _UserActionsMenu(user: user),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _UserMgmtDropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _UserMgmtDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.expand_more,
              size: 20, color: Color(0xFF9CA3AF)),
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF374151),
          ),
          items: items
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(item),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// STATS CARDS ROW
// ═══════════════════════════════════════════════════════════════

class _StatsRow extends ConsumerWidget {
  final bool isCompact;
  const _StatsRow({required this.isCompact});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);

    return statsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, _) => Text('Error loading stats: $e'),
      data: (stats) {
        final cards = [
          _StatCard(
            icon: Icons.people_alt_rounded,
            iconBg: const Color(0xFFDBEAFE),
            iconColor: const Color(0xFF3B82F6),
            value: _fmt(stats.totalUsers),
            label: 'Total Users',
          ),
          _StatCard(
            icon: Icons.show_chart,
            iconBg: const Color(0xFFDBEAFE),
            iconColor: const Color(0xFF1E3A8A),
            value: _fmt(stats.activeToday),
            label: 'Active today',
          ),
          _StatCard(
            icon: Icons.access_time_rounded,
            iconBg: const Color(0xFFFEF3C7),
            iconColor: const Color(0xFFF59E0B),
            value: _fmt(stats.pendingActions),
            label: 'Pending actions',
          ),
          _StatCard(
            icon: Icons.warning_amber_rounded,
            iconBg: const Color(0xFFFEE2E2),
            iconColor: const Color(0xFFEF4444),
            value: _fmt(stats.complianceAlerts),
            label: 'Compliance alerts',
          ),
        ];

        if (isCompact) {
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: cards
                .map((c) => SizedBox(
                      width: (MediaQuery.of(context).size.width - 72) / 2,
                      child: c,
                    ))
                .toList(),
          );
        }

        return Row(
          children: [
            for (int i = 0; i < cards.length; i++)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: i == cards.length - 1 ? 0 : 12,
                  ),
                  child: cards[i],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 22, color: iconColor),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// FILTER BAR
// ═══════════════════════════════════════════════════════════════

class _FilterBar extends ConsumerWidget {
  final String searchQuery;
  final String orgFilter;
  final String roleFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onOrgChanged;
  final ValueChanged<String> onRoleChanged;

  const _FilterBar({
    required this.searchQuery,
    required this.orgFilter,
    required this.roleFilter,
    required this.onSearchChanged,
    required this.onOrgChanged,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orgs = ref.watch(adminOrganizationsProvider).valueOrNull ?? [];
    final orgOptions = ['All Organisations', ...orgs];
    const roleOptions = [
      'All Roles',
      'Care Worker',
      'Senior Carer',
      'Manager',
      'Admin',
    ];

    return Row(
      children: [
        // Search
        Expanded(
          child: SizedBox(
            height: 44,
            child: TextField(
              onChanged: onSearchChanged,
              style: GoogleFonts.inter(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search by name or email',
                hintStyle: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF9CA3AF),
                ),
                prefixIcon: const Icon(Icons.search,
                    size: 20, color: Color(0xFF9CA3AF)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                      color: Color(0xFF1E3A8A), width: 1.5),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActiveFilterDropdown(
            icon: Icons.business_outlined,
            value: orgFilter,
            items: orgOptions,
            onChanged: onOrgChanged,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActiveFilterDropdown(
            icon: Icons.people_outline,
            value: roleFilter,
            items: roleOptions,
            onChanged: onRoleChanged,
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: IconButton(
            icon: const Icon(Icons.person_search_outlined,
                size: 20, color: Color(0xFF6B7280)),
            onPressed: () {},
            tooltip: 'Filter by user',
            padding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _FilterDropdown(
            icon: Icons.calendar_today_outlined,
            label: 'Last 30 days',
          ),
        ),
      ],
    );
  }
}

class _ActiveFilterDropdown extends StatelessWidget {
  final IconData icon;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  const _ActiveFilterDropdown({
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.only(left: 14, right: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF6B7280)),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: items.contains(value) ? value : items.first,
                isExpanded: true,
                icon: const Icon(Icons.expand_more,
                    size: 20, color: Color(0xFF9CA3AF)),
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  color: const Color(0xFF374151),
                ),
                items: items
                    .map((item) => DropdownMenuItem(
                          value: item,
                          child: Text(item,
                              overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) onChanged(v);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FilterDropdown({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF6B7280)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF374151),
                fontWeight: FontWeight.w400,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.expand_more,
              size: 20, color: Color(0xFF9CA3AF)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// USER MANAGEMENT OVERVIEW TABLE
// ═══════════════════════════════════════════════════════════════

class _UserManagementSection extends ConsumerWidget {
  final String searchQuery;
  final String orgFilter;
  final String roleFilter;

  const _UserManagementSection({
    required this.searchQuery,
    required this.orgFilter,
    required this.roleFilter,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(adminUsersProvider);

    return _DashCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'User Management Overview',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => const _AddUserDialog(),
                ),
                icon: const Icon(Icons.add, size: 16),
                label: Text(
                  'Add User',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Table ──
          usersAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text('Error loading users: $e'),
            data: (allUsers) {
              // Apply filters
              var filtered = allUsers;
              if (searchQuery.isNotEmpty) {
                final q = searchQuery.toLowerCase();
                filtered = filtered
                    .where((u) =>
                        u.fullName.toLowerCase().contains(q) ||
                        u.email.toLowerCase().contains(q))
                    .toList();
              }
              if (orgFilter != 'All Organisations') {
                filtered = filtered
                    .where((u) => u.organizationId == orgFilter)
                    .toList();
              }
              if (roleFilter != 'All Roles') {
                filtered = filtered
                    .where((u) => u.displayRole == roleFilter)
                    .toList();
              }

              if (filtered.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'No users match the current filters',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                );
              }

              // ── Full-width custom table ──
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Column(
                  children: [
                    // Header
                    Container(
                      width: double.infinity,
                      color: const Color(0xFFF9FAFB),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                              flex: 3,
                              child: Text('Name',
                                  style: GoogleFonts.inter(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF6B7280)))),
                          Expanded(
                              flex: 2,
                              child: Text('Role',
                                  style: GoogleFonts.inter(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF6B7280)))),
                          Expanded(
                              flex: 2,
                              child: Text('Organisation',
                                  style: GoogleFonts.inter(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF6B7280)))),
                          Expanded(
                              flex: 2,
                              child: Text('Status',
                                  style: GoogleFonts.inter(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF6B7280)))),
                          const SizedBox(
                              width: 48,
                              child: Text('',
                                  style: TextStyle(fontSize: 12.5))),
                        ],
                      ),
                    ),
                    // Rows
                    ...filtered.take(15).map((user) => Container(
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                  color: Color(0xFFE5E7EB), width: 1),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              Expanded(
                                  flex: 3,
                                  child: Text(
                                    user.fullName,
                                    style: GoogleFonts.inter(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF111827)),
                                    overflow: TextOverflow.ellipsis,
                                  )),
                              Expanded(
                                  flex: 2,
                                  child: Text(
                                    user.displayRole,
                                    style: GoogleFonts.inter(
                                        fontSize: 13.5,
                                        color: const Color(0xFF374151)),
                                  )),
                              Expanded(
                                  flex: 2,
                                  child: Text(
                                    user.organizationId ?? '—',
                                    style: GoogleFonts.inter(
                                        fontSize: 13.5,
                                        color: const Color(0xFF374151)),
                                    overflow: TextOverflow.ellipsis,
                                  )),
                              Expanded(
                                flex: 2,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: _StatusBadge(
                                      label: user.statusLabel),
                                ),
                              ),
                              SizedBox(
                                width: 48,
                                child: _UserActionsMenu(user: user),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  const _StatusBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (label) {
      case 'Current':
        bg = const Color(0xFFDBEAFE);
        fg = const Color(0xFF1E3A8A);
        break;
      case 'Pending':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFF59E0B);
        break;
      case 'Incomplete':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFEF4444);
        break;
      default:
        bg = const Color(0xFFF3F4F6);
        fg = const Color(0xFF6B7280);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: fg,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// TWO-COLUMN LAYOUT HELPER
// ═══════════════════════════════════════════════════════════════

class _TwoColumnSection extends StatelessWidget {
  final bool isCompact;
  final Widget left;
  final Widget right;

  const _TwoColumnSection({
    required this.isCompact,
    required this.left,
    required this.right,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return Column(
        children: [left, const SizedBox(height: 16), right],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 16),
        Expanded(child: right),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ENGAGEMENT & ACTIVITY CARD
// ═══════════════════════════════════════════════════════════════

class _EngagementCard extends ConsumerWidget {
  const _EngagementCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final engagementAsync = ref.watch(adminEngagementProvider);
    final complianceAsync = ref.watch(adminComplianceProvider);

    return _DashCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Engagement & Activity',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 20),
          engagementAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, _) => Text('Error: $e'),
            data: (engagement) {
              final compliance = complianceAsync.valueOrNull;
              final total = compliance?.totalUsers ?? 1;
              final completed = total > 0
                  ? ((compliance?.gdprTrainingPercent ?? 0) * total / 100)
                      .round()
                  : 0;
              final quizRate = compliance != null && total > 0
                  ? (compliance.gdprTrainingPercent / 100).clamp(0.0, 1.0)
                  : 0.0;
              return Column(
                children: [
                  _MetricRow(
                    icon: Icons.people_alt_rounded,
                    iconColor: const Color(0xFF3B82F6),
                    iconBg: const Color(0xFFDBEAFE),
                    value: _fmt(engagement.dailyActiveUsers),
                    label: 'Daily Active Users',
                  ),
                  const SizedBox(height: 16),
                  _MetricRow(
                    icon: Icons.star_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    iconBg: const Color(0xFFFEF3C7),
                    value: _fmt(engagement.kudosSentMonthly),
                    label: 'Kudos Sent (Month)',
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0E7FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.quiz_outlined,
                          size: 18,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quiz Completion',
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: quizRate,
                                minHeight: 6,
                                backgroundColor: const Color(0xFFE5E7EB),
                                valueColor: const AlwaysStoppedAnimation(
                                  Color(0xFF3B82F6),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '$completed',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E3A8A),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String value;
  final String label;

  const _MetricRow({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// COMPLIANCE & TRAINING CARD
// ═══════════════════════════════════════════════════════════════

class _ComplianceTrainingCard extends ConsumerWidget {
  const _ComplianceTrainingCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final complianceAsync = ref.watch(adminComplianceProvider);

    return _DashCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Compliance & Training',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 20),
          complianceAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, _) => Text('Error: $e'),
            data: (compliance) => Column(
              children: [
                _ProgressRow(
                  label: 'GDPR Training',
                  value: compliance.gdprTrainingPercent.round(),
                  color: const Color(0xFF1E3A8A),
                ),
                const SizedBox(height: 16),
                _ProgressRow(
                  label: 'Onboarding Complete',
                  value: compliance.onboardingCompletePercent.round(),
                  color: const Color(0xFF16A34A),
                ),
                const SizedBox(height: 20),
                if (compliance.expiringCertifications > 0)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            size: 20, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${compliance.expiringCertifications} Expiring Certifications',
                                style: GoogleFonts.inter(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Review required within 30 days',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _ProgressRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF374151),
              ),
            ),
            Text(
              '$value%',
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value / 100,
            minHeight: 8,
            backgroundColor: const Color(0xFFE5E7EB),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CONTENT & SYSTEM CARD
// ═══════════════════════════════════════════════════════════════

class _ContentSystemCard extends ConsumerWidget {
  const _ContentSystemCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueCountAsync = ref.watch(adminModerationQueueCountProvider);
    final queueCount = queueCountAsync.valueOrNull ?? 0;

    void navTo(int index) =>
        ref.read(adminNavIndexProvider.notifier).state = index;

    return _DashCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Content & System',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 12),
          _NavRow(
            icon: Icons.quiz_outlined,
            label: 'Manage Quiz Questions',
            onTap: () => navTo(6),
          ),
          _NavRow(
            icon: Icons.menu_book_outlined,
            label: 'Training Content',
            onTap: () => navTo(7),
          ),
          _NavRow(
            icon: Icons.message_outlined,
            label: 'Moderation Queue',
            badge: queueCount > 0 ? '$queueCount' : null,
            onTap: () => navTo(5),
          ),
          _NavRow(
            icon: Icons.campaign_outlined,
            label: 'Send Announcement',
            onTap: () => showDialog(
              context: context,
              builder: (_) => const _AnnouncementDialog(),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? badge;
  final VoidCallback? onTap;

  const _NavRow({
    required this.icon,
    required this.label,
    this.badge,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF6B7280)),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF374151),
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge!,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
            const Spacer(),
            const Icon(Icons.chevron_right,
                size: 20, color: Color(0xFFD1D5DB)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// REPORTS CARD
// ═══════════════════════════════════════════════════════════════

void _downloadCsv(String csvContent, String filename) {
  final blob = html.Blob([csvContent], 'text/csv');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
}

class _ReportsCard extends ConsumerWidget {
  const _ReportsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(adminUsersProvider);
    final complianceAsync = ref.watch(adminComplianceProvider);

    Future<void> exportEngagement() async {
      final users = usersAsync.valueOrNull ?? [];
      final buf = StringBuffer('Name,Role,Organisation,Active,Kudos\n');
      for (final u in users) {
        buf.writeln('${u.fullName},${u.displayRole},${u.organizationId ?? ''},${u.statusLabel},0');
      }
      _downloadCsv(buf.toString(), 'engagement_report_${DateTime.now().millisecondsSinceEpoch}.csv');
    }

    Future<void> exportCompliance() async {
      final users = usersAsync.valueOrNull ?? [];
      final buf = StringBuffer('Name,Role,Organisation,GDPR Training,Onboarding,Status\n');
      for (final u in users) {
        buf.writeln('${u.fullName},${u.displayRole},${u.organizationId ?? ''},${u.gdprTrainingCompleted ? 'Completed' : 'Pending'},${u.gdprConsentGiven ? 'Completed' : 'Pending'},${u.statusLabel}');
      }
      _downloadCsv(buf.toString(), 'training_compliance_${DateTime.now().millisecondsSinceEpoch}.csv');
    }

    return _DashCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Compliance & Training',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),
          _ReportItem(
            icon: Icons.description_outlined,
            iconBg: const Color(0xFFDBEAFE),
            iconColor: const Color(0xFF3B82F6),
            title: 'Engagement Report',
            subtitle: 'User activity & kudos metrics',
            buttonLabel: 'Export PDF',
            buttonColor: const Color(0xFF16A34A),
            onExport: () {
              PdfExport.exportEngagementReport(
                users: (usersAsync.valueOrNull ?? []).map((u) => {
                  'name': u.fullName,
                  'role': u.displayRole,
                  'org': u.organizationId ?? '',
                  'status': u.statusLabel,
                  'kudos': '${u.totalStars}',
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 16),
          _ReportItem(
            icon: Icons.description_outlined,
            iconBg: const Color(0xFFF3E8FF),
            iconColor: const Color(0xFF7C3AED),
            title: 'Training Compliance',
            subtitle: 'GDPR & certification status',
            buttonLabel: 'Export CSV',
            buttonColor: const Color(0xFF1E3A8A),
            onExport: exportCompliance,
          ),
        ],
      ),
    );
  }
}

class _ReportItem extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final Color buttonColor;
  final VoidCallback? onExport;

  const _ReportItem({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.buttonColor,
    this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF9CA3AF),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: onExport,
                icon: Icon(Icons.download, size: 14, color: Colors.white),
                label: Text(
                  buttonLabel,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
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
// PLATFORM HEALTH CARD
// ═══════════════════════════════════════════════════════════════

class _PlatformHealthCard extends ConsumerWidget {
  const _PlatformHealthCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final complianceAsync = ref.watch(adminComplianceProvider);
    final queueAsync = ref.watch(adminModerationQueueCountProvider);

    final gdprRate =
        complianceAsync.valueOrNull?.gdprTrainingPercent.round() ?? 0;
    final tickets = queueAsync.valueOrNull ?? 0;

    return _DashCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Platform Health',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── System Uptime ──
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.access_time_rounded,
                        size: 20,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '99.9%',
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF111827),
                          ),
                        ),
                        Text(
                          'System Uptime',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 48,
                color: const Color(0xFFE5E7EB),
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),
              // ── App Versions ──
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDBEAFE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.bar_chart_rounded,
                        size: 20,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'App Versions',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF374151),
                                ),
                              ),
                              Text(
                                '$gdprRate%',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1E3A8A),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: gdprRate / 100,
                              minHeight: 8,
                              backgroundColor: const Color(0xFFE5E7EB),
                              valueColor: const AlwaysStoppedAnimation(
                                Color(0xFF1E3A8A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 48,
                color: const Color(0xFFE5E7EB),
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),
              // ── Support Tickets ──
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.confirmation_num_outlined,
                        size: 20,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$tickets',
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF111827),
                          ),
                        ),
                        Text(
                          'Support Tickets Open',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// NOTIFICATIONS & ALERTS
// ═══════════════════════════════════════════════════════════════

class _NotificationsSection extends ConsumerWidget {
  const _NotificationsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(adminPendingPostsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notifications & Alerts',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 12),
        pendingAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, _) => Text('Error: $e'),
          data: (posts) {
            if (posts.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No pending alerts',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              );
            }
            final display = posts.take(4).toList();
            return Wrap(
              spacing: 16,
              runSpacing: 12,
              children: display
                  .map((post) => _AlertCard(
                        title: 'CQC Evidence Report',
                        subtitle: post.gdprFlagged
                            ? 'Possible GDPR concerns detected'
                            : 'Review required within 30 days',
                        onApprove: () async {
                          await approveCertAlert(post.postId);
                          ref.invalidate(adminPendingPostsProvider);
                        },
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _AlertCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final Future<void> Function() onApprove;

  const _AlertCard({
    required this.title,
    required this.subtitle,
    required this.onApprove,
  });

  @override
  State<_AlertCard> createState() => _AlertCardState();
}

class _AlertCardState extends State<_AlertCard> {
  bool _approving = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth > 900
        ? (screenWidth - 240 - 48 - 48 - 16) / 2
        : (screenWidth - 48 - 16) / 2;

    return Container(
      width: cardWidth.clamp(260, 500).toDouble(),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFDBEAFE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.description_outlined,
                size: 18, color: Color(0xFF1E3A8A)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _approving
                ? null
                : () async {
                    setState(() => _approving = true);
                    await widget.onApprove();
                    if (mounted) setState(() => _approving = false);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFF93C5FD),
              elevation: 0,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: _approving
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Approve',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// USER ACTIONS MENU (three-dot)
// ═══════════════════════════════════════════════════════════════

class _UserActionsMenu extends ConsumerWidget {
  final AdminUser user;
  const _UserActionsMenu({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 18, color: Color(0xFF9CA3AF)),
      offset: const Offset(0, 32),
      onSelected: (value) async {
        switch (value) {
          case 'view':
            showDialog(
              context: context,
              builder: (_) => _UserProfileDialog(user: user),
            );
            break;
          case 'edit_role':
            showDialog(
              context: context,
              builder: (_) => _EditRoleDialog(user: user),
            );
            break;
          case 'remove':
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (_) => _ConfirmRemoveDialog(user: user),
            );
            if (confirmed == true) {
              await removeAdminUser(user.uid);
              ref.invalidate(adminUsersProvider);
              ref.invalidate(adminStatsProvider);
            }
            break;
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'view',
          child: Row(children: [
            const Icon(Icons.person_outline,
                size: 16, color: Color(0xFF374151)),
            const SizedBox(width: 10),
            Text('View Profile',
                style: GoogleFonts.inter(
                    fontSize: 13, color: const Color(0xFF374151))),
          ]),
        ),
        PopupMenuItem(
          value: 'edit_role',
          child: Row(children: [
            const Icon(Icons.edit_outlined,
                size: 16, color: Color(0xFF374151)),
            const SizedBox(width: 10),
            Text('Change Role',
                style: GoogleFonts.inter(
                    fontSize: 13, color: const Color(0xFF374151))),
          ]),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'remove',
          child: Row(children: [
            const Icon(Icons.delete_outline,
                size: 16, color: Color(0xFFEF4444)),
            const SizedBox(width: 10),
            Text('Remove User',
                style: GoogleFonts.inter(
                    fontSize: 13, color: const Color(0xFFEF4444))),
          ]),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// USER PROFILE DIALOG
// ═══════════════════════════════════════════════════════════════

class _UserProfileDialog extends StatelessWidget {
  final AdminUser user;
  const _UserProfileDialog({required this.user});

  @override
  Widget build(BuildContext context) {
    Widget _row(String label, String value) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 140,
                child: Text(label,
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF6B7280),
                        fontWeight: FontWeight.w500)),
              ),
              Expanded(
                child: Text(value,
                    style: GoogleFonts.inter(
                        fontSize: 13, color: const Color(0xFF111827))),
              ),
            ],
          ),
        );

    return AlertDialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text('User Profile',
          style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827))),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _row('Full Name', user.fullName),
            _row('Email', user.email),
            _row('Role', user.displayRole),
            _row('Organisation', user.organizationId ?? '—'),
            _row('GDPR Consent',
                user.gdprConsentGiven ? 'Granted' : 'Not Given'),
            _row('GDPR Training',
                user.gdprTrainingCompleted ? 'Completed' : 'Pending'),
            _row('Status', user.statusLabel),
            _row('Total Stars', '${user.totalStars}'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close',
              style: GoogleFonts.inter(
                  fontSize: 14, color: const Color(0xFF1E3A8A))),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// EDIT ROLE DIALOG
// ═══════════════════════════════════════════════════════════════

class _EditRoleDialog extends ConsumerStatefulWidget {
  final AdminUser user;
  const _EditRoleDialog({required this.user});

  @override
  ConsumerState<_EditRoleDialog> createState() => _EditRoleDialogState();
}

class _EditRoleDialogState extends ConsumerState<_EditRoleDialog> {
  late String _selectedRole;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.user.role;
  }

  @override
  Widget build(BuildContext context) {
    const roles = [
      'care_worker',
      'senior_carer',
      'manager',
      'admin',
    ];
    const displayNames = {
      'care_worker': 'Care Worker',
      'senior_carer': 'Senior Carer',
      'manager': 'Manager',
      'admin': 'Admin',
    };

    return AlertDialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text('Change Role — ${widget.user.fullName}',
          style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827))),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select new role:',
                style: GoogleFonts.inter(
                    fontSize: 14, color: const Color(0xFF374151))),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
              items: roles
                  .map((r) => DropdownMenuItem(
                        value: r,
                        child: Text(displayNames[r] ?? r,
                            style: GoogleFonts.inter(fontSize: 14)),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedRole = v);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: Text('Cancel',
              style: GoogleFonts.inter(
                  fontSize: 14, color: const Color(0xFF6B7280))),
        ),
        ElevatedButton(
          onPressed: _saving
              ? null
              : () async {
                  setState(() => _saving = true);
                  await updateAdminUserRole(
                      widget.user.uid, _selectedRole);
                  ref.invalidate(adminUsersProvider);
                  if (context.mounted) Navigator.pop(context);
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child:
                      CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text('Save',
                  style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CONFIRM REMOVE DIALOG
// ═══════════════════════════════════════════════════════════════

class _ConfirmRemoveDialog extends StatelessWidget {
  final AdminUser user;
  const _ConfirmRemoveDialog({required this.user});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text('Remove User',
          style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827))),
      content: Text(
        'Are you sure you want to remove ${user.fullName}? This will delete their profile from the platform.',
        style: GoogleFonts.inter(
            fontSize: 14, color: const Color(0xFF374151)),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Cancel',
              style: GoogleFonts.inter(
                  fontSize: 14, color: const Color(0xFF6B7280))),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEF4444),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
          child: Text('Remove',
              style: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ═══════════════════════════════════════════════════════════════
// ANNOUNCEMENT DIALOG
// ═══════════════════════════════════════════════════════════════

class _AnnouncementDialog extends ConsumerStatefulWidget {
  const _AnnouncementDialog();

  @override
  ConsumerState<_AnnouncementDialog> createState() =>
      _AnnouncementDialogState();
}

class _AnnouncementDialogState extends ConsumerState<_AnnouncementDialog> {
  final _titleCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_titleCtrl.text.trim().isEmpty || _messageCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Title and message are required');
      return;
    }
    setState(() { _sending = true; _error = null; });
    try {
      await FirebaseFirestore.instance.collection('announcements').add({
        'title': _titleCtrl.text.trim(),
        'message': _messageCtrl.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': FirebaseAuth.instance.currentUser?.uid ?? 'admin',
        'type': 'announcement',
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Announcement sent successfully'),
            backgroundColor: Color(0xFF22C55E),
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _sending = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.campaign_outlined,
                      size: 22, color: Color(0xFF1E3A8A)),
                  const SizedBox(width: 10),
                  Text('Send Announcement',
                      style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF111827))),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 20),
                    color: const Color(0xFF6B7280),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('Broadcast a message to all staff members',
                  style: GoogleFonts.inter(
                      fontSize: 13, color: const Color(0xFF6B7280))),
              const SizedBox(height: 24),
              Text('Title',
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF374151))),
              const SizedBox(height: 6),
              TextField(
                controller: _titleCtrl,
                style: GoogleFonts.inter(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'e.g. Important Policy Update',
                  hintStyle: GoogleFonts.inter(
                      fontSize: 14, color: const Color(0xFF9CA3AF)),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: Color(0xFFE5E7EB))),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: Color(0xFFE5E7EB))),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                          color: Color(0xFF1E3A8A), width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
              Text('Message',
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF374151))),
              const SizedBox(height: 6),
              TextField(
                controller: _messageCtrl,
                maxLines: 4,
                style: GoogleFonts.inter(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Write your announcement here...',
                  hintStyle: GoogleFonts.inter(
                      fontSize: 14, color: const Color(0xFF9CA3AF)),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: Color(0xFFE5E7EB))),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: Color(0xFFE5E7EB))),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                          color: Color(0xFF1E3A8A), width: 1.5)),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!,
                    style: GoogleFonts.inter(
                        fontSize: 12, color: Colors.red)),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text('Cancel',
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              color: const Color(0xFF374151))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _sending ? null : _send,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white))
                          : Text('Send',
                              style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ADD USER DIALOG
// ═══════════════════════════════════════════════════════════════

class _AddUserDialog extends ConsumerStatefulWidget {
  const _AddUserDialog();

  @override
  ConsumerState<_AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends ConsumerState<_AddUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _orgCtrl = TextEditingController();
  String _role = 'care_worker';
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _orgCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await addAdminUser(
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        role: _role,
        organizationId: _orgCtrl.text.trim(),
      );
      ref.invalidate(adminUsersProvider);
      ref.invalidate(adminStatsProvider);
      ref.invalidate(adminOrganizationsProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _saving = false;
      });
    }
  }

  InputDecoration _field(String label, {String? hint}) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle:
            GoogleFonts.inter(fontSize: 13, color: const Color(0xFF374151)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );

  @override
  Widget build(BuildContext context) {
    const roles = [
      'care_worker',
      'senior_carer',
      'manager',
      'admin',
    ];
    const displayNames = {
      'care_worker': 'Care Worker',
      'senior_carer': 'Senior Carer',
      'manager': 'Manager',
      'admin': 'Admin',
    };

    return AlertDialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text('Add New User',
          style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827))),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_error!,
                      style: GoogleFonts.inter(
                          fontSize: 13, color: const Color(0xFFEF4444))),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstNameCtrl,
                      decoration: _field('First Name'),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Required'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _lastNameCtrl,
                      decoration: _field('Last Name'),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Required'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _emailCtrl,
                decoration: _field('Email', hint: 'user@example.com'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _role,
                decoration: _field('Role'),
                items: roles
                    .map((r) => DropdownMenuItem(
                          value: r,
                          child: Text(displayNames[r] ?? r,
                              style: GoogleFonts.inter(fontSize: 14)),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _role = v);
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _orgCtrl,
                decoration: _field('Organisation ID',
                    hint: 'e.g. Oakwood Care'),
              ),
              const SizedBox(height: 8),
              Text(
                'Note: A Firestore profile will be created. The user will need Firebase Auth credentials to log in.',
                style: GoogleFonts.inter(
                    fontSize: 11.5, color: const Color(0xFF9CA3AF)),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: Text('Cancel',
              style: GoogleFonts.inter(
                  fontSize: 14, color: const Color(0xFF6B7280))),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
            elevation: 0,
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : Text('Add User',
                  style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// MODERATION QUEUE PAGE
// ═══════════════════════════════════════════════════════════════

class _ModerationQueueContent extends ConsumerStatefulWidget {
  const _ModerationQueueContent();

  @override
  ConsumerState<_ModerationQueueContent> createState() =>
      _ModerationQueueContentState();
}

class _ModerationQueueContentState
    extends ConsumerState<_ModerationQueueContent> {
  String _filter = 'All';

  static const _filters = ['All', 'Pending', 'Approved', 'Rejected'];

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(adminModerationStreamProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Moderation Queue',
                        style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF111827))),
                    const SizedBox(height: 4),
                    postsAsync.when(
                      data: (posts) {
                        final pending =
                            posts.where((p) => p.approvalStatus == 'pending').length;
                        return Text(
                          '$pending post${pending == 1 ? '' : 's'} pending review',
                          style: GoogleFonts.inter(
                              fontSize: 14, color: const Color(0xFF6B7280)),
                        );
                      },
                      loading: () => const SizedBox(),
                      error: (_, __) => const SizedBox(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Filter tabs ──
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: _filters.map((f) {
                final active = _filter == f;
                return GestureDetector(
                  onTap: () => setState(() => _filter = f),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: active
                          ? const Color(0xFF1E3A8A)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(f,
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: active
                                ? Colors.white
                                : const Color(0xFF6B7280))),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // ── Posts ──
          postsAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
            data: (all) {
              final posts = all.where((p) {
                if (_filter == 'All') return true;
                if (_filter == 'Pending') return p.approvalStatus == 'pending';
                if (_filter == 'Approved') return p.approvalStatus == 'approved';
                if (_filter == 'Rejected') return p.approvalStatus == 'rejected';
                return true;
              }).toList();

              if (posts.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(48),
                    child: Column(
                      children: [
                        const Icon(Icons.inbox_outlined,
                            size: 48, color: Color(0xFFD1D5DB)),
                        const SizedBox(height: 12),
                        Text('No posts in this category',
                            style: GoogleFonts.inter(
                                fontSize: 15,
                                color: const Color(0xFF6B7280))),
                      ],
                    ),
                  ),
                );
              }

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  children: [
                    // Table header
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.vertical(
                            top: Radius.circular(12)),
                        border: Border(
                            bottom:
                                BorderSide(color: Color(0xFFE5E7EB))),
                      ),
                      child: Row(
                        children: [
                          Expanded(flex: 3,
                              child: Text('Author',
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF6B7280)))),
                          Expanded(flex: 4,
                              child: Text('Content',
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF6B7280)))),
                          Expanded(flex: 2,
                              child: Text('Category',
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF6B7280)))),
                          Expanded(flex: 1,
                              child: Text('Status',
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF6B7280)))),
                          const SizedBox(width: 140),
                        ],
                      ),
                    ),
                    // Rows
                    ...posts.map((post) => _ModerationRow(post: post)),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }
}

class _ModerationRow extends ConsumerStatefulWidget {
  final AdminModerationPost post;
  const _ModerationRow({required this.post});

  @override
  ConsumerState<_ModerationRow> createState() => _ModerationRowState();
}

class _ModerationRowState extends ConsumerState<_ModerationRow> {
  bool _loading = false;

  Future<void> _approve() async {
    setState(() => _loading = true);
    await adminApprovePost(widget.post.postId);
    // Notify the post author
    if (widget.post.authorId.isNotEmpty) {
      await FirebaseFirestore.instance.collection('push_notifications').add({
        'recipientId': widget.post.authorId,
        'title': 'Your post was approved ✅',
        'body': 'Your recognition post has been approved and is now visible.',
        'data': {'type': 'post_approved', 'postId': widget.post.postId},
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    ref.invalidate(adminModerationStreamProvider);
    ref.invalidate(adminPendingCountProvider);
    ref.invalidate(adminStatsProvider);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _reject() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const _ReasonDialog(title: 'Reject Post'),
    );
    if (reason == null || reason.isEmpty) return;
    setState(() => _loading = true);
    await adminRejectPost(widget.post.postId, reason);
    // Notify the post author
    if (widget.post.authorId.isNotEmpty) {
      await FirebaseFirestore.instance.collection('push_notifications').add({
        'recipientId': widget.post.authorId,
        'title': 'Post needs revision',
        'body': reason.isNotEmpty ? reason : 'Your post requires changes before it can be approved.',
        'data': {'type': 'post_rejected', 'postId': widget.post.postId},
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    ref.invalidate(adminModerationStreamProvider);
    ref.invalidate(adminPendingCountProvider);
    ref.invalidate(adminStatsProvider);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _requestEdit() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const _ReasonDialog(title: 'Request Edit'),
    );
    if (reason == null || reason.isEmpty) return;
    setState(() => _loading = true);
    await adminRequestEdit(widget.post.postId, reason);
    ref.invalidate(adminModerationStreamProvider);
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final isPending = post.approvalStatus == 'pending';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFF1E3A8A),
                  child: Text(
                    post.authorName.isNotEmpty
                        ? post.authorName.trim().split(' ')
                            .map((w) => w.isNotEmpty ? w[0] : '')
                            .take(2)
                            .join()
                            .toUpperCase()
                        : '?',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.authorName,
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF111827)),
                          overflow: TextOverflow.ellipsis),
                      if (post.gdprFlagged)
                        Container(
                          margin: const EdgeInsets.only(top: 3),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('GDPR',
                              style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFEF4444))),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            flex: 4,
            child: Text(
              post.content,
              style: GoogleFonts.inter(
                  fontSize: 13, color: const Color(0xFF374151)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Category
          Expanded(
            flex: 2,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                post.category,
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1E3A8A)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // Status
          Expanded(
            flex: 1,
            child: _ModerationStatusBadge(status: post.approvalStatus),
          ),

          // Actions
          SizedBox(
            width: 140,
            child: _loading
                ? const Center(
                    child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2)))
                : isPending
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ActionBtn(
                              label: 'Approve',
                              color: const Color(0xFF16A34A),
                              onTap: _approve),
                          const SizedBox(width: 6),
                          _ActionBtn(
                              label: 'Reject',
                              color: const Color(0xFFEF4444),
                              onTap: _reject),
                        ],
                      )
                    : TextButton(
                        onPressed: _approve,
                        child: Text('Re-approve',
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(0xFF6B7280))),
                      ),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label,
            style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white)),
      ),
    );
  }
}

class _ModerationStatusBadge extends StatelessWidget {
  final String status;
  const _ModerationStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;
    switch (status) {
      case 'approved':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF16A34A);
        label = 'Approved';
        break;
      case 'rejected':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFEF4444);
        label = 'Rejected';
        break;
      case 'edit_requested':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFF59E0B);
        label = 'Edit Req.';
        break;
      default:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFF59E0B);
        label = 'Pending';
    }
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg)),
    );
  }
}

class _ReasonDialog extends StatefulWidget {
  final String title;
  const _ReasonDialog({required this.title});

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.title,
                  style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF111827))),
              const SizedBox(height: 16),
              TextField(
                controller: _ctrl,
                maxLines: 3,
                autofocus: true,
                style: GoogleFonts.inter(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Enter reason...',
                  hintStyle: GoogleFonts.inter(
                      fontSize: 14, color: const Color(0xFF9CA3AF)),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: Color(0xFFE5E7EB))),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: Color(0xFFE5E7EB))),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                          color: Color(0xFF1E3A8A), width: 1.5)),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: Color(0xFFE5E7EB)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text('Cancel',
                          style: GoogleFonts.inter(fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          Navigator.pop(context, _ctrl.text.trim()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text('Confirm',
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// ═══════════════════════════════════════════════════════════════
// QUIZ QUESTIONS PAGE
// ═══════════════════════════════════════════════════════════════

class _QuizQuestionsContent extends ConsumerWidget {
  const _QuizQuestionsContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionsAsync = ref.watch(adminQuizQuestionsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Manage Quiz Questions',
                        style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: const Color(0xFF111827))),
                    const SizedBox(height: 4),
                    Text('Add, edit or delete GDPR training quiz questions',
                        style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF6B7280))),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => _QuizQuestionDialog(
                    onSave: (q) async {
                      final count = questionsAsync.valueOrNull?.length ?? 0;
                      await addQuizQuestion(
                        question: q['question']!,
                        correctAnswer: q['correctAnswer'] == 'true',
                        correctMessage: q['correctMessage']!,
                        incorrectMessage: q['incorrectMessage']!,
                        category: q['category']!,
                        order: count,
                      );
                      ref.invalidate(adminQuizQuestionsProvider);
                    },
                  ),
                ),
                icon: const Icon(Icons.add, size: 16),
                label: Text('Add Question', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          questionsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: \$e'),
            data: (questions) {
              if (questions.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(48),
                    child: Column(
                      children: [
                        const Icon(Icons.quiz_outlined, size: 48, color: Color(0xFFD1D5DB)),
                        const SizedBox(height: 12),
                        Text('No quiz questions yet. Add some above.',
                            style: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF6B7280))),
                        const SizedBox(height: 8),
                        Text('The mobile GDPR quiz will use these questions.',
                            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF9CA3AF))),
                      ],
                    ),
                  ),
                );
              }
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
                      ),
                      child: Row(children: [
                        Expanded(flex: 1, child: Text('#', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280)))),
                        Expanded(flex: 5, child: Text('Question', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280)))),
                        Expanded(flex: 2, child: Text('Category', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280)))),
                        Expanded(flex: 1, child: Text('Answer', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280)))),
                        const SizedBox(width: 80),
                      ]),
                    ),
                    ...questions.asMap().entries.map((e) {
                      final idx = e.key;
                      final q = e.value;
                      return Container(
                        decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFE5E7EB)))),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        child: Row(
                          children: [
                            Expanded(flex: 1, child: Text('\${idx + 1}', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6B7280)))),
                            Expanded(flex: 5, child: Text(q.question, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF111827)), maxLines: 2, overflow: TextOverflow.ellipsis)),
                            Expanded(flex: 2, child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(6)),
                              child: Text(q.category, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: const Color(0xFF1E3A8A))),
                            )),
                            Expanded(flex: 1, child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: q.correctAnswer ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(q.correctAnswer ? 'Yes' : 'No',
                                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600,
                                      color: q.correctAnswer ? const Color(0xFF16A34A) : const Color(0xFFEF4444))),
                            )),
                            SizedBox(
                              width: 80,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 17, color: Color(0xFF6B7280)),
                                    onPressed: () => showDialog(
                                      context: context,
                                      builder: (_) => _QuizQuestionDialog(
                                        existing: q,
                                        onSave: (data) async {
                                          await updateQuizQuestion(q.id,
                                            question: data['question'],
                                            correctAnswer: data['correctAnswer'] == 'true',
                                            correctMessage: data['correctMessage'],
                                            incorrectMessage: data['incorrectMessage'],
                                            category: data['category'],
                                          );
                                          ref.invalidate(adminQuizQuestionsProvider);
                                        },
                                      ),
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 17, color: Color(0xFFEF4444)),
                                    onPressed: () async {
                                      final ok = await showDialog<bool>(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          title: Text('Delete question?', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                                          content: Text(q.question, style: GoogleFonts.inter(fontSize: 13)),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                                          ],
                                        ),
                                      );
                                      if (ok == true) {
                                        await deleteQuizQuestion(q.id);
                                        ref.invalidate(adminQuizQuestionsProvider);
                                      }
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }
}

class _QuizQuestionDialog extends StatefulWidget {
  final QuizQuestion? existing;
  final Future<void> Function(Map<String, String>) onSave;
  const _QuizQuestionDialog({this.existing, required this.onSave});

  @override
  State<_QuizQuestionDialog> createState() => _QuizQuestionDialogState();
}

class _QuizQuestionDialogState extends State<_QuizQuestionDialog> {
  late final TextEditingController _questionCtrl;
  late final TextEditingController _correctMsgCtrl;
  late final TextEditingController _incorrectMsgCtrl;
  late bool _correctAnswer;
  late String _category;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final q = widget.existing;
    _questionCtrl = TextEditingController(text: q?.question ?? '');
    _correctMsgCtrl = TextEditingController(text: q?.correctMessage ?? '');
    _incorrectMsgCtrl = TextEditingController(text: q?.incorrectMessage ?? '');
    _correctAnswer = q?.correctAnswer ?? true;
    _category = q?.category ?? 'GDPR';
  }

  @override
  void dispose() {
    _questionCtrl.dispose();
    _correctMsgCtrl.dispose();
    _incorrectMsgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.existing == null ? 'Add Quiz Question' : 'Edit Quiz Question',
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF111827))),
              const SizedBox(height: 20),
              _FormField(label: 'Question', controller: _questionCtrl, maxLines: 2),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Category', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF374151))),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE5E7EB)), borderRadius: BorderRadius.circular(8)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _category,
                          isExpanded: true,
                          items: ['GDPR', 'Health & Safety', 'Care Standards', 'General']
                              .map((c) => DropdownMenuItem(value: c, child: Text(c, style: GoogleFonts.inter(fontSize: 14))))
                              .toList(),
                          onChanged: (v) { if (v != null) setState(() => _category = v); },
                        ),
                      ),
                    ),
                  ],
                )),
                const SizedBox(width: 16),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Correct Answer', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF374151))),
                    const SizedBox(height: 6),
                    Row(children: [
                      _AnswerChip(label: 'Yes', selected: _correctAnswer, onTap: () => setState(() => _correctAnswer = true)),
                      const SizedBox(width: 8),
                      _AnswerChip(label: 'No', selected: !_correctAnswer, onTap: () => setState(() => _correctAnswer = false)),
                    ]),
                  ],
                )),
              ]),
              const SizedBox(height: 16),
              _FormField(label: 'Correct Answer Feedback', controller: _correctMsgCtrl, maxLines: 3,
                  hint: 'Shown when user answers correctly...'),
              const SizedBox(height: 16),
              _FormField(label: 'Incorrect Answer Feedback', controller: _incorrectMsgCtrl, maxLines: 3,
                  hint: 'Shown when user answers incorrectly...'),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('Cancel', style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF374151))),
                )),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(
                  onPressed: _saving ? null : () async {
                    if (_questionCtrl.text.trim().isEmpty) return;
                    setState(() => _saving = true);
                    await widget.onSave({
                      'question': _questionCtrl.text.trim(),
                      'correctAnswer': _correctAnswer.toString(),
                      'correctMessage': _correctMsgCtrl.text.trim(),
                      'incorrectMessage': _incorrectMsgCtrl.text.trim(),
                      'category': _category,
                    });
                    if (mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _saving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text('Save', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                )),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int maxLines;
  final String? hint;
  const _FormField({required this.label, required this.controller, this.maxLines = 1, this.hint});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF374151))),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.inter(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF9CA3AF)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 1.5)),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }
}

class _AnswerChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _AnswerChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1E3A8A) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? const Color(0xFF1E3A8A) : const Color(0xFFE5E7EB)),
        ),
        child: Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: selected ? Colors.white : const Color(0xFF374151))),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// TRAINING CONTENT ADMIN PAGE
// ═══════════════════════════════════════════════════════════════

class _TrainingContentAdminPage extends ConsumerWidget {
  const _TrainingContentAdminPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modulesAsync = ref.watch(adminTrainingModulesProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Training Content', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: const Color(0xFF111827))),
                  const SizedBox(height: 4),
                  Text('Manage training modules shown to staff in the mobile app', style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF6B7280))),
                ],
              )),
              ElevatedButton.icon(
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => _TrainingModuleDialog(
                    onSave: (data) async {
                      final count = modulesAsync.valueOrNull?.length ?? 0;
                      await addTrainingModule(
                        title: data['title']!,
                        description: data['description']!,
                        body: data['body']!,
                        category: data['category']!,
                        type: data['type']!,
                        url: data['url']!,
                        order: count,
                      );
                      ref.invalidate(adminTrainingModulesProvider);
                    },
                  ),
                ),
                icon: const Icon(Icons.add, size: 16),
                label: Text('Add Module', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          modulesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: \$e'),
            data: (modules) {
              if (modules.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(48),
                    child: Column(
                      children: [
                        const Icon(Icons.menu_book_outlined, size: 48, color: Color(0xFFD1D5DB)),
                        const SizedBox(height: 12),
                        Text('No training modules yet.', style: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF6B7280))),
                        const SizedBox(height: 8),
                        Text('Add modules to show them in the staff mobile app.', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF9CA3AF))),
                      ],
                    ),
                  ),
                );
              }
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: modules.map((m) => _TrainingModuleCard(module: m, ref: ref)).toList(),
              );
            },
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }
}

class _TrainingModuleCard extends StatelessWidget {
  final TrainingModule module;
  final WidgetRef ref;
  const _TrainingModuleCard({required this.module, required this.ref});

  IconData get _typeIcon {
    switch (module.type) {
      case 'video': return Icons.play_circle_outline;
      case 'pdf': return Icons.picture_as_pdf_outlined;
      default: return Icons.article_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10)),
              child: Icon(_typeIcon, size: 20, color: const Color(0xFF1E3A8A)),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(4)),
                  child: Text(module.category, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF6B7280))),
                ),
                Text(module.type.toUpperCase(), style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF9CA3AF))),
              ],
            )),
          ]),
          const SizedBox(height: 12),
          Text(module.title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF111827))),
          if (module.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(module.description, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280)), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => _TrainingModuleDialog(
                  existing: module,
                  onSave: (data) async {
                    await updateTrainingModule(module.id, {
                      'title': data['title'],
                      'description': data['description'],
                      'body': data['body'],
                      'category': data['category'],
                      'type': data['type'],
                      'url': data['url'],
                    });
                    ref.invalidate(adminTrainingModulesProvider);
                  },
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
                side: const BorderSide(color: Color(0xFFE5E7EB)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              child: Text('Edit', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF374151))),
            )),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text('Delete module?', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    content: Text(module.title, style: GoogleFonts.inter(fontSize: 13)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );
                if (ok == true) {
                  await deleteTrainingModule(module.id);
                  ref.invalidate(adminTrainingModulesProvider);
                }
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                side: const BorderSide(color: Color(0xFFFEE2E2)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              child: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFEF4444)),
            ),
          ]),
        ],
      ),
    );
  }
}

class _TrainingModuleDialog extends StatefulWidget {
  final TrainingModule? existing;
  final Future<void> Function(Map<String, String>) onSave;
  const _TrainingModuleDialog({this.existing, required this.onSave});

  @override
  State<_TrainingModuleDialog> createState() => _TrainingModuleDialogState();
}

class _TrainingModuleDialogState extends State<_TrainingModuleDialog> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _bodyCtrl;
  late final TextEditingController _urlCtrl;
  late String _category;
  late String _type;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final m = widget.existing;
    _titleCtrl = TextEditingController(text: m?.title ?? '');
    _descCtrl = TextEditingController(text: m?.description ?? '');
    _bodyCtrl = TextEditingController(text: m?.body ?? '');
    _urlCtrl = TextEditingController(text: m?.url ?? '');
    _category = m?.category ?? 'GDPR';
    _type = m?.type ?? 'article';
  }

  @override
  void dispose() {
    _titleCtrl.dispose(); _descCtrl.dispose(); _bodyCtrl.dispose(); _urlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.existing == null ? 'Add Training Module' : 'Edit Training Module',
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF111827))),
              const SizedBox(height: 20),
              _FormField(label: 'Title', controller: _titleCtrl),
              const SizedBox(height: 16),
              _FormField(label: 'Short Description', controller: _descCtrl, hint: 'Shown in the module card...'),
              const SizedBox(height: 16),
              _FormField(label: 'Content / Body', controller: _bodyCtrl, maxLines: 5, hint: 'Full training content...'),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Category', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF374151))),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE5E7EB)), borderRadius: BorderRadius.circular(8)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _category,
                          isExpanded: true,
                          items: ['GDPR', 'Health & Safety', 'Care Standards', 'General']
                              .map((c) => DropdownMenuItem(value: c, child: Text(c, style: GoogleFonts.inter(fontSize: 14)))).toList(),
                          onChanged: (v) { if (v != null) setState(() => _category = v); },
                        ),
                      ),
                    ),
                  ],
                )),
                const SizedBox(width: 16),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Type', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF374151))),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE5E7EB)), borderRadius: BorderRadius.circular(8)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _type,
                          isExpanded: true,
                          items: ['article', 'video', 'pdf']
                              .map((t) => DropdownMenuItem(value: t, child: Text(t, style: GoogleFonts.inter(fontSize: 14)))).toList(),
                          onChanged: (v) { if (v != null) setState(() => _type = v); },
                        ),
                      ),
                    ),
                  ],
                )),
              ]),
              const SizedBox(height: 16),
              _FormField(label: 'URL (optional)', controller: _urlCtrl, hint: 'https://... video or PDF link'),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('Cancel', style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF374151))),
                )),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(
                  onPressed: _saving ? null : () async {
                    if (_titleCtrl.text.trim().isEmpty) return;
                    setState(() => _saving = true);
                    await widget.onSave({
                      'title': _titleCtrl.text.trim(),
                      'description': _descCtrl.text.trim(),
                      'body': _bodyCtrl.text.trim(),
                      'category': _category,
                      'type': _type,
                      'url': _urlCtrl.text.trim(),
                    });
                    if (mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _saving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text('Save', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                )),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SYSTEM SETTINGS PAGE  (Firestore-backed)
// ═══════════════════════════════════════════════════════════════

class _SystemSettingsContent extends ConsumerWidget {
  const _SystemSettingsContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(adminSettingsProvider);
    final auditAsync = ref.watch(adminAuditLogsProvider);

    return settingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading settings: $e')),
      data: (settings) => SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title ──
            Text(
              'System Settings',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Configure platform settings, roles, notifications, and integrations',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 28),

            // ── Platform Configuration ──
            _settingsSectionHeading('Platform Configuration'),
            const SizedBox(height: 16),
            _SettingsConfigRow(
              icon: Icons.edit_outlined,
              title: 'Platform Name',
              subtitle: 'Display name for the CareKudos platform',
              value: settings.platformName,
              fieldKey: 'platformName',
              auditLabel: 'platform name',
            ),
            const Divider(height: 1, color: Color(0xFFF3F4F6)),
            _SettingsConfigRow(
              icon: Icons.business_outlined,
              title: 'Default Organisation Settings',
              subtitle: 'New users are assigned to default organisation',
              value: settings.defaultOrgEnabled ? 'Enabled' : 'Disabled',
              fieldKey: 'defaultOrgEnabled',
              auditLabel: 'default organisation settings',
              options: const ['Enabled', 'Disabled'],
            ),
            const Divider(height: 1, color: Color(0xFFF3F4F6)),
            _SettingsConfigRow(
              icon: Icons.storage_outlined,
              title: 'Data Retention Policy',
              subtitle: 'How long user data is stored before archival',
              value: settings.dataRetentionDays,
              fieldKey: 'dataRetentionDays',
              auditLabel: 'data retention policy',
              options: const ['30 days', '60 days', '90 days', '180 days', '365 days'],
            ),
            const Divider(height: 1, color: Color(0xFFF3F4F6)),
            _SettingsConfigRow(
              icon: Icons.language_outlined,
              title: 'Timezone / Locale',
              subtitle: 'Default timezone and language settings',
              value: settings.timezoneLocale,
              fieldKey: 'timezoneLocale',
              auditLabel: 'timezone / locale',
              options: const [
                'GMT (London) / en-GB',
                'CET (Berlin) / de-DE',
                'EST (New York) / en-US',
                'PST (Los Angeles) / en-US',
              ],
            ),
            const SizedBox(height: 32),

            // ── Role & Permission Management ──
            _settingsSectionHeading('Role & Permission Management'),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                    child: SizedBox(
                      width: double.infinity,
                      child: DataTable(
                        headingRowColor:
                            WidgetStateProperty.all(const Color(0xFFF9FAFB)),
                        headingTextStyle: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6B7280),
                        ),
                        dataTextStyle: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF374151),
                        ),
                        columnSpacing: 24,
                        horizontalMargin: 24,
                        columns: const [
                          DataColumn(label: Text('Role')),
                          DataColumn(label: Text('Description')),
                          DataColumn(label: Text('Access Level')),
                        ],
                        rows: [
                          DataRow(cells: [
                            DataCell(Text('Care Worker',
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w500))),
                            const DataCell(Text(
                                'Access to main feed, give/receive kudos, view personal profile and notifications')),
                            DataCell(Text('Upload',
                                style: GoogleFonts.inter(
                                    color: const Color(0xFFF59E0B),
                                    fontWeight: FontWeight.w600))),
                          ]),
                          DataRow(cells: [
                            DataCell(Text('Manager',
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w500))),
                            const DataCell(Text(
                                'Access to care worker features plus team dashboard, reports, and moderation tools')),
                            DataCell(Text('Extended',
                                style: GoogleFonts.inter(
                                    color: const Color(0xFF3B82F6),
                                    fontWeight: FontWeight.w600))),
                          ]),
                          DataRow(cells: [
                            DataCell(Text('Admin',
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w500))),
                            const DataCell(Text(
                                'Full system access including user management, compliance tracking, analytics, and settings')),
                            DataCell(Text('Full Access',
                                style: GoogleFonts.inter(
                                    color: const Color(0xFF1E3A8A),
                                    fontWeight: FontWeight.w600))),
                          ]),
                        ],
                      ),
                    ),
                  ),
                  // Footer
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Role definitions are system-defined and cannot be modified',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              color: const Color(0xFF9CA3AF),
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Manage Permissions',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── Notifications & Alerts Configuration ──
            _settingsSectionHeading('Notifications & Alerts Configuration'),
            const SizedBox(height: 16),
            _SettingsToggleRow(
              icon: Icons.notifications_outlined,
              title: 'Compliance Alerts',
              subtitle:
                  'Send alerts for certification expiry and non-compliance',
              value: settings.complianceAlerts,
              fieldKey: 'complianceAlerts',
            ),
            const SizedBox(height: 6),
            _SettingsToggleRow(
              icon: Icons.school_outlined,
              title: 'Training Reminders',
              subtitle:
                  'Remind users to complete GDPR and onboarding training',
              value: settings.trainingReminders,
              fieldKey: 'trainingReminders',
            ),
            const SizedBox(height: 6),
            _SettingsToggleRow(
              icon: Icons.campaign_outlined,
              title: 'System Announcements',
              subtitle:
                  'Broadcast platform updates and maintenance notices',
              value: settings.systemAnnouncements,
              fieldKey: 'systemAnnouncements',
            ),
            const SizedBox(height: 32),

            // ── System Info ──
            _settingsSectionHeading('System Info'),
            const SizedBox(height: 16),
            Row(
              children: [
                _sysInfoCardWidget(
                  dotColor: const Color(0xFF16A34A),
                  label: 'System Uptime',
                  value: '99.8%',
                  sub: 'Last 30 days',
                ),
                const SizedBox(width: 16),
                _sysInfoCardWidget(
                  dotColor: const Color(0xFF3B82F6),
                  label: 'Current App Version',
                  value: 'v2.4.1',
                  sub: 'Production',
                ),
                const SizedBox(width: 16),
                _sysInfoCardWidget(
                  dotColor: const Color(0xFFF59E0B),
                  label: 'Last Deployment',
                  value: 'Feb 5',
                  sub: '2026 at 14:30 GMT',
                ),
                const SizedBox(width: 16),
                _sysInfoCardWidget(
                  dotColor: const Color(0xFF16A34A),
                  label: 'API Status',
                  value: 'Healthy',
                  sub: 'All services operational',
                ),
              ],
            ),
            const SizedBox(height: 32),

            // ── Connected Integrations ──
            _settingsSectionHeading('Connected Integrations'),
            const SizedBox(height: 16),
            Row(
              children: [
                _integrationChipWidget(
                  icon: Icons.hub_outlined,
                  label: 'HR System',
                  connected: true,
                ),
                const SizedBox(width: 24),
                _integrationChipWidget(
                  icon: Icons.email_outlined,
                  label: 'Email Service',
                  connected: true,
                ),
                const SizedBox(width: 24),
                _integrationChipWidget(
                  icon: Icons.cloud_outlined,
                  label: 'Cloud Storage',
                  connected: false,
                ),
              ],
            ),
            const SizedBox(height: 32),

            // ── Audit & Logs Summary (REAL DATA) ──
            _settingsSectionHeading('Audit & Logs Summary'),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                    child: SizedBox(
                      width: double.infinity,
                      child: auditAsync.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (e, _) => Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text('Error loading audit logs: $e'),
                        ),
                        data: (logs) {
                          if (logs.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.all(24),
                              child: Center(
                                child: Text(
                                  'No audit logs yet — changes you make will appear here',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: const Color(0xFF9CA3AF),
                                  ),
                                ),
                              ),
                            );
                          }
                          return DataTable(
                            headingRowColor: WidgetStateProperty.all(
                                const Color(0xFFF9FAFB)),
                            headingTextStyle: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF6B7280),
                            ),
                            dataTextStyle: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF374151),
                            ),
                            columnSpacing: 24,
                            horizontalMargin: 24,
                            columns: const [
                              DataColumn(label: Text('Action')),
                              DataColumn(label: Text('User')),
                              DataColumn(label: Text('Details')),
                              DataColumn(label: Text('Timestamp')),
                            ],
                            rows: logs.map((log) {
                              final ts = DateFormat('yyyy-MM-dd HH:mm')
                                  .format(log.timestamp);
                              return DataRow(cells: [
                                DataCell(Text(log.action)),
                                DataCell(Text(log.user)),
                                DataCell(Text(log.details)),
                                DataCell(Text(ts,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: const Color(0xFF9CA3AF),
                                    ))),
                              ]);
                            }).toList(),
                          );
                        },
                      ),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                    ),
                    child: Text(
                      'Showing recent system changes • Live audit log',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}

// ── Shared helper widgets for System Settings ──

Widget _settingsSectionHeading(String text) {
  return Text(
    text,
    style: GoogleFonts.inter(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: const Color(0xFF111827),
    ),
  );
}

Widget _sysInfoCardWidget({
  required Color dotColor,
  required String label,
  required String value,
  required String sub,
}) {
  return Expanded(
    child: Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _integrationChipWidget({
  required IconData icon,
  required String label,
  required bool connected,
}) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 20, color: const Color(0xFF374151)),
      const SizedBox(width: 8),
      Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF111827),
        ),
      ),
      const SizedBox(width: 10),
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: connected
              ? const Color(0xFF16A34A)
              : const Color(0xFFF59E0B),
          shape: BoxShape.circle,
        ),
      ),
      const SizedBox(width: 6),
      Text(
        connected ? 'Connected' : 'Not Connected',
        style: GoogleFonts.inter(
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
          color: connected
              ? const Color(0xFF16A34A)
              : const Color(0xFFF59E0B),
        ),
      ),
    ],
  );
}

/// Editable config row — tapping opens a dropdown to pick a new value
class _SettingsConfigRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String value;
  final String fieldKey;
  final String auditLabel;
  final List<String>? options;

  const _SettingsConfigRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.fieldKey,
    required this.auditLabel,
    this.options,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showEditDialog(context),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFDBEAFE),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, size: 18, color: const Color(0xFF1E3A8A)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.expand_more,
                size: 18, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context) async {
    if (options != null && options!.isNotEmpty) {
      // Show a selection dialog
      final picked = await showDialog<String>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: Text(
            'Change $title',
            style: GoogleFonts.inter(
                fontSize: 16, fontWeight: FontWeight.w600),
          ),
          children: options!.map((opt) {
            return SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, opt),
              child: Row(
                children: [
                  if (opt == value)
                    const Icon(Icons.check,
                        size: 18, color: Color(0xFF1E3A8A))
                  else
                    const SizedBox(width: 18),
                  const SizedBox(width: 10),
                  Text(opt,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight:
                            opt == value ? FontWeight.w600 : FontWeight.w400,
                        color: const Color(0xFF111827),
                      )),
                ],
              ),
            );
          }).toList(),
        ),
      );
      if (picked != null && picked != value) {
        dynamic firestoreValue = picked;
        // Convert "Enabled"/"Disabled" to bool for defaultOrgEnabled
        if (fieldKey == 'defaultOrgEnabled') {
          firestoreValue = picked == 'Enabled';
        }
        await updateAdminSetting(
          fields: {fieldKey: firestoreValue},
          auditDetails: 'Changed $auditLabel to "$picked"',
        );
      }
    } else {
      // Free-text edit
      final controller = TextEditingController(text: value);
      final newValue = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
            'Edit $title',
            style: GoogleFonts.inter(
                fontSize: 16, fontWeight: FontWeight.w600),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: GoogleFonts.inter(fontSize: 14),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: GoogleFonts.inter(color: const Color(0xFF6B7280))),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
              ),
              child: Text('Save',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
      if (newValue != null && newValue.isNotEmpty && newValue != value) {
        await updateAdminSetting(
          fields: {fieldKey: newValue},
          auditDetails: 'Changed $auditLabel from "$value" to "$newValue"',
        );
      }
    }
  }
}

/// Toggle row that writes to Firestore on change
class _SettingsToggleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final String fieldKey;

  const _SettingsToggleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.fieldKey,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 22, color: const Color(0xFF6B7280)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: (v) async {
              await updateAdminSetting(
                fields: {fieldKey: v},
                auditDetails:
                    '${v ? "Enabled" : "Disabled"} $title',
              );
            },
            activeThumbColor: Colors.white,
            activeTrackColor: const Color(0xFF1E3A8A),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFFD1D5DB),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// REUSABLE DASHBOARD CARD
// ═══════════════════════════════════════════════════════════════

class _DashCard extends StatelessWidget {
  final Widget child;
  const _DashCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: child,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ANALYTICS & REPORTS PAGE (nav index 3)
// ═══════════════════════════════════════════════════════════════

class _AnalyticsContent extends ConsumerStatefulWidget {
  final bool isCompact;
  const _AnalyticsContent({required this.isCompact});

  @override
  ConsumerState<_AnalyticsContent> createState() => _AnalyticsContentState();
}

class _AnalyticsContentState extends ConsumerState<_AnalyticsContent> {
  String _periodFilter = 'Last 30 Days';
  String _orgFilter = 'All Organisations';
  String _roleFilter = 'All Roles';

  void _applyPeriodFilter(String period) {
    final now = DateTime.now();
    DateTimeRange range;
    switch (period) {
      case 'Last 7 Days':
        range = DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now);
        break;
      case 'Last 90 Days':
        range = DateTimeRange(start: now.subtract(const Duration(days: 90)), end: now);
        break;
      case 'This Year':
        range = DateTimeRange(start: DateTime(now.year, 1, 1), end: now);
        break;
      case 'Custom Range':
        _pickCustomRange();
        return;
      default: // Last 30 Days
        range = DateTimeRange(start: now.subtract(const Duration(days: 30)), end: now);
    }
    ref.read(adminDateRangeProvider.notifier).state = range;
    setState(() => _periodFilter = period);
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: now,
      initialDateRange: ref.read(adminDateRangeProvider),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF1E3A8A),
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      ref.read(adminDateRangeProvider.notifier).state = picked;
      setState(() => _periodFilter = 'Custom Range');
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateRange = ref.watch(adminDateRangeProvider);
    final rangeLabel = _periodFilter == 'Custom Range'
        ? '${DateFormat('MMM d').format(dateRange.start)} – ${DateFormat('MMM d').format(dateRange.end)}'
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title ──
          Text(
            'Analytics & Reports',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'View engagement metrics, training analytics, and export reports',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 24),

          // ── Filter Bar ──
          Row(
            children: [
              Expanded(
                child: _UserMgmtDropdown(
                  value: _periodFilter,
                  items: const [
                    'Last 7 Days',
                    'Last 30 Days',
                    'Last 90 Days',
                    'This Year',
                    'Custom Range',
                  ],
                  onChanged: (v) => _applyPeriodFilter(v!),
                ),
              ),
              if (rangeLabel != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(rangeLabel,
                      style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1E3A8A))),
                ),
              ],
              const SizedBox(width: 16),
              Expanded(
                child: _UserMgmtDropdown(
                  value: _orgFilter,
                  items: const ['All Organisations'],
                  onChanged: (v) => setState(() => _orgFilter = v!),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _UserMgmtDropdown(
                  value: _roleFilter,
                  items: const [
                    'All Roles',
                    'Care Worker',
                    'Senior Carer',
                    'Manager',
                    'Family Member',
                  ],
                  onChanged: (v) => setState(() => _roleFilter = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // ── Analytics Overview ──
          _AnalyticsSectionTitle(title: 'Analytics Overview'),
          const SizedBox(height: 16),
          _AnalyticsOverviewCards(isCompact: widget.isCompact),
          const SizedBox(height: 28),

          // ── Engagement Analytics ──
          _AnalyticsSectionTitle(title: 'Engagement Analytics'),
          const SizedBox(height: 16),
          _EngagementChartsRow(isCompact: widget.isCompact),
          const SizedBox(height: 28),

          // ── GDPR Compliance Overview ──
          _AnalyticsSectionTitle(title: 'GDPR Compliance Overview'),
          const SizedBox(height: 16),
          _GdprComplianceChartsRow(isCompact: widget.isCompact),
          const SizedBox(height: 28),

          // ── Training & Onboarding Analytics ──
          _AnalyticsSectionTitle(title: 'Training & Onboarding Analytics'),
          const SizedBox(height: 16),
          _TrainingAnalyticsRow(isCompact: widget.isCompact),
          const SizedBox(height: 28),

          // ── Reports ──
          _AnalyticsSectionTitle(title: 'Reports'),
          const SizedBox(height: 16),
          const _ReportsSection(),
          const SizedBox(height: 28),
        ],
      ),
    );
  }
}

// ─── Section title helper ───

class _AnalyticsSectionTitle extends StatelessWidget {
  final String title;
  const _AnalyticsSectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF111827),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ANALYTICS OVERVIEW — 4 KPI CARDS
// ═══════════════════════════════════════════════════════════════

class _AnalyticsOverviewCards extends ConsumerWidget {
  final bool isCompact;
  const _AnalyticsOverviewCards({required this.isCompact});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminAnalyticsOverviewProvider);
    return async.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, _) => Text('Error: $e'),
      data: (data) {
        String fmtPct(double v) =>
            v >= 0 ? '+${v.toStringAsFixed(1)}%' : '${v.toStringAsFixed(1)}%';

        final cards = [
          _AnalyticsKpiCard(
            indicatorColor: const Color(0xFF22C55E),
            label: 'Daily Active Users',
            value: _fmt(data.dailyActiveUsers),
            subtitle: '${fmtPct(data.dailyChangePercent)} from yesterday',
            subtitleColor: data.dailyChangePercent >= 0
                ? const Color(0xFF22C55E)
                : const Color(0xFFEF4444),
          ),
          _AnalyticsKpiCard(
            indicatorColor: const Color(0xFF3B82F6),
            label: 'Monthly Active Users',
            value: _fmt(data.monthlyActiveUsers),
            subtitle:
                '${fmtPct(data.monthlyChangePercent)} from last month',
            subtitleColor: data.monthlyChangePercent >= 0
                ? const Color(0xFF22C55E)
                : const Color(0xFFEF4444),
          ),
          _AnalyticsKpiCard(
            indicatorColor: const Color(0xFF1E3A8A),
            label: 'Total Kudos Sent',
            value: _fmt(data.totalKudosSent),
            subtitle: 'Last 30 days',
            subtitleColor: const Color(0xFF6B7280),
          ),
          _AnalyticsKpiCard(
            indicatorColor: const Color(0xFF9CA3AF),
            label: 'Avg Kudos per User',
            value: data.avgKudosPerUser.toStringAsFixed(1),
            subtitle: 'Per month average',
            subtitleColor: const Color(0xFF6B7280),
          ),
        ];

        if (isCompact) {
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: cards
                .map((c) => SizedBox(
                      width: (MediaQuery.of(context).size.width - 80) / 2,
                      child: c,
                    ))
                .toList(),
          );
        }

        return Row(
          children: [
            for (int i = 0; i < cards.length; i++)
              Expanded(
                child: Padding(
                  padding:
                      EdgeInsets.only(right: i == cards.length - 1 ? 0 : 12),
                  child: cards[i],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _AnalyticsKpiCard extends StatelessWidget {
  final Color indicatorColor;
  final String label;
  final String value;
  final String subtitle;
  final Color subtitleColor;

  const _AnalyticsKpiCard({
    required this.indicatorColor,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: indicatorColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: subtitleColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ENGAGEMENT CHARTS ROW
// ═══════════════════════════════════════════════════════════════

class _EngagementChartsRow extends StatelessWidget {
  final bool isCompact;
  const _EngagementChartsRow({required this.isCompact});

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return Column(
        children: const [
          _DailyMonthlyLineChart(),
          SizedBox(height: 16),
          _KudosSentReceivedBarChart(),
        ],
      );
    }
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _DailyMonthlyLineChart()),
        SizedBox(width: 16),
        Expanded(child: _KudosSentReceivedBarChart()),
      ],
    );
  }
}

// ─── Daily vs Monthly Active Line Chart ───

class _DailyMonthlyLineChart extends ConsumerWidget {
  const _DailyMonthlyLineChart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chartAsync = ref.watch(adminEngagementChartFilteredProvider);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily vs Monthly Active Users',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: chartAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  Center(child: Text('$e', style: GoogleFonts.inter())),
              data: (data) => _buildChart(data),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              _ChartLegendDash(
                  color: Color(0xFF06B6D4), label: 'Daily Active'),
              SizedBox(width: 24),
              _ChartLegendDash(
                  color: Color(0xFF1E3A8A), label: 'Monthly Active'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChart(AdminEngagementChartData data) {
    final all = [...data.dailyActive, ...data.monthlyActive];
    final maxVal = all.isEmpty ? 0.0 : all.reduce((a, b) => a > b ? a : b);
    final maxY = maxVal == 0 ? 10.0 : (maxVal * 1.3).ceilToDouble();
    final interval =
        maxY <= 10 ? 2.0 : (maxY / 4).ceilToDouble();

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots
                .map((s) => LineTooltipItem(
                      s.y.toInt().toString(),
                      GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ))
                .toList(),
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx >= 0 &&
                    idx < data.labels.length &&
                    idx % 2 == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      data.labels[idx],
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: interval,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: const Color(0xFF9CA3AF),
                ),
              ),
            ),
          ),
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (_) => const FlLine(
            color: Color(0xFFF3F4F6),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          // Daily Active — teal
          LineChartBarData(
            spots: List.generate(
              data.dailyActive.length,
              (i) => FlSpot(i.toDouble(), data.dailyActive[i]),
            ),
            isCurved: true,
            color: const Color(0xFF06B6D4),
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF06B6D4).withValues(alpha: 0.08),
            ),
          ),
          // Monthly Active — navy
          LineChartBarData(
            spots: List.generate(
              data.monthlyActive.length,
              (i) => FlSpot(i.toDouble(), data.monthlyActive[i]),
            ),
            isCurved: true,
            color: const Color(0xFF1E3A8A),
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF1E3A8A).withValues(alpha: 0.06),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Kudos Sent vs Received Bar Chart ───

class _KudosSentReceivedBarChart extends ConsumerWidget {
  const _KudosSentReceivedBarChart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chartAsync = ref.watch(adminKudosChartFilteredProvider);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kudos Sent vs Received',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: chartAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  Center(child: Text('$e', style: GoogleFonts.inter())),
              data: (data) => _buildChart(data),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              _ChartLegendSquare(
                  color: Color(0xFF1E3A8A), label: 'Kudos Sent'),
              SizedBox(width: 24),
              _ChartLegendSquare(
                  color: Color(0xFF93C5FD), label: 'Kudos Received'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChart(AdminKudosChartData data) {
    final all = [...data.sent, ...data.received];
    final maxVal = all.isEmpty ? 0.0 : all.reduce((a, b) => a > b ? a : b);
    final maxY = maxVal == 0 ? 10.0 : (maxVal * 1.3).ceilToDouble();
    final interval = maxY <= 10 ? 2.0 : (maxY / 4).ceilToDouble();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => const Color(0xFF1E3A8A),
            tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            tooltipBorderRadius: BorderRadius.circular(8),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final label = rodIndex == 0 ? 'Sent' : 'Received';
              return BarTooltipItem(
                '$label: ${rod.toY.toInt()}',
                GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx >= 0 && idx < data.months.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      data.months[idx],
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              interval: interval,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: const Color(0xFF9CA3AF),
                ),
              ),
            ),
          ),
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (_) => const FlLine(
            color: Color(0xFFF3F4F6),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(data.months.length, (i) {
          return BarChartGroupData(
            x: i,
            barsSpace: 4,
            barRods: [
              BarChartRodData(
                toY: data.sent[i],
                color: const Color(0xFF1E3A8A),
                width: 14,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4)),
              ),
              BarChartRodData(
                toY: data.received[i],
                color: const Color(0xFF93C5FD),
                width: 14,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4)),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ─── Chart legend helpers ───

class _ChartLegendDash extends StatelessWidget {
  final Color color;
  final String label;
  const _ChartLegendDash({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 3,
          decoration:
              BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 12, color: const Color(0xFF6B7280))),
      ],
    );
  }
}

class _ChartLegendSquare extends StatelessWidget {
  final Color color;
  final String label;
  const _ChartLegendSquare({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 12, color: const Color(0xFF6B7280))),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// TRAINING & ONBOARDING ANALYTICS ROW
// ═══════════════════════════════════════════════════════════════

class _TrainingAnalyticsRow extends ConsumerWidget {
  final bool isCompact;
  const _TrainingAnalyticsRow({required this.isCompact});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminTrainingAnalyticsProvider);
    return async.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, _) => Text('Error: $e'),
      data: (data) {
        final gdprCard = _TrainingProgressCard(
          indicatorColor: const Color(0xFF1E3A8A),
          label: 'GDPR Training Completion',
          percent: data.gdprPercent,
          barColor: const Color(0xFF1E3A8A),
          completed: data.gdprCompleted,
          total: data.totalUsers,
        );
        final onboardingCard = _TrainingProgressCard(
          indicatorColor: const Color(0xFF22C55E),
          label: 'Onboarding Completion',
          percent: data.onboardingPercent,
          barColor: const Color(0xFF22C55E),
          completed: data.onboardingCompleted,
          total: data.totalUsers,
        );

        if (isCompact) {
          return Column(children: [
            gdprCard,
            const SizedBox(height: 12),
            onboardingCard,
          ]);
        }

        return Row(
          children: [
            Expanded(child: gdprCard),
            const SizedBox(width: 16),
            Expanded(child: onboardingCard),
          ],
        );
      },
    );
  }
}

class _TrainingProgressCard extends StatelessWidget {
  final Color indicatorColor;
  final String label;
  final double percent;
  final Color barColor;
  final int completed;
  final int total;

  const _TrainingProgressCard({
    required this.indicatorColor,
    required this.label,
    required this.percent,
    required this.barColor,
    required this.completed,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (percent / 100).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: indicatorColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF374151),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${percent.toStringAsFixed(0)}%',
            style: GoogleFonts.inter(
              fontSize: 40,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
              height: 1,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: const Color(0xFFF3F4F6),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$completed of $total users completed',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// GDPR COMPLIANCE CHARTS
// ═══════════════════════════════════════════════════════════════

class _GdprComplianceChartsRow extends ConsumerWidget {
  final bool isCompact;
  const _GdprComplianceChartsRow({required this.isCompact});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gdprAsync = ref.watch(adminGdprComplianceChartProvider);
    return gdprAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, _) => Text('Error: $e'),
      data: (data) {
        final pieChart = _GdprPieChart(data: data);
        final barChart = _GdprBarChart(data: data);
        if (isCompact) {
          return Column(children: [
            pieChart,
            const SizedBox(height: 16),
            barChart,
          ]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: pieChart),
            const SizedBox(width: 16),
            Expanded(child: barChart),
          ],
        );
      },
    );
  }
}

class _GdprPieChart extends StatefulWidget {
  final GdprComplianceChartData data;
  const _GdprPieChart({required this.data});

  @override
  State<_GdprPieChart> createState() => _GdprPieChartState();
}

class _GdprPieChartState extends State<_GdprPieChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final labels = ['Compliant', 'In Progress', 'Non-Compliant'];
    final colors = [const Color(0xFF16A34A), const Color(0xFFF59E0B), const Color(0xFFDC2626)];
    final values = [data.completed, data.inProgress, data.nonCompliant];
    final percents = [data.completedPercent, data.inProgressPercent, data.nonCompliantPercent];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'GDPR Compliance Status',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: data.totalUsers == 0
                ? Center(
                    child: Text('No data',
                        style: GoogleFonts.inter(color: const Color(0xFF9CA3AF))))
                : PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              _touchedIndex = -1;
                              return;
                            }
                            _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      sectionsSpace: 3,
                      centerSpaceRadius: 40,
                      sections: List.generate(3, (i) {
                        final isTouched = i == _touchedIndex;
                        return PieChartSectionData(
                          value: values[i].toDouble(),
                          color: colors[i],
                          title: isTouched
                              ? '${labels[i]}\n${values[i]} users'
                              : '${percents[i].toStringAsFixed(0)}%',
                          titleStyle: GoogleFonts.inter(
                            fontSize: isTouched ? 11 : 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          radius: isTouched ? 60 : 50,
                          titlePositionPercentageOffset: isTouched ? 0.55 : 0.5,
                        );
                      }),
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              _ChartLegendSquare(color: Color(0xFF16A34A), label: 'Compliant'),
              SizedBox(width: 16),
              _ChartLegendSquare(color: Color(0xFFF59E0B), label: 'In Progress'),
              SizedBox(width: 16),
              _ChartLegendSquare(color: Color(0xFFDC2626), label: 'Non-Compliant'),
            ],
          ),
        ],
      ),
    );
  }
}

class _GdprBarChart extends StatelessWidget {
  final GdprComplianceChartData data;
  const _GdprBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxY = (data.totalUsers * 1.2).ceilToDouble().clamp(5.0, 1000.0);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Compliance Breakdown',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: data.totalUsers == 0
                ? Center(
                    child: Text('No data',
                        style: GoogleFonts.inter(color: const Color(0xFF9CA3AF))))
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxY,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, gIdx, rod, rIdx) =>
                              BarTooltipItem(
                            '${rod.toY.toInt()} users',
                            GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 32,
                            getTitlesWidget: (value, meta) {
                              const labels = ['Compliant', 'In Progress', 'Non-Compliant'];
                              final idx = value.toInt();
                              if (idx >= 0 && idx < labels.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(labels[idx],
                                      style: GoogleFonts.inter(
                                          fontSize: 10,
                                          color: const Color(0xFF9CA3AF))),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 32,
                            getTitlesWidget: (value, meta) => Text(
                              value.toInt().toString(),
                              style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: const Color(0xFF9CA3AF)),
                            ),
                          ),
                        ),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (_) => const FlLine(
                          color: Color(0xFFF3F4F6),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: [
                        BarChartGroupData(x: 0, barRods: [
                          BarChartRodData(
                            toY: data.completed.toDouble(),
                            color: const Color(0xFF16A34A),
                            width: 32,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4)),
                          ),
                        ]),
                        BarChartGroupData(x: 1, barRods: [
                          BarChartRodData(
                            toY: data.inProgress.toDouble(),
                            color: const Color(0xFFF59E0B),
                            width: 32,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4)),
                          ),
                        ]),
                        BarChartGroupData(x: 2, barRods: [
                          BarChartRodData(
                            toY: data.nonCompliant.toDouble(),
                            color: const Color(0xFFDC2626),
                            width: 32,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4)),
                          ),
                        ]),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          Text(
            'Total: ${data.totalUsers} users',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// REPORTS SECTION
// ═══════════════════════════════════════════════════════════════

class _ReportsSection extends ConsumerWidget {
  const _ReportsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(adminUsersProvider);
    final complianceAsync = ref.watch(adminComplianceProvider);
    final users = usersAsync.valueOrNull ?? [];
    final compliance = complianceAsync.valueOrNull;

    void exportEngagementCsv() {
      final buf = StringBuffer('Name,Role,Organisation,Status,Kudos\n');
      for (final u in users) {
        buf.writeln('${u.fullName},${u.displayRole},${u.organizationId ?? ''},${u.statusLabel},${u.totalStars}');
      }
      _downloadCsv(buf.toString(), 'engagement_report_${DateTime.now().millisecondsSinceEpoch}.csv');
    }

    void exportEngagementPdf() {
      PdfExport.exportEngagementReport(
        users: users.map((u) => {
          'name': u.fullName,
          'role': u.displayRole,
          'org': u.organizationId ?? '',
          'status': u.statusLabel,
          'kudos': '${u.totalStars}',
        }).toList(),
      );
    }

    void exportComplianceCsv() {
      final buf = StringBuffer('Name,Role,Organisation,GDPR Training,Onboarding,Status\n');
      for (final u in users) {
        buf.writeln('${u.fullName},${u.displayRole},${u.organizationId ?? ''},${u.gdprTrainingCompleted ? 'Completed' : 'Pending'},${u.gdprConsentGiven ? 'Completed' : 'Pending'},${u.statusLabel}');
      }
      _downloadCsv(buf.toString(), 'compliance_report_${DateTime.now().millisecondsSinceEpoch}.csv');
    }

    void exportCompliancePdf() {
      PdfExport.exportComplianceReport(
        users: users.map((u) => {
          'name': u.fullName,
          'role': u.displayRole,
          'org': u.organizationId ?? '',
          'gdpr': u.gdprTrainingCompleted ? 'Completed' : 'Pending',
          'onboarding': u.gdprConsentGiven ? 'Completed' : 'Pending',
          'status': u.statusLabel,
        }).toList(),
        gdprPercent: compliance?.gdprTrainingPercent ?? 0,
        onboardingPercent: compliance?.onboardingCompletePercent ?? 0,
      );
    }

    void exportRecognitionCsv() {
      final buf = StringBuffer('Name,Role,Stars Received,Status\n');
      for (final u in users) {
        buf.writeln('${u.fullName},${u.displayRole},${u.totalStars},${u.statusLabel}');
      }
      _downloadCsv(buf.toString(), 'recognition_report_${DateTime.now().millisecondsSinceEpoch}.csv');
    }

    void exportRecognitionPdf() {
      PdfExport.exportRecognitionReport(
        users: users.map((u) => {
          'name': u.fullName,
          'role': u.displayRole,
          'stars': '${u.totalStars}',
          'posts': '0',
          'status': u.statusLabel,
        }).toList(),
        totalKudos: users.fold<int>(0, (sum, u) => sum + u.totalStars),
        totalPosts: 0,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          _ReportRow(
            iconBg: const Color(0xFFF3F4F6),
            iconColor: const Color(0xFF6B7280),
            icon: Icons.description_outlined,
            title: 'Engagement Report',
            description:
                'User activity, Kudos sent/received, and interaction metrics.',
            onCsv: exportEngagementCsv,
            onPdf: exportEngagementPdf,
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
          _ReportRow(
            iconBg: const Color(0xFFF3F4F6),
            iconColor: const Color(0xFF6B7280),
            icon: Icons.description_outlined,
            title: 'Training & Compliance Report',
            description:
                'GDPR training status, certification tracking, and compliance metrics.',
            onCsv: exportComplianceCsv,
            onPdf: exportCompliancePdf,
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
          _ReportRow(
            iconBg: const Color(0xFFF3F4F6),
            iconColor: const Color(0xFF6B7280),
            icon: Icons.description_outlined,
            title: 'Feedback & Recognition Report',
            description:
                'Recognition patterns, feedback analysis, and team engagement.',
            onCsv: exportRecognitionCsv,
            onPdf: exportRecognitionPdf,
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
          _ReportRow(
            iconBg: const Color(0xFFFEF3C7),
            iconColor: const Color(0xFFF59E0B),
            icon: Icons.schedule_outlined,
            title: 'Scheduled Reports',
            description:
                'No scheduled reports configured. Automated reporting can be set up in System Settings.',
          ),
        ],
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  final Color iconBg;
  final Color iconColor;
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onCsv;
  final VoidCallback? onPdf;

  const _ReportRow({
    required this.iconBg,
    required this.iconColor,
    required this.icon,
    required this.title,
    required this.description,
    this.onCsv,
    this.onPdf,
  });

  @override
  Widget build(BuildContext context) {
    final showButtons = onCsv != null || onPdf != null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          if (showButtons) ...[
            const SizedBox(width: 12),
            if (onCsv != null)
              OutlinedButton.icon(
                onPressed: onCsv,
                icon: const Icon(Icons.upload_outlined, size: 15),
                label: Text(
                  'Export CSV',
                  style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w500),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF374151),
                  side: const BorderSide(color: Color(0xFFD1D5DB)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            if (onPdf != null) ...[
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: onPdf,
                icon: const Icon(Icons.upload_outlined, size: 15),
                label: Text(
                  'Export PDF',
                  style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// TRAINING & COMPLIANCE PAGE (nav index 2)
// ═══════════════════════════════════════════════════════════════

class _TrainingComplianceContent extends ConsumerStatefulWidget {
  final bool isCompact;
  const _TrainingComplianceContent({required this.isCompact});

  @override
  ConsumerState<_TrainingComplianceContent> createState() =>
      _TrainingComplianceContentState();
}

class _TrainingComplianceContentState
    extends ConsumerState<_TrainingComplianceContent> {
  String _roleFilter = 'All Roles';
  String _orgFilter = 'All Organisations';
  String _statusFilter = 'All Statuses';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title ──
          Text(
            'Training & Compliance',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Monitor training completion, certifications, and compliance status',
            style: GoogleFonts.inter(
                fontSize: 14, color: const Color(0xFF6B7280)),
          ),
          const SizedBox(height: 24),

          // ── 4 Stat Cards ──
          _TcStatsRow(isCompact: widget.isCompact),
          const SizedBox(height: 28),

          // ── Certification Alerts ──
          _AnalyticsSectionTitle(title: 'Certification Alerts'),
          const SizedBox(height: 16),
          const _CertAlertsSection(),
          const SizedBox(height: 28),

          // ── Training Status ──
          _AnalyticsSectionTitle(title: 'Training Status'),
          const SizedBox(height: 16),
          _TrainingStatusSection(
            roleFilter: _roleFilter,
            orgFilter: _orgFilter,
            statusFilter: _statusFilter,
            onRoleChanged: (v) => setState(() => _roleFilter = v!),
            onOrgChanged: (v) => setState(() => _orgFilter = v!),
            onStatusChanged: (v) => setState(() => _statusFilter = v!),
          ),
          const SizedBox(height: 28),

          // ── Audit & Consent Log ──
          _AnalyticsSectionTitle(title: 'Audit & Consent Log'),
          const SizedBox(height: 16),
          const _AuditConsentSection(),
          const SizedBox(height: 28),
        ],
      ),
    );
  }
}

// ─── 4 stat cards row ───

class _TcStatsRow extends ConsumerWidget {
  final bool isCompact;
  const _TcStatsRow({required this.isCompact});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminTrainingComplianceStatsProvider);
    return async.when(
      loading: () => const Center(
          child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator())),
      error: (e, _) => Text('Error: $e'),
      data: (s) {
        final cards = [
          _TcStatCard(
            indicatorColor: const Color(0xFF3B82F6),
            label: 'GDPR Training',
            value: '${s.gdprPercent.toStringAsFixed(0)}%',
            showBar: true,
            barValue: s.gdprPercent / 100,
            barColor: const Color(0xFF1E3A8A),
          ),
          _TcStatCard(
            indicatorColor: const Color(0xFF22C55E),
            label: 'Onboarding Complete',
            value: '${s.onboardingPercent.toStringAsFixed(0)}%',
            showBar: true,
            barValue: s.onboardingPercent / 100,
            barColor: const Color(0xFF22C55E),
          ),
          _TcStatCard(
            indicatorColor: const Color(0xFFF59E0B),
            label: 'Expiring Soon',
            value: '${s.expiringSoon}',
            showBar: false,
            subtitle: 'GDPR Training',
            subtitleColor: const Color(0xFFF59E0B),
          ),
          _TcStatCard(
            indicatorColor: const Color(0xFFEF4444),
            label: 'Non Compliant',
            value: '${s.nonCompliant}',
            showBar: false,
            subtitle: 'Requires Action',
            subtitleColor: const Color(0xFFEF4444),
          ),
        ];

        if (isCompact) {
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: cards
                .map((c) => SizedBox(
                    width: (MediaQuery.of(context).size.width - 80) / 2,
                    child: c))
                .toList(),
          );
        }

        return Row(
          children: [
            for (int i = 0; i < cards.length; i++)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                      right: i == cards.length - 1 ? 0 : 12),
                  child: cards[i],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _TcStatCard extends StatelessWidget {
  final Color indicatorColor;
  final String label;
  final String value;
  final bool showBar;
  final double barValue;
  final Color barColor;
  final String subtitle;
  final Color subtitleColor;

  const _TcStatCard({
    required this.indicatorColor,
    required this.label,
    required this.value,
    required this.showBar,
    this.barValue = 0,
    this.barColor = const Color(0xFF1E3A8A),
    this.subtitle = '',
    this.subtitleColor = const Color(0xFF6B7280),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: indicatorColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
              height: 1,
            ),
          ),
          const SizedBox(height: 12),
          if (showBar)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: barValue.clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: const Color(0xFFF3F4F6),
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            )
          else
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: subtitleColor,
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Certification Alerts ───

class _CertAlertsSection extends ConsumerWidget {
  const _CertAlertsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminCertAlertsProvider);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: async.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Error: $e'),
        ),
        data: (alerts) {
          if (alerts.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'No certification alerts',
                  style: GoogleFonts.inter(
                      fontSize: 14, color: const Color(0xFF6B7280)),
                ),
              ),
            );
          }
          return Column(
            children: [
              for (int i = 0; i < alerts.length; i++) ...[
                if (i > 0)
                  const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFE5E7EB)),
                _CertAlertRow(alert: alerts[i]),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _CertAlertRow extends ConsumerWidget {
  final AdminCertAlert alert;
  const _CertAlertRow({required this.alert});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expiry = DateFormat('yyyy-MM-dd').format(alert.expiresAt);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Report name + expiring badge + cert info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      alert.reportName,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Expiring',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFFF59E0B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${alert.certType} • Expires: $expiry',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Approve button
          ElevatedButton(
            onPressed: () async {
              await approveCertAlert(alert.id);
              ref.invalidate(adminCertAlertsProvider);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              elevation: 0,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Approve',
              style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Training Status Table ───

class _TrainingStatusSection extends ConsumerWidget {
  final String roleFilter;
  final String orgFilter;
  final String statusFilter;
  final ValueChanged<String?> onRoleChanged;
  final ValueChanged<String?> onOrgChanged;
  final ValueChanged<String?> onStatusChanged;

  const _TrainingStatusSection({
    required this.roleFilter,
    required this.orgFilter,
    required this.statusFilter,
    required this.onRoleChanged,
    required this.onOrgChanged,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(adminTrainingUsersProvider);

    return Column(
      children: [
        // Filter bar
        Row(
          children: [
            Expanded(
              child: _UserMgmtDropdown(
                value: roleFilter,
                items: const [
                  'All Roles',
                  'Care Worker',
                  'Senior Carer',
                  'Manager',
                  'Family Member',
                ],
                onChanged: onRoleChanged,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _UserMgmtDropdown(
                value: orgFilter,
                items: const ['All Organisations'],
                onChanged: onOrgChanged,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _UserMgmtDropdown(
                value: statusFilter,
                items: const [
                  'All Statuses',
                  'Completed',
                  'Pending',
                ],
                onChanged: onStatusChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Table
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: usersAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Error: $e'),
            ),
            data: (allUsers) {
              var filtered = allUsers;

              if (roleFilter != 'All Roles') {
                filtered = filtered
                    .where((u) => u.displayRole == roleFilter)
                    .toList();
              }
              if (statusFilter != 'All Statuses') {
                filtered = filtered
                    .where((u) => u.gdprLabel == statusFilter)
                    .toList();
              }

              if (filtered.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(48),
                  child: Center(
                    child: Text('No users found',
                        style: GoogleFonts.inter(
                            fontSize: 14,
                            color: const Color(0xFF6B7280))),
                  ),
                );
              }

              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                        const Color(0xFFF9FAFB)),
                    headingTextStyle: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6B7280),
                    ),
                    dataTextStyle: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF374151),
                    ),
                    columnSpacing: 24,
                    horizontalMargin: 20,
                    columns: const [
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Role')),
                      DataColumn(label: Text('Organisation')),
                      DataColumn(label: Text('GDPR Training')),
                      DataColumn(label: Text('Certification')),
                      DataColumn(label: Text('Last Completed')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: filtered.map((u) {
                      return DataRow(cells: [
                        DataCell(Text(u.name)),
                        DataCell(Text(u.displayRole)),
                        DataCell(Text(u.organisation)),
                        DataCell(_TcBadge(label: u.gdprLabel)),
                        DataCell(_TcBadge(label: u.certLabel)),
                        DataCell(Text(
                          u.lastCompleted != null
                              ? DateFormat('yyyy-MM-dd')
                                  .format(u.lastCompleted!)
                              : '—',
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF374151)),
                        )),
                        DataCell(
                          IconButton(
                            icon: const Icon(Icons.more_vert,
                                size: 18, color: Color(0xFF9CA3AF)),
                            onPressed: () {},
                            splashRadius: 16,
                          ),
                        ),
                      ]);
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Audit & Consent Log ───

class _AuditConsentSection extends ConsumerWidget {
  const _AuditConsentSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(adminConsentLogsProvider);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: logsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Error: $e'),
        ),
        data: (logs) {
          if (logs.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text('No consent activity',
                    style: GoogleFonts.inter(
                        fontSize: 14, color: const Color(0xFF6B7280))),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12)),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                        const Color(0xFFF9FAFB)),
                    headingTextStyle: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6B7280),
                    ),
                    dataTextStyle: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF374151),
                    ),
                    columnSpacing: 32,
                    horizontalMargin: 20,
                    columns: const [
                      DataColumn(label: Text('User')),
                      DataColumn(label: Text('Content Type')),
                      DataColumn(label: Text('Action')),
                      DataColumn(label: Text('Timestamp')),
                    ],
                    rows: logs.map((log) {
                      return DataRow(cells: [
                        DataCell(Text(log.user)),
                        DataCell(Text(log.contentType)),
                        DataCell(_TcBadge(label: log.action)),
                        DataCell(Text(
                          DateFormat('yyyy-MM-dd HH:mm')
                              .format(log.timestamp),
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF374151)),
                        )),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
              const Divider(
                  height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                child: Text(
                  'Showing recent consent activity  •  Read-only audit log',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Reusable status pill for Training & Compliance ───

class _TcBadge extends StatelessWidget {
  final String label;
  const _TcBadge({required this.label});

  Color get _fg {
    switch (label) {
      case 'Completed':
      case 'Valid':
      case 'Granted':
        return const Color(0xFF22C55E);
      case 'Pending':
      case 'Expiring':
        return const Color(0xFFF59E0B);
      case 'Expired':
      case 'Revoked':
        return const Color(0xFFEF4444);
      case 'Updated':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFF6B7280);
    }
  }

  Color get _bg => _fg.withValues(alpha: 0.1);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: _fg,
        ),
      ),
    );
  }
}
