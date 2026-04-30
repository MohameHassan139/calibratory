import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../controllers/calibration_controller.dart';

// ── Device definitions ────────────────────────────────────────────────────────

class _DeviceType {
  final String name;
  final IconData icon;
  final Color color;
  const _DeviceType(this.name, this.icon, this.color);
}

const _devices = [
  _DeviceType('ECG Machines', Icons.monitor_heart_outlined, Color(0xFFE53935)),
  _DeviceType('NIBP Monitors', Icons.speed_outlined, Color(0xFF1565C0)),
  _DeviceType('Pulse Oximeters', Icons.bloodtype_outlined, Color(0xFF00897B)),
  _DeviceType('Fetal Monitors', Icons.child_care_outlined, Color(0xFFE91E63)),
  _DeviceType('Infusion Pumps', Icons.water_drop_outlined, Color(0xFF0288D1)),
  _DeviceType('Syringe Pumps', Icons.vaccines_outlined, Color(0xFF7B1FA2)),
  _DeviceType('Manual Defibrillators', Icons.bolt_outlined, Color(0xFFFF6F00)),
  _DeviceType('AEDs', Icons.favorite_outlined, Color(0xFFD32F2F)),
  _DeviceType('Ventilators', Icons.air_outlined, Color(0xFF388E3C)),
  _DeviceType('CPAP / BiPAP', Icons.masks_outlined, Color(0xFF0097A7)),
  _DeviceType('Suction Machines', Icons.cyclone_outlined, Color(0xFF5D4037)),
  _DeviceType('Electrosurgical Units (ESU)', Icons.electric_bolt_outlined, Color(0xFFF57C00)),
  _DeviceType('Oxygen Cylinder', Icons.bubble_chart_outlined, Color(0xFF1976D2)),
  _DeviceType('Electrical Safety', Icons.electrical_services_outlined, Color(0xFF455A64)),
];

// ── Period selector ───────────────────────────────────────────────────────────

enum _Period { month1, months3, months6, months12 }

extension _PeriodExt on _Period {
  String get label {
    switch (this) {
      case _Period.month1:
        return 'This Month';
      case _Period.months3:
        return '3 Months';
      case _Period.months6:
        return '6 Months';
      case _Period.months12:
        return '12 Months';
    }
  }

  int get months {
    switch (this) {
      case _Period.month1:
        return 1;
      case _Period.months3:
        return 3;
      case _Period.months6:
        return 6;
      case _Period.months12:
        return 12;
    }
  }

  DateTime get since {
    final now = DateTime.now();
    if (this == _Period.month1) {
      return DateTime(now.year, now.month, 1);
    }
    return DateTime(now.year, now.month - months + 1, 1);
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class CalibrationStatsScreen extends StatefulWidget {
  const CalibrationStatsScreen({super.key});

  @override
  State<CalibrationStatsScreen> createState() => _CalibrationStatsScreenState();
}

class _CalibrationStatsScreenState extends State<CalibrationStatsScreen> {
  _Period _period = _Period.month1;

  @override
  Widget build(BuildContext context) {
    final calibCtrl = Get.find<CalibrationController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Calibration Statistics'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Get.back(),
        ),
        actions: [
          Obx(() => calibCtrl.isLoading.value
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: calibCtrl.loadHistory,
                )),
          const SizedBox(width: 8),
        ],
      ),
      body: Obx(() {
        final since = _period.since;
        final filtered = calibCtrl.history.where((s) {
          return s.createdAt.isAfter(since);
        }).toList();

        final total = filtered.length;
        final passed = filtered.where((s) => s.overallResult == 'PASS').length;
        final failed = filtered.where((s) => s.overallResult == 'FAIL').length;
        final passRate = total == 0 ? 0.0 : passed / total;

        return RefreshIndicator(
          onRefresh: calibCtrl.loadHistory,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PeriodSelector(
                      selected: _period,
                      onChanged: (p) => setState(() => _period = p),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _SummaryRow(
                        total: total,
                        passed: passed,
                        failed: failed,
                        passRate: passRate,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _PassRateCard(
                        passed: passed,
                        failed: failed,
                        total: total,
                        passRate: passRate,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'By Device Type',
                        style: TextStyle(
                          fontFamily: 'Syne',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.35,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final device = _devices[i];
                      // Match by exact deviceType field
                      final count = filtered
                          .where((s) => s.deviceType == device.name)
                          .length;
                      return _DeviceStatCard(
                        device: device,
                        count: count,
                        total: total,
                      );
                    },
                    childCount: _devices.length,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

// ── Period Selector ───────────────────────────────────────────────────────────

class _PeriodSelector extends StatelessWidget {
  final _Period selected;
  final ValueChanged<_Period> onChanged;
  const _PeriodSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Time Period',
            style: TextStyle(
              fontFamily: 'DMSans',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textHint,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: _Period.values.map((p) {
              final isSelected = p == selected;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(p),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.accent : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      p.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.border),
        ],
      ),
    );
  }
}

// ── Summary Row ───────────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final int total, passed, failed;
  final double passRate;
  const _SummaryRow({
    required this.total,
    required this.passed,
    required this.failed,
    required this.passRate,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SummaryCard(
          label: 'Total',
          value: '$total',
          icon: Icons.science_outlined,
          color: AppColors.accent,
        ),
        const SizedBox(width: 10),
        _SummaryCard(
          label: 'Passed',
          value: '$passed',
          icon: Icons.check_circle_outline_rounded,
          color: AppColors.success,
        ),
        const SizedBox(width: 10),
        _SummaryCard(
          label: 'Failed',
          value: '$failed',
          icon: Icons.cancel_outlined,
          color: AppColors.error,
        ),
        const SizedBox(width: 10),
        _SummaryCard(
          label: 'Pass Rate',
          value: '${(passRate * 100).toStringAsFixed(0)}%',
          icon: Icons.bar_chart_rounded,
          color: const Color(0xFF7C3AED),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Syne',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'DMSans',
                fontSize: 10,
                color: AppColors.textHint,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Pass Rate Card ────────────────────────────────────────────────────────────

class _PassRateCard extends StatelessWidget {
  final int passed, failed, total;
  final double passRate;
  const _PassRateCard({
    required this.passed,
    required this.failed,
    required this.total,
    required this.passRate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Overall Pass Rate',
                style: TextStyle(
                  fontFamily: 'Syne',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${(passRate * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontFamily: 'Syne',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: passRate >= 0.8
                      ? AppColors.success
                      : passRate >= 0.5
                          ? AppColors.warning
                          : AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              children: [
                Container(
                  height: 10,
                  color: AppColors.error.withValues(alpha: 0.15),
                ),
                FractionallySizedBox(
                  widthFactor: passRate,
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.success,
                          AppColors.success.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _LegendDot(color: AppColors.success, label: '$passed Passed'),
              const SizedBox(width: 16),
              _LegendDot(color: AppColors.error, label: '$failed Failed'),
              const Spacer(),
              Text(
                '$total total',
                style: const TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 12,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'DMSans',
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ── Device Stat Card ──────────────────────────────────────────────────────────

class _DeviceStatCard extends StatelessWidget {
  final _DeviceType device;
  final int count;
  final int total;
  const _DeviceStatCard({
    required this.device,
    required this.count,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : count / total;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: device.color.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: device.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(device.icon, color: device.color, size: 18),
              ),
              const Spacer(),
              Text(
                '$count',
                style: TextStyle(
                  fontFamily: 'Syne',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: device.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            device.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'DMSans',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),
          const Spacer(),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 4,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(device.color),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            count == 0
                ? 'No calibrations'
                : '${(ratio * 100).toStringAsFixed(0)}% of total',
            style: const TextStyle(
              fontFamily: 'DMSans',
              fontSize: 9,
              color: AppColors.textHint,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
