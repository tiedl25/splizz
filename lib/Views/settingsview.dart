import 'package:flutter/material.dart';

import '../Models/Storage.dart';

class SettingsView extends StatefulWidget{
  final Function setParentState;

  const SettingsView({
    super.key,
    required this.setParentState
  });

  @override
  State<StatefulWidget> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView>{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2B2B2B),
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
      ),
    );
  }
}