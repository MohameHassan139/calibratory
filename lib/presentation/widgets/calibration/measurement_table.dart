import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Column header cell for the measurement table
class TableHeaderCell extends StatelessWidget {
  final String text;
  final double flex;

  const TableHeaderCell(this.text, this.flex, {super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: (flex * 10).toInt(),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Syne',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textWhite,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Single data row in the measurement table
class MeasurementTableRow extends StatelessWidget {
  final double settingValue;
  final List<TextEditingController> controllers;
  final String rangeStr;
  final double? avg;
  final bool? status;
  final bool isLast;
  final VoidCallback onChanged;

  const MeasurementTableRow({
    super.key,
    required this.settingValue,
    required this.controllers,
    required this.rangeStr,
    required this.avg,
    required this.status,
    required this.isLast,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Setting value
            Expanded(
              flex: 12,
              child: Container(
                padding: const EdgeInsets.all(8),
                color: AppColors.surfaceVariant,
                child: Text(
                  settingValue.toStringAsFixed(0),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            // Read inputs
            ...List.generate(
              3,
              (i) => Expanded(
                flex: 10,
                child: Container(
                  decoration: const BoxDecoration(
                    border: Border(left: BorderSide(color: AppColors.border)),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: TextField(
                    controller: controllers[i],
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '-',
                      hintStyle:
                          TextStyle(fontSize: 12, color: AppColors.textHint),
                      contentPadding: EdgeInsets.zero,
                      filled: false,
                    ),
                    onChanged: (_) => onChanged(),
                  ),
                ),
              ),
            ),
            // Average
            Expanded(
              flex: 10,
              child: Container(
                decoration: const BoxDecoration(
                  border: Border(left: BorderSide(color: AppColors.border)),
                ),
                padding: const EdgeInsets.all(8),
                child: Text(
                  avg != null ? avg!.toStringAsFixed(2) : '-',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            // Range
            Expanded(
              flex: 15,
              child: Container(
                decoration: const BoxDecoration(
                  border: Border(left: BorderSide(color: AppColors.border)),
                ),
                padding: const EdgeInsets.all(8),
                child: Text(
                  rangeStr,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            // Status
            Expanded(
              flex: 9,
              child: Container(
                decoration: const BoxDecoration(
                  border: Border(left: BorderSide(color: AppColors.border)),
                ),
                padding: const EdgeInsets.all(8),
                child: status == null
                    ? const Text(
                        '-',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textHint),
                      )
                    : Icon(
                        status! ? Icons.check_circle : Icons.cancel,
                        color: status! ? AppColors.success : AppColors.error,
                        size: 18,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
