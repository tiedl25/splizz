import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24.0, 96.0, 24.0, 24.0),
        children: [
          Column(
            children: [
              const Text(
                'Supabase Auth UI',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 24.0),
              SupaEmailAuth(
                redirectTo:
                    kIsWeb ? null : "splizz://de.tmc.splizz",
                onSignInComplete: (res) => Navigator.pushNamed(context, '/home'),
                onSignUpComplete: (res) => Navigator.pushNamed(context, '/home'),
                onError: (error) => SnackBar(content: Text(error.toString())),
              ),
              SupaSocialsAuth(
                socialProviders: const [
                  OAuthProvider.google,
                  OAuthProvider.github,
                ],
                redirectUrl:
                    kIsWeb ? null : "splizz://de.tmc.splizz",
                onSuccess: (session) => Navigator.pushNamed(
                  context,
                  '/home',
                ),
                onError: (error) => SnackBar(
                  content: Text(
                    error.toString(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
