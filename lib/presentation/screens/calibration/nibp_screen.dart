import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/models.dart';
import '../../controllers/calibration_controller.dart';
import '../../widgets/calibration/calibration_step_bar.dart';
import '../../widgets/calibration/nibp_row_card.dart';

class NIBPScreen extends StatefulWidget {
  const NIBPScreen({super.key});

  @override
  State<NIBPScreen> createState() => _NIBPScreenState();
}

class _NIBPScreenState extends State<NIBPScreen> {
  final CalibrationController _ctrl = Get.find();
  late List<List<TextEditingController>> sysControllers;
  late List<List<TextEditingController>> diaControllers;
  late List<NIBPRow> rows;

  @override
  void initState() {
    super.initState();
    rows = MonitorConstants.nibpSettings
        .map((pair) => NIBPRow(
              systolicSetting: pair[0],
              diastolicSetting: pair[1],
            ))
        .toList();
    sysControllers = List.generate(
        rows.length, (_) => List.generate(3, (_) => TextEditingController()));
    diaControllers = List.generate(
        rows.length, (_) => List.generate(3, (_) => TextEditingController()));
  }

  void _computeAndNext() {
    for (int i = 0; i < rows.length; i++) {
      final sysReads = sysControllers[i]
          .map((c) => double.tryParse(c.text.trim()))
          .whereType<double>()
          .toList();
      final diaReads = diaControllers[i]
          .map((c) => double.tryParse(c.text.trim()))
          .whereType<double>()
          .toList();

      rows[i] = NIBPRow(
        systolicSetting: rows[i].systolicSetting,
        diastolicSetting: rows[i].diastolicSetting,
        systolicReads: sysReads,
        diastolicReads: diaReads,
      );

      if (sysReads.isNotEmpty) {
        final avg = sysReads.reduce((a, b) => a + b) / sysReads.length;
        final range =
            MonitorConstants.nibpAcceptedRange(rows[i].systolicSetting);
        rows[i].systolicStatus = avg >= range[0] && avg <= range[1];
      }
      if (diaReads.isNotEmpty) {
        final avg = diaReads.reduce((a, b) => a + b) / diaReads.length;
        final range =
            MonitorConstants.nibpAcceptedRange(rows[i].diastolicSetting);
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
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: rows.length,
              itemBuilder: (ctx, i) => NibpRowCard(
                systolicSetting: rows[i].systolicSetting,
                diastolicSetting: rows[i].diastolicSetting,
                sysControllers: sysControllers[i],
                diaControllers: diaControllers[i],
                onChanged: () => setState(() {}),
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
