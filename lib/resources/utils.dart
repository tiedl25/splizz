import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

bool approximatelyZero(double value, [double epsilon = 0.005]) {
  return value.abs() < epsilon;
}

bool isWebLandscape(BuildContext context) {
  return MediaQuery.of(context).size.width > MediaQuery.of(context).size.height && kIsWeb;
}

bool isWebPortrait(BuildContext context) {
  return MediaQuery.of(context).size.height > MediaQuery.of(context).size.width && kIsWeb;
}

bool isWebPhone(BuildContext context) {
  return MediaQuery.of(context).size.width < 500 && kIsWeb;
}

bool isWebPhonePortrait(BuildContext context) {
  return isWebPhone(context) && isWebPortrait(context);
}