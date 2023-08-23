import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:splizz/Helper/database.dart';
import 'package:splizz/Helper/filehandle.dart';
import 'package:splizz/Helper/ui_model.dart';

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
    return DialogModel(
          title: 'Share Splizz',
          content: const Text('Do you really want to share this item', style: TextStyle(color: Colors.white, fontSize: 20),),
          onConfirmed: (){
            setState(() {
              _upload();
            });
          }
        );
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

class _ManageDialogState extends State<ManageDialog>{
  late Item _item;
  List _people = [];
  TextEditingController tc = TextEditingController();

  @override
  void initState(){
    super.initState();
    _item = widget.item;
    _fetchData();
  }

  Future<List> _fetchData() async {
    _people = await GoogleDrive.instance.getSharedPeople(_item.sharedId);
    return _people;
  }

  _addPerson() async {
    var person = {};
    if (tc.text.isNotEmpty) person = await GoogleDrive.instance.addPeople(_item.sharedId, tc.text);
    if (person.isNotEmpty && !_people.contains(person)) {
      setState(() {
        _people.add(person);
        tc.text = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List>(
      future: _fetchData(),
        builder: (BuildContext context, AsyncSnapshot<List> snapshot) {
          if(!snapshot.hasData) {
            return DialogModel(
              title: 'Manage Access',
              content: const Text('Loading...', style: TextStyle(fontSize: 20, color: Colors.white)),
              onConfirmed: (){}
            );
          }
          return DialogModel(
              title: 'Manage Access',
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
                          controller: tc,
                          //contextMenuBuilder: , Todo
                          style: const TextStyle(color: Colors.white),
                          decoration: TfDecorationModel(
                            context: context,
                              title: 'E-Mail Address',
                              icon: IconButton(
                                  onPressed: () {
                                    _addPerson();
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
                                margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 5),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.all(Radius.circular(15)),
                                ),
                                child: Dismissible(
                                    key: UniqueKey(),
                                    direction: DismissDirection.endToStart,
                                    onDismissed: (context) async {
                                      GoogleDrive.instance.removePeople(_item.sharedId, _people[i]['id']);
                                      _fetchData().then(
                                              (_) => setState(() {})

                                      );
                                    },
                                    confirmDismiss: (direction){
                                      return showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return DialogModel(
                                              title: 'Confirm Dismiss',
                                              content: const Text('Do you really want to remove this Person', style: TextStyle(color: Colors.white, fontSize: 20),),
                                              onConfirmed: (){}
                                          );
                                        },
                                      );
                                    },
                                    background: Container(
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                                      child: const Icon(Icons.delete, color: Colors.white),
                                    ),
                                    child: Container(
                                      alignment: Alignment.center,
                                      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                                      decoration: BoxDecorationModel(),
                                      child: Text("${_people[i]['name']}", style: const TextStyle(fontSize: 20, color: Colors.white),),
                                    )
                                ),
                              );
                            }
                        ),
                      )
                    ],
                  ),
                ),
              ),
            onConfirmed: (){},
          );
        }
    );
    }
}