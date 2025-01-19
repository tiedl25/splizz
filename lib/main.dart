import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:splizz/brick/repository.dart';
import 'package:sqflite/sqflite.dart' show databaseFactory;

import 'package:splizz/bloc/masterview_bloc.dart';
import 'package:splizz/bloc/settingsview_bloc.dart';

import 'package:splizz/ui/views/masterview.dart';
import 'package:splizz/ui/views/settingsview.dart';
import 'package:splizz/ui/views/authview.dart';

import 'package:splizz/theme/dark_theme.dart';
import 'package:splizz/theme/light_theme.dart';

Future main() async {
  await Repository.configure(databaseFactory);
  await Repository().initialize();

  await dotenv.load(fileName: 'keys.env');

  final SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp(sharedPreferences: sharedPreferences,));
}

class MyApp extends StatefulWidget {
  //const MyApp({Key? key}) : super(key: key);

  final SharedPreferences? sharedPreferences;

  const MyApp({Key? key, this.sharedPreferences})
      : assert(sharedPreferences != null),
        super(key: key);

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
    if (widget.sharedPreferences!.getBool('offline') == null) {
      widget.sharedPreferences!.setBool('offline', false);
    }
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
    return MaterialApp(
      title: 'Splizz',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: _systemThemeToggle ? ThemeMode.system : (_darkModeToggle ? ThemeMode.dark : ThemeMode.light),
      initialRoute: '/',
      routes: {
        '/': (context) => SplashView(updateTheme: loadSwitchValue, prefs: widget.sharedPreferences!,),
        '/auth': (context) => AuthView(prefs: widget.sharedPreferences!,),
        '/home': (context) => BlocProvider(
          create: (context) => MasterViewCubit(widget.sharedPreferences!,), 
          child: MasterView()
        ),
        '/settings': (context) => BlocProvider(
          create: (context) => SettingsViewCubit(),
          child: SettingsView(),
        ),
      },
      //home: MasterView(updateTheme: loadSwitchValue,),
      debugShowCheckedModeBanner: false,
    );
  }
}
