import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/models.dart';
import '../../controllers/calibration_controller.dart';
import '../../widgets/calibration/measurement_table.dart';

class TemperatureScreen extends StatefulWidget {
  const TemperatureScreen({super.key});

  @override
  State<TemperatureScreen> createState() => _TemperatureScreenState();
}

class _TemperatureScreenState extends State<TemperatureScreen> {
  final CalibrationController _ctrl = Get.find();

  // Module 1
  late List<MeasurementRow> temp1Rows;
  late List<TextEditingController> temp1SetCtrl;
  late List<List<TextEditingController>> temp1ReadCtrl;
  late List<bool> temp1Errors;

  // Module 2
  late List<MeasurementRow> temp2Rows;
  late List<TextEditingController> temp2SetCtrl;
  late List<List<TextEditingController>> temp2ReadCtrl;
  late List<bool> temp2Errors;

  @override
  void initState() {
    super.initState();
    final settings = MonitorConstants.tempSettings;

    temp1Rows = settings.map((s) => MeasurementRow(settingValue: s)).toList();
    temp1SetCtrl = temp1Rows
        .map((r) => TextEditingController(text: r.settingValue.toStringAsFixed(0)))
        .toList();
    temp1ReadCtrl = List.generate(temp1Rows.length, (_) => List.generate(5, (_) => TextEditingController()));
    temp1Errors = List.filled(temp1Rows.length, false);

    temp2Rows = settings.map((s) => MeasurementRow(settingValue: s)).toList();
    temp2SetCtrl = temp2Rows
        .map((r) => TextEditingController(text: r.settingValue.toStringAsFixed(0)))
        .toList();
    temp2ReadCtrl = List.generate(temp2Rows.length, (_) => List.generate(5, (_) => TextEditingController()));
    temp2Errors = List.filled(temp2Rows.length, false);
  }

  @override
  void dispose() {
    for (final c in temp1SetCtrl) { c.dispose(); }
    for (final c in temp2SetCtrl) { c.dispose(); }
    for (final row in temp1ReadCtrl) { for (final c in row) { c.dispose(); } }
    for (final row in temp2ReadCtrl) { for (final c in row) { c.dispose(); } }
    super.dispose();
  }

  void _onChanged(int i, bool isModule1) {
    setState(() {
      final rows = isModule1 ? temp1Rows : temp2Rows;
      final setCtrl = isModule1 ? temp1SetCtrl : temp2SetCtrl;
      final readCtrl = isModule1 ? temp1ReadCtrl : temp2ReadCtrl;
      final errors = isModule1 ? temp1Errors : temp2Errors;

      final sv = double.tryParse(setCtrl[i].text.trim()) ?? rows[i].settingValue;
      final reads = readCtrl[i]
          .map((c) => double.tryParse(c.text.trim()))
          .whereType<double>()
          .toList();

      errors[i] = reads.length < 3;

      if (reads.length >= 3) {
        final avg = reads.reduce((a, b) => a + b) / reads.length;
        rows[i].average = avg;
        final range = MonitorConstants.tempAcceptedRange(sv);
        rows[i].status = avg >= range[0] && avg <= range[1];
      } else {
        rows[i].average = null;
        rows[i].status = null;
      }
    });
  }

  void _computeAndSave() {
    bool hasError = false;

    void validate(
      List<MeasurementRow> rows,
      List<TextEditingController> setCtrl,
      List<List<TextEditingController>> readCtrl,
      List<bool> errors,
    ) {
      for (int i = 0; i < rows.length; i++) {
        final reads = readCtrl[i]
            .map((c) => double.tryParse(c.text.trim()))
            .whereType<double>()
            .toList();
        errors[i] = reads.length < 3;
        if (errors[i]) hasError = true;

        final sv = double.tryParse(setCtrl[i].text.trim()) ?? rows[i].settingValue;
        rows[i] = MeasurementRow(settingValue: sv, reads: reads);
        if (reads.isNotEmpty) {
          final avg = reads.reduce((a, b) => a + b) / reads.length;
          rows[i].average = avg;
          final range = MonitorConstants.tempAcceptedRange(sv);
          rows[i].status = avg >= range[0] && avg <= range[1];
        }
      }
    }

    validate(temp1Rows, temp1SetCtrl, temp1ReadCtrl, temp1Errors);
    validate(temp2Rows, temp2SetCtrl, temp2ReadCtrl, temp2Errors);

    if (hasError) {
      setState(() {});
      Get.snackbar(
        'Incomplete Data',
        'Every row needs at least 3 readings.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    _ctrl.updateTempRows(temp1Rows, temp2Rows);
    Get.toNamed(AppRoutes.calibrationSummary);
  }

  Widget _buildTable({
    required String title,
    required List<MeasurementRow> rows,
    required List<TextEditingController> setCtrl,
    required List<List<TextEditingController>> readCtrl,
    required List<bool> errors,
    required bool isModule1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: 'Syne',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    color: AppColors.primary,
                    child: const Row(
                      children: [
                        TableHeaderCell('Set\n(°C)', colSetting),
                        TableHeaderCell('Read 1', colRead),
                        TableHeaderCell('Read 2', colRead),
                        TableHeaderCell('Read 3', colRead),
                        TableHeaderCell('Read 4', colRead),
                        TableHeaderCell('Read 5', colRead),
                        TableHeaderCell('Avg', colAvg),
                        TableHeaderCell('Range', colRange),
                        TableHeaderCell('Status', colStatus),
                      ],
                    ),
                  ),
                  // Data rows
                  ...List.generate(rows.length, (i) {
                    final effectiveSetting =
                        double.tryParse(setCtrl[i].text.trim()) ?? rows[i].settingValue;
                    final range = MonitorConstants.tempAcceptedRange(effectiveSetting);
                    return MeasurementTableRow(
                      settingValue: rows[i].settingValue,
                      settingController: setCtrl[i],
                      controllers: readCtrl[i],
                      rangeStr:
                          '${range[0].toStringAsFixed(3)}-${range[1].toStringAsFixed(3)}',
                      avg: rows[i].average,
                      status: rows[i].status,
                      isLast: i == rows.length - 1,
                      hasError: errors[i],
                      onChanged: () => _onChanged(i, isModule1),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!(_ctrl.session.value?.showTempTables ?? false)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _ctrl.updateTempRows([], []);
        Get.toNamed(AppRoutes.calibrationSummary);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Temperature Measurement'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info banner
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            color: AppColors.accent, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Enter 3 to 5 readings per row (min 3). Average updates automatically.',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.accent.withValues(alpha: 0.9)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Module 1 table
                  _buildTable(
                    title: 'Temperature Measurement (MODULE 1)',
                    rows: temp1Rows,
                    setCtrl: temp1SetCtrl,
                    readCtrl: temp1ReadCtrl,
                    errors: temp1Errors,
                    isModule1: true,
                  ),
                  const SizedBox(height: 24),
                  // Module 2 table
                  _buildTable(
                    title: 'Temperature Measurement (MODULE 2)',
                    rows: temp2Rows,
                    setCtrl: temp2SetCtrl,
                    readCtrl: temp2ReadCtrl,
                    errors: temp2Errors,
                    isModule1: false,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _computeAndSave,
                child: const Text('Complete Measurements'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
