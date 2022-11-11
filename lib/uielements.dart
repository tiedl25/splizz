import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class UIElements {
  static InputDecoration tfDecoration({required String title, IconButton? icon}) {
    return InputDecoration(
      suffixIcon: icon,
      hintText: title,
      hintStyle: const TextStyle(color: Colors.white),
      labelStyle: const TextStyle(color: Colors.white),
      enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(15)),
          borderSide: BorderSide(color: Colors.white)
      ),
      focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(15)),
          borderSide: BorderSide(color: Colors.white)
      ),
      errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(15)),
          borderSide: BorderSide(color: Colors.red)
      )
    );
  }

  static List<Widget> dialogButtons({required BuildContext context, required Function callback}){
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
                  padding: EdgeInsets.symmetric(vertical: 0),
                  child: const Text('Discard'),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                )
            ),
            const VerticalDivider(
              color: Colors.white54,
            ),
            Expanded(
              child: CupertinoButton(
                padding: EdgeInsets.symmetric(vertical: 0),
                  child: const Text('Apply'),
                  onPressed: () {
                    callback();
                    Navigator.pop(context);
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