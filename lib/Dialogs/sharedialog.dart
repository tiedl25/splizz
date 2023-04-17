import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:splizz/Helper/uielements.dart';

import '../Helper/drive.dart';
import '../Models/item.dart';

class ShareDialog extends StatefulWidget {
  final Item item;
  final Function setParentState;

  const ShareDialog({
    Key? key,
    required this.item,
    required this.setParentState
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _ShareDialogState();
  }
}

class _ShareDialogState extends State<ShareDialog>{
  late Item _item;

  void _init(){
    _item = widget.item;
  }

  @override
  Widget build(BuildContext context) {
    _init();

    return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
        child: AlertDialog(
          title: const Text('Share Splizz', style: TextStyle(color: Colors.white),),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
          backgroundColor: const Color(0xFF2B2B2B),
          actions: UIElements.dialogButtons(
              context: context,
              callback: () {
                setState(() {
                  _upload();
                });
              }),
        ));
  }

  Future<void> _upload() async {
    Directory dir = await getApplicationSupportDirectory();
    var filepath = dir.path;
    var gd = GoogleDrive();
    File file = File('$filepath/item_${_item.id}.json');
    var id = await gd.testFilenames(_item.id);
    if(id != 'false'){
      gd.updateFile(file, id);
    } else {
      gd.uploadFileToGoogleDrive(file);
    }
  }
}