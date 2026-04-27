import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../controllers/calibration_controller.dart';
import '../../widgets/auth/custom_text_field.dart';
import '../../widgets/calibration/summary_row.dart';

class CalibrationSummaryScreen extends StatefulWidget {
  const CalibrationSummaryScreen({super.key});

  @override
  State<CalibrationSummaryScreen> createState() =>
      _CalibrationSummaryScreenState();
}

class _CalibrationSummaryScreenState extends State<CalibrationSummaryScreen> {
  final CalibrationController _ctrl = Get.find();
  final _notesCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final session = _ctrl.session.value;
    if (session == null) {
      return const Scaffold(body: Center(child: Text('No session')));
    }
    if (session.id != null) return _CompletedView(session: session);

    return Scaffold(
      appBar: AppBar(title: const Text('Review & Complete')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Summary card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Session Summary',
                    style: TextStyle(
                      fontFamily: 'Syne',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Divider(height: 24),
                  SummaryRow('Customer', session.customerName),
                  SummaryRow('Serial No.', session.serialNumber),
                  SummaryRow('Model', session.model),
                  SummaryRow('Manufacturer', session.manufacturer),
                  SummaryRow('Department', session.department),
                  const Divider(height: 16),
                  SummaryRow(
                      'HR Table', session.showHrTable ? '✓ Included' : '✗ NF'),
                  SummaryRow('SPO2 Table',
                      session.showSpo2Table ? '✓ Included' : '✗ NF'),
                  SummaryRow('NIBP Table',
                      session.showNibpTable ? '✓ Included' : '✗ NF'),
                  SummaryRow('Respiration Table',
                      session.showRespirationTable ? '✓ Included' : '✗ NF'),
                  SummaryRow('Temp Tables',
                      session.showTempTables ? '✓ Included' : '✗ NF'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Notes',
              hint: 'Add any additional notes...',
              controller: _notesCtrl,
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Client Email (for certificate delivery)',
              hint: 'client@hospital.com',
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.email_outlined,
            ),
            const SizedBox(height: 28),
            Obx(() => _ctrl.isLoading.value
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.verified_outlined),
                      label: const Text('Complete & Generate Certificate'),
                      onPressed: () => _ctrl.completeCalibration(
                          notes: _notesCtrl.text.trim()),
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}

class _CompletedView extends StatelessWidget {
  final dynamic session;
  const _CompletedView({required this.session});

  @override
  Widget build(BuildContext context) {
    final bool passed = session.overallResult == true;
    final Color color = passed ? AppColors.success : AppColors.error;

    return Scaffold(
      appBar: AppBar(title: const Text('Certificate Ready')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                passed ? Icons.verified_rounded : Icons.cancel_rounded,
                size: 50,
                color: color,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              passed ? 'PASSED' : 'FAILED',
              style: TextStyle(
                fontFamily: 'Syne',
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Calibration complete. Certificate generated.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            if (session.certificateUrl != null)
              ElevatedButton.icon(
                icon: const Icon(Icons.download_rounded),
                label: const Text('Download Certificate'),
                onPressed: () {},
              ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.share_rounded),
              label: const Text('Share Certificate'),
              onPressed: () {},
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Get.offAllNamed(AppRoutes.home),
              child: const Text('Back to Dashboard'),
            ),
          ],
        ),
      ),
    );
  }
}
