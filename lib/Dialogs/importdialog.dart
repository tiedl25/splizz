import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:splizz/Helper/database.dart';
import 'package:splizz/Helper/filehandle.dart';
import 'package:splizz/Helper/uielements.dart';
import 'package:splizz/Helper/drive.dart';
import 'package:path/path.dart' as p;

import '../Models/item.dart';

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
  late List _itemlist = [];
  final List<bool> _isSelected = [];
  int _selection = -1;

  @override
  void initState(){
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    _itemlist = await GoogleDrive.instance.getFilenames();
    setState((){});
  }

  @override
  Widget build(BuildContext context) {
    for (var _ in _itemlist){
      _isSelected.add(false);
    }

    if(_itemlist.isEmpty){
      return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
          child: AlertDialog(
            title: const Text('Import Splizz', style: TextStyle(color: Colors.white),),
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
            backgroundColor: const Color(0xFF2B2B2B),
            content: const Text('No items available. Make sure that there are items shared with you.', style: TextStyle(fontSize: 20, color: Colors.white)),
            actions: UIElements.dialogButtons(
                context: context,
                callback: () {
                  setState(() {});
                }),
          ));
    } else {
      return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
          child: AlertDialog(
            content: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height/4,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                        height: MediaQuery.of(context).size.height/4,
                        child: ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            itemCount: _itemlist.length,
                            itemBuilder: (context, i) {
                              return Container(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(10)),
                                  ),
                                  title: Text(_itemlist[i][2], style: const TextStyle(fontSize: 20, color: Colors.white),),
                                  tileColor: const Color(0xFF383838),
                                  selected: _isSelected[i],
                                  selectedTileColor: Colors.blue,
                                  onTap: (){
                                    setState(() {
                                      var selected = _isSelected[i];
                                      _isSelected.fillRange(0, _isSelected.length, false);
                                      _isSelected[i] = !selected;
                                      _selection = i;
                                    });
                                  },
                                ),
                              );
                            }
                        )
                    )
                  ],
                ),
              ),
            ),
            title: const Text('Import Splizz', style: TextStyle(color: Colors.white),),
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
            backgroundColor: const Color(0xFF2B2B2B),
            actions: UIElements.dialogButtons(
                context: context,
                callback: () async {
                  if (_selection != -1){
                    File file = await GoogleDrive.instance.downloadFile(_itemlist[_selection][1], _itemlist[_selection][0]);
                    Item item = Item.fromJson(await FileHandler.instance.readJsonFile(p.basename(file.absolute.path)));
                    item.sharedId = _itemlist[_selection][1];
                    DatabaseHelper.instance.add(item);
                    //GoogleDrive.instance.addParents(file, item.sharedId);
                    FileHandler.instance.deleteFile(file.path);
                    widget.setParentState((){});
                  }
                }),
          ));
    }
  }

}