// lib/presentation/screens/calibration/public_data_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/models.dart';
import '../../controllers/calibration_controller.dart';
import '../../widgets/shared_widgets.dart';

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
              'Temperature'
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
              _SectionCard(
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
                        child: _DateField(
                          label: 'Order Date',
                          date: _orderDate,
                          onTap: () => _pickDate(true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DateField(
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
              _SectionCard(
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

// ── Qualitative Test Screen ──────────────────────────────────────────────────

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
    // Navigate based on cable availability
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
              'Temperature'
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.info.withOpacity(0.2)),
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
                          fontSize: 12, color: AppColors.info.withOpacity(0.9)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            _SectionCard(
              title: 'Qualitative Test',
              icon: Icons.checklist_outlined,
              children: MonitorConstants.qualitativeItems
                  .map((item) => _QualRow(
                        item: item,
                        value: _results[item]!,
                        onChanged: (v) => setState(() => _results[item] = v),
                      ))
                  .toList(),
            ),

            const SizedBox(height: 16),

            _SectionCard(
              title: 'ECG Representation',
              icon: Icons.monitor_heart_outlined,
              children: MonitorConstants.ecgRepresentationItems
                  .map((item) => _QualRow(
                        item: item,
                        value: _ecgResults[item]!,
                        onChanged: (v) => setState(() => _ecgResults[item] = v),
                      ))
                  .toList(),
            ),

            const SizedBox(height: 28),

            // Preview which tables will show
            _ctrl.session.value != null
                ? _TablePreview(
                    showHR: _ctrl.session.value!.showHrTable,
                    showSPO2: _ctrl.session.value!.showSpo2Table,
                    showNIBP: _ctrl.session.value!.showNibpTable,
                    showResp: _ctrl.session.value!.showRespirationTable,
                    showTemp: _ctrl.session.value!.showTempTables,
                  )
                : const SizedBox(),

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

class _QualRow extends StatelessWidget {
  final String item;
  final ItemStatus value;
  final ValueChanged<ItemStatus> onChanged;
  const _QualRow(
      {required this.item, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(item,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textPrimary)),
          ),
          _StatusToggle(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _StatusToggle extends StatelessWidget {
  final ItemStatus value;
  final ValueChanged<ItemStatus> onChanged;
  const _StatusToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: ItemStatus.values.map((s) {
        final isSelected = s == value;
        Color color;
        switch (s) {
          case ItemStatus.pass:
            color = AppColors.success;
            break;
          case ItemStatus.fail:
            color = AppColors.error;
            break;
          case ItemStatus.notAvailable:
            color = AppColors.textHint;
            break;
        }
        return GestureDetector(
          onTap: () => onChanged(s),
          child: Container(
            margin: const EdgeInsets.only(left: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? color : AppColors.border,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Text(
              s.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected ? color : AppColors.textHint,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _TablePreview extends StatelessWidget {
  final bool showHR, showSPO2, showNIBP, showResp, showTemp;
  const _TablePreview(
      {required this.showHR,
      required this.showSPO2,
      required this.showNIBP,
      required this.showResp,
      required this.showTemp});

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
            ? AppColors.success.withOpacity(0.1)
            : AppColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: visible
              ? AppColors.success.withOpacity(0.3)
              : AppColors.error.withOpacity(0.2),
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

// ── Measurement Table Screen (generic) ───────────────────────────────────────

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
  // Controllers: each row has up to 3 controllers (app uses 3 reads based on excel pattern)
  late List<List<TextEditingController>> controllers;
  final CalibrationController _ctrl = Get.find();

  @override
  void initState() {
    super.initState();
    // Init rows from settings
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
      // Auto-skip: mark NF and go next
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
              'Temperature'
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
                  // Table header info
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: AppColors.accent.withOpacity(0.15)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            color: AppColors.accent, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Enter 3 readings for each setting value. The average will be computed automatically and compared to the accepted range.',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.accent.withOpacity(0.9)),
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
                              _HeaderCell('Set (${widget.unit})', 1.2),
                              const _HeaderCell('Read 1', 1),
                              const _HeaderCell('Read 2', 1),
                              const _HeaderCell('Read 3', 1),
                              const _HeaderCell('Avg', 1),
                              const _HeaderCell('Range', 1.5),
                              const _HeaderCell('Status', 0.9),
                            ],
                          ),
                        ),
                        // Rows
                        ...List.generate(rows.length, (i) {
                          final range =
                              widget.acceptedRangeFunc(rows[i].settingValue);
                          return _MeasRow(
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

class _HeaderCell extends StatelessWidget {
  final String text;
  final double flex;
  const _HeaderCell(this.text, this.flex);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: (flex * 10).toInt(),
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

class _MeasRow extends StatelessWidget {
  final double settingValue;
  final List<TextEditingController> controllers;
  final String rangeStr;
  final double? avg;
  final bool? status;
  final bool isLast;
  final VoidCallback onChanged;

  const _MeasRow({
    required this.settingValue,
    required this.controllers,
    required this.rangeStr,
    required this.avg,
    required this.status,
    required this.isLast,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Setting value
            Expanded(
              flex: 12,
              child: Container(
                padding: const EdgeInsets.all(8),
                color: AppColors.surfaceVariant,
                child: Text(
                  settingValue.toStringAsFixed(0),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            // Read inputs
            ...List.generate(
                3,
                (i) => Expanded(
                      flex: 10,
                      child: Container(
                        decoration: const BoxDecoration(
                          border:
                              Border(left: BorderSide(color: AppColors.border)),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: TextField(
                          controller: controllers[i],
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: '-',
                            hintStyle: TextStyle(
                                fontSize: 12, color: AppColors.textHint),
                            contentPadding: EdgeInsets.zero,
                            filled: false,
                          ),
                          onChanged: (_) => onChanged(),
                        ),
                      ),
                    )),
            // Average
            Expanded(
              flex: 10,
              child: Container(
                decoration: const BoxDecoration(
                  border: Border(left: BorderSide(color: AppColors.border)),
                ),
                padding: const EdgeInsets.all(8),
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
            ),
            // Range
            Expanded(
              flex: 15,
              child: Container(
                decoration: const BoxDecoration(
                  border: Border(left: BorderSide(color: AppColors.border)),
                ),
                padding: const EdgeInsets.all(8),
                child: Text(
                  rangeStr,
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            // Status
            Expanded(
              flex: 9,
              child: Container(
                decoration: const BoxDecoration(
                  border: Border(left: BorderSide(color: AppColors.border)),
                ),
                padding: const EdgeInsets.all(8),
                child: status == null
                    ? const Text('-',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textHint))
                    : Icon(
                        status! ? Icons.check_circle : Icons.cancel,
                        color: status! ? AppColors.success : AppColors.error,
                        size: 18,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helper section card ───────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _SectionCard(
      {required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: AppColors.accent, size: 20),
                ),
                const SizedBox(width: 12),
                Text(title,
                    style: const TextStyle(
                      fontFamily: 'Syne',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    )),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Divider(height: 24),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;
  const _DateField(
      {required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                fontFamily: 'DMSans',
                fontSize: 14,
                fontWeight: FontWeight.w500,
              )),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 16, color: AppColors.textHint),
                const SizedBox(width: 8),
                Text(
                  '${date.day}/${date.month}/${date.year}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
