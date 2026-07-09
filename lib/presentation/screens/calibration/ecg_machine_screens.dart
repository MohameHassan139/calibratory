import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/models.dart';
import '../../controllers/calibration_controller.dart';
import '../../widgets/auth/custom_text_field.dart';
import '../history/calibration_detail_screen.dart';

// ── ECG Machine Summary Screen ────────────────────────────────────────────────

class EcgMachineSummaryScreen extends StatefulWidget {
  const EcgMachineSummaryScreen({super.key});

  @override
  State<EcgMachineSummaryScreen> createState() =>
      _EcgMachineSummaryScreenState();
}

class _EcgMachineSummaryScreenState extends State<EcgMachineSummaryScreen> {
  final CalibrationController _ctrl = Get.find();
  final _notesCtrl  = TextEditingController();
  final _emailCtrl  = TextEditingController();

  @override
  void dispose() {
    _notesCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = _ctrl.session.value;
    if (session == null) {
      return const Scaffold(body: Center(child: Text('No session')));
    }
    if (session.id != null) return _EcgMachineCompletedView(session: session);

    final hrRows = session.ecgMachineHrRows;

    return Scaffold(
      appBar: AppBar(title: const Text('Review & Complete')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Session summary ──────────────────────────────────────────
            _card(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Session Summary',
                    style: TextStyle(
                        fontFamily: 'Syne',
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
                const Divider(height: 24),
                _row('Customer',    session.customerName),
                _row('Serial No.',  session.serialNumber),
                _row('Model',       session.model),
                _row('Manufacturer', session.manufacturer),
                _row('Department',  session.department),
                _row('Device Type', session.deviceType),
                const Divider(height: 16),
                _row('Tester',    session.engineerName),
                _row('Test Lab',  session.testLab),
                _row('Test Type', session.testType),
              ],
            )),
            const SizedBox(height: 16),
            // ── Qualitative ──────────────────────────────────────────────
            _card(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Qualitative – Visual Inspection & Arrhythmia',
                    style: TextStyle(
                        fontFamily: 'Syne',
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
                const Divider(height: 16),
                ...session.qualitativeResults.entries.map((e) {
                  final color = e.value == ItemStatus.pass
                      ? AppColors.success
                      : e.value == ItemStatus.fail
                          ? AppColors.error
                          : AppColors.textSecondary;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(children: [
                      Expanded(child: Text(e.key,
                          style: const TextStyle(fontSize: 13))),
                      Text(e.value.label,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: color)),
                    ]),
                  );
                }),
              ],
            )),
            const SizedBox(height: 16),

            // ── Heart Rate table ─────────────────────────────────────────
            _card(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Heart Rate Measurement for Normal ECG rhythm',
                    style: TextStyle(
                        fontFamily: 'Syne',
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
                const Divider(height: 16),
                if (hrRows.isEmpty)
                  const Text('No data entered.',
                      style: TextStyle(color: AppColors.textSecondary))
                else
                  _hrTable(hrRows),
              ],
            )),
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
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.verified_outlined),
                      label: const Text('Complete & Generate Certificate'),
                      onPressed: () => _ctrl.completeEcgMachineCalibration(
                        notes: _notesCtrl.text.trim(),
                        clientEmail: _emailCtrl.text.trim().isEmpty
                            ? null
                            : _emailCtrl.text.trim(),
                      ),
                    ),
                  )),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _hrTable(List<MeasurementRow> rows) {
    const headers = [
      'Setting\n(BPM*)',
      'Avg\nMeasured**',
      'Error***',
      'Accepted\nRange ±5%',
      'Status',
      'Uncertainty\n(Type A)',
    ];
    const widths   = [70.0, 80.0, 65.0, 130.0, 60.0, 90.0];
    const ranges   = EcgMachineConstants.hrAcceptedRanges;
    const settings = EcgMachineConstants.hrSettings;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Table(
          defaultColumnWidth: const IntrinsicColumnWidth(),
          border: TableBorder.all(color: AppColors.border, width: 0.5),
          children: [
            TableRow(
              decoration: const BoxDecoration(color: AppColors.primary),
              children: List.generate(
                  headers.length, (i) => _th(headers[i], widths[i])),
            ),
            ...List.generate(rows.length, (i) {
              final r       = rows[i];
              final avg     = r.average;
              final setting = i < settings.length ? settings[i] : r.settingValue;
              final err     = avg != null
                  ? (setting - avg).abs().toStringAsFixed(2)
                  : 'N/A';
              final rangeStr = i < ranges.length
                  ? '(${ranges[i][0]}  -  ${ranges[i][1]})'
                  : 'N/A';
              final sta = r.status == true
                  ? 'PASS'
                  : r.status == false ? 'FAIL' : 'N/A';
              final staColor = r.status == true
                  ? AppColors.success
                  : r.status == false ? AppColors.error : AppColors.textSecondary;
              final unc = avg != null ? _typeA(r.reads) : 'N/A';
              return TableRow(children: [
                _td(setting.toStringAsFixed(0), widths[0]),
                _td(avg != null ? avg.toStringAsFixed(2) : 'N/A', widths[1]),
                _td(err, widths[2]),
                _td(rangeStr, widths[3]),
                _td(sta, widths[4], color: staColor, bold: true),
                _td(unc, widths[5]),
              ]);
            }),
          ],
        ),
      ),
    );
  }

  static String _typeA(List<double> reads) {
    if (reads.length < 2) return '0.0000';
    final mean = reads.reduce((a, b) => a + b) / reads.length;
    double sumSq = 0;
    for (final r in reads) sumSq += (r - mean) * (r - mean);
    final s = _sqrt(sumSq / (reads.length - 1));
    return (s / _sqrt(reads.length.toDouble())).toStringAsFixed(4);
  }

  static double _sqrt(double v) {
    if (v <= 0) return 0;
    double x = v;
    for (int i = 0; i < 50; i++) x = (x + v / x) / 2;
    return x;
  }

  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: child,
      );

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          Expanded(child: Text(label,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
          Expanded(child: Text(value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
        ]),
      );

  Widget _th(String text, double width) => SizedBox(
        width: width,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Text(text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
        ),
      );

  Widget _td(String text, double width, {Color? color, bool bold = false}) =>
      SizedBox(
        width: width,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
          child: Text(text,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12,
                  color: color ?? AppColors.textPrimary,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.normal)),
        ),
      );
}

// ── ECG Machine Completed View ────────────────────────────────────────────────

class _EcgMachineCompletedView extends StatelessWidget {
  final dynamic session;
  const _EcgMachineCompletedView({required this.session});

  @override
  Widget build(BuildContext context) {
    final bool passed = session.overallResult == 'PASS';
    final Color color = passed ? AppColors.success : AppColors.error;
    return Scaffold(
      appBar: AppBar(title: const Text('Certificate Ready')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(
                    passed ? Icons.verified_rounded : Icons.cancel_rounded,
                    size: 50,
                    color: color),
              ),
              const SizedBox(height: 24),
              Text(passed ? 'PASSED' : 'FAILED',
                  style: TextStyle(
                      fontFamily: 'Syne',
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: color)),
              const SizedBox(height: 8),
              const Text('ECG machine calibration complete. Certificate generated.',
                  style: TextStyle(color: AppColors.textSecondary),
                  textAlign: TextAlign.center),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('View Full Details'),
                  onPressed: () => Get.to(
                    () => CalibrationDetailScreen(session: session),
                    transition: Transition.rightToLeft,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.home_outlined),
                  label: const Text('Back to Dashboard'),
                  onPressed: () => Get.offAllNamed(AppRoutes.home),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
