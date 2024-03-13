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
  final Alignment alignment;
  final bool scrollable;

  const DialogModel({
    super.key,
    this.title,
    required this.content,
    this.onConfirmed,
    this.leftText='Cancel',
    this.rightText='OK',
    this.insetPadding=const EdgeInsets.all(15),
    this.contentPadding=const EdgeInsets.all(20),
    this.alignment=Alignment.bottomCenter,
    this.scrollable=true
  });

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
        child: AlertDialog(
          elevation: 0,
          alignment: alignment,
          insetPadding: insetPadding,
          contentPadding: contentPadding,
          scrollable: scrollable,
          title: title != null ? Text(title!) : null,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
          backgroundColor: Theme.of(context).colorScheme.background,
          content: content,
          actions: onConfirmed != null ? [
            const Divider(
              thickness: 0.5,
              indent: 0,
              endIndent: 0,
            ),
            IntrinsicHeight(
              child: Container(
                padding: EdgeInsets.all(0),
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
                    const VerticalDivider(
                      indent: 5,
                      endIndent: 5,
                    ),
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
              )
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

class PillModel extends StatelessWidget{
  final Color color;
  final Widget child;

  const PillModel({
    super.key,
    required this.color,
    required this.child
  });

  @override
  Widget build(BuildContext context){
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

