import 'package:flutter/material.dart';

class ScannerAnimationWidget extends StatefulWidget {
  final bool isScanning;
  final Color scannerColor;

  const ScannerAnimationWidget({
    super.key,
    this.isScanning = true,
    this.scannerColor = Colors.cyanAccent,
  });

  @override
  State<ScannerAnimationWidget> createState() => _ScannerAnimationWidgetState();
}

class _ScannerAnimationWidgetState extends State<ScannerAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isScanning) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _ScannerPainter(
            animationValue: _controller.value,
            color: widget.scannerColor,
          ),
          child: Container(),
        );
      },
    );
  }
}

class _ScannerPainter extends CustomPainter {
  final double animationValue;
  final Color color;

  _ScannerPainter({required this.animationValue, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // Calculate the position of the scanner line
    final double scanLineY = size.height * animationValue;

    // Draw the gradient trail behind the scan line
    final shader =
        LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            color.withValues(alpha: 0.1),
            color.withValues(alpha: 0.4),
          ],
          stops: const [0.0, 0.8, 1.0],
        ).createShader(
          Rect.fromLTWH(0, scanLineY - 100, size.width, 100),
        ); // Trail length

    paint.shader = shader;

    // Draw the trail
    if (scanLineY > 0) {
      canvas.drawRect(
        Rect.fromLTWH(0, scanLineY - 100, size.width, 100),
        paint,
      );
    }

    // Draw the main laser line
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3); // Glow

    canvas.drawLine(
      Offset(0, scanLineY),
      Offset(size.width, scanLineY),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScannerPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
