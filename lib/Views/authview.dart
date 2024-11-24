import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:splizz/Helper/database.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';

class AuthView extends StatelessWidget {
  final SharedPreferences prefs;

  const AuthView({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24.0, 96.0, 24.0, 24.0),
        children: [
          Column(
            children: [
              const Text(
                'Sign in / Sign up',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 24.0),
              SupaEmailAuth(
                redirectTo: kIsWeb ? null : "splizz://de.tmc.splizz",
                onSignInComplete: (res) {
                  DatabaseHelper.instance.syncData();
                  Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                },
                onSignUpComplete: (res) {
                  DatabaseHelper.instance.syncData();
                  Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                },
                onError: (error) => SnackBar(content: Text(error.toString())),
              ),
              SupaSocialsAuth(
                socialProviders: const [OAuthProvider.google],
                redirectUrl: kIsWeb ? null : "splizz://de.tmc.splizz",
                onSuccess: (session) {
                  DatabaseHelper.instance.syncData();
                  Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                },
                onError: (error) => SnackBar(content: Text(error.toString())),
              ),
              const SizedBox(height: 24.0),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  minimumSize: const Size(double.infinity, 30),
                ),
                onPressed: () {
                  prefs.setBool('offline', true);
                  Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                }, 
                child: Text(
                  'Continue without an account',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  )
                )
              )
            ],
          ),
        ],
      ),
    );
  }
}
