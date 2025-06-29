import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:splizz/bloc/main_bloc.dart';
import 'package:splizz/brick/repository.dart';
import 'package:sqflite/sqflite.dart' show databaseFactory;

import 'package:splizz/bloc/masterview_bloc.dart';
import 'package:splizz/bloc/settingsview_bloc.dart';
import 'package:splizz/ui/views/masterview.dart';
import 'package:splizz/ui/views/settingsview.dart';
import 'package:splizz/ui/views/authview.dart';
import 'package:splizz/ui/theme/dark_theme.dart';
import 'package:splizz/ui/theme/light_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent, // Make nav bar transparent
      systemNavigationBarIconBrightness: Brightness.dark, // or Brightness.light
      statusBarColor: Colors.transparent, // Optional: make status bar transparent too
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  
  await Repository.configure(databaseFactory);
  await Repository().initialize();
  await dotenv.load(fileName: 'keys.env');

  final SharedPreferences sharedPreferences =
      await SharedPreferences.getInstance();

  // Ensure offline setting exists
  if (sharedPreferences.getBool('offline') == null) {
    sharedPreferences.setBool('offline', false);
  }

  runApp(MyApp(sharedPreferences: sharedPreferences));
}

class MyApp extends StatelessWidget {
  final SharedPreferences sharedPreferences;

  const MyApp({Key? key, required this.sharedPreferences}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Provide the ThemeCubit used for updating the app theme.
        BlocProvider<ThemeCubit>(
          create: (_) => ThemeCubit(sharedPreferences),
        ),
      ],
      // BlocBuilder listens to the ThemeCubit and rebuilds MaterialApp when theme changes.
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp(
            title: 'Splizz',
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: themeMode,
            initialRoute: '/',
            routes: {
              '/': (context) => SplashView(prefs: sharedPreferences),
              '/auth': (context) => AuthView(prefs: sharedPreferences),
              '/home': (context) => BlocProvider(
                    create: (_) => MasterViewCubit(sharedPreferences),
                    child: MasterView(),
                  ),
              '/settings': (context) => BlocProvider(
                    create: (_) => SettingsViewCubit(context.read<ThemeCubit>()),
                    child: SettingsView(),
                  ),
            },
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
