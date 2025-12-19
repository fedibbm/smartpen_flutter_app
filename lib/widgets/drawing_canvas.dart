import 'package:flutter/material.dart';
import '../models/smart_pen_models.dart' as models;

class DrawingCanvas extends StatelessWidget {
  final List<models.PenStroke> strokes;
  final VoidCallback? onClear;

  const DrawingCanvas({
    Key? key,
    required this.strokes,
    this.onClear,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300, width: 2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          CustomPaint(
            painter: StrokePainter(strokes),
            size: Size.infinite,
          ),
          if (strokes.isEmpty)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.draw,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Connect a smart pen to start drawing',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          if (onClear != null && strokes.isNotEmpty)
            Positioned(
              top: 16,
              right: 16,
              child: FloatingActionButton.small(
                onPressed: onClear,
                backgroundColor: Colors.red.shade400,
                child: const Icon(Icons.clear, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

class StrokePainter extends CustomPainter {
  final List<models.PenStroke> strokes;

  StrokePainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      if (stroke.points.length > 1) {
        final path = Path();
        path.moveTo(stroke.points.first.dx, stroke.points.first.dy);
        
        for (int i = 1; i < stroke.points.length; i++) {
          path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
        }
        
        canvas.drawPath(path, paint);
      } else if (stroke.points.isNotEmpty) {
        // Draw a single point
        canvas.drawCircle(
          Offset(stroke.points.first.dx, stroke.points.first.dy),
          stroke.strokeWidth / 2,
          paint..style = PaintingStyle.fill,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
