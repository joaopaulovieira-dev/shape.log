import 'package:flutter/material.dart';
import '../utils/bmi_utils.dart';

class BMIGauge extends StatelessWidget {
  final double bmiValue;

  const BMIGauge({super.key, required this.bmiValue});

  @override
  Widget build(BuildContext context) {
    final statusText = BMIUtils.getBMIGrade(bmiValue);
    final statusColor = BMIUtils.getBMIColor(bmiValue);

    return Column(
      children: [
        SizedBox(
          height: 30,
          width: double.infinity,
          child: CustomPaint(painter: _BMIGaugePainter(bmiValue)),
        ),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            text: "IMC: ${bmiValue.toStringAsFixed(1)} ",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            children: [
              TextSpan(
                text: "($statusText)",
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BMIGaugePainter extends CustomPainter {
  final double bmiValue;

  _BMIGaugePainter(this.bmiValue);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF00E5FF), // Blue (Underweight)
          Color(0xFF00FF94), // Green (Normal)
          Color(0xFFFFAA00), // Yellow/Orange (Overweight)
          Color(0xFFFF5500), // Dark Orange (Obesity I)
          Color(0xFFFF0055), // Red/Pink (Obesity II)
          Color(0xFFCC0000), // Dark Red (Obesity III)
        ],
        // Range 15 to 40 (Total 25)
        // 18.5 -> 0.14
        // 25.0 -> 0.40
        // 30.0 -> 0.60
        // 35.0 -> 0.80
        stops: [0.0, 0.14, 0.40, 0.60, 0.80, 1.0],
      ).createShader(rect)
      ..style = PaintingStyle.fill;

    // Draw track
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(15));
    canvas.drawRRect(rrect, paint);

    // Calculate indicator position
    // Map BMI range 15-40 to 0-1
    double normalized = (bmiValue - 15) / (40 - 15);
    normalized = normalized.clamp(0.0, 1.0);

    final indicatorX = normalized * size.width;

    // Draw indicator
    final indicatorPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.black45
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawCircle(
      Offset(indicatorX, size.height / 2 + 2),
      size.height / 1.5,
      shadowPaint,
    );

    canvas.drawCircle(
      Offset(indicatorX, size.height / 2),
      size.height / 1.5,
      indicatorPaint,
    );

    // Indicator Border
    final indicatorBorder = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(
      Offset(indicatorX, size.height / 2),
      size.height / 1.5,
      indicatorBorder,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
