import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:splizz/Helper/uielements.dart';

import '../Helper/database.dart';
import '../Models/item.dart';
import '../Models/member.dart';

class ItemDialog extends StatefulWidget {
  final List<Item> items;
  final Function setParentState;

  const ItemDialog({
    Key? key,
    required this.items,
    required this.setParentState
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _ItemDialogState();
  }
}

class _ItemDialogState extends State<ItemDialog>{
  late List<Item> _items;

  String title = '';
  List<String> member = [];
  var cm = List<Color>.from(Item.colormap);
  int count = 2;

  @override
  Widget build(BuildContext context) {
    _items = widget.items;

    return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
        child: AlertDialog(
            title: const Text('Create a new Splizz', style: TextStyle(color: Colors.white),),
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
                    SizedBox(
                        height: MediaQuery.of(context).size.height/4,
                        child: ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            itemCount: count,
                            itemBuilder: (context, i) {
                              if(i == 0) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: TextField(
                                    onChanged: (value) {
                                      setState(() {
                                        title = value;
                                      });
                                    },
                                    style: const TextStyle(color: Colors.white),
                                    decoration: UIElements.tfDecoration(
                                        title: 'Title',
                                        icon: IconButton(onPressed: _imagePicker, icon: const Icon(Icons.camera_alt, color: Colors.black45,))),
                                  ),
                                );
                              }
                              return _textField(i);
                            }
                        )
                    )
                  ],
                ),
              ),
            ),
            actions: UIElements.dialogButtons(
                context: context,
                callback: (){
                  List<Member> members = [];
                  for(String name in member){
                    if(name != ''){
                      members.add(Member(members.length, name, cm[members.length]));
                    }
                  }
                  if(title != '' && members.length > 1) {
                    widget.setParentState(() {
                      Item newItem = Item(_items.length, title, members);
                      DatabaseHelper.instance.add(newItem);
                    });
                  }
                }
            )
        ));
  }

  void _imagePicker(){

  }

  void _colorPicker(int i){
    showDialog(
        context: context,
        builder: (BuildContext context){
          Color defaultColor = cm[i-1];
          return AlertDialog(
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
              backgroundColor: const Color(0xFF303030),
              insetPadding: EdgeInsets.zero,
              content: SizedBox(
                  width: MediaQuery.of(context).size.width/2,
                  height: MediaQuery.of(context).size.height/3,
                  child: BlockPicker(
                      availableColors: cm,
                      pickerColor: defaultColor,
                      onColorChanged: (Color color){
                        setState(() {
                          //cm[i-1] = color;
                          for(int a=0; a<cm.length; a++){
                            if(cm[a] == color){
                              Color tmp = cm[i-1];
                              cm[i-1] = cm[a];
                              cm[a] = tmp;
                            }
                          }
                        }
                        );
                        Navigator.of(context).pop();
                      })
              ));
        });
  }

  Container _textField(int i){
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: TextField(
          onChanged: (name) {
            setState((){
              if(member.length < i) {
                member.add(name);
              } else {
                member[i-1] = name;
              }
              if (count <= member.length+1 && count<=12){
                count++;
              }
            });
          },
          style: const TextStyle(color: Colors.white),
          decoration: UIElements.tfDecoration(
              title: 'Member $i',
              icon: IconButton(icon: const Icon(Icons.color_lens), color: cm[i-1], onPressed: () { _colorPicker(i); })
          )
      ),
    );
  }
}