import 'package:flutter/material.dart';

enum BodyPart {
  head,
  chest,
  bicepsRight,
  bicepsLeft,
  waist,
  hips,
  thighRight,
  thighLeft,
  calves,
  none,
}

class BodyMapWidget extends StatelessWidget {
  final BodyPart selectedPart;
  final ValueChanged<BodyPart> onPartSelected;

  const BodyMapWidget({
    super.key,
    required this.selectedPart,
    required this.onPartSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 400,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Base Silhouette (Simplified abstract shape for Cyberpunk feel)
          CustomPaint(
            size: const Size(300, 400),
            painter: _BodySilhouettePainter(selectedPart: selectedPart),
          ),

          // Touch Targets (Invisible or debug colored)
          // Head
          _buildTarget(top: 20, height: 50, width: 50, part: BodyPart.head),

          // Chest
          _buildTarget(top: 75, height: 60, width: 100, part: BodyPart.chest),

          // Waist/Abdomen
          _buildTarget(top: 140, height: 50, width: 90, part: BodyPart.waist),

          // Hips
          _buildTarget(top: 195, height: 40, width: 100, part: BodyPart.hips),

          // Lefty Bicep (Viewer's Right)
          _buildTarget(
            top: 85,
            left: 180,
            height: 50,
            width: 40,
            part: BodyPart.bicepsLeft,
          ),

          // Right Bicep (Viewer's Left)
          _buildTarget(
            top: 85,
            right: 180,
            height: 50,
            width: 40,
            part: BodyPart.bicepsRight,
          ),

          // Left Thigh (Viewer's Right)
          _buildTarget(
            top: 240,
            left: 160,
            height: 70,
            width: 45,
            part: BodyPart.thighLeft,
          ),

          // Right Thigh (Viewer's Left)
          _buildTarget(
            top: 240,
            right: 160,
            height: 70,
            width: 45,
            part: BodyPart.thighRight,
          ),

          // Calves (Both active for simplicity or split)
          _buildTarget(top: 320, height: 60, width: 100, part: BodyPart.calves),
        ],
      ),
    );
  }

  Widget _buildTarget({
    double? top,
    double? left,
    double? right,
    double? bottom,
    required double height,
    required double width,
    required BodyPart part,
  }) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: GestureDetector(
        onTap: () => onPartSelected(part),
        child: Container(
          height: height,
          width: width,
          color: Colors.transparent, // Debug: Colors.red.withOpacity(0.3)
        ),
      ),
    );
  }
}

class _BodySilhouettePainter extends CustomPainter {
  final BodyPart selectedPart;

  _BodySilhouettePainter({required this.selectedPart});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade800
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final selectedPaint = Paint()
      ..color = Colors
          .greenAccent // Neon Green
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 10);

    final selectedStroke = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final center = size.width / 2;

    // Simplistic Geometric Body
    // Head
    final headRect = Rect.fromCenter(
      center: Offset(center, 45),
      width: 40,
      height: 50,
    );
    _drawPart(
      canvas,
      headRect,
      BodyPart.head,
      paint,
      selectedPaint,
      selectedStroke,
    );

    // Chest
    final chestRect = Rect.fromCenter(
      center: Offset(center, 105),
      width: 90,
      height: 60,
    );
    _drawPart(
      canvas,
      chestRect,
      BodyPart.chest,
      paint,
      selectedPaint,
      selectedStroke,
    );

    // Waist
    final waistRect = Rect.fromCenter(
      center: Offset(center, 165),
      width: 80,
      height: 50,
    );
    _drawPart(
      canvas,
      waistRect,
      BodyPart.waist,
      paint,
      selectedPaint,
      selectedStroke,
    );

    // Hips
    final hipsRect = Rect.fromCenter(
      center: Offset(center, 215),
      width: 90,
      height: 40,
    );
    _drawPart(
      canvas,
      hipsRect,
      BodyPart.hips,
      paint,
      selectedPaint,
      selectedStroke,
    );

    // Arms (Rects)
    final rightArmRect = Rect.fromLTWH(
      center - 85,
      85,
      30,
      60,
    ); // Viewer's Left
    _drawPart(
      canvas,
      rightArmRect,
      BodyPart.bicepsRight,
      paint,
      selectedPaint,
      selectedStroke,
    );

    final leftArmRect = Rect.fromLTWH(
      center + 55,
      85,
      30,
      60,
    ); // Viewer's Right
    _drawPart(
      canvas,
      leftArmRect,
      BodyPart.bicepsLeft,
      paint,
      selectedPaint,
      selectedStroke,
    );

    // Legs
    final rightLegRect = Rect.fromLTWH(center - 50, 240, 40, 70);
    _drawPart(
      canvas,
      rightLegRect,
      BodyPart.thighRight,
      paint,
      selectedPaint,
      selectedStroke,
    );

    final leftLegRect = Rect.fromLTWH(center + 10, 240, 40, 70);
    _drawPart(
      canvas,
      leftLegRect,
      BodyPart.thighLeft,
      paint,
      selectedPaint,
      selectedStroke,
    );

    // Calves
    final calvesRect = Rect.fromLTWH(
      center - 50,
      320,
      100,
      60,
    ); // Merged for visual simplicity or detailed
    _drawPart(
      canvas,
      calvesRect,
      BodyPart.calves,
      paint,
      selectedPaint,
      selectedStroke,
    );
  }

  void _drawPart(
    Canvas canvas,
    Rect rect,
    BodyPart part,
    Paint defaultPaint,
    Paint selectedFill,
    Paint selectedStroke,
  ) {
    if (selectedPart == part) {
      canvas.drawRect(rect, selectedFill);
      canvas.drawRect(rect, selectedStroke);
    } else {
      canvas.drawRect(rect, defaultPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BodySilhouettePainter oldDelegate) {
    return oldDelegate.selectedPart != selectedPart;
  }
}
