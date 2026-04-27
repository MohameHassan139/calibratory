import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class StatusChip extends StatelessWidget {
  final bool status;
  final String? label;

  const StatusChip({super.key, required this.status, this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: status
            ? AppColors.success.withValues(alpha: 0.12)
            : AppColors.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: status
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status ? Icons.check_circle_outline : Icons.cancel_outlined,
            size: 14,
            color: status ? AppColors.success : AppColors.error,
          ),
          const SizedBox(width: 4),
          Text(
            label ?? (status ? 'Pass' : 'Fail'),
            style: TextStyle(
              fontFamily: 'DMSans',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: status ? AppColors.success : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}
