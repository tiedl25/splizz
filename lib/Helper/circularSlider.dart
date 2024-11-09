import 'package:flutter/material.dart';
import 'dart:math' as math;

class CircularSlider extends StatefulWidget {
  final double sum;
  final List<double> angles;
  final List<Color> colors;

  CircularSlider({Key? key, required this.sum, required this.angles, required this.colors}) : super(key: key);
  @override
  _CircularSliderState createState() => _CircularSliderState();
}

class _CircularSliderState extends State<CircularSlider> {
  late List<double> angles;
  bool lock = false;

  @override
  void initState() {
    super.initState();

    if (widget.sum == 0.0) {
      lock = true;
    }

    double factor = lock ? widget.angles.length.toDouble() : widget.sum / (2 * math.pi);
    print(factor);
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
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          //color: Colors.black
        ),
        padding: EdgeInsets.all(20),
          child: CustomPaint(
          size: Size(200, 200),
          painter: CircularSliderPainter(angles, widget.colors, widget.sum, this.lock),
        ),
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
  final List<Color> colors;
  final double sum;
  bool lock;

  CircularSliderPainter(this.angles, this.colors, this.sum, this.lock);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    final radius = size.width / 2;
    final center = Offset(size.width / 2, size.height / 2);

    canvas.drawCircle(center, radius, paint);

    // Draw segments between handles
    final segmentPaint = Paint()
      ..color = Colors.grey
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0;

    for (int i = 0; i < angles.length; i++) {
      final startAngle = angles[i];
      final endAngle = angles[(i + 1) % angles.length];
      final path = Path();
      path.arcTo(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        (endAngle - startAngle) % (2 * math.pi),
        false,
      );
      segmentPaint.color = Color.alphaBlend(this.lock ? Color.fromARGB(136, 97, 97, 97) : Color.fromARGB(0, 255, 255, 255), colors[i]);
      canvas.drawPath(path, segmentPaint);
    }

    for (double angle in angles) {
      _drawHandle(canvas, center, radius, angle);
    }

    if (this.lock) return;

    for (int i = 0; i < angles.length; i++) {
      double ang = i == angles.length - 1 ? angles[0]: angles[i+1];
      double pos2 = angles[i] > ang ? ang + 2*math.pi : ang;
      double labelPos = (angles[i] + pos2) / 2;

      double pathLength = (angles[i] - pos2).abs();
      _drawLabel(canvas, center, radius, labelPos > 2*math.pi ? labelPos - 2*math.pi : labelPos, pathLength);
    }
  }

  void _drawHandle(Canvas canvas, Offset center, double radius, double angle) {
    final handlePaint = Paint()
      ..color = Colors.grey
      ..style = PaintingStyle.fill;

    final handleCenter = Offset(
      center.dx + radius * math.cos(angle),
      center.dy + radius * math.sin(angle),
    );
    canvas.drawCircle(handleCenter, 15.0, handlePaint);
  }

  void _drawLabel(Canvas canvas, Offset center, double radius, double angle, double pathLength) {
    final labelPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final labelCenter = Offset(
      center.dx + radius * math.cos(angle),
      center.dy + radius * math.sin(angle),
    );
    //canvas.drawCircle(labelCenter, 12.0, labelPaint);
    canvas.drawRect(
      Rect.fromCenter(
        center: labelCenter,
        width: 50,
        height: 20,
      ),
      Paint()..color = Colors.white,
    );

    // Draw labels
    final textPainter = TextPainter(
      text: TextSpan(
        text: (sum / (2*math.pi / pathLength)).toStringAsFixed(2) + ' €',
        style: TextStyle(color: Colors.black, fontSize: 12),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(minWidth: 0, maxWidth: 50);
    final offset = Offset(labelCenter.dx - textPainter.width / 2, labelCenter.dy - 5);
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
