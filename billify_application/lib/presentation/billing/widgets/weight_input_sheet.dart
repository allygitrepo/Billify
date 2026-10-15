import 'package:billify/core/theme/app_theme.dart';
import 'package:billify/data/models/product_model.dart';
import 'package:billify/data/models/uom_model.dart';
import 'package:billify/providers/uom_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WeightInputSheet extends ConsumerStatefulWidget {
  final ProductModel product;
  final Function(double quantity) onAdd;
  final String buttonLabel;
  final double? initialQuantity;

  const WeightInputSheet({
    super.key,
    required this.product,
    required this.onAdd,
    this.buttonLabel = 'ADD TO CART',
    this.initialQuantity,
  });

  @override
  ConsumerState<WeightInputSheet> createState() => _WeightInputSheetState();
}

class _WeightInputSheetState extends ConsumerState<WeightInputSheet> {
  late final TextEditingController _weightController;
  bool _isSubUnit = false;

  @override
  void initState() {
    super.initState();
    String initialText = '';
    if (widget.initialQuantity != null && widget.initialQuantity! > 0) {
      final qty = widget.initialQuantity!;
      if (qty % 1 == 0) {
        initialText = qty.toInt().toString();
      } else {
        initialText = qty.toStringAsFixed(3).replaceAll(RegExp(r'0+$'), '');
      }
    }
    _weightController = TextEditingController(text: initialText);
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  void _onNumberPressed(String value) {
    if (value == '.' && _weightController.text.contains('.')) return;

    // Max 3 decimal places
    if (_weightController.text.contains('.')) {
      final parts = _weightController.text.split('.');
      if (parts.length > 1 && parts[1].length >= 3) return;
    }

    setState(() {
      _weightController.text += value;
      _weightController.selection = TextSelection.fromPosition(
        TextPosition(offset: _weightController.text.length),
      );
    });
  }

  void _onBackspace() {
    if (_weightController.text.isNotEmpty) {
      setState(() {
        _weightController.text = _weightController.text.substring(
          0,
          _weightController.text.length - 1,
        );
        _weightController.selection = TextSelection.fromPosition(
          TextPosition(offset: _weightController.text.length),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Resolve UOM
    final uoms = ref.watch(uomProvider);
    final uom = uoms.firstWhere(
      (u) => u.id == widget.product.uom,
      orElse: () => UomModel(
        id: widget.product.uom,
        name: widget.product.uom,
        shortCode: widget.product.uom,
      ),
    );

    final String baseUnit = uom.shortCode.toUpperCase();
    String currentUnit = baseUnit;
    double conversionFactor = 1.0;

    // Determine sub-unit (gm for kg, ml for ltr)
    String? subUnit;
    if (baseUnit == 'KG') {
      subUnit = 'GM';
    } else if (baseUnit == 'LTR' || baseUnit == 'L' || baseUnit == 'LITRE') {
      subUnit = 'ML';
    }

    if (_isSubUnit && subUnit != null) {
      currentUnit = subUnit;
      conversionFactor = 1000.0;
    }

    final double enteredValue = double.tryParse(_weightController.text) ?? 0.0;
    final double baseQuantity = enteredValue / conversionFactor;
    final double subtotal = baseQuantity * widget.product.price_per_unit;

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        bottom: true,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Enter Quantity for ${widget.product.name}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // Weight Display & Input Area
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.primaryTeal.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: TextField(
                    controller: _weightController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryTeal,
                    ),
                    decoration: const InputDecoration(
                      hintText: '0.000',
                      hintStyle: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (val) {
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  currentUnit,
                  style: const TextStyle(
                    fontSize: 24,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Unit Selection Toggle
          if (subUnit != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _UnitToggleButton(
                  label: baseUnit,
                  isSelected: !_isSubUnit,
                  onTap: () {
                    if (_isSubUnit) {
                      final val = double.tryParse(_weightController.text);
                      if (val != null && val > 0) {
                        final inKg = val / 1000.0;
                        _weightController.text = inKg
                            .toStringAsFixed(3)
                            .replaceAll(RegExp(r'0+$'), '');
                      }
                      setState(() => _isSubUnit = false);
                    }
                  },
                ),
                const SizedBox(width: 12),
                _UnitToggleButton(
                  label: subUnit,
                  isSelected: _isSubUnit,
                  onTap: () {
                    if (!_isSubUnit) {
                      final val = double.tryParse(_weightController.text);
                      if (val != null && val > 0) {
                        final inGm = val * 1000.0;
                        _weightController.text = inGm % 1 == 0
                            ? inGm.toInt().toString()
                            : inGm.toStringAsFixed(1);
                      }
                      setState(() => _isSubUnit = true);
                    }
                  },
                ),
              ],
            ),

          const SizedBox(height: 16),

          Text(
            '₹${widget.product.price_per_unit.toStringAsFixed(2)} / $baseUnit  |  Subtotal: ₹${subtotal.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 20),

          // Numeric Keypad
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              ...['1', '2', '3', '4', '5', '6', '7', '8', '9', '.', '0'].map(
                (val) =>
                    _KeyButton(label: val, onTap: () => _onNumberPressed(val)),
              ),
              _KeyButton(
                icon: Icons.backspace_outlined,
                onTap: _onBackspace,
                color: Colors.red.withValues(alpha: 0.1),
                iconColor: Colors.red,
              ),
            ],
          ),

          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: enteredValue > 0
                ? () {
                    Navigator.pop(context);
                    widget.onAdd(baseQuantity);
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryTeal,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              disabledBackgroundColor: Colors.grey.withValues(alpha: 0.3),
            ),
            child: Text(
              widget.buttonLabel,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    ),
  ),
);
}
}

class _UnitToggleButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _UnitToggleButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryTeal : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryTeal
                : Colors.grey.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _KeyButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  final Color? color;
  final Color? iconColor;

  const _KeyButton({
    this.label,
    this.icon,
    required this.onTap,
    this.color,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: color ?? Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
          ),
          child: Center(
            child: label != null
                ? Text(
                    label!,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : Icon(icon, color: iconColor ?? AppTheme.primaryTeal),
          ),
        ),
      ),
    );
  }
}
