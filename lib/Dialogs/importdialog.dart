import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:splizz/Helper/database.dart';
import 'package:splizz/Helper/filehandle.dart';
import 'package:splizz/Helper/uielements.dart';
import 'package:splizz/Helper/drive.dart';

class ImportDialog extends StatefulWidget {
  final Function setParentState;

  const ImportDialog({
    Key? key,
    required this.setParentState
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _ImportDialogState();
  }
}

class _ImportDialogState extends State<ImportDialog>{
  List _sharedList = [];
  List _savedList = [];
  final List<bool> _isSelected = [];
  final List<bool> _isSelected2 = [];
  List _selection = [-1, false]; //true means items is in shared list, false means in saved list

  @override
  void initState(){
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    _sharedList = await GoogleDrive.instance.getFilenames();
    _savedList = await GoogleDrive.instance.getFilenames(owner: true);
    setState((){});
  }

  @override
  Widget build(BuildContext context) {
    for (var i=0; i<_sharedList.length; i++){
      _isSelected.add(false);
    }
    for (var i=0; i<_savedList.length; i++){
      _isSelected2.add(false);
    }

    if(_sharedList.isEmpty){
      return UIElements.dialog(
        title: 'Import Splizz',
        context: context,
        content: const Text('No items available. Make sure that there are items shared with you.', style: TextStyle(fontSize: 20, color: Colors.white)),
        onConfirmed: (){
          setState((){});
        }
        );
    } else {
      return UIElements.dialog(
          title: 'Import Splizz',
          context: context,
          content: SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height/2,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _sharedList.isNotEmpty ? const Text('Shared with me', style: TextStyle(color: Colors.white, fontSize: 20),) : const Text(''),
                    ListView.builder(
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _sharedList.length,
                        itemBuilder: (context, i) {
                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(Radius.circular(10)),
                              ),
                              title: Text(_sharedList[i][2], style: const TextStyle(fontSize: 20, color: Colors.white),),
                              tileColor: const Color(0xFF383838),
                              selected: _isSelected[i],
                              selectedTileColor: Colors.blue,
                              onTap: (){
                                setState(() {
                                  var selected = _isSelected[i];
                                  _isSelected.fillRange(0, _isSelected.length, false);
                                  _isSelected2.fillRange(0, _isSelected2.length, false);
                                  _isSelected[i] = !selected;
                                  _selection = [i, true];
                                });
                              },
                            ),
                          );
                        }
                    ),
                    _savedList.isNotEmpty && _sharedList.isNotEmpty ? Container(height: 20,) : Container(),
                    _savedList.isNotEmpty ? const Text('Saved by me', style: TextStyle(color: Colors.white, fontSize: 20),) : const Text(''),
                    ListView.builder(
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _savedList.length,
                        itemBuilder: (context, i) {
                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(Radius.circular(10)),
                              ),
                              title: Text(_savedList[i][2], style: const TextStyle(fontSize: 20, color: Colors.white),),
                              tileColor: const Color(0xFF383838),
                              selected: _isSelected2[i],
                              selectedTileColor: Colors.blue,
                              onTap: (){
                                setState(() {
                                  var selected = _isSelected2[i];
                                  _isSelected2.fillRange(0, _isSelected2.length, false);
                                  _isSelected.fillRange(0, _isSelected.length, false);
                                  _isSelected2[i] = !selected;
                                  _selection = [i, false];
                                });
                              },
                            ),
                          );
                        }
                    )

                  ],
                ),
              ),
            ),
          onConfirmed: () async {
            var selection = _selection[0];
                if (selection != -1){
                  File file;
                  if (_selection[1]) {
                    file = await GoogleDrive.instance.downloadFile(_sharedList[selection][1], _sharedList[selection][0]);
                    DatabaseHelper.instance.import(file.path, _sharedList[selection][1]);
                  } else {
                    file = await GoogleDrive.instance.downloadFile(_savedList[selection][1], _savedList[selection][0]);
                    DatabaseHelper.instance.import(file.path, _savedList[selection][1]);
                  }

                  //GoogleDrive.instance.addParents(file, item.sharedId);
                  FileHandler.instance.deleteFile(file.path);
                  widget.setParentState((){});
                }
              }
        );
    }
  }

}