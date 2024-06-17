import 'dart:io';

import 'package:flutter/material.dart';
import 'package:splizz/Helper/database.dart';
import 'package:splizz/Helper/drive.dart';
import 'package:splizz/Helper/file_handle.dart';
import 'package:splizz/Helper/ui_model.dart';
import 'package:splizz/Models/item.dart';

class NotFoundDialog extends StatefulWidget {
  final Item item;

  const NotFoundDialog({
    Key? key,
    required this.item
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _NotFoundDialogState();
  }
}

class _NotFoundDialogState extends State<NotFoundDialog>{
  int selection = 0;

  Item get item => widget.item;

  @override
  void initState(){
    super.initState();
  }

  Future<void> _upload() async {
    List<File> files = await DatabaseHelper.instance.export(item.id!); // Json File and Image File

    try{
      item.imageSharedId = (await GoogleDrive.instance.uploadFile(files.last))!;
      item.sharedId = (await GoogleDrive.instance.uploadFile(files.first, item.name, item.imageSharedId))!;
    } catch(_){
      GoogleDrive.instance.deleteFile(item.imageSharedId);
      GoogleDrive.instance.deleteFile(item.sharedId);
      item.imageSharedId = '';
      item.sharedId = '';
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item upload failed')));
    }
    DatabaseHelper.instance.update(item);
    FileHandler.instance.deleteFile(files.first.path);
    FileHandler.instance.deleteFile(files.last.path);
  }

  @override
  Widget build(BuildContext context) {
      return DialogModel(
          title: 'How do you want to proceed?',
          content: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Column(
              children: [
                RadioListTile(
                  title: const Text('Delete this item'),
                  value: 1, 
                  groupValue: selection,
                  onChanged: (value) {
                    setState(() {
                      selection = value as int;
                    });
                  }
                ),
                RadioListTile(
                  title: const Text('Upload this item again'),
                  value: 2, 
                  groupValue: selection,
                  onChanged: (value){
                    setState(() {
                      selection = value as int;
                    });
                  }
                ),
                RadioListTile(
                  title: const Text('Keep this item locally'),
                  value: 3, 
                  groupValue: selection,
                  onChanged: (value){
                    setState(() {
                      selection = value as int;
                    });
                  }
                ),
              ]
            )
          ),
          onConfirmed: () async {
            if(selection == 1){
              await DatabaseHelper.instance.remove(item.id!);
            } else if (selection == 2){
              _upload();
            } else if (selection == 3){
              item.sharedId = '';
              item.imageSharedId = '';
              item.owner = true;
              DatabaseHelper.instance.update(item);
            }
          },
          returnValue: selection==1,
        );
    }
}