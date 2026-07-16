import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:splizz/bloc/main_bloc.dart';
import 'package:splizz/data/app_config.dart';
import 'package:splizz/resources/strings.dart';

import 'package:splizz/bloc/masterview_bloc.dart';
import 'package:splizz/bloc/settingsview_bloc.dart';
import 'package:splizz/resources/utils.dart';
import 'package:splizz/ui/views/masterview.dart';
import 'package:splizz/ui/views/settingsview.dart';
import 'package:splizz/ui/views/authview.dart';
import 'package:splizz/ui/theme/dark_theme.dart';
import 'package:splizz/ui/theme/light_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
  ));

  //await Repository.configure(databaseFactory);
  //await Repository().initialize();
  //await dotenv.load(fileName: 'keys.env');

  await dotenv.load(fileName: 'keys.env');

  await Supabase.initialize(
    url: AppConfig.isDebug ? dotenv.get('DEBUG_SUPABASE_URL') : dotenv.get('SUPABASE_URL'),
    publishableKey: AppConfig.isDebug ? dotenv.get('DEBUG_SUPABASE_ANON_KEY') : dotenv.get('SUPABASE_ANON_KEY'),
  );

  final SharedPreferences sharedPreferences =
      await SharedPreferences.getInstance();

  // Ensure offline setting exists
  if (sharedPreferences.getBool('offline') == null) {
    sharedPreferences.setBool('offline', false);
  }

  if (!AppConfig.isDebug) {
    try {
      // 1. Check for updates
      final updateInfo = await InAppUpdate.checkForUpdate();

      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        
        // 2. Handle Immediate Update
        if (updateInfo.immediateUpdateAllowed) {
          final result = await InAppUpdate.performImmediateUpdate();
          if (result == AppUpdateResult.success) {
            // App Update successful
          }
          
        // 3. Handle Flexible Update
        } else if (updateInfo.flexibleUpdateAllowed) {
          final result = await InAppUpdate.startFlexibleUpdate();
          if (result == AppUpdateResult.success) {
            // Flexible download finished, now install it
            await InAppUpdate.completeFlexibleUpdate();
          }
        }
      }
    } on PlatformException catch (e) {
      // This catches the -6 error (low battery/storage) and other Play Store issues
      print('Play Store Update Error: ${e.code} - ${e.message}');
      
      if (e.message?.contains('-6') ?? false) {
        // Optional: Show a subtle toast telling the user to charge their phone or free up space
      }
    } catch (e) {
      // Catches any other unexpected errors
      print('Unknown update error: $e');
    }
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
            title: appTitle,
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: themeMode,
            initialRoute: '/',
            routes: {
              '/': (context) => SplashView(prefs: sharedPreferences, themeMode: themeMode),
              '/auth': (context) => AuthView(prefs: sharedPreferences),
              '/home': (context) => BlocProvider(
                    create: (_) => MasterViewCubit(sharedPreferences),
                    child: MasterView(themeMode: themeMode,),
                  ),
              '/settings': (context) => BlocProvider(
                    create: (_) => SettingsViewCubit(context.read<ThemeCubit>()),
                    child: SettingsView(),
                  ),
            },
            debugShowCheckedModeBanner: false,
            builder: isWebPhone(context) ? null : (context, child) {
              return Scaffold(
                backgroundColor: Theme.of(context).brightness == Brightness.dark 
                    ? Color.fromARGB(255, 38, 39, 45).withAlpha(239)
                    : Color.fromARGB(255, 238, 236, 245).withAlpha(239),
                body: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 500),
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: child,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
