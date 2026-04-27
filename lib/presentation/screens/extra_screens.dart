// lib/presentation/screens/calibration/nibp_screen.dart
import 'package:caliborty/presentation/controllers/auth_controller.dart';
import 'package:caliborty/presentation/widgets/shared_widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/models.dart';

// Missing import
import 'package:flutter/material.dart';

import '../controllers/calibration_controller.dart';

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
              'Temperature'
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
              itemBuilder: (ctx, i) => _NIBPRowCard(
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

class _NIBPRowCard extends StatelessWidget {
  final double systolicSetting;
  final double diastolicSetting;
  final List<TextEditingController> sysControllers;
  final List<TextEditingController> diaControllers;
  final VoidCallback onChanged;

  const _NIBPRowCard({
    required this.systolicSetting,
    required this.diastolicSetting,
    required this.sysControllers,
    required this.diaControllers,
    required this.onChanged,
  });

  Widget _input(TextEditingController ctrl, VoidCallback onChange) => SizedBox(
        width: 64,
        child: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: '-',
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onChanged: (_) => onChange(),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final sysRange = MonitorConstants.nibpAcceptedRange(systolicSetting);
    final diaRange = MonitorConstants.nibpAcceptedRange(diastolicSetting);

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
          Text(
            'Systolic: ${systolicSetting.toStringAsFixed(0)} / Diastolic: ${diastolicSetting.toStringAsFixed(0)} mmHg',
            style: const TextStyle(
              fontFamily: 'Syne',
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Sys: ',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ...sysControllers.map((c) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _input(c, onChanged),
                  )),
              const Spacer(),
              Text(
                '${sysRange[0].toStringAsFixed(1)}-${sysRange[1].toStringAsFixed(1)}',
                style: const TextStyle(fontSize: 10, color: AppColors.textHint),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Dia: ',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ...diaControllers.map((c) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _input(c, onChanged),
                  )),
              const Spacer(),
              Text(
                '${diaRange[0].toStringAsFixed(1)}-${diaRange[1].toStringAsFixed(1)}',
                style: const TextStyle(fontSize: 10, color: AppColors.textHint),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Calibration Summary / Completion Screen ───────────────────────────────────

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
    if (session == null)
      return const Scaffold(body: Center(child: Text('No session')));

    // Check if already completed (navigating to existing summary)
    if (session.id != null) return _CompletedView(session: session);

    return Scaffold(
      appBar: const CupertinoNavigationBar(title: 'Review & Complete'),
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
                  const Text('Session Summary',
                      style: TextStyle(
                          fontFamily: 'Syne',
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                  const Divider(height: 24),
                  _SummaryRow('Customer', session.customerName),
                  _SummaryRow('Serial No.', session.serialNumber),
                  _SummaryRow('Model', session.model),
                  _SummaryRow('Manufacturer', session.manufacturer),
                  _SummaryRow('Department', session.department),
                  const Divider(height: 16),
                  _SummaryRow(
                      'HR Table', session.showHrTable ? '✓ Included' : '✗ NF'),
                  _SummaryRow('SPO2 Table',
                      session.showSpo2Table ? '✓ Included' : '✗ NF'),
                  _SummaryRow('NIBP Table',
                      session.showNibpTable ? '✓ Included' : '✗ NF'),
                  _SummaryRow('Respiration Table',
                      session.showRespirationTable ? '✓ Included' : '✗ NF'),
                  _SummaryRow('Temp Tables',
                      session.showTempTables ? '✓ Included' : '✗ NF'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Notes
            CustomTextField(
              label: 'Notes',
              hint: 'Add any additional notes...',
              controller: _notesCtrl,
              maxLines: 4,
            ),

            const SizedBox(height: 16),

            // Email for sending certificate
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
                      onPressed: () {
                        _ctrl.completeCalibration(
                            notes: _notesCtrl.text.trim());
                      },
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryRow(this.label, this.value);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary))),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}

class _CompletedView extends StatelessWidget {
  final dynamic session;
  const _CompletedView({required this.session});

  @override
  Widget build(BuildContext context) {
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
                color: (session.overallResult == true
                        ? AppColors.success
                        : AppColors.error)
                    .withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                session.overallResult == true
                    ? Icons.verified_rounded
                    : Icons.cancel_rounded,
                size: 50,
                color: session.overallResult == true
                    ? AppColors.success
                    : AppColors.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              session.overallResult == true ? 'PASSED' : 'FAILED',
              style: TextStyle(
                fontFamily: 'Syne',
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: session.overallResult == true
                    ? AppColors.success
                    : AppColors.error,
              ),
            ),
            const SizedBox(height: 8),
            const Text('Calibration complete. Certificate generated.',
                style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 32),
            if (session.certificateUrl != null)
              ElevatedButton.icon(
                icon: const Icon(Icons.download_rounded),
                label: const Text('Download Certificate'),
                onPressed: () {
                  // Open URL in browser
                },
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

// Placeholder for CupertinoNavigationBar - use AppBar instead
class CupertinoNavigationBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  const CupertinoNavigationBar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return AppBar(title: Text(title));
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// ── Price Offer Screen ────────────────────────────────────────────────────────

class PriceOfferScreen extends StatefulWidget {
  const PriceOfferScreen({super.key});
  @override
  State<PriceOfferScreen> createState() => _PriceOfferScreenState();
}

class _PriceOfferScreenState extends State<PriceOfferScreen> {
  final Map<String, double> prices = {};
  final Map<String, int> quantities = {};
  final Map<String, bool> electricCheck = {};
  final Map<String, bool> functionCheck = {};
  final _clientNameCtrl = TextEditingController();
  final _clientEmailCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    for (var device in MonitorConstants.deviceTypes) {
      prices[device] = 0;
      quantities[device] = 0;
      electricCheck[device] = false;
      functionCheck[device] = false;
    }
  }

  double get total => MonitorConstants.deviceTypes
      .fold(0, (sum, d) => sum + (prices[d]! * quantities[d]!));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Price Offer'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Client info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        CustomTextField(
                          label: 'Client Name',
                          hint: 'Hospital / Clinic name',
                          controller: _clientNameCtrl,
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          label: 'Client Email',
                          hint: 'client@hospital.com',
                          controller: _clientEmailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icons.email_outlined,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Device cards
                  ...MonitorConstants.deviceTypes.map((device) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _DeviceCard(
                          device: device,
                          price: prices[device]!,
                          qty: quantities[device]!,
                          electric: electricCheck[device]!,
                          function: functionCheck[device]!,
                          onPriceChanged: (v) =>
                              setState(() => prices[device] = v),
                          onQtyChanged: (v) =>
                              setState(() => quantities[device] = v),
                          onElectricChanged: (v) =>
                              setState(() => electricCheck[device] = v),
                          onFunctionChanged: (v) =>
                              setState(() => functionCheck[device] = v),
                        ),
                      )),
                ],
              ),
            ),
          ),

          // Total bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Text('Total Value',
                        style: TextStyle(
                            fontFamily: 'DMSans',
                            fontSize: 16,
                            color: AppColors.textSecondary)),
                    const Spacer(),
                    Text(
                      '\$${total.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontFamily: 'Syne',
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() {
                          for (var d in MonitorConstants.deviceTypes) {
                            prices[d] = 0;
                            quantities[d] = 0;
                            electricCheck[d] = false;
                            functionCheck[d] = false;
                          }
                        }),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.border),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Reset',
                            style: TextStyle(color: AppColors.textPrimary)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.save_outlined, size: 18),
                        label: const Text('Save to History'),
                        onPressed: () {
                          // Save logic - send email to client
                          _sendOffer();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendOffer() {
    if (_clientEmailCtrl.text.contains('@')) {
      Get.snackbar('Offer Sent!',
          'Price offer has been sent to ${_clientEmailCtrl.text}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: Colors.white);
    }
  }
}

class _DeviceCard extends StatelessWidget {
  final String device;
  final double price;
  final int qty;
  final bool electric;
  final bool function;
  final ValueChanged<double> onPriceChanged;
  final ValueChanged<int> onQtyChanged;
  final ValueChanged<bool> onElectricChanged;
  final ValueChanged<bool> onFunctionChanged;

  const _DeviceCard({
    required this.device,
    required this.price,
    required this.qty,
    required this.electric,
    required this.function,
    required this.onPriceChanged,
    required this.onQtyChanged,
    required this.onElectricChanged,
    required this.onFunctionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final subtotal = price * qty;
    return Container(
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
                child: Text(device,
                    style: const TextStyle(
                        fontFamily: 'Syne',
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
              ),
              Text(
                'SUBTOTAL: \$${subtotal.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('PRICE (\$)',
                        style: TextStyle(
                            fontSize: 10, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    TextField(
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        hintText: '0',
                      ),
                      onChanged: (v) => onPriceChanged(double.tryParse(v) ?? 0),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('QTY',
                        style: TextStyle(
                            fontSize: 10, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    TextField(
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        hintText: '0',
                      ),
                      onChanged: (v) => onQtyChanged(int.tryParse(v) ?? 0),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _CheckRow(
                label: 'Electric Check',
                value: electric,
                onChanged: onElectricChanged,
              ),
              const SizedBox(width: 16),
              _CheckRow(
                label: 'Function Check',
                value: function,
                onChanged: onFunctionChanged,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _CheckRow(
      {required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: value ? AppColors.accent : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: value ? AppColors.accent : AppColors.border,
                width: 2,
              ),
            ),
            child: value
                ? const Icon(Icons.check, size: 12, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

// ── History Screen ────────────────────────────────────────────────────────────

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
          itemBuilder: (ctx, i) {
            final s = ctrl.history[i];
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
                            s.customerName.isEmpty ? 'Unknown' : s.customerName,
                            style: const TextStyle(
                                fontFamily: 'Syne',
                                fontWeight: FontWeight.w700,
                                fontSize: 15)),
                      ),
                      if (s.overallResult != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: (s.overallResult == true
                                    ? AppColors.success
                                    : AppColors.error)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            s.overallResult == true ? 'PASS' : 'FAIL',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: s.overallResult == true
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                      '${s.manufacturer} · ${s.model} · S/N: ${s.serialNumber}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text(
                      '${s.visitDate.day}/${s.visitDate.month}/${s.visitDate.year} · ${s.department}',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textHint)),
                  if (s.certificateUrl != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.download_rounded, size: 14),
                          label: const Text('Certificate',
                              style: TextStyle(fontSize: 12)),
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
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
                          label: const Text('Send Email',
                              style: TextStyle(fontSize: 12)),
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
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
          },
        );
      }),
    );
  }
}

// ── Profile Screen ────────────────────────────────────────────────────────────

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final calibCtrl = Get.find<CalibrationController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar
            Obx(() => Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundColor: AppColors.accent.withOpacity(0.1),
                          backgroundImage: auth.appUser.value?.photoUrl != null
                              ? NetworkImage(auth.appUser.value!.photoUrl!)
                              : null,
                          child: auth.appUser.value?.photoUrl == null
                              ? Text(
                                  auth.appUser.value?.fullName
                                          .substring(0, 1)
                                          .toUpperCase() ??
                                      'U',
                                  style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.accent,
                                  ),
                                )
                              : null,
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.edit_rounded,
                              size: 14, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      auth.appUser.value?.fullName ?? 'Engineer',
                      style: const TextStyle(
                        fontFamily: 'Syne',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      auth.appUser.value?.email ?? '',
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('UMECC · Calibration Engineer',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                )),

            const SizedBox(height: 28),

            // Stats
            Obx(() => Row(
                  children: [
                    _ProfileStat(
                        value: calibCtrl.history.length.toString(),
                        label: 'Calibrations'),
                    _Divider(),
                    _ProfileStat(
                        value: calibCtrl.history
                            .where((h) => h.overallResult == true)
                            .length
                            .toString(),
                        label: 'Passed'),
                    _Divider(),
                    _ProfileStat(
                        value: calibCtrl.history
                            .where((h) => h.overallResult == false)
                            .length
                            .toString(),
                        label: 'Failed'),
                  ],
                )),

            const SizedBox(height: 24),

            // Settings items
            _SettingsGroup(
              title: 'Account',
              items: [
                _SettingsItem(
                  icon: Icons.person_outline,
                  label: 'Edit Profile',
                  onTap: () {},
                ),
                _SettingsItem(
                  icon: Icons.phone_outlined,
                  label: 'Phone Number',
                  onTap: () {},
                  trailing: Text(
                    auth.appUser.value?.phone ?? '',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            _SettingsGroup(
              title: 'Calibration',
              items: [
                _SettingsItem(
                  icon: Icons.download_rounded,
                  label: 'Download All Certificates',
                  onTap: () {},
                ),
                _SettingsItem(
                  icon: Icons.share_outlined,
                  label: 'Share Report',
                  onTap: () {},
                ),
              ],
            ),

            const SizedBox(height: 12),

            _SettingsGroup(
              title: 'App',
              items: [
                _SettingsItem(
                  icon: Icons.info_outline,
                  label: 'About Caliborty',
                  onTap: () {},
                ),
                _SettingsItem(
                  icon: Icons.logout_rounded,
                  label: 'Sign Out',
                  isDestructive: true,
                  onTap: () => Get.find<AuthController>().logout(),
                ),
              ],
            ),

            const SizedBox(height: 32),
            const Text(
              'Caliborty v1.0.0 · UMECC · Minia University',
              style: TextStyle(fontSize: 11, color: AppColors.textHint),
            ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(height: 40, width: 1, color: AppColors.border);
  }
}

class _ProfileStat extends StatelessWidget {
  final String value;
  final String label;
  const _ProfileStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontFamily: 'Syne',
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<_SettingsItem> items;
  const _SettingsGroup({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 4),
          child: Text(title,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textHint)),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(children: items),
        ),
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;
  final Widget? trailing;

  const _SettingsItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.error : AppColors.textPrimary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 14),
            Expanded(
                child: Text(label,
                    style: TextStyle(
                        fontSize: 14,
                        color: color,
                        fontWeight: FontWeight.w500))),
            trailing ??
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textHint, size: 20),
          ],
        ),
      ),
    );
  }
}

class CustomTextField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool obscureText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final int maxLines;

  const CustomTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
              fontFamily: 'DMSans',
              fontSize: 14,
              fontWeight: FontWeight.w500,
            )),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          maxLines: obscureText ? 1 : maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: AppColors.textHint, size: 20)
                : null,
            suffix: suffixIcon,
          ),
        ),
      ],
    );
  }
}
