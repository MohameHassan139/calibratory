import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class NibpRowCard extends StatelessWidget {
  final double systolicSetting;
  final double diastolicSetting;
  final List<TextEditingController> sysControllers;
  final List<TextEditingController> diaControllers;
  final VoidCallback onChanged;

  const NibpRowCard({
    super.key,
    required this.systolicSetting,
    required this.diastolicSetting,
    required this.sysControllers,
    required this.diaControllers,
    required this.onChanged,
  });

  Widget _input(TextEditingController ctrl) => SizedBox(
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
          onChanged: (_) => onChanged(),
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
                    child: _input(c),
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
                    child: _input(c),
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
