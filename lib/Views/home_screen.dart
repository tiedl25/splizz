import 'package:flutter/material.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';

final supabase = Supabase.instance.client;
final activeSession = supabase.auth.currentSession;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    if (activeSession == null) {
      Navigator.pushNamed(context, '/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'You are home - ${activeSession?.user.id}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 24.0),
            ElevatedButton(
              onPressed: () async {
                await supabase.auth.signOut();
                Navigator.pushNamed(context, '/');
              },
              child: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }
}
