import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DialogModel extends StatelessWidget {
  final String? title;
  final Widget content;
  final Function? onConfirmed;
  final String leftText;
  final String rightText;
  final EdgeInsets insetPadding;
  final EdgeInsets contentPadding;

  const DialogModel({
    super.key,
    this.title,
    required this.content,
    this.onConfirmed,
    this.leftText='Cancel',
    this.rightText='OK',
    this.insetPadding=const EdgeInsets.all(15),
    this.contentPadding=const EdgeInsets.all(20)
  });

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
        child: AlertDialog(
          alignment: Alignment.bottomCenter,
          insetPadding: insetPadding,
          contentPadding: contentPadding,
          scrollable: true,
          title: title != null ? Text(title!) : null,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
          backgroundColor: Theme.of(context).colorScheme.background,
          content: content,
          actions: onConfirmed != null ? [
            const Divider(
              thickness: 0.5,
            ),
            IntrinsicHeight(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 0),
                        child: Text(leftText, style: Theme.of(context).textTheme.labelLarge,),
                        onPressed: () {
                          Navigator.of(context).pop(false);
                        },
                      )
                  ),
                  const VerticalDivider(),
                  Expanded(
                    child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 0),
                        child: Text(rightText, style: Theme.of(context).textTheme.labelLarge,),
                        onPressed: () {
                          onConfirmed!();
                          Navigator.of(context).pop(true);
                        }
                    ),
                  ),
                ],
              ),
            ),
          ] : null
        )
    );
  }
}

class TfDecorationModel extends InputDecoration {
  TfDecorationModel({required BuildContext context, required String title, IconButton? icon}) : super(
      suffixIcon: icon,
      hintText: title,
      fillColor: Theme.of(context).colorScheme.surface,
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

class SelectionBar extends StatelessWidget {
  final Color selectedColor;
  final Function onPressed;
  final int itemCount;


  const SelectionBar({
    super.key,
    this.selectedColor=Colors.white38,
    required this.onPressed,
    required this.itemCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

