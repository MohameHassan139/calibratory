import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class CalibrationStepBar extends StatelessWidget {
  final int totalSteps;
  final int currentStep;
  final List<String> stepLabels;

  const CalibrationStepBar({
    super.key,
    required this.totalSteps,
    required this.currentStep,
    required this.stepLabels,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.surface,
      child: Column(
        children: [
          Row(
            children: List.generate(totalSteps, (i) {
              final isActive = i == currentStep;
              final isDone = i < currentStep;
              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDone || isActive
                              ? AppColors.accent
                              : AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    if (i < totalSteps - 1)
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDone ? AppColors.accent : AppColors.border,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          Text(
            currentStep < stepLabels.length ? stepLabels[currentStep] : '',
            style: const TextStyle(
              fontFamily: 'DMSans',
              fontSize: 12,
              color: AppColors.accent,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
