import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:splizz/Helper/ui_model.dart';
import 'package:splizz/Helper/colormap.dart';

import 'package:splizz/Helper/database.dart';
import 'package:splizz/Models/item.dart';
import 'package:splizz/Models/member.dart';

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
  String title = '';
  List<String> member = [];
  int count = 2;
  int image = 1;

  @override
  Widget build(BuildContext context) {
    return DialogModel(
            title: 'Create a new Splizz',
            content: SizedBox(
              width: MediaQuery.of(context).size.width,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: List.generate(
                      count,
                          (i) {
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
                              decoration: TfDecorationModel(
                                  context: context,
                                  title: 'Title',
                                  icon: IconButton(onPressed: _imagePicker, icon: const Icon(Icons.camera_alt, color: Colors.black45,))),
                            ),
                          );
                        }
                        return _textField(i);
                      }
                  ),
                ),
              ),
            ),
            onConfirmed:  (){
                  List<Member> members = [];
                  for(String name in member){
                    if(name != ''){
                      members.add(Member(name, colormap[members.length]));
                    }
                  }
                  if(title != '' && members.length > 1) {
                    widget.setParentState(() {
                      Item newItem = Item(title, members: members, image: image);
                      DatabaseHelper.instance.add(newItem);
                    });
                  }
                }
            );
  }

  void _imagePicker(){
    showDialog(
        context: context,
        builder: (BuildContext context){
          return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: AlertDialog(
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
                  backgroundColor: Theme.of(context).colorScheme.background,
                  insetPadding: EdgeInsets.zero,
                  content: SizedBox(
                      width: MediaQuery.of(context).size.width/2,
                      height: MediaQuery.of(context).size.height/3,
                      child: GridView.count(
                        childAspectRatio: 1.5,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 20,
                        physics: const BouncingScrollPhysics(),
                        crossAxisCount: 2,
                        children: List.generate(6, (index){
                          return GestureDetector(
                            onTap: (){
                              setState((){
                                image = index+1;
                                Navigator.of(context).pop();
                              });
                              },
                            child: ClipRRect(
                              borderRadius: const BorderRadius.all(Radius.circular(15)),
                              child: Image(
                                  fit: BoxFit.cover,
                                  image: AssetImage('images/image_${index+1}.jpg')
                              ),
                            ),
                          );
                      },
                      )
                  )
                  )
              )
          );
        });
  }

  void _colorPicker(int i){
    showDialog(
        context: context,
        builder: (BuildContext context){
          Color defaultColor = colormap[i-1];
          return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: AlertDialog(
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
              backgroundColor: Theme.of(context).colorScheme.background,
              insetPadding: EdgeInsets.zero,
              content: SizedBox(
                  width: MediaQuery.of(context).size.width/2,
                  height: MediaQuery.of(context).size.height/3,
                  child: BlockPicker(
                      availableColors: colormap,
                      pickerColor: defaultColor,
                      onColorChanged: (Color color){
                        setState(() {
                          //cm[i-1] = color;
                          for(int a=0; a<colormap.length; a++){
                            if(colormap[a] == color){
                              Color tmp = colormap[i-1];
                              colormap[i-1] = colormap[a];
                              colormap[a] = tmp;
                            }
                          }
                        }
                        );
                        Navigator.of(context).pop();
                      })
              )));
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
          decoration: TfDecorationModel(
            context: context,
              title: 'Member $i',
              icon: IconButton(icon: const Icon(Icons.color_lens), color: colormap[i-1], onPressed: () { _colorPicker(i); })
          )
      ),
    );
  }
}