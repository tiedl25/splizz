bool approximatelyZero(double value, [double epsilon = 0.005]) {
  return value.abs() < epsilon;
}