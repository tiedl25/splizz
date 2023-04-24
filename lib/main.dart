import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:splizz/Helper/database.dart';
import 'package:splizz/Helper/filehandle.dart';
import 'package:splizz/Views/masterview.dart';

import 'Models/item.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

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
