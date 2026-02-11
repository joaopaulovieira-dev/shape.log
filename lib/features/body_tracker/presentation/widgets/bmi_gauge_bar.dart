import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class BmiGaugeBar extends StatelessWidget {
  final double bmi;

  const BmiGaugeBar({super.key, required this.bmi});

  @override
  Widget build(BuildContext context) {
    // Normalized for bar (approx range 15-40)
    final progress = ((bmi - 15) / (40 - 15)).clamp(0.0, 1.0);

    return Column(
      children: [
        SizedBox(
          height: 12,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final markerPosition = progress * width;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Gradient Bar
                  Container(
                    width: double.infinity,
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF00E5FF), // Blue (Underweight)
                          Color(0xFF00FF94), // Green (Normal)
                          Color(0xFFFFAA00), // Yellow/Orange (Overweight)
                          Color(0xFFFF5500), // Dark Orange (Obesity I)
                          Color(0xFFFF0055), // Red/Pink (Obesity II)
                          Color(0xFFCC0000), // Dark Red (Obesity III)
                        ],
                        // Range 15 to 40 (Total 25)
                        stops: [0.0, 0.14, 0.40, 0.60, 0.80, 1.0],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),

                  // Glow Pointer
                  Positioned(
                    left: (markerPosition - 6).clamp(0.0, width - 12),
                    top: -4,
                    child: Container(
                      width: 12,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.8),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 2,
                          height: 10,
                          color: AppColors.background,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
