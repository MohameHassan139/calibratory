import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/models.dart';
import '../../controllers/calibration_controller.dart';
import '../../widgets/auth/custom_text_field.dart';
import '../../widgets/calibration/calibration_step_bar.dart';
import '../../widgets/calibration/section_card.dart';
import '../../widgets/calibration/date_field.dart';
import '../../widgets/calibration/qual_row.dart';
import '../../widgets/calibration/table_preview.dart';
import '../../widgets/calibration/measurement_table.dart';

// ── Public Data Screen ────────────────────────────────────────────────────────

class PublicDataScreen extends StatefulWidget {
  const PublicDataScreen({super.key});

  @override
  State<PublicDataScreen> createState() => _PublicDataScreenState();
}

class _PublicDataScreenState extends State<PublicDataScreen> {
  final CalibrationController _ctrl = Get.find();
  final _customerCtrl = TextEditingController();
  final _deptCtrl = TextEditingController();
  final _mfrCtrl = TextEditingController();
  final _serialCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _visitTimeCtrl = TextEditingController();
  DateTime _orderDate = DateTime.now();
  DateTime _visitDate = DateTime.now();
  final _formKey = GlobalKey<FormState>();

  Future<void> _pickDate(bool isOrder) async {
    final d = await showDatePicker(
      context: context,
      initialDate: isOrder ? _orderDate : _visitDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (d != null) setState(() => isOrder ? _orderDate = d : _visitDate = d);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Calibration'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(40),
          child: CalibrationStepBar(
            totalSteps: 7,
            currentStep: 0,
            stepLabels: [
              'Public Data',
              'Qualitative Test',
              'Heart Rate',
              'SPO2',
              'NIBP',
              'Respiration',
              'Temperature',
            ],
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionCard(
                title: 'Customer Data',
                icon: Icons.person_outline,
                children: [
                  CustomTextField(
                    label: 'Customer Name',
                    hint: 'Enter customer name',
                    controller: _customerCtrl,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DateField(
                          label: 'Order Date',
                          date: _orderDate,
                          onTap: () => _pickDate(true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DateField(
                          label: 'Visit Date',
                          date: _visitDate,
                          onTap: () => _pickDate(false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Visit Time',
                    hint: 'e.g., 10:00 AM',
                    controller: _visitTimeCtrl,
                    prefixIcon: Icons.access_time_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: 'Monitor Data',
                icon: Icons.monitor_heart_outlined,
                children: [
                  CustomTextField(
                    label: 'Department',
                    hint: 'e.g., ICU, Emergency',
                    controller: _deptCtrl,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Manufacturer',
                    hint: 'e.g., Philips, GE',
                    controller: _mfrCtrl,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: 'Serial Number',
                          hint: 'S/N',
                          controller: _serialCtrl,
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          label: 'Model',
                          hint: 'Model name',
                          controller: _modelCtrl,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _ctrl.updatePublicData(
                        customerName: _customerCtrl.text.trim(),
                        orderDate: _orderDate,
                        visitDate: _visitDate,
                        visitTime: _visitTimeCtrl.text.trim(),
                        department: _deptCtrl.text.trim(),
                        manufacturer: _mfrCtrl.text.trim(),
                        serialNumber: _serialCtrl.text.trim(),
                        model: _modelCtrl.text.trim(),
                      );
                      Get.toNamed(AppRoutes.calibrationQualitative);
                    }
                  },
                  child: const Text('Next: Qualitative Test'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Qualitative Test Screen ───────────────────────────────────────────────────

class QualitativeTestScreen extends StatefulWidget {
  const QualitativeTestScreen({super.key});

  @override
  State<QualitativeTestScreen> createState() => _QualitativeTestScreenState();
}

class _QualitativeTestScreenState extends State<QualitativeTestScreen> {
  final CalibrationController _ctrl = Get.find();
  late Map<String, ItemStatus> _results;
  late Map<String, ItemStatus> _ecgResults;

  @override
  void initState() {
    super.initState();
    _results = {
      for (var item in MonitorConstants.qualitativeItems) item: ItemStatus.pass,
    };
    _ecgResults = {
      for (var item in MonitorConstants.ecgRepresentationItems)
        item: ItemStatus.pass,
    };
  }

  void _next() {
    _ctrl.updateQualitative(_results);
    _ctrl.updateEcgRepresentation(_ecgResults);
    final s = _ctrl.session.value!;
    if (s.showHrTable) {
      Get.toNamed(AppRoutes.calibrationHR);
    } else if (s.showSpo2Table) {
      Get.toNamed(AppRoutes.calibrationSPO2);
    } else if (s.showNibpTable) {
      Get.toNamed(AppRoutes.calibrationNIBP);
    } else if (s.showRespirationTable) {
      Get.toNamed(AppRoutes.calibrationRespiration);
    } else if (s.showTempTables) {
      Get.toNamed(AppRoutes.calibrationTemp);
    } else {
      Get.toNamed(AppRoutes.calibrationSummary);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Qualitative Test'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(40),
          child: CalibrationStepBar(
            totalSteps: 7,
            currentStep: 1,
            stepLabels: [
              'Public Data',
              'Qualitative Test',
              'Heart Rate',
              'SPO2',
              'NIBP',
              'Respiration',
              'Temperature',
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: AppColors.info.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: AppColors.info, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Select Pass / Fail / N/A for each item. Cable availability determines which measurement tables will be shown.',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.info.withValues(alpha: 0.9)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Qualitative Test',
              icon: Icons.checklist_outlined,
              children: MonitorConstants.qualitativeItems
                  .map((item) => QualRow(
                        item: item,
                        value: _results[item]!,
                        onChanged: (v) => setState(() => _results[item] = v),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'ECG Representation',
              icon: Icons.monitor_heart_outlined,
              children: MonitorConstants.ecgRepresentationItems
                  .map((item) => QualRow(
                        item: item,
                        value: _ecgResults[item]!,
                        onChanged: (v) => setState(() => _ecgResults[item] = v),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 28),
            if (_ctrl.session.value != null)
              TablePreview(
                showHR: _ctrl.session.value!.showHrTable,
                showSPO2: _ctrl.session.value!.showSpo2Table,
                showNIBP: _ctrl.session.value!.showNibpTable,
                showResp: _ctrl.session.value!.showRespirationTable,
                showTemp: _ctrl.session.value!.showTempTables,
              ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _next,
                child: const Text('Next: Measurements'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Generic Measurement Table Screen ─────────────────────────────────────────

class MeasurementTableScreen extends StatefulWidget {
  final String title;
  final String unit;
  final List<double> settings;
  final List<double> Function(double) acceptedRangeFunc;
  final List<MeasurementRow> initialRows;
  final void Function(List<MeasurementRow>) onSave;
  final String nextRoute;
  final int stepIndex;
  final bool isVisible;

  const MeasurementTableScreen({
    super.key,
    required this.title,
    required this.unit,
    required this.settings,
    required this.acceptedRangeFunc,
    required this.initialRows,
    required this.onSave,
    required this.nextRoute,
    required this.stepIndex,
    this.isVisible = true,
  });

  @override
  State<MeasurementTableScreen> createState() => _MeasurementTableScreenState();
}

class _MeasurementTableScreenState extends State<MeasurementTableScreen> {
  late List<MeasurementRow> rows;
  late List<List<TextEditingController>> controllers;

  @override
  void initState() {
    super.initState();
    rows = widget.settings
        .map((s) => MeasurementRow(settingValue: s, reads: []))
        .toList();
    controllers = List.generate(
        rows.length, (_) => List.generate(3, (_) => TextEditingController()));
  }

  void _computeAndSave() {
    for (int i = 0; i < rows.length; i++) {
      final reads = controllers[i]
          .map((c) => double.tryParse(c.text.trim()))
          .whereType<double>()
          .toList();
      rows[i] =
          MeasurementRow(settingValue: rows[i].settingValue, reads: reads);
      if (reads.isNotEmpty) {
        final avg = reads.reduce((a, b) => a + b) / reads.length;
        rows[i].average = avg;
        final range = widget.acceptedRangeFunc(rows[i].settingValue);
        rows[i].status = avg >= range[0] && avg <= range[1];
      }
    }
    widget.onSave(rows);
    Get.toNamed(widget.nextRoute);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onSave(rows);
        Get.toNamed(widget.nextRoute);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: CalibrationStepBar(
            totalSteps: 7,
            currentStep: widget.stepIndex,
            stepLabels: const [
              'Public Data',
              'Qualitative',
              'Heart Rate',
              'SPO2',
              'NIBP',
              'Respiration',
              'Temperature',
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
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
                            'Enter 3 readings for each setting value. The average will be computed automatically.',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.accent.withValues(alpha: 0.9)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Table
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                          child: Row(
                            children: [
                              TableHeaderCell('Set (${widget.unit})', 1.2),
                              const TableHeaderCell('Read 1', 1),
                              const TableHeaderCell('Read 2', 1),
                              const TableHeaderCell('Read 3', 1),
                              const TableHeaderCell('Avg', 1),
                              const TableHeaderCell('Range', 1.5),
                              const TableHeaderCell('Status', 0.9),
                            ],
                          ),
                        ),
                        // Data rows
                        ...List.generate(rows.length, (i) {
                          final range =
                              widget.acceptedRangeFunc(rows[i].settingValue);
                          return MeasurementTableRow(
                            settingValue: rows[i].settingValue,
                            controllers: controllers[i],
                            rangeStr:
                                '${range[0].toStringAsFixed(1)}-${range[1].toStringAsFixed(1)}',
                            avg: rows[i].average,
                            status: rows[i].status,
                            isLast: i == rows.length - 1,
                            onChanged: () => setState(() {
                              final reads = controllers[i]
                                  .map((c) => double.tryParse(c.text.trim()))
                                  .whereType<double>()
                                  .toList();
                              if (reads.length == 3) {
                                final avg = reads.reduce((a, b) => a + b) /
                                    reads.length;
                                rows[i].average = avg;
                                rows[i].status =
                                    avg >= range[0] && avg <= range[1];
                              }
                            }),
                          );
                        }),
                      ],
                    ),
                  ),
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
                child: const Text('Next'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
