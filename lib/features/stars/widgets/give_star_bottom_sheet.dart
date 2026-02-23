import 'package:flutter/material.dart';

/// Star type model for the Give Star popup
class StarType {
  final String label;
  final int starCount;
  final int points;

  const StarType({
    required this.label,
    required this.starCount,
    required this.points,
  });
}

/// Bottom sheet for giving a star 
/// Shows three star-type cards (Peer / Manager / Family), an optional note,
/// a daily-limit counter, and a CTA button.
class GiveStarBottomSheet extends StatefulWidget {
  final String postId;
  final String postAuthorId;
  final String category;
  final int starsLeftToday;
  final int maxStarsPerDay;
  final Future<void> Function({
    required String starType,
    required int points,
    required String? note,
  }) onGiveStar;

  const GiveStarBottomSheet({
    super.key,
    required this.postId,
    required this.postAuthorId,
    required this.category,
    required this.starsLeftToday,
    required this.maxStarsPerDay,
    required this.onGiveStar,
  });

  /// Convenience method to show the bottom sheet
  static Future<bool?> show({
    required BuildContext context,
    required String postId,
    required String postAuthorId,
    required String category,
    required int starsLeftToday,
    required int maxStarsPerDay,
    required Future<void> Function({
      required String starType,
      required int points,
      required String? note,
    }) onGiveStar,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GiveStarBottomSheet(
        postId: postId,
        postAuthorId: postAuthorId,
        category: category,
        starsLeftToday: starsLeftToday,
        maxStarsPerDay: maxStarsPerDay,
        onGiveStar: onGiveStar,
      ),
    );
  }

  @override
  State<GiveStarBottomSheet> createState() => _GiveStarBottomSheetState();
}

class _GiveStarBottomSheetState extends State<GiveStarBottomSheet> {
  static const _starTypes = [
    StarType(label: 'Peer', starCount: 1, points: 1),
    StarType(label: 'Manager', starCount: 3, points: 3),
    StarType(label: 'Family', starCount: 5, points: 5),
  ];

  int _selectedIndex = 0; // default: Peer
  final _noteController = TextEditingController();
  bool _isSubmitting = false;

  StarType get _selected => _starTypes[_selectedIndex];

  bool get _canSubmit => !_isSubmitting && widget.starsLeftToday > 0;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _isSubmitting = true);

    try {
      await widget.onGiveStar(
        starType: _selected.label,
        points: _selected.points,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Drag handle ──
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDEE2E6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Title ──
              const Text(
                'Give a Star',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Recognise great care',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF8E8E93),
                ),
              ),
              const SizedBox(height: 24),

              // ── Choose star type label ──
              const Text(
                'Choose star type',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 12),

              // ── Star type cards ──
              ...List.generate(_starTypes.length, (i) {
                final type = _starTypes[i];
                final isSelected = _selectedIndex == i;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _StarTypeCard(
                    type: type,
                    isSelected: isSelected,
                    onTap: () => setState(() => _selectedIndex = i),
                  ),
                );
              }),

              const SizedBox(height: 20),

              // ── Note field ──
              const Text(
                'Add a note (optional)',
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
                  controller: _noteController,
                  maxLines: 3,
                  maxLength: 200,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1A1A2E),
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Add a note (optional)',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: Color(0xFFB0B0B0),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(14),
                    counterText: '',
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Stars left today ──
              Center(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF8E8E93),
                      fontFamily: 'Inter',
                    ),
                    children: [
                      const TextSpan(text: 'You have  '),
                      TextSpan(
                        text: '${widget.starsLeftToday}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      const TextSpan(text: ' / '),
                      TextSpan(
                        text: '${widget.maxStarsPerDay}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      const TextSpan(text: ' stars left today'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── CTA Button ──
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _canSubmit ? _submit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _canSubmit
                        ? const Color(0xFFD4AF37)
                        : const Color(0xFFE0E0E0),
                    foregroundColor:
                        _canSubmit ? Colors.white : const Color(0xFF9E9E9E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
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
                          'Give Star',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual star-type selection card
// ─────────────────────────────────────────────────────────────────────────────
class _StarTypeCard extends StatelessWidget {
  final StarType type;
  final bool isSelected;
  final VoidCallback onTap;

  const _StarTypeCard({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0F4FF) : const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0A2C6B)
                : const Color(0xFFF0F0F0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Label
            Text(
              type.label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? const Color(0xFF0A2C6B)
                    : const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(width: 12),
            // Stars
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                type.starCount,
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
            // Points text
            Text(
              '${type.points} point${type.points > 1 ? 's' : ''}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                color: isSelected
                    ? const Color(0xFF0A2C6B)
                    : const Color(0xFF8E8E93),
              ),
            ),
            // Checkmark when selected
            if (isSelected) ...[
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
          ],
        ),
      ),
    );
  }
}
