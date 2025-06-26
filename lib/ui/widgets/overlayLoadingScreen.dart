import 'dart:ui';
import 'package:flutter/material.dart';

class OverlayLoadingScreen extends OverlayEntry {
  OverlayLoadingScreen({
    Color backgroundColor = Colors.transparent,
    Color circleColor = Colors.white,
  }) : super(
    builder: (context) => Center(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
          ),
          child: CircularProgressIndicator(
            color: circleColor,
            strokeWidth: 3.0,
          ),
        ),
      ),
    ),
  );
}