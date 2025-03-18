import 'package:flutter/material.dart';
import '../../models/pain_location.dart';

class PainMarkerPainter extends CustomPainter {
  final List<PainLocation> painLocations;
  final Size modelSize;

  PainMarkerPainter(this.painLocations, this.modelSize);

  Color _getSeverityColor(double severity) {
    if (severity < 3) return Colors.yellow;
    if (severity < 7) return Colors.orange;
    return Colors.red;
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (var pain in painLocations) {
      // Convert 3D coordinates to 2D screen space
      double screenX = (pain.x + 1) * size.width / 2;
      double screenY = (-pain.y + 1) * size.height / 2;

      // Draw marker
      final paint = Paint()
        ..color = _getSeverityColor(pain.severity).withOpacity(0.7)
        ..style = PaintingStyle.fill;

      // Draw outer circle
      canvas.drawCircle(
        Offset(screenX, screenY),
        15,
        paint,
      );

      // Draw severity text
      final textPainter = TextPainter(
        text: TextSpan(
          text: pain.severity.round().toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          screenX - textPainter.width / 2,
          screenY - textPainter.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(PainMarkerPainter oldDelegate) => true;
}
