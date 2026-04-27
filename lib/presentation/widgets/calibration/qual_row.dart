import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/models.dart';

class QualRow extends StatelessWidget {
  final String item;
  final ItemStatus value;
  final ValueChanged<ItemStatus> onChanged;

  const QualRow({
    super.key,
    required this.item,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          StatusToggle(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class StatusToggle extends StatelessWidget {
  final ItemStatus value;
  final ValueChanged<ItemStatus> onChanged;

  const StatusToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: ItemStatus.values.map((s) {
        final isSelected = s == value;
        final Color color;
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
              color: isSelected
                  ? color.withValues(alpha: 0.15)
                  : Colors.transparent,
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
