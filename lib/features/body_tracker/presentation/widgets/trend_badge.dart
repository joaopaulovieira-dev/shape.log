import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class TrendBadge extends StatelessWidget {
  final double value;
  final double? previousValue;
  final bool lowerIsBetter;
  final String unit;
  final int precision;

  const TrendBadge({
    super.key,
    required this.value,
    this.previousValue,
    this.lowerIsBetter = false,
    this.unit = "",
    this.precision = 1,
  });

  @override
  Widget build(BuildContext context) {
    if (previousValue == null) {
      return const SizedBox.shrink();
    }

    final diff = value - previousValue!;
    if (diff.abs() < 0.01) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(Icons.remove, size: 12, color: Colors.grey),
      );
    }

    final isGood = lowerIsBetter ? diff < 0 : diff > 0;
    final color = isGood ? AppColors.success : AppColors.error;
    final icon = diff > 0 ? Icons.arrow_upward : Icons.arrow_downward;
    final text =
        "${diff > 0 ? '+' : ''}${diff.toStringAsFixed(precision)}$unit";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 2),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
