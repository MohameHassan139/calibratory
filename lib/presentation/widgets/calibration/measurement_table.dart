import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

// Fixed column widths
const double colSetting = 64;
const double colRead = 60;
const double colAvg = 68;
const double colRange = 90;
const double colStatus = 56;

double get tableMinWidth =>
    colSetting + colRead * 5 + colAvg + colRange + colStatus;

/// Column header cell — fixed width
class TableHeaderCell extends StatelessWidget {
  final String text;
  final double width;

  const TableHeaderCell(this.text, this.width, {super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
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

/// Single data row — fixed widths matching header
class MeasurementTableRow extends StatelessWidget {
  final double settingValue;
  final TextEditingController settingController;
  final List<TextEditingController> controllers;
  final String rangeStr;
  final double? avg;
  final bool? status;
  final bool isLast;
  final bool hasError; // true when 1–2 reads entered (not enough)
  final VoidCallback onChanged;

  const MeasurementTableRow({
    super.key,
    required this.settingValue,
    required this.settingController,
    required this.controllers,
    required this.rangeStr,
    required this.avg,
    required this.status,
    required this.isLast,
    required this.onChanged,
    this.hasError = false,
  });

  Widget _inputCell({
    required double width,
    required TextEditingController controller,
    required String hintText,
    required TextStyle style,
    required TextStyle hintStyle,
    bool leftBorder = true,
    Color? bg,
  }) {
    return Container(
      width: width,
      height: double.infinity,
      decoration: BoxDecoration(
        color: bg,
        border: leftBorder
            ? const Border(left: BorderSide(color: AppColors.border))
            : null,
      ),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.center,
        textAlignVertical: TextAlignVertical.center,
        expands: true,
        maxLines: null,
        style: style,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: hintStyle,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          isCollapsed: true,
        ),
        onChanged: (_) => onChanged(),
      ),
    );
  }

  Widget _cell({
    required double width,
    required Widget child,
    bool leftBorder = true,
    Color? bg,
  }) {
    return Container(
      width: width,
      height: double.infinity,
      decoration: BoxDecoration(
        color: bg,
        border: leftBorder
            ? const Border(left: BorderSide(color: AppColors.border))
            : null,
      ),
      alignment: Alignment.center,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        border: Border(
          bottom: isLast
              ? BorderSide.none
              : const BorderSide(color: AppColors.border),
          left: hasError
              ? const BorderSide(color: AppColors.error, width: 3)
              : BorderSide.none,
        ),
      ),
      child: Row(
        children: [
          // Setting value — editable
          _inputCell(
            width: colSetting,
            leftBorder: false,
            bg: AppColors.surfaceVariant,
            controller: settingController,
            hintText: settingValue.toStringAsFixed(0),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
            hintStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textHint,
            ),
          ),
          // Read inputs ×5
          ...List.generate(
            5,
            (i) => _inputCell(
              width: colRead,
              controller: controllers[i],
              hintText: i < 3 ? '*' : '-',
              style: TextStyle(
                fontSize: 13,
                color: i < 3 ? AppColors.textPrimary : AppColors.textSecondary,
              ),
              hintStyle: TextStyle(
                fontSize: 13,
                color: i < 3
                    ? AppColors.accent.withValues(alpha: 0.4)
                    : AppColors.textHint,
              ),
            ),
          ),
          // Average
          _cell(
            width: colAvg,
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
          // Range
          _cell(
            width: colRange,
            child: Text(
              rangeStr,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
          // Status
          _cell(
            width: colStatus,
            child: hasError
                ? const Icon(Icons.warning_amber_rounded,
                    color: AppColors.error, size: 18)
                : status == null
                    ? const Text('-',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textHint))
                    : Icon(
                        status! ? Icons.check_circle : Icons.cancel,
                        color:
                            status! ? AppColors.success : AppColors.error,
                        size: 18,
                      ),
          ),
        ],
      ),
    );
  }
}
