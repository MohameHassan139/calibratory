import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../controllers/calibration_controller.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<CalibrationController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calibration History'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: ctrl.loadHistory,
          ),
        ],
      ),
      body: Obx(() {
        if (ctrl.history.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_edu_outlined,
                    size: 64, color: AppColors.textHint),
                SizedBox(height: 16),
                Text('No calibration sessions yet.',
                    style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: ctrl.history.length,
          itemBuilder: (ctx, i) => _HistoryCard(session: ctrl.history[i]),
        );
      }),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final dynamic session;
  const _HistoryCard({required this.session});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                  session.customerName.isEmpty
                      ? 'Unknown'
                      : session.customerName,
                  style: const TextStyle(
                    fontFamily: 'Syne',
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              if (session.overallResult != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (session.overallResult == true
                            ? AppColors.success
                            : AppColors.error)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    session.overallResult == true ? 'PASS' : 'FAIL',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: session.overallResult == true
                          ? AppColors.success
                          : AppColors.error,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${session.manufacturer} · ${session.model} · S/N: ${session.serialNumber}',
            style:
                const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            '${session.visitDate.day}/${session.visitDate.month}/${session.visitDate.year} · ${session.department}',
            style: const TextStyle(fontSize: 11, color: AppColors.textHint),
          ),
          if (session.certificateUrl != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.download_rounded, size: 14),
                  label:
                      const Text('Certificate', style: TextStyle(fontSize: 12)),
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.email_outlined, size: 14),
                  label:
                      const Text('Send Email', style: TextStyle(fontSize: 12)),
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    side: const BorderSide(color: AppColors.accent),
                    foregroundColor: AppColors.accent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
