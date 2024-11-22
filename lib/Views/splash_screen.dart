import 'package:shared_preferences/shared_preferences.dart';
import 'package:splizz/Views/auth_screen.dart';
import 'package:flutter/material.dart';
import 'package:splizz/Views/masterview.dart';

import 'package:supabase_auth_ui/supabase_auth_ui.dart';

final activeSession = Supabase.instance.client.auth.currentSession;

class SplashScreen extends StatelessWidget {
  final Function updateTheme;
  final SharedPreferences prefs;

  const SplashScreen({Key? key, required this.updateTheme, required this.prefs}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: activeSession == null && prefs.getBool('offline') == false ? AuthScreen(prefs: prefs,) : MasterView(updateTheme: updateTheme, prefs: prefs,)),
    );
  }
}
