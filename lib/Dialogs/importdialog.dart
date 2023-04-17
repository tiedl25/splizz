import 'dart:ui';

import 'package:flutter/material.dart';
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
  late List _itemlist = [];

  @override
  void initState(){
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    var gd = GoogleDrive();
    _itemlist = await gd.getFilenames();
    setState((){
    });
  }

  @override
  Widget build(BuildContext context) {
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
                  setState(() {
                  //Todo
                  });
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
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(10)),
                                ),
                                title: Text(_itemlist[i][0], style: const TextStyle(fontSize: 20, color: Colors.white),),
                                tileColor: const Color(0xFF383838),
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
                callback: () {
                  setState(() {
                  //Todo
                  });
                }),
          ));
    }
  }

}