import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../features/admin/providers/admin_dashboard_provider.dart';

class TrainingLibraryScreen extends ConsumerWidget {
  const TrainingLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modulesAsync = ref.watch(trainingModulesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A2E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Training Library',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A2E),
          ),
        ),
      ),
      body: modulesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading modules: $e')),
        data: (modules) {
          if (modules.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF3FB),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.menu_book_outlined,
                          size: 36, color: Color(0xFF0A2C6B)),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'No training modules yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your organisation hasn\'t added any training content yet. Check back later.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Color(0xFF8E8E93)),
                    ),
                  ],
                ),
              ),
            );
          }

          // Group by category
          final Map<String, List<TrainingModule>> grouped = {};
          for (final m in modules) {
            grouped.putIfAbsent(m.category, () => []).add(m);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final entry in grouped.entries) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    entry.key,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ),
                ...entry.value.map((m) => _ModuleCard(module: m)),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final TrainingModule module;
  const _ModuleCard({required this.module});

  IconData get _icon {
    switch (module.type) {
      case 'video': return Icons.play_circle_outline_rounded;
      case 'pdf': return Icons.picture_as_pdf_outlined;
      default: return Icons.article_outlined;
    }
  }

  Color get _iconColor {
    switch (module.category) {
      case 'GDPR': return const Color(0xFF0A2C6B);
      case 'Health & Safety': return const Color(0xFF16A34A);
      case 'Care Standards': return const Color(0xFF7C3AED);
      default: return const Color(0xFF6B7280);
    }
  }

  Color get _iconBg {
    switch (module.category) {
      case 'GDPR': return const Color(0xFFEEF3FB);
      case 'Health & Safety': return const Color(0xFFDCFCE7);
      case 'Care Standards': return const Color(0xFFF3E8FF);
      default: return const Color(0xFFF3F4F6);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE5E5EA)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openModule(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_icon, size: 24, color: _iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            module.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            module.type.toUpperCase(),
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6B7280)),
                          ),
                        ),
                      ],
                    ),
                    if (module.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        module.description,
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF8E8E93)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Color(0xFFD1D5DB), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _openModule(BuildContext context) {
    if (module.url.isNotEmpty) {
      launchUrl(Uri.parse(module.url), mode: LaunchMode.externalApplication);
      return;
    }
    if (module.body.isEmpty) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: const Color(0xFFD9D9D9),
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Text(module.title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: const Color(0xFFEEF3FB), borderRadius: BorderRadius.circular(6)),
              child: Text(module.category,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF0A2C6B))),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),
            Text(module.body,
                style: const TextStyle(fontSize: 15, height: 1.6, color: Color(0xFF1A1A2E))),
          ],
        ),
      ),
    );
  }
}
