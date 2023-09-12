import 'dart:io';

import 'package:flutter/material.dart';
import 'package:splizz/Helper/database.dart';
import 'package:splizz/Helper/file_handle.dart';
import 'package:splizz/Helper/ui_model.dart';
import 'package:splizz/Helper/drive.dart';
import 'package:splizz/Models/item.dart';

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
          content: const Text('Do you really want to share this item', style: TextStyle(fontSize: 20),),
          onConfirmed: (){
            setState(() {
              _upload();
            });
          }
        );
  }

  Future<void> _upload() async {
    List<File> files = await DatabaseHelper.instance.export(_item.id!); // Json File and Image File

    _item.imageSharedId = (await GoogleDrive.instance.uploadFile(files.last))!;
    if(_item.imageSharedId != '1'){
      _item.sharedId = (await GoogleDrive.instance.uploadFile(files.first, _item.name, _item.imageSharedId))!;
      if(_item.sharedId != '1'){
        DatabaseHelper.instance.update(_item);
      } else {
        GoogleDrive.instance.deleteFile(_item.imageSharedId);
      }
    }

    FileHandler.instance.deleteFile(files.first.path);
    FileHandler.instance.deleteFile(files.last.path);
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
    final response = await GoogleDrive.instance.getSharedPeople(_item.sharedId);
    if(response == 1) {
      showDialog(
          context: context,
          builder: (context){
            return ErrorDialog('Item not found');
          }
      );
    }
    return _people;
  }

  _addPerson() async {
    if (tc.text.isNotEmpty) {
      var person = await GoogleDrive.instance.addPeople(_item.sharedId, tc.text);
      if (person != 1 && !_people.contains(person)) {
        await GoogleDrive.instance.addPeople(_item.imageSharedId, tc.text);
        setState(() {
          _people.add(person);
          tc.text = '';
        });
      } else {
        showDialog(context: context, builder: (BuildContext){
          return const ErrorDialog('There is no Google Account linked to this email address');
        });
        tc.text = '';
      }
    }

  }

  @override
  Widget build(BuildContext context) {
    return DialogModel(
        title: 'Manage Access',
        content: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: FutureBuilder<List>(
              future: _fetchData(),
              builder: (BuildContext context, AsyncSnapshot<List> snapshot) {
                return !snapshot.hasData ?
                  const Center(child: CircularProgressIndicator()) :
                  SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: TextField(
                              controller: tc,
                              decoration: TfDecorationModel(
                                  context: context,
                                  title: 'E-Mail Address',
                                  icon: IconButton(
                                      onPressed: () {
                                        _addPerson();
                                      },
                                      icon: const Icon(Icons.add)
                                  )
                              ),
                            ),
                          ),
                          SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              children: List.generate(
                                  _people.length,
                                      (i) {
                                    return Container(
                                      margin: const EdgeInsets.symmetric(vertical: 5),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.all(Radius.circular(15)),
                                      ),
                                      child: Dismissible(
                                          key: UniqueKey(),
                                          direction: DismissDirection.endToStart,
                                          onDismissed: (context) async {
                                            var response = await GoogleDrive.instance.removePeople(_item.sharedId, _people[i]['id']);
                                            if(response == 1){
                                              showDialog(context: this.context, builder: (BuildContext){
                                                return ErrorDialog('Person could\'t be removed');
                                              });
                                              return;
                                            }
                                            _fetchData().then((_) => setState(() {}));
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
                                            child: const Icon(Icons.delete, color: Colors.white),
                                          ),
                                          child: Container(
                                            alignment: Alignment.centerLeft,
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).colorScheme.surface,
                                              border: Border.all(style: BorderStyle.none),
                                              borderRadius: const BorderRadius.all(Radius.circular(15)),
                                            ),
                                            child: Text("${_people[i]['name']}", style: const TextStyle(fontSize: 20),),
                                          )
                                      ),
                                    );
                                  }
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                );
              }
          ),
        ),
      onConfirmed: (){},
    );
    }
}