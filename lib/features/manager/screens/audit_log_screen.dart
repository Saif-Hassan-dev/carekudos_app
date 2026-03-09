import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme.dart';

/// Displays the moderation audit log for managers — all approve/reject/edit
/// actions are tracked here for CQC and GDPR compliance evidence.
class AuditLogScreen extends ConsumerWidget {
  const AuditLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 24, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new,
                        size: 20, color: AppColors.textPrimary),
                    onPressed: () => context.pop(),
                  ),
                  const Expanded(
                    child: Text(
                      'Moderation Audit Log',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_user_outlined,
                            size: 14, color: const Color(0xFF0A2C6B)),
                        const SizedBox(width: 4),
                        const Text(
                          'CQC Ready',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0A2C6B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Info banner ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF0A2C6B).withOpacity(0.15)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 18, color: const Color(0xFF0A2C6B)),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'All post moderation actions are logged for GDPR compliance and CQC audit evidence.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF374151),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // ── Log entries ──
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('moderation_logs')
                    .orderBy('timestamp', descending: true)
                    .limit(100)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error loading logs: ${snapshot.error}'),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.history,
                              size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text(
                            'No moderation actions yet',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 8),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final data =
                          docs[index].data() as Map<String, dynamic>;
                      return _AuditLogEntry(data: data);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuditLogEntry extends StatelessWidget {
  final Map<String, dynamic> data;

  const _AuditLogEntry({required this.data});

  @override
  Widget build(BuildContext context) {
    final action = data['action'] as String? ?? 'unknown';
    final reason = data['reason'] as String?;
    final timestamp = (data['timestamp'] as Timestamp?)?.toDate();

    final actionInfo = _actionDetails(action);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Action icon ──
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: actionInfo.bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(actionInfo.icon, size: 18, color: actionInfo.iconColor),
          ),
          const SizedBox(width: 12),

          // ── Details ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: actionInfo.bgColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        actionInfo.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: actionInfo.iconColor,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (timestamp != null)
                      Text(
                        _formatTimestamp(timestamp),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Post: ${_truncateId(data['postId'] as String? ?? '')}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
                if (reason != null && reason.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Reason: $reason',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF374151),
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  _ActionInfo _actionDetails(String action) {
    switch (action) {
      case 'approved':
        return _ActionInfo(
          label: 'Approved',
          icon: Icons.check_circle_outline,
          iconColor: const Color(0xFF16A34A),
          bgColor: const Color(0xFFDCFCE7),
        );
      case 'rejected':
        return _ActionInfo(
          label: 'Rejected',
          icon: Icons.cancel_outlined,
          iconColor: const Color(0xFFDC2626),
          bgColor: const Color(0xFFFEF2F2),
        );
      case 'edit_requested':
        return _ActionInfo(
          label: 'Edit Requested',
          icon: Icons.edit_outlined,
          iconColor: const Color(0xFFEA580C),
          bgColor: const Color(0xFFFFF7ED),
        );
      default:
        return _ActionInfo(
          label: action,
          icon: Icons.info_outline,
          iconColor: const Color(0xFF6B7280),
          bgColor: const Color(0xFFF3F4F6),
        );
    }
  }

  String _truncateId(String id) {
    if (id.length <= 12) return id;
    return '${id.substring(0, 6)}…${id.substring(id.length - 4)}';
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _ActionInfo {
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;

  const _ActionInfo({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });
}
