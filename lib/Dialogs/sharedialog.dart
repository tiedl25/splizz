import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:splizz/Helper/database.dart';
import 'package:splizz/Helper/filehandle.dart';
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

  @override
  void initState(){
    super.initState();
    _item = widget.item;
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
        child: AlertDialog(
          title: const Text('Share Splizz', style: TextStyle(color: Colors.white),),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
          backgroundColor: const Color(0xFF2B2B2B),
          content: Container(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: UIElements.tfDecoration(
                  title: 'E-Mail Address',
                  icon: IconButton(
                      onPressed: () {

                      },
                      icon: const Icon(Icons.add, color: Colors.white,)
                  )
              ),
            ),
          ),
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
    File file = await DatabaseHelper.instance.export(_item.id!);
    String? sharedId = await GoogleDrive.instance.uploadFile(file);
    _item.sharedId = sharedId!;
    DatabaseHelper.instance.update(_item);
    FileHandler.instance.deleteFile(file.path);
  }
}

class ManageDialog extends StatefulWidget {
  final Item item;
  final Function setParentState;

  const ManageDialog({
    Key? key,
    required this.item,
    required this.setParentState
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _ManageDialogState();
  }
}

//Todo
class _ManageDialogState extends State<ManageDialog>{
  late Item _item;
  List _people = [];

  @override
  void initState(){
    super.initState();
    _item = widget.item;
    _fetchData();
  }

  Future<void> _fetchData() async {
    _people = await GoogleDrive.instance.getSharedPeople(_item.sharedId);
    setState((){});
  }

  @override
  Widget build(BuildContext context) {
    if (_people.isEmpty) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
          child: AlertDialog(
            title: const Text('Manage Access', style: TextStyle(color: Colors.white),),
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
            backgroundColor: const Color(0xFF2B2B2B),
            content: const Text('Loading...', style: TextStyle(fontSize: 20, color: Colors.white)),
            actions: UIElements.dialogButtons(
                context: context,
                callback: () {
                  setState(() {});
                }),
          )
      );
    } else {
      return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
          child: AlertDialog(
            title: const Text('Manage Access', style: TextStyle(color: Colors.white),),
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
            backgroundColor: const Color(0xFF2B2B2B),
            content: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height/4,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: TextField(
                        style: const TextStyle(color: Colors.white),
                        decoration: UIElements.tfDecoration(
                            title: 'E-Mail Address',
                            icon: IconButton(
                                onPressed: () {

                                },
                                icon: const Icon(Icons.add, color: Colors.white,)
                            )
                        ),
                      ),
                    ),
                    SizedBox(
                        height: MediaQuery.of(context).size.height/6,
                        child:
                            ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              itemCount: _people.length,
                              itemBuilder: (context, i) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                                  margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 5),
                                  decoration: UIElements.boxDecoration(),
                                  child: SingleChildScrollView(
                                    physics: const BouncingScrollPhysics(),
                                    scrollDirection: Axis.horizontal,
                                    child: Text("${_people[i]['name']} (${_people[i]['email']})", style: const TextStyle(fontSize: 20, color: Colors.white),),
                                  ),
                                );
                              }
                          ),
                        )
                  ],
                ),
              ),
            ),
            actions: UIElements.dialogButtons(
              context: context,
              callback: () {
                setState(() {
                  //Todo
                });
              },),
          ));
      }
    }

}