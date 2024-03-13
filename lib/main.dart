import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:splizz/Views/masterview.dart';
import 'package:splizz/theme/dark_theme.dart';
import 'package:splizz/theme/light_theme.dart';

Future main() async {
  await dotenv.load(fileName: 'keys.env');

  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp>{
  bool _systemThemeToggle=true;
  bool _darkModeToggle=false;

  @override
  void initState() {
    super.initState();
    loadSwitchValue(); // Load the switch value from SharedPreferences
  }

  Future<void> loadSwitchValue() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _systemThemeToggle = prefs.getBool('systemTheme') ?? true;
      _darkModeToggle = prefs.getBool('darkMode') ?? false;
    });
  }

  // This widget is the root of your application.
  // It contains everything to run the application, nothing more
  @override
  Widget build(BuildContext context) {
    //loadSwitchValue();

    return MaterialApp(
      title: 'Splizz',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: _systemThemeToggle ? ThemeMode.system : (_darkModeToggle ? ThemeMode.dark : ThemeMode.light),
      home: MasterView(updateTheme: loadSwitchValue,),
      debugShowCheckedModeBanner: false,
    );
  }
}
