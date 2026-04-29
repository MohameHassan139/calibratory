import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/models.dart';

class RecentSessionCard extends StatelessWidget {
  final CalibrationSession session;

  const RecentSessionCard({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final Color statusColor = session.overallResult == 'PASS'
        ? AppColors.success
        : session.overallResult == 'FAIL'
            ? AppColors.error
            : AppColors.warning;

    final IconData statusIcon = session.overallResult == 'PASS'
        ? Icons.check_circle_outline
        : session.overallResult == 'FAIL'
            ? Icons.cancel_outlined
            : Icons.pending_outlined;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(statusIcon, color: statusColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.customerName.isEmpty
                      ? 'Unnamed Patient'
                      : session.customerName,
                  style: const TextStyle(
                    fontFamily: 'DMSans',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${session.manufacturer} · ${session.model}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${session.createdAt.day}/${session.createdAt.month}',
            style: const TextStyle(fontSize: 12, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }
}
