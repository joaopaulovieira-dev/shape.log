import 'package:flutter/material.dart';

class BMIGauge extends StatelessWidget {
  final double bmiValue;

  const BMIGauge({super.key, required this.bmiValue});

  @override
  Widget build(BuildContext context) {
    String statusText;
    Color statusColor;

    if (bmiValue < 18.5) {
      statusText = "Abaixo do Peso";
      statusColor = Colors.blue;
    } else if (bmiValue < 24.9) {
      statusText = "Peso Normal";
      statusColor = Colors.green;
    } else if (bmiValue < 29.9) {
      statusText = "Sobrepeso";
      statusColor = Colors.yellow;
    } else if (bmiValue < 34.9) {
      statusText = "Obesidade I";
      statusColor = Colors.orange;
    } else if (bmiValue < 39.9) {
      statusText = "Obesidade II";
      statusColor = Colors.deepOrange;
    } else {
      statusText = "Obesidade III";
      statusColor = Colors.red;
    }

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
          Colors.blue,
          Colors.green,
          Colors.yellow,
          Colors.orange,
          Colors.red,
        ],
        stops: [0.0, 0.25, 0.5, 0.75, 1.0],
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
    // Note: Paint does not have a direct shadows property in Flutter's Paint class wrappers in all context,
    // but usually we use canvas.drawShadow or MaskFilter for shadows on shapes.
    // For simplicity in this gauge, we'll omit the shadow or use MaskFilter.blur for a simple glowing effect if needed,
    // but standard Paint doesn't support list of Shadows directly like BoxDecoration.

    // Let's add a simple shadow using drawCircle with blur before the main circle
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
