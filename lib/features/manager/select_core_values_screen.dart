import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/utils/constants.dart';

class SelectCoreValuesScreen extends ConsumerStatefulWidget {
  const SelectCoreValuesScreen({super.key});

  @override
  ConsumerState<SelectCoreValuesScreen> createState() =>
      _SelectCoreValuesScreenState();
}

class _SelectCoreValuesScreenState
    extends ConsumerState<SelectCoreValuesScreen> {
  final Set<String> _selected = {};
  final TextEditingController _customController = TextEditingController();
  final List<String> _customValues = [];
  bool _isSaving = false;

  static const int _minValues = 3;
  static const int _maxValues = 5;

  List<String> get _allSelected => [..._selected, ..._customValues];
  int get _remaining => (_minValues - _allSelected.length).clamp(0, _minValues);
  bool get _canSave =>
      _allSelected.length >= _minValues && _allSelected.length <= _maxValues;

  void _toggleValue(String value) {
    setState(() {
      if (_selected.contains(value)) {
        _selected.remove(value);
      } else if (_allSelected.length < _maxValues) {
        _selected.add(value);
      }
    });
  }

  void _addCustom() {
    final text = _customController.text.trim();
    if (text.isEmpty) return;
    if (_allSelected.length >= _maxValues) return;
    if (_allSelected.contains(text)) return;
    setState(() {
      _customValues.add(text);
      _customController.clear();
    });
  }

  Future<void> _saveAndContinue() async {
    if (!_canSave || _isSaving) return;
    setState(() => _isSaving = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .update({
        'companyValues': _allSelected,
        'coreValuesSetupComplete': true,
      });

      if (mounted) {
        context.go('/manager-dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save values: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 12),
                    // ── Logo ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/smallLogo.png',
                          height: 32,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.star,
                            color: Color(0xFF0A2C6B),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'CareKudos',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0A2C6B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // ── Title card ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 28),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F8FA),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Column(
                        children: [
                          Text(
                            "Define Your Company's Core\nValues",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A2E),
                              height: 1.25,
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'These values will shape recognition and\nculture insights across your organisation.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF6B7280),
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Counter pill ──
                    _buildCounterPill(),
                    const SizedBox(height: 28),

                    // ── Select from predefined values ──
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Select from predefined values',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildChips(),
                    const SizedBox(height: 28),

                    // ── Add custom value ──
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Add custom value',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildCustomInput(),

                    // ── Custom value chips ──
                    if (_customValues.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildCustomChips(),
                    ],
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // ── Save & Continue ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _canSave ? _saveAndContinue : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _canSave
                        ? const Color(0xFF0A2C6B)
                        : const Color(0xFFE0E0E0),
                    foregroundColor:
                        _canSave ? Colors.white : const Color(0xFF9E9E9E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Save & Continue',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, size: 18),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCounterPill() {
    final count = _allSelected.length;
    final met = count >= _minValues;
    final color = met ? const Color(0xFF16A34A) : const Color(0xFFEA580C);
    final bg = met
        ? const Color(0xFFDCFCE7)
        : const Color(0xFFFFF7ED);
    final border = met
        ? const Color(0xFF86EFAC)
        : const Color(0xFFFED7AA);

    final text = met
        ? '$count of $_minValues\u2013$_maxValues values selected'
        : '$count of $_minValues\u2013$_maxValues values selected ($_remaining more required)';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Widget _buildChips() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: AppConstants.predefinedCoreValues.map((value) {
          final isSelected = _selected.contains(value);
          return GestureDetector(
            onTap: () => _toggleValue(value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF0A2C6B)
                    : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF0A2C6B)
                      : const Color(0xFFD1D5DB),
                ),
              ),
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCustomInput() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFD1D5DB)),
            ),
            child: TextField(
              controller: _customController,
              style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
              decoration: const InputDecoration(
                hintText: 'e.g., Innovation, Tr...',
                hintStyle: TextStyle(fontSize: 14, color: Color(0xFFB0B0B0)),
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              onSubmitted: (_) => _addCustom(),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _addCustom,
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text('Add',
                  overflow: TextOverflow.ellipsis, maxLines: 1),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A2C6B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomChips() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _customValues.map((value) {
          return Chip(
            label: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF0A2C6B),
              ),
            ),
            backgroundColor: const Color(0xFFEEF2FF),
            side: const BorderSide(color: Color(0xFF0A2C6B)),
            deleteIcon: const Icon(Icons.close, size: 16),
            deleteIconColor: const Color(0xFF0A2C6B),
            onDeleted: () {
              setState(() => _customValues.remove(value));
            },
          );
        }).toList(),
      ),
    );
  }
}
