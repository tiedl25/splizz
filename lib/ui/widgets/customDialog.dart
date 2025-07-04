import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CustomDialog extends StatelessWidget {
  final String? title;
  final Widget? header;
  final Widget content;
  final Function? onConfirmed;
  final Function? onDismissed;
  final returnValue;
  final String leftText;
  final String rightText;
  final EdgeInsets insetPadding;
  final EdgeInsets contentPadding;
  final Alignment alignment;
  final bool scrollable;
  final bool pop;
  final Color? color;
  bool confirmed;

  CustomDialog({
    super.key,
    this.title,
    this.header,
    required this.content,
    this.onConfirmed,
    this.onDismissed,
    this.leftText = 'Cancel',
    this.rightText = 'OK',
    this.insetPadding = const EdgeInsets.all(15),
    this.contentPadding = const EdgeInsets.all(20),
    this.alignment = Alignment.bottomCenter,
    this.scrollable = true,
    this.returnValue,
    this.pop = true,
    this.color
  }) : confirmed = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && !confirmed) {
          onDismissed?.call();
        }
      },
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
        child: AlertDialog(
          elevation: 0,
          alignment: alignment,
          actionsPadding: const EdgeInsets.fromLTRB(20, 5, 20, 15),
          insetPadding: insetPadding,
          contentPadding: contentPadding,
          scrollable: scrollable,
          title: header ?? (title != null ? Text(title!) : null),
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(15))),
          backgroundColor: color == null ? Theme.of(context).colorScheme.surface : color,
          content: content,
          actions: onConfirmed != null
            ? [
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
                            child: Text(
                              leftText,
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            onPressed: () => Navigator.of(context).pop(false),
                          )
                        ),
                        const VerticalDivider(
                          indent: 5,
                          endIndent: 5,
                        ),
                        Expanded(
                          child: CupertinoButton(
                            padding: const EdgeInsets.symmetric(vertical: 0),
                            child: Text(
                              rightText,
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            onPressed: () {
                              this.confirmed = true;
                              onConfirmed?.call();
                              if (pop) Navigator.of(context).pop(returnValue ?? true);
                            }
                          ),
                        ),
                      ],
                    ),
                  )
                ),
              ]
            : null
        )
      ),
    );
  }
}