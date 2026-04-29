import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/models.dart';
import '../../controllers/calibration_controller.dart';
import '../../widgets/calibration/calibration_step_bar.dart';

const double _colLabel = 80;
const double _colSet = 64;
const double _colRead = 60;
const double _colAvg = 68;
const double _colRange = 90;
const double _colSta = 56;

class NIBPScreen extends StatefulWidget {
  const NIBPScreen({super.key});

  @override
  State<NIBPScreen> createState() => _NIBPScreenState();
}

class _NIBPScreenState extends State<NIBPScreen> {
  final CalibrationController _ctrl = Get.find();

  late List<NIBPRow> rows;
  late List<TextEditingController> sysSetCtrl;
  late List<TextEditingController> diaSetCtrl;
  late List<List<TextEditingController>> sysCtrl;
  late List<List<TextEditingController>> diaCtrl;
  late List<bool> sysErrors;
  late List<bool> diaErrors;
  late List<double?> sysAvg;
  late List<double?> diaAvg;
  late List<bool?> sysSta;
  late List<bool?> diaSta;

  @override
  void initState() {
    super.initState();
    rows = MonitorConstants.nibpSettings
        .map((p) => NIBPRow(systolicSetting: p[0], diastolicSetting: p[1]))
        .toList();
    sysSetCtrl = rows
        .map((r) =>
            TextEditingController(text: r.systolicSetting.toStringAsFixed(0)))
        .toList();
    diaSetCtrl = rows
        .map((r) =>
            TextEditingController(text: r.diastolicSetting.toStringAsFixed(0)))
        .toList();
    sysCtrl = List.generate(
        rows.length, (_) => List.generate(5, (_) => TextEditingController()));
    diaCtrl = List.generate(
        rows.length, (_) => List.generate(5, (_) => TextEditingController()));
    sysErrors = List.filled(rows.length, false);
    diaErrors = List.filled(rows.length, false);
    sysAvg = List.filled(rows.length, null);
    diaAvg = List.filled(rows.length, null);
    sysSta = List.filled(rows.length, null);
    diaSta = List.filled(rows.length, null);
  }

  @override
  void dispose() {
    for (final c in sysSetCtrl) c.dispose();
    for (final c in diaSetCtrl) c.dispose();
    for (final row in sysCtrl) {
      for (final c in row) c.dispose();
    }
    for (final row in diaCtrl) {
      for (final c in row) c.dispose();
    }
    super.dispose();
  }

  void _onChanged(int i) {
    setState(() {
      final sv = double.tryParse(sysSetCtrl[i].text.trim()) ??
          rows[i].systolicSetting;
      final dv = double.tryParse(diaSetCtrl[i].text.trim()) ??
          rows[i].diastolicSetting;
      final sr = sysCtrl[i]
          .map((c) => double.tryParse(c.text.trim()))
          .whereType<double>()
          .toList();
      final dr = diaCtrl[i]
          .map((c) => double.tryParse(c.text.trim()))
          .whereType<double>()
          .toList();
      sysErrors[i] = sr.length < 3;
      diaErrors[i] = dr.length < 3;
      if (sr.length >= 3) {
        final avg = sr.reduce((a, b) => a + b) / sr.length;
        sysAvg[i] = avg;
        final range = MonitorConstants.nibpAcceptedRange(sv);
        sysSta[i] = avg >= range[0] && avg <= range[1];
      } else {
        sysAvg[i] = null;
        sysSta[i] = null;
      }
      if (dr.length >= 3) {
        final avg = dr.reduce((a, b) => a + b) / dr.length;
        diaAvg[i] = avg;
        final range = MonitorConstants.nibpAcceptedRange(dv);
        diaSta[i] = avg >= range[0] && avg <= range[1];
      } else {
        diaAvg[i] = null;
        diaSta[i] = null;
      }
    });
  }

  void _computeAndNext() {
    bool hasError = false;
    for (int i = 0; i < rows.length; i++) {
      final sr = sysCtrl[i]
          .map((c) => double.tryParse(c.text.trim()))
          .whereType<double>()
          .toList();
      final dr = diaCtrl[i]
          .map((c) => double.tryParse(c.text.trim()))
          .whereType<double>()
          .toList();
      sysErrors[i] = sr.length < 3;
      diaErrors[i] = dr.length < 3;
      if (sysErrors[i] || diaErrors[i]) hasError = true;
    }
    if (hasError) {
      setState(() {});
      Get.snackbar(
        'Incomplete Data',
        'Every row needs at least 3 readings for both Systolic and Diastolic.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    for (int i = 0; i < rows.length; i++) {
      final sv = double.tryParse(sysSetCtrl[i].text.trim()) ??
          rows[i].systolicSetting;
      final dv = double.tryParse(diaSetCtrl[i].text.trim()) ??
          rows[i].diastolicSetting;
      final sr = sysCtrl[i]
          .map((c) => double.tryParse(c.text.trim()))
          .whereType<double>()
          .toList();
      final dr = diaCtrl[i]
          .map((c) => double.tryParse(c.text.trim()))
          .whereType<double>()
          .toList();
      rows[i] = NIBPRow(
        systolicSetting: sv,
        diastolicSetting: dv,
        systolicReads: sr,
        diastolicReads: dr,
      );
      if (sr.isNotEmpty) {
        final avg = sr.reduce((a, b) => a + b) / sr.length;
        final range = MonitorConstants.nibpAcceptedRange(sv);
        rows[i].systolicStatus = avg >= range[0] && avg <= range[1];
      }
      if (dr.isNotEmpty) {
        final avg = dr.reduce((a, b) => a + b) / dr.length;
        final range = MonitorConstants.nibpAcceptedRange(dv);
        rows[i].diastolicStatus = avg >= range[0] && avg <= range[1];
      }
    }

    _ctrl.updateNibpRows(rows);
    final s = _ctrl.session.value!;
    if (s.showRespirationTable) {
      Get.toNamed(AppRoutes.calibrationRespiration);
    } else if (s.showTempTables) {
      Get.toNamed(AppRoutes.calibrationTemp);
    } else {
      Get.toNamed(AppRoutes.calibrationSummary);
    }
  }

  Widget _headerCell(String text, double width) => SizedBox(
        width: width,
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

  Widget _inputCell({
    required double width,
    required TextEditingController controller,
    required String hintText,
    required TextStyle style,
    required TextStyle hintStyle,
    bool leftBorder = true,
    Color? bg,
    VoidCallback? onChanged,
  }) =>
      Container(
        width: width,
        height: double.infinity,
        decoration: BoxDecoration(
          color: bg,
          border: Border(
            left: leftBorder
                ? const BorderSide(color: AppColors.border)
                : BorderSide.none,
          ),
        ),
        child: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.center,
          textAlignVertical: TextAlignVertical.center,
          expands: true,
          maxLines: null,
          style: style,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: hintText,
            hintStyle: hintStyle,
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            isCollapsed: true,
          ),
          onChanged: onChanged != null ? (_) => onChanged() : null,
        ),
      );

  Widget _cell({
    required double width,
    required Widget child,
    bool leftBorder = true,
    Color? bg,
  }) =>
      Container(
        width: width,
        height: double.infinity,
        decoration: BoxDecoration(
          color: bg,
          border: Border(
            left: leftBorder
                ? const BorderSide(color: AppColors.border)
                : BorderSide.none,
          ),
        ),
        alignment: Alignment.center,
        child: child,
      );

  Widget _buildRow(int i, bool isSystolic) {
    final label = isSystolic ? 'Systolic' : 'Diastolic';
    final setCtrl = isSystolic ? sysSetCtrl[i] : diaSetCtrl[i];
    final hint =
        isSystolic ? rows[i].systolicSetting : rows[i].diastolicSetting;
    final readCtrls = isSystolic ? sysCtrl[i] : diaCtrl[i];
    final avg = isSystolic ? sysAvg[i] : diaAvg[i];
    final sta = isSystolic ? sysSta[i] : diaSta[i];
    final hasErr = isSystolic ? sysErrors[i] : diaErrors[i];
    final effectiveSetting = double.tryParse(setCtrl.text.trim()) ?? hint;
    final range = MonitorConstants.nibpAcceptedRange(effectiveSetting);
    final rangeStr =
        '${range[0].toStringAsFixed(1)}-${range[1].toStringAsFixed(1)}';
    final isLast = !isSystolic && i == rows.length - 1;

    return Container(
      height: 52,
      decoration: BoxDecoration(
        border: Border(
          bottom: isLast
              ? BorderSide.none
              : const BorderSide(color: AppColors.border),
          left: hasErr
              ? const BorderSide(color: AppColors.error, width: 3)
              : BorderSide.none,
        ),
      ),
      child: Row(
        children: [
          // Label
          _cell(
            width: _colLabel,
            leftBorder: false,
            bg: isSystolic
                ? AppColors.accent.withValues(alpha: 0.08)
                : AppColors.surfaceVariant,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color:
                    isSystolic ? AppColors.accent : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Setting value — label on top, input fills remaining height
          Container(
            width: _colSet,
            height: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.surfaceVariant,
              border: Border(left: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    isSystolic ? 'Sys' : 'Dia',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: isSystolic ? AppColors.accent : AppColors.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: setCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    textAlignVertical: TextAlignVertical.center,
                    expands: true,
                    maxLines: null,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: hint.toStringAsFixed(0),
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textHint,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      isCollapsed: true,
                    ),
                    onChanged: (_) => _onChanged(i),
                  ),
                ),
              ],
            ),
          ),
          // 5 read fields
          ...List.generate(
            5,
            (j) => _inputCell(
              width: _colRead,
              controller: readCtrls[j],
              hintText: j < 3 ? '*' : '-',
              style: TextStyle(
                fontSize: 13,
                color: j < 3 ? AppColors.textPrimary : AppColors.textSecondary,
              ),
              hintStyle: TextStyle(
                fontSize: 13,
                color: j < 3
                    ? AppColors.accent.withValues(alpha: 0.4)
                    : AppColors.textHint,
              ),
              onChanged: () => _onChanged(i),
            ),
          ),
          // Average
          _cell(
            width: _colAvg,
            child: Text(
              avg != null ? avg.toStringAsFixed(2) : '-',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Range
          _cell(
            width: _colRange,
            child: Text(
              rangeStr,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
          // Status
          _cell(
            width: _colSta,
            child: hasErr
                ? const Icon(Icons.warning_amber_rounded,
                    color: AppColors.error, size: 18)
                : sta == null
                    ? const Text('-',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textHint))
                    : Icon(
                        sta ? Icons.check_circle : Icons.cancel,
                        color: sta ? AppColors.success : AppColors.error,
                        size: 18,
                      ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isVisible = _ctrl.session.value?.showNibpTable ?? false;
    if (!isVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _ctrl.updateNibpRows([]);
        final s = _ctrl.session.value!;
        if (s.showRespirationTable) {
          Get.toNamed(AppRoutes.calibrationRespiration);
        } else if (s.showTempTables) {
          Get.toNamed(AppRoutes.calibrationTemp);
        } else {
          Get.toNamed(AppRoutes.calibrationSummary);
        }
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('NIBP Measurement'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(40),
          child: CalibrationStepBar(
            totalSteps: 7,
            currentStep: 4,
            stepLabels: [
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
                                color: AppColors.accent
                                    .withValues(alpha: 0.9)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
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
                                  vertical: 12, horizontal: 0),
                              color: AppColors.primary,
                              child: Row(
                                children: [
                                  _headerCell('Type', _colLabel),
                                  _headerCell('Set\n(mmHg)', _colSet),
                                  _headerCell('Read 1', _colRead),
                                  _headerCell('Read 2', _colRead),
                                  _headerCell('Read 3', _colRead),
                                  _headerCell('Read 4', _colRead),
                                  _headerCell('Read 5', _colRead),
                                  _headerCell('Avg', _colAvg),
                                  _headerCell('Range', _colRange),
                                  _headerCell('Status', _colSta),
                                ],
                              ),
                            ),
                            // Rows: sys + dia per pair
                            ...List.generate(
                              rows.length,
                              (i) => Column(
                                children: [
                                  _buildRow(i, true),
                                  _buildRow(i, false),
                                ],
                              ),
                            ),
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
                onPressed: _computeAndNext,
                child: const Text('Next'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
