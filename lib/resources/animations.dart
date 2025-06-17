import 'dart:math';

import 'package:flutter/cupertino.dart';

class SlowStartCurve extends Curve {
  @override
  double transform(double t) {
    return pow(t, 10).toDouble();
  }
}

class SlowEndCurve extends Curve {
  @override
  double transform(double t) {
    t = 1.0 - pow(t, 2).toDouble();
    return 1.0 - pow(t, 3).toDouble();
  }
}