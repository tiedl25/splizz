import 'package:flutter/material.dart';


class UIElements{
  static InputDecoration tfDecoration(String title, [Icon? icon]){
    return InputDecoration(
        suffixIcon: icon,
        hintText: title,
        hintStyle: const TextStyle(color: Colors.white),
        labelStyle: const TextStyle(color: Colors.white),
        enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white)
        ),
        focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white)
        ),
        errorBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.red)
        )
    );
  }
}
