import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/utils/constants.dart';

/// Modal dialog shown from the manager dashboard to edit company core values.
/// Matches the "Edit Company Values" Figma design (second screenshot).
class EditCompanyValuesDialog extends StatefulWidget {
  /// Current saved values to pre-populate.
  final List<String> currentValues;

  /// Manager's user id (to save back to Firestore).
  final String userId;

  /// Called after successful save with the new values list.
  final ValueChanged<List<String>>? onSaved;

  const EditCompanyValuesDialog({
    super.key,
    required this.currentValues,
    required this.userId,
    this.onSaved,
  });

  /// Convenience method to show as a dialog.
  static Future<void> show(
    BuildContext context, {
    required List<String> currentValues,
    required String userId,
    ValueChanged<List<String>>? onSaved,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => EditCompanyValuesDialog(
        currentValues: currentValues,
        userId: userId,
        onSaved: onSaved,
      ),
    );
  }

  @override
  State<EditCompanyValuesDialog> createState() =>
      _EditCompanyValuesDialogState();
}

class _EditCompanyValuesDialogState extends State<EditCompanyValuesDialog> {
  late final Set<String> _selected;
  late final List<String> _customValues;
  final TextEditingController _customController = TextEditingController();
  bool _isSaving = false;

  static const int _minValues = 3;
  static const int _maxValues = 5;

  @override
  void initState() {
    super.initState();
    // Separate currentValues into predefined and custom
    _selected = {};
    _customValues = [];
    for (final v in widget.currentValues) {
      if (AppConstants.predefinedCoreValues.contains(v)) {
        _selected.add(v);
      } else {
        _customValues.add(v);
      }
    }
  }

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

  Future<void> _save() async {
    if (!_canSave || _isSaving) return;
    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(widget.userId)
          .update({
        'companyValues': _allSelected,
        'coreValuesSetupComplete': true,
      });

      widget.onSaved?.call(_allSelected);
      if (mounted) Navigator.pop(context);
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
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Title ──
              const Text(
                'Edit Company Values',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'These values will shape recognition and\nculture insights across your organisation.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF6B7280),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),

              // ── Counter pill ──
              _buildCounterPill(),
              const SizedBox(height: 24),

              // ── Select from predefined values ──
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Select from predefined values',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildChips(),
              const SizedBox(height: 24),

              // ── Add custom value ──
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Add custom value',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _buildCustomInput(),

              // ── Custom value chips ──
              if (_customValues.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildCustomChips(),
              ],
              const SizedBox(height: 24),

              // ── Save button ──
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _canSave ? _save : null,
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
                      : const Text(
                          'Save',
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

  Widget _buildCounterPill() {
    final count = _allSelected.length;
    final met = count >= _minValues;
    final color = met ? const Color(0xFF16A34A) : const Color(0xFFEA580C);
    final bg = met ? const Color(0xFFDCFCE7) : const Color(0xFFFFF7ED);
    final border = met ? const Color(0xFF86EFAC) : const Color(0xFFFED7AA);

    final text = met
        ? '$count of $_minValues\u2013$_maxValues values selected'
        : '$count of $_minValues\u2013$_maxValues values selected ($_remaining more required)';

    return Container(
      width: double.infinity,
      alignment: Alignment.center,
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
                color:
                    isSelected ? const Color(0xFF0A2C6B) : Colors.white,
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
                  color:
                      isSelected ? Colors.white : const Color(0xFF1A1A2E),
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
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFD1D5DB)),
            ),
            child: TextField(
              controller: _customController,
              style:
                  const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
              decoration: const InputDecoration(
                hintText: 'e.g., Innovation,...',
                hintStyle:
                    TextStyle(fontSize: 14, color: Color(0xFFB0B0B0)),
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
