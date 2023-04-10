import 'package:flutter/material.dart';

import 'package:file_picker/file_picker.dart';

import '../Models/Storage.dart';

class SettingsView extends StatefulWidget{
  final Settings settings;
  final Function setParentState;

  const SettingsView({
    super.key,
    required this.settings,
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
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return ListView(
      children: [
        ListTile(
          title: const Text('Add storage location', style: TextStyle(color: Colors.white),),
          onTap: () {
            _pickDir();
          }
    )
    ]
    );
  }


  Future<void> _pickDir() async {
    FilePickerResult? selectedFile = await FilePicker.platform.pickFiles();
    String? filepath = selectedFile?.files.single.path;
    if (selectedFile != null) {
      widget.setParentState(() {
        print(filepath);
        widget.settings.locations.add(filepath!);
        widget.settings.save();
      });


    }
  }
}