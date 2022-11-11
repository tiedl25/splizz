import 'package:flutter/material.dart';
import 'package:splizz/Views/masterview.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  // It contains everything to run the application, nothing more
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Splizz',
      home: MasterView(),
    );
  }
}
