import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:splizz/bloc/detailview_bloc.dart';
import 'package:splizz/bloc/detailview_states.dart';
import 'dart:math' as math;

class CircularSlider extends StatelessWidget {
  late final context;
  late final cubit;

  @override
  Widget build(BuildContext context) {
    this.context = context;
    this.cubit = context.read<DetailViewCubit>();

    return BlocBuilder<DetailViewCubit, DetailViewState>(
      bloc: cubit,
      buildWhen: (_, current) => current is DetailViewTransactionDialog,
      builder: (context, state) {
        int numberOfSelectedMembers = (state as DetailViewTransactionDialog).memberSelection.where((e) => e == true).length;
        List<Map<String, dynamic>> members = state.involvedMembers;

        state.sum == 0.0 || numberOfSelectedMembers <= 1
          ? state.lock = true
          : state.lock = false;

        if (numberOfSelectedMembers != members.length) cubit.updateCircularSlider();

        return GestureDetector(
          onPanDown: (value) {},
          onPanUpdate: state.lock
              ? null
              : (DragUpdateDetails details) =>
                  cubit.updateCircularSliderPosition(details, context.findRenderObject() as RenderBox),
          //onPanEnd: cubit.getInvolvedMembers(members),
          child: CustomPaint(
            size: Size(200, 200),
            painter: CircularSliderPainter(
              members,
              state.sum,
              state.lock,
            ))
        );
      },
    );
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
      segmentPaint.color = Color.alphaBlend(
          this.lock
              ? Color.fromARGB(136, 97, 97, 97)
              : Color.fromARGB(0, 255, 255, 255),
          Color(members[i]['color']));
      canvas.drawPath(path, segmentPaint);
    }

    for (double angle in members.map((e) => e['angle'])) {
      _drawHandle(canvas, center, radius, angle);
    }

    if (this.lock) return;

    for (int i = 0; i < members.length; i++) {
      double ang = i == members.length - 1
          ? members[0]['angle']
          : members[i + 1]['angle'];
      double pos2 = members[i]['angle'] > ang ? ang + 2 * math.pi : ang;
      double labelPos = (members[i]['angle'] + pos2) / 2;

      double pathLength = (members[i]['angle'] - pos2).abs();

      members[i]['balance'] =
          double.parse((sum / (2 * math.pi / pathLength)).toStringAsFixed(2));

      _drawLabel(
          canvas,
          center,
          radius,
          labelPos > 2 * math.pi ? labelPos - 2 * math.pi : labelPos,
          members[i]['balance']);
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

  void _drawLabel(Canvas canvas, Offset center, double radius, double angle,
      double balance) {
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
    final offset =
        Offset(labelCenter.dx - textPainter.width / 2, labelCenter.dy - 5);
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
