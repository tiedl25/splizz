import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:splizz/models/member.model.dart';

class CircularSlider extends StatefulWidget {
  final double sum;
  final List<Member> members;
  final List<double> memberBalances;
  final List<bool> memberSelection;
  final Function getInvolvedMembers;

  CircularSlider({Key? key, required this.sum, required this.members, required this.memberBalances, required this.memberSelection, required this.getInvolvedMembers}) : super(key: key);
  @override
  _CircularSliderState createState() => _CircularSliderState();
}

class _CircularSliderState extends State<CircularSlider> {
  late List<Map<String, dynamic>> members;
  bool lock = false;

  @override
  void initState() {
    super.initState();
    
    update();
  }

  void update(){
    this.members = [];

    double val = 0;
    double angle = (2*math.pi) / widget.memberSelection.where((e) => e==true).length;
    double balance = widget.sum / widget.memberSelection.where((e) => e==true).length;
    
    for (int i=0; i<widget.members.length; i++) {
      if(!widget.memberSelection[i]) continue;
      val = angle + val;
      
      this.members.add({
        'listId': i,
        'id': widget.members[i].id,
        'color': widget.members[i].color,
        'balance': balance,
        'angle': val
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    int numberOfSelectedMembers = widget.memberSelection.where((e) => e==true).length;

    widget.sum == 0.0 || numberOfSelectedMembers == 0 || numberOfSelectedMembers == 1 ? lock = true : lock = false;
    numberOfSelectedMembers != members.length ? update() : null;
    //update();

    return GestureDetector(
      onPanDown: (value){},
      onPanUpdate: lock ? null : _updatePosition,
      onPanEnd: widget.getInvolvedMembers(members),
      child: CustomPaint(
        size: Size(200, 200),
        painter: CircularSliderPainter(this.members,
          widget.sum, 
          this.lock, 
        )
      ),
    );
  }

  void _updatePosition(DragUpdateDetails details) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.globalToLocal(details.globalPosition);
    final center = Offset(renderBox.size.width / 2, renderBox.size.height / 2);
    final angle = (math.atan2(offset.dy - center.dy, offset.dx - center.dx) + 2 * math.pi) % (2 * math.pi);
    setState(() {
      for (int i = 0; i < members.length; i++) {

        double mAngle = members[i]['angle'];

        if ((angle - mAngle).abs() < 0.2 || (angle - mAngle + 2 * math.pi).abs() < 0.2 || (angle - mAngle - 2 * math.pi).abs() < 0.2) {
          
          if ((members[i+1 >= members.length ? 0 : i+1]['angle'] - mAngle).abs() < 0.25 && angle > mAngle) {
            //lock = true;
            break;
          }

          if ((mAngle - members[i-1 < 0 ? members.length-1 : i-1]['angle']).abs() < 0.25 && angle < mAngle) {
            //lock = true;
            break;
          }

          members[i]['angle'] = angle;
          break;
        }
      }
    });
  }
}

class CircularSliderPainter extends CustomPainter {
  final List<Map<String, dynamic>> members;
  final double sum;
  bool lock;

  CircularSliderPainter(this.members, this.sum, this.lock);

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

    for (int i = 0; i < members.length; i++) {
      final startAngle = members[i]['angle'];
      final endAngle = members[(i + 1) % members.length]['angle'];
      final path = Path();
      path.arcTo(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        (endAngle - startAngle) % (2 * math.pi),
        false,
      );
      segmentPaint.color = Color.alphaBlend(this.lock ? Color.fromARGB(136, 97, 97, 97) : Color.fromARGB(0, 255, 255, 255), Color(members[i]['color']));
      canvas.drawPath(path, segmentPaint);
    }

    for (double angle in members.map((e) => e['angle'])) {
      _drawHandle(canvas, center, radius, angle);
    }

    if (this.lock) return;

    for (int i = 0; i < members.length; i++) {
      double ang = i == members.length - 1 ? members[0]['angle']: members[i+1]['angle'];
      double pos2 = members[i]['angle'] > ang ? ang + 2*math.pi : ang;
      double labelPos = (members[i]['angle'] + pos2) / 2;

      double pathLength = (members[i]['angle'] - pos2).abs();

      members[i]['balance'] = double.parse((sum / (2*math.pi / pathLength)).toStringAsFixed(2));

      _drawLabel(canvas, center, radius, labelPos > 2*math.pi ? labelPos - 2*math.pi : labelPos, members[i]['balance']);
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

  void _drawLabel(Canvas canvas, Offset center, double radius, double angle, double balance) {
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
        text: balance.toStringAsFixed(2) + ' €',
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
