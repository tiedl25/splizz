import 'package:flutter/material.dart';
import 'dart:async';

import 'package:splizz/ui/widgets/overlayLoadingScreen.dart';

class TfDecorationModel extends InputDecoration {
  TfDecorationModel({required BuildContext context, required String title, IconButton? icon})
    : super(
        suffixIcon: icon,
        hintText: title,
        fillColor: Theme.of(context).colorScheme.surfaceContainer,
        filled: true,
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(15)),
          borderSide: BorderSide(style: BorderStyle.none)
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(15)),
          borderSide: BorderSide(color: Colors.blue)
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(15)),
          borderSide: BorderSide(color: Colors.red)
        )
      );
}

class PillModel extends StatelessWidget {
  final Color color;
  final Widget child;

  const PillModel({super.key, required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(style: BorderStyle.none, width: 0),
        borderRadius: const BorderRadius.all(Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      margin: const EdgeInsets.all(2),
      child: child
    );
  }
}

void showOverlayMessage({
  required BuildContext context,
  required String message,
  Duration duration = const Duration(seconds: 3),
  Color backgroundColor = Colors.black,
  Color textColor = Colors.white,
}) {
  final overlayEntry = OverlayEntry(
    builder: (context) => SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 10,
            left: 10,
            right: 10,
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            padding: EdgeInsets.all(10),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              message,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Overlay.of(context).insert(overlayEntry);
  Timer(duration, () => overlayEntry.remove());
}

Future<void> showLoadingEntry({
  required BuildContext context,
  required Function onWait
}) async {
  final overlayEntry = OverlayLoadingScreen();
  Overlay.of(context).insert(overlayEntry);
  await onWait();
  overlayEntry.remove();
}