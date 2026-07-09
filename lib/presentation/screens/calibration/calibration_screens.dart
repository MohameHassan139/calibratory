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
  final _testDeviceMfrCtrl = TextEditingController();
  final _testDeviceSerialCtrl = TextEditingController();
  final _testDeviceModelCtrl = TextEditingController();
  final _engineerNameCtrl = TextEditingController();
  final _testTypeCtrl = TextEditingController();
  final _testLabCtrl = TextEditingController();
  DateTime _orderDate = DateTime.now();
  DateTime _visitDate = DateTime.now();
  String? _deviceType;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final s = _ctrl.session.value;
    if (s != null) {
      _customerCtrl.text = s.customerName;
      _deptCtrl.text = s.department;
      _mfrCtrl.text = s.manufacturer;
      _serialCtrl.text = s.serialNumber;
      _modelCtrl.text = s.model;
      _visitTimeCtrl.text = s.visitTime;
      _orderDate = s.orderDate;
      _visitDate = s.visitDate;
      if (s.deviceType.isNotEmpty) {
        _deviceType = s.deviceType;
      }
      _testDeviceMfrCtrl.text = s.testDeviceManufacturer;
      _testDeviceSerialCtrl.text = s.testDeviceSerialNumber;
      _testDeviceModelCtrl.text = s.testDeviceModel;
      _engineerNameCtrl.text = s.engineerName;
      _testTypeCtrl.text = s.testType;
      _testLabCtrl.text = s.testLab;
    }
  }

  @override
  void dispose() {
    _customerCtrl.dispose();
    _deptCtrl.dispose();
    _mfrCtrl.dispose();
    _serialCtrl.dispose();
    _modelCtrl.dispose();
    _visitTimeCtrl.dispose();
    _testDeviceMfrCtrl.dispose();
    _testDeviceSerialCtrl.dispose();
    _testDeviceModelCtrl.dispose();
    _engineerNameCtrl.dispose();
    _testTypeCtrl.dispose();
    _testLabCtrl.dispose();
    super.dispose();
  }

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
                title: 'Test & Lab Information',
                icon: Icons.science_outlined,
                children: [
                  CustomTextField(
                    label: 'Tester Name (القائم بالاختبار)',
                    hint: 'Enter tester name',
                    controller: _engineerNameCtrl,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Test Laboratory (معمل الاختبار)',
                    hint: 'Enter laboratory name',
                    controller: _testLabCtrl,
                    maxLines: 2,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Test Type (نوع الاختبار)',
                    hint: 'Enter test type',
                    controller: _testTypeCtrl,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: 'Devices ',
                icon: Icons.device_hub,
                children: [
                  // Device Type dropdown
                  DropdownButtonFormField<String>(
                    value: _deviceType,
                    decoration: InputDecoration(
                      labelText: 'Device Type',
                      hintText: 'Select device type',
                      prefixIcon: const Icon(Icons.devices_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                    items: MonitorConstants.deviceTypes
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) => setState(() => _deviceType = v),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
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
              const SizedBox(height: 16),
              SectionCard(
                title: 'Testing Device Data',
                icon: Icons.biotech_outlined,
                children: [
                  CustomTextField(
                    label: 'Testing Device Manufacturer',
                    hint: 'e.g., Pronk, Fluke',
                    controller: _testDeviceMfrCtrl,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: 'Testing Device Serial Number',
                          hint: 'S/N',
                          controller: _testDeviceSerialCtrl,
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          label: 'Testing Device Model',
                          hint: 'Model name',
                          controller: _testDeviceModelCtrl,
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
                        deviceType: _deviceType ?? '',
                        testDeviceManufacturer: _testDeviceMfrCtrl.text.trim(),
                        testDeviceModel: _testDeviceModelCtrl.text.trim(),
                        testDeviceSerialNumber: _testDeviceSerialCtrl.text.trim(),
                        engineerName: _engineerNameCtrl.text.trim(),
                        testType: _testTypeCtrl.text.trim(),
                        testLab: _testLabCtrl.text.trim(),
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
  late List<TextEditingController> settingControllers;
  late List<bool> rowErrors; // true when 1–2 reads entered
  late List<bool> selectedRows; // true when row is selected for deletion

  @override
  void initState() {
    super.initState();
    rows = widget.settings
        .map((s) => MeasurementRow(settingValue: s, reads: []))
        .toList();
    controllers = List.generate(
        rows.length, (_) => List.generate(5, (_) => TextEditingController()));
    settingControllers = rows
        .map((r) =>
            TextEditingController(text: r.settingValue.toStringAsFixed(0)))
        .toList();
    rowErrors = List.filled(rows.length, false, growable: true);
    selectedRows = List.filled(rows.length, false, growable: true);
  }

  @override
  void dispose() {
    for (final c in settingControllers) {
      c.dispose();
    }
    for (final row in controllers) {
      for (final c in row) {
        c.dispose();
      }
    }
    super.dispose();
  }

  void _deleteSelected() {
    final indices = <int>[];
    for (int i = 0; i < selectedRows.length; i++) {
      if (selectedRows[i]) indices.add(i);
    }
    if (indices.isEmpty) return;

    setState(() {
      // Dispose controllers for deleted rows
      for (final i in indices.reversed) {
        settingControllers[i].dispose();
        for (final c in controllers[i]) {
          c.dispose();
        }
        rows.removeAt(i);
        controllers.removeAt(i);
        settingControllers.removeAt(i);
        rowErrors.removeAt(i);
        selectedRows.removeAt(i);
      }
    });
  }

  void _computeAndSave() {
    // Mark rows with fewer than 3 reads as errors (0 reads also invalid)
    bool hasAnyError = false;
    for (int i = 0; i < rows.length; i++) {
      final reads = controllers[i]
          .map((c) => double.tryParse(c.text.trim()))
          .whereType<double>()
          .toList();
      rowErrors[i] = reads.length < 3;
      if (rowErrors[i]) hasAnyError = true;
    }
    if (hasAnyError) {
      setState(() {});
      Get.snackbar(
        'Incomplete Data',
        'Every row needs at least 3 readings.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    for (int i = 0; i < rows.length; i++) {
      final enteredSetting =
          double.tryParse(settingControllers[i].text.trim());
      if (enteredSetting != null) rows[i].settingValue = enteredSetting;
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
                            'Enter 3 to 5 readings per row (minimum 3 required). Average updates automatically.',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.accent.withValues(alpha: 0.9)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Delete selected button
                  if (selectedRows.any((s) => s))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          TextButton.icon(
                            onPressed: _deleteSelected,
                            icon: const Icon(Icons.delete_outline,
                                color: AppColors.error, size: 18),
                            label: Text(
                              'Remove selected (${selectedRows.where((s) => s).length})',
                              style: const TextStyle(color: AppColors.error),
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Table
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
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 8),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: colCheckbox,
                                    child: Checkbox(
                                      value: selectedRows.isNotEmpty &&
                                          selectedRows.every((s) => s),
                                      tristate: selectedRows.any((s) => s) &&
                                          !selectedRows.every((s) => s),
                                      onChanged: (v) => setState(() {
                                        final val = v ?? false;
                                        for (int i = 0;
                                            i < selectedRows.length;
                                            i++) {
                                          selectedRows[i] = val;
                                        }
                                      }),
                                      activeColor: AppColors.error,
                                      checkColor: Colors.white,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                                  TableHeaderCell('Set\n(${widget.unit})', colSetting),
                                  const TableHeaderCell('Read 1', colRead),
                                  const TableHeaderCell('Read 2', colRead),
                                  const TableHeaderCell('Read 3', colRead),
                                  const TableHeaderCell('Read 4', colRead),
                                  const TableHeaderCell('Read 5', colRead),
                                  const TableHeaderCell('Avg', colAvg),
                                  const TableHeaderCell('Range', colRange),
                                  const TableHeaderCell('Status', colStatus),
                                ],
                              ),
                            ),
                            // Data rows
                            ...List.generate(rows.length, (i) {
                              final effectiveSetting = double.tryParse(
                                      settingControllers[i].text.trim()) ??
                                  rows[i].settingValue;
                              final range =
                                  widget.acceptedRangeFunc(effectiveSetting);
                              return MeasurementTableRow(
                                settingValue: rows[i].settingValue,
                                settingController: settingControllers[i],
                                controllers: controllers[i],
                                rangeStr:
                                    '${range[0].toStringAsFixed(3)}-${range[1].toStringAsFixed(3)}',
                                avg: rows[i].average,
                                status: rows[i].status,
                                isLast: i == rows.length - 1,
                                onChanged: () => setState(() {
                                  final sv = double.tryParse(
                                          settingControllers[i].text.trim()) ??
                                      rows[i].settingValue;
                                  final reads = controllers[i]
                                      .map((c) =>
                                          double.tryParse(c.text.trim()))
                                      .whereType<double>()
                                      .toList();
                                  // Update error state live
                                  rowErrors[i] = reads.length < 3;
                                  if (reads.length >= 3) {
                                    final avg =
                                        reads.reduce((a, b) => a + b) /
                                            reads.length;
                                    rows[i].average = avg;
                                    final r = widget.acceptedRangeFunc(sv);
                                    rows[i].status =
                                        avg >= r[0] && avg <= r[1];
                                  } else {
                                    rows[i].average = null;
                                    rows[i].status = null;
                                  }
                                }),
                                hasError: rowErrors[i],
                                isSelected: selectedRows[i],
                                onToggleSelect: () => setState(
                                    () => selectedRows[i] = !selectedRows[i]),
                              );
                            }),
                          ],
                        ),
                      ),
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
