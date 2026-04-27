import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class TablePreview extends StatelessWidget {
  final bool showHR;
  final bool showSPO2;
  final bool showNIBP;
  final bool showResp;
  final bool showTemp;

  const TablePreview({
    super.key,
    required this.showHR,
    required this.showSPO2,
    required this.showNIBP,
    required this.showResp,
    required this.showTemp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tables to be measured:',
            style: TextStyle(
              fontFamily: 'Syne',
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _PreviewChip(label: 'Heart Rate', visible: showHR),
              _PreviewChip(label: 'SPO2', visible: showSPO2),
              _PreviewChip(label: 'NIBP', visible: showNIBP),
              _PreviewChip(label: 'Respiration', visible: showResp),
              _PreviewChip(label: 'Temperature', visible: showTemp),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreviewChip extends StatelessWidget {
  final String label;
  final bool visible;

  const _PreviewChip({required this.label, required this.visible});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: visible
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: visible
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.error.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            visible ? Icons.check_rounded : Icons.block_rounded,
            size: 12,
            color: visible ? AppColors.success : AppColors.error,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: visible ? AppColors.success : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}
