import 'package:flutter/material.dart';
import 'dart:math' as math;

class CircularSlider extends StatefulWidget {
  final double sum;
  final List<double> angles;

  CircularSlider({Key? key, required this.sum, required this.angles}) : super(key: key);
  @override
  _CircularSliderState createState() => _CircularSliderState();
}

class _CircularSliderState extends State<CircularSlider> {
  late List<double> angles;
  bool lock = false;

  @override
  void initState() {
    super.initState();

    double factor = widget.sum / (2 * math.pi);

    angles = [];
    double val = 0;
    for (double angle in widget.angles) {
      angles.add(angle/factor + val);
      val = angle/factor + val;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanDown: (value){lock = false;},
      onPanUpdate: lock ? null : _updatePosition,
      child: CustomPaint(
        size: Size(200, 200),
        painter: CircularSliderPainter(angles),
      ),
    );
  }

  void _updatePosition(DragUpdateDetails details) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.globalToLocal(details.globalPosition);
    final center = Offset(renderBox.size.width / 2, renderBox.size.height / 2);
    final angle = (math.atan2(offset.dy - center.dy, offset.dx - center.dx) + 2 * math.pi) % (2 * math.pi);
    setState(() {
      for (int i = 0; i < angles.length; i++) {

        if ((angle - angles[i]).abs() < 0.2 || (angle - angles[i] + 2 * math.pi).abs() < 0.2 || (angle - angles[i] - 2 * math.pi).abs() < 0.2) {
          
          if ((angles[i+1 >= angles.length ? 0 : i+1] - angles[i]).abs() < 0.25 && angle > angles[i]) {
            //lock = true;
            break;
          }

          if ((angles[i] - angles[i-1 < 0 ? angles.length-1 : i-1]).abs() < 0.25 && angle < angles[i]) {
            //lock = true;
            break;
          }

          print(i);
          angles[i] = angle;
          break;
        }
      }
      //if ((angle - angle1).abs() < 0.2) {
      //  angle1 = angle;
      //} else if ((angle - angle2).abs() < 0.2) {
      //  angle2 = angle;
      //} else if ((angle - angle3).abs() < 0.2) {
      //  angle3 = angle;
      //}
    });
  }
}

class CircularSliderPainter extends CustomPainter {
  final List<double> angles;

  CircularSliderPainter(this.angles);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    final radius = size.width / 2;
    final center = Offset(size.width / 2, size.height / 2);

    canvas.drawCircle(center, radius, paint);

    for (double angle in angles) {
      _drawHandle(canvas, center, radius, angle);
    }
  }

  void _drawHandle(Canvas canvas, Offset center, double radius, double angle) {
    final handlePaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    final handleCenter = Offset(center.dx + radius * math.cos(angle), center.dy + radius * math.sin(angle));
    canvas.drawCircle(handleCenter, 10.0, handlePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
