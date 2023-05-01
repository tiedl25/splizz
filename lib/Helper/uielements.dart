import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class UIElements {
  static InputDecoration tfDecoration({required String title, IconButton? icon}) {
    return InputDecoration(
      suffixIcon: icon,
      hintText: title,
      fillColor: const Color(0xFF383838),
      filled: true,
      hintStyle: const TextStyle(color: Colors.white),
      labelStyle: const TextStyle(color: Colors.white),
      enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(15)),
          borderSide: BorderSide(color: Color(0xFF383838))
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

  static BoxDecoration boxDecoration() {
    return BoxDecoration(
        color: const Color(0xFF383838),
        border: Border.all(color: const Color(0xFF383838)),
        borderRadius: const BorderRadius.all(Radius.circular(15)),
    );
  }

  static BackdropFilter dialog({required String title, required Widget content, required BuildContext context, required Function onConfirmed}) {
    return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
        child: AlertDialog(
          scrollable: true,
          title: Text(title, style: const TextStyle(color: Colors.white),),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
          backgroundColor: const Color(0xFF2B2B2B),
          content: content,
          actions: UIElements.dialogButtons(
            context: context,
            callback: onConfirmed,
          ),
        )
    );
  }

  static List<Widget> dialogButtons({required BuildContext context, required Function callback, String leftText='Discard', String rightText='Apply'}){
    return <Widget>[
      const Divider(
        color: Colors.white54,
      ),
      IntrinsicHeight(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 0),
                  child: Text(leftText),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                )
            ),
            const VerticalDivider(
              color: Colors.white54,
            ),
            Expanded(
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 0),
                  child: Text(rightText),
                  onPressed: () {
                    callback();
                    Navigator.of(context).pop(true);
                  }
              ),
            )
            ,
          ],
        ),
      )
      ,
    ];
  }
}