import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
import 'package:splizz/Helper/database.dart';
import 'package:splizz/Helper/ui_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsView extends StatefulWidget{
  final Function updateTheme; //Triggers setState method of MyApp
  final String version;
  final SharedPreferences prefs;

  const SettingsView({
    super.key,
    required this.updateTheme,
    required this.version,
    required this.prefs
  });

  @override
  State<StatefulWidget> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView>{
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

  Future<void> showLogoutDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return DialogModel(
          content: Text("Are you sure you want to log out?", style: TextStyle(fontSize: 20),),
          onConfirmed: () async {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setBool('offline', false);
            await Supabase.instance.client.auth.signOut();
            await DatabaseHelper.instance.deleteDatabase();
            Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
          },
          pop: false
        );
      },
    );
  } 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border.all(style: BorderStyle.none, ),
              borderRadius: BorderRadius.circular(20)
            ),
            child: Column(
              children: [
                SwitchListTile(
                    title: const Text("Use system theme"),
                    value: _systemThemeToggle,
                    onChanged: (bool value) async {
                      SharedPreferences prefs = await SharedPreferences.getInstance();
                      setState(() {
                        prefs.setBool('systemTheme', value);
                        _systemThemeToggle = value;
                      });
                      widget.updateTheme();
                    }
                ),
                const Divider(
                  thickness: 0.2,
                  indent: 15,
                  endIndent: 15,
                ),
                SwitchListTile(
                    title: const Text("Dark Mode"),
                    value: _darkModeToggle,
                    tileColor: _systemThemeToggle ? Theme.of(context).colorScheme.surface : null,
                    onChanged: _systemThemeToggle ? null : (bool value) async {
                      SharedPreferences prefs = await SharedPreferences.getInstance();
                      setState(() {
                        prefs.setBool('darkMode', value);
                        _darkModeToggle = value;
                      });
                      widget.updateTheme();
                    }
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border.all(style: BorderStyle.none, ),
              borderRadius: BorderRadius.circular(20)
            ),
            child: Column(
              children: [
                ListTile(
                  title: Text("Version"),
                  subtitle: Text(widget.version),
                ),
                const Divider(
                  thickness: 0.2,
                  indent: 15,
                  endIndent: 15,
                ),
                ListTile(
                  title: Text("Privacy Policy"),
                  trailing: Icon(Icons.open_in_browser),
                  onTap: () {
                    launchUrl(
                      Uri.parse("https://tmc.tiedl.rocks/splizz/dsgvo"),
                      customTabsOptions: CustomTabsOptions(
                        urlBarHidingEnabled: false,
                        instantAppsEnabled: true,
                        closeButton: CustomTabsCloseButton(position: CustomTabsCloseButtonPosition.end),
                        showTitle: true,
                      )
                    );                  
                  },
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border.all(style: BorderStyle.none, ),
              borderRadius: BorderRadius.circular(20)
            ),
            child: Supabase.instance.client.auth.currentSession != null ? ListTile(
              title: const Text("Logout"),
              trailing: Icon(Icons.logout),
              onTap: () => showLogoutDialog(),
            ) : 
            ListTile(
              title: const Text("Login"),
              trailing: Icon(Icons.login),
              onTap: () {
                widget.prefs.setBool('offline', false);
                Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false);
              },
            )
          )
        ]
      )
    );
  }
}