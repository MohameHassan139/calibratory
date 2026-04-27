import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'check_row.dart';

class DeviceCard extends StatelessWidget {
  final String device;
  final double price;
  final int qty;
  final bool electric;
  final bool function;
  final ValueChanged<double> onPriceChanged;
  final ValueChanged<int> onQtyChanged;
  final ValueChanged<bool> onElectricChanged;
  final ValueChanged<bool> onFunctionChanged;

  const DeviceCard({
    super.key,
    required this.device,
    required this.price,
    required this.qty,
    required this.electric,
    required this.function,
    required this.onPriceChanged,
    required this.onQtyChanged,
    required this.onElectricChanged,
    required this.onFunctionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final subtotal = price * qty;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  device,
                  style: const TextStyle(
                    fontFamily: 'Syne',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              Text(
                'SUBTOTAL: \$${subtotal.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PRICE (\$)',
                      style: TextStyle(
                          fontSize: 10, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        hintText: '0',
                      ),
                      onChanged: (v) => onPriceChanged(double.tryParse(v) ?? 0),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'QTY',
                      style: TextStyle(
                          fontSize: 10, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        hintText: '0',
                      ),
                      onChanged: (v) => onQtyChanged(int.tryParse(v) ?? 0),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              CheckRow(
                label: 'Electric Check',
                value: electric,
                onChanged: onElectricChanged,
              ),
              const SizedBox(width: 16),
              CheckRow(
                label: 'Function Check',
                value: function,
                onChanged: onFunctionChanged,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
