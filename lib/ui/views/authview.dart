import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';

class AuthView extends StatelessWidget {
  late final context;

  final SharedPreferences prefs;

  AuthView({super.key, required this.prefs});

  get emailAuth => SupaEmailAuth(
    redirectTo: kIsWeb ? null : "splizz://de.tmc.splizz",
    onSignInComplete: (res) {
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    },
    onSignUpComplete: (res) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please check your email to verify your account.")));
    },
    onError: (error) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text((error as AuthApiException).message))),
  );

  get offlineButton => TextButton(
    style: TextButton.styleFrom(
      foregroundColor: Theme.of(context).textTheme.labelMedium!.color,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      minimumSize: const Size(double.infinity, 30),
    ),
    onPressed: () {
      prefs.setBool('offline', true);
      Navigator.pushNamedAndRemoveUntil(
          context, '/', (route) => false
      );
    },
    child: Text(
      'Continue without an account',
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 18,
      )
    )
  );

  @override
  Widget build(BuildContext context) {
    this.context = context;

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
              emailAuth,
              const SizedBox(height: 24.0),
              offlineButton,
            ],
          ),
        ],
      ),
    );
  }
}
