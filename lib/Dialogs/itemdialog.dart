import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:splizz/Helper/database.dart';
import 'package:splizz/Helper/ui_model.dart';
import 'package:splizz/Helper/colormap.dart';

import 'package:splizz/models/item.model.dart';
import 'package:splizz/models/member.model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ItemDialog extends StatefulWidget {
  final List<Item> items;
  final Function updateItemList;

  const ItemDialog({
    Key? key,
    required this.items,
    required this.updateItemList
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
  int image = 0;

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
                              decoration: TfDecorationModel(
                                  context: context,
                                  title: 'Title',
                                  icon: IconButton(onPressed: imagePicker, icon: const Icon(Icons.camera_alt, color: Colors.black45,))),
                            ),
                          );
                        }
                        return textField(i);
                      }
                  ),
                ),
              ),
            ),
            onConfirmed:  (){
              List<Member> members = [];
              for(String name in member){
                if(name != ''){
                  members.add(Member(name:name, color: colormap[members.length].value));
                }
              }
              if(title != '' && members.length > 1) {
                saveItem(members);
              }
            }
            );
  }

  Future<void> saveItem(members) async {
    ByteData data = await rootBundle.load('images/image_${image+1}.jpg');
    var imageBytes = data.buffer.asUint8List();

    Item newItem = Item(name: title, members: members, image: imageBytes);
    for (Member m in members){
      m.itemId = newItem.id;
    }

    //DatabaseHelper.instance.add(newItem);
    DatabaseHelper.instance.upsertItem(newItem);
  }

  void imagePicker(){
    showDialog(
        context: context,
        builder: (BuildContext context){
          return StatefulBuilder(
              builder: (context, setState){
                return DialogModel(
                  content: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height/3,
                      child: GridView.builder(
                        physics: const BouncingScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 200,
                          childAspectRatio: 1.5,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 20,
                        ),
                        itemCount: 6,
                        itemBuilder: (BuildContext context, int index) {
                          return GestureDetector(
                              onTap: (){
                                setState((){
                                  image = index;
                                  //Navigator.of(context).pop();
                                });
                              },
                              child: Container(
                                  decoration: BoxDecoration(
                                    border: image==index ? Border.all(color: Colors.red, width: 3) : Border.all(style: BorderStyle.none),
                                    borderRadius: const BorderRadius.all(Radius.circular(17)),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.all(Radius.circular(15)),
                                    child: Image(
                                        fit: BoxFit.cover,
                                        image: AssetImage('images/image_${index+1}.jpg')
                                    ),
                                  )
                              )
                          );
                        },
                      )
                  ),
                  onConfirmed: (){},
                );
              }
          );
        });
  }

  void colorPicker(int i){
    showDialog(
        context: context,
        builder: (BuildContext context) {
          Color defaultColor = colormap[i - 1];
          return DialogModel(
            content: SizedBox(
              width: MediaQuery.of(context).size.width,
              child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: BlockPicker(
                    availableColors: colormap,
                    pickerColor: defaultColor,
                    onColorChanged: (Color color) {
                      setState(() {
                        //cm[i-1] = color;
                        for (int a = 0; a < colormap.length; a++) {
                          if (colormap[a] == color) {
                            Color tmp = colormap[i - 1];
                            colormap[i - 1] = colormap[a];
                            colormap[a] = tmp;
                          }
                        }
                      });
                      Navigator.of(context).pop();
                    }),
              ),
            ),
            onConfirmed: null,
          );
        }
    );
  }

  Container textField(int i){
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
          decoration: TfDecorationModel(
            context: context,
              title: 'Member $i',
              icon: IconButton(icon: const Icon(Icons.color_lens), color: colormap[i-1], onPressed: () { colorPicker(i); })
          )
      ),
    );
  }
}