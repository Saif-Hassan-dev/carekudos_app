import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/utils/constants.dart';

/// Staff member search result model.
class _StaffResult {
  final String uid;
  final String name;
  final String role;
  final String? profilePhotoBase64;

  const _StaffResult({
    required this.uid,
    required this.name,
    required this.role,
    this.profilePhotoBase64,
  });
}

/// Callback with selected staff uid, name, star points, and optional comment.
typedef QuickRecognitionCallback = void Function(
  String staffUid,
  String staffName,
  int starPoints,
  String? comment,
);

class QuickRecognitionSheet extends StatefulWidget {
  final QuickRecognitionCallback onSend;

  /// If a staff member is pre-selected (from "Give Star" button on a row),
  /// populate these.
  final String? preselectedUid;
  final String? preselectedName;

  const QuickRecognitionSheet({
    super.key,
    required this.onSend,
    this.preselectedUid,
    this.preselectedName,
  });

  /// Convenience method to show as a modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required QuickRecognitionCallback onSend,
    String? preselectedUid,
    String? preselectedName,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QuickRecognitionSheet(
        onSend: onSend,
        preselectedUid: preselectedUid,
        preselectedName: preselectedName,
      ),
    );
  }

  @override
  State<QuickRecognitionSheet> createState() => _QuickRecognitionSheetState();
}

class _QuickRecognitionSheetState extends State<QuickRecognitionSheet> {
  // Manager recognition is always 3 stars — no tier selection needed
  static const int _managerStarPoints = 3;
  static const int _managerStarCount = 3;

  final _commentController = TextEditingController();
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();

  _StaffResult? _selectedStaff;
  List<_StaffResult> _searchResults = [];
  bool _isSearching = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    if (widget.preselectedUid != null && widget.preselectedName != null) {
      _selectedStaff = _StaffResult(
        uid: widget.preselectedUid!,
        name: widget.preselectedName!,
        role: '',
      );
      _searchController.text = widget.preselectedName!;
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  bool get _canSend => _selectedStaff != null && !_isSending;

  Future<void> _searchStaff(String query) async {
    if (query.trim().length < 2) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final snap = await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .get();

      final lowerQuery = query.toLowerCase();
      final results = snap.docs
          .where((doc) {
            final data = doc.data();
            final role = data['role'] as String? ?? '';
            if (role != 'care_worker' && role != 'senior_carer') return false;
            final full =
                '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'
                    .trim()
                    .toLowerCase();
            return full.contains(lowerQuery);
          })
          .map((doc) {
            final data = doc.data();
            return _StaffResult(
              uid: doc.id,
              name:
                  '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim(),
              role: _formatRole(data['role'] as String? ?? ''),
              profilePhotoBase64: data['profilePhotoBase64'] as String?,
            );
          })
          .take(8)
          .toList();

      if (mounted) setState(() { _searchResults = results; _isSearching = false; });
    } catch (e) {
      debugPrint('[QuickRecognition] Staff search failed: $e');
      if (mounted) setState(() { _searchResults = []; _isSearching = false; });
    }
  }

  String _formatRole(String role) {
    if (role.isEmpty) return '';
    return role.replaceAll('_', ' ').split(' ').map((w) {
      if (w.isEmpty) return w;
      return '${w[0].toUpperCase()}${w.substring(1)}';
    }).join(' ');
  }

  void _selectStaff(_StaffResult staff) {
    setState(() {
      _selectedStaff = staff;
      _searchController.text = staff.name;
      _searchResults = [];
    });
    _searchFocus.unfocus();
  }

  void _clearSelection() {
    setState(() {
      _selectedStaff = null;
      _searchController.clear();
      _searchResults = [];
    });
  }

  void _submit() {
    if (!_canSend) return;
    setState(() => _isSending = true);

    final comment = _commentController.text.trim().isEmpty
        ? null
        : _commentController.text.trim();

    widget.onSend(
      _selectedStaff!.uid,
      _selectedStaff!.name,
      _managerStarPoints,
      comment,
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Drag handle ──
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9D9D9),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Title ──
              const Text(
                'Quick Recognition',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Send recognition instantly to a team member',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF8E8E93),
                ),
              ),
              const SizedBox(height: 24),

              // ── Select Staff Member ──
              const Text(
                'Select Staff Member',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E5EA)),
                  color: const Color(0xFFF8F8F8),
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocus,
                  onChanged: (val) {
                    if (_selectedStaff != null &&
                        val != _selectedStaff!.name) {
                      _selectedStaff = null;
                    }
                    _searchStaff(val);
                  },
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1A1A2E),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search by name...',
                    hintStyle: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFFB0B0B0),
                    ),
                    prefixIcon: const Icon(Icons.search,
                        color: Color(0xFF8E8E93), size: 20),
                    suffixIcon: _selectedStaff != null
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: _clearSelection,
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                  ),
                ),
              ),

              // ── Search results dropdown ──
              if (_searchResults.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E5EA)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: _searchResults.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final staff = _searchResults[i];
                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 2),
                        leading: _buildAvatar(staff),
                        title: Text(
                          staff.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        subtitle: staff.role.isNotEmpty
                            ? Text(
                                staff.role,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF8E8E93),
                                ),
                              )
                            : null,
                        onTap: () => _selectStaff(staff),
                      );
                    },
                  ),
                ),

              if (_isSearching)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),

              // ── Selected staff chip ──
              if (_selectedStaff != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4FF),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: const Color(0xFF0A2C6B), width: 1),
                  ),
                  child: Row(
                    children: [
                      _buildAvatar(_selectedStaff!, size: 28),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _selectedStaff!.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0A2C6B),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _clearSelection,
                        child: const Icon(Icons.close,
                            size: 18, color: Color(0xFF0A2C6B)),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // ── Star info badge (fixed 3-star Manager recognition) ──
              const Text(
                'Recognition Stars',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: const Color(0xFF0A2C6B), width: 1.5),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Manager Star',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0A2C6B),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        _managerStarCount,
                        (_) => const Padding(
                          padding: EdgeInsets.only(right: 2),
                          child: Icon(
                            Icons.star_rounded,
                            color: Color(0xFFD4AF37),
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      '3 points',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF0A2C6B),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00BCD4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Comment field ──
              const Text(
                'Add Comment (optional)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E5EA)),
                ),
                child: TextField(
                  controller: _commentController,
                  maxLines: 3,
                  maxLength: 250,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1A1A2E),
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Write a message of recognition...',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: Color(0xFFB0B0B0),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(14),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Send Recognition button ──
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _canSend ? _submit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _canSend
                        ? const Color(0xFF0A2C6B)
                        : const Color(0xFFE0E0E0),
                    foregroundColor:
                        _canSend ? Colors.white : const Color(0xFF9E9E9E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isSending
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Send Recognition',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Cancel button ──
              SizedBox(
                width: double.infinity,
                height: 44,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(_StaffResult staff, {double size = 36}) {
    if (staff.profilePhotoBase64 != null &&
        staff.profilePhotoBase64!.isNotEmpty) {
      try {
        final bytes = base64Decode(staff.profilePhotoBase64!);
        return CircleAvatar(
          radius: size / 2,
          backgroundImage: MemoryImage(Uint8List.fromList(bytes)),
        );
      } catch (_) {}
    }
    // Fallback initials avatar
    final initials = staff.name.isNotEmpty
        ? staff.name
            .split(' ')
            .where((w) => w.isNotEmpty)
            .take(2)
            .map((w) => w[0].toUpperCase())
            .join()
        : '?';
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: const Color(0xFF0A2C6B),
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.36,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
