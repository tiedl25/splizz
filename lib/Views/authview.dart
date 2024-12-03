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
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please check your email to verify your account.")));
                },
                onError: (error) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text((error as AuthApiException).message))),
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
