import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsView extends StatefulWidget{
  final Function setParentState;
  final Function updateTheme; //Triggers setState method of MyApp

  const SettingsView({
    super.key,
    required this.setParentState,
    required this.updateTheme,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Container(
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(style: BorderStyle.none, ),
          borderRadius: BorderRadius.circular(20)
        ),
        child: SingleChildScrollView(
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
      ),
    );
  }
}