import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:splizz/detailview.dart';
import 'package:splizz/item.dart';
import 'package:splizz/filehandle.dart';

import 'member.dart';

class ListGenerator extends StatefulWidget{
  const ListGenerator({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => MasterView();
}


class MasterView extends State<ListGenerator>{
  final _items = <Item>[];
  final _hearted = <Item>{};

  bool _itemsLoaded = false;

  getItem(final element) async{
    FileHandler fh = FileHandler.path(element.path);
    Item item = Item.fromJson(await fh.readJsonFile());
    setState(() {
      _items.add(item);
    });
  }

  void _loadItems() async {
    Directory dir = await getApplicationSupportDirectory();
    var li = dir.listSync(followLinks: false);
    for (var element in li) {
      getItem(element);
    }
  }

  void _showContent() {
    String title = '';
    List<String> member = [];
    int count = 2;

    showDialog(
      context: context, barrierDismissible: false, // user must tap button!

      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Create a new Splizz', style: TextStyle(color: Colors.white),),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
          backgroundColor: const Color(0xFF2B2B2B),
          content: SingleChildScrollView(
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height/4,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StatefulBuilder(builder: (context, setState) {
                    return SizedBox(
                        height: MediaQuery.of(context).size.height/4,
                        child: ListView.builder(
                            itemCount: count,
                            itemBuilder: (context, i) {
                              if(i == 0) {
                                return TextField(
                                  onChanged: (value) {
                                    setState(() {
                                      title = value;
                                    });
                                  },
                                  decoration: const InputDecoration(
                                      hintText: 'Enter a Title',
                                      hintStyle: TextStyle(color: Colors.white),
                                      labelStyle: TextStyle(color: Colors.white),
                                      enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(color: Colors.white)
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(color: Colors.white)
                                      ),
                                      errorBorder: OutlineInputBorder(
                                          borderSide: BorderSide(color: Colors.red)
                                      )
                                  ),
                                );
                              }
                              else if(i == 1) {
                                return TextField(
                                  onChanged: (name) {
                                    setState(() {
                                      if(member.length < i){
                                        member.add(name);
                                      }
                                      else{
                                        member[i-1] = name;
                                      }
                                      if (count <= member.length+1){
                                        count++;
                                      }
                                    });
                                  },
                                  decoration: const InputDecoration(
                                      hintText: 'Enter the name of a member',
                                      hintStyle: TextStyle(color: Colors.white),
                                      labelStyle: TextStyle(color: Colors.white),
                                      enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(color: Colors.white)
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(color: Colors.white)
                                      ),
                                      errorBorder: OutlineInputBorder(
                                          borderSide: BorderSide(color: Colors.red)
                                      )
                                  ),
                                );
                              }
                              return Dismissible(
                                  key: ValueKey(i),
                                  direction: DismissDirection.endToStart,
                                  onDismissed: (context){
                                    count--;
                                    member.removeAt(i);
                                  },
                                  child: TextField(
                                    onChanged: (name) {
                                      setState((){
                                        if(member.length < i) {
                                          member.add(name);
                                        } else {
                                          member[i-1] = name;
                                        }
                                        if (count <= member.length+1 && count<=18){
                                          count++;
                                        }

                                      });

                                    },
                                    decoration: const InputDecoration(
                                        hintText: 'Enter the name of a member',
                                        hintStyle: TextStyle(color: Colors.white),
                                        labelStyle: TextStyle(color: Colors.white),
                                        enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(color: Colors.white)
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(color: Colors.white)
                                        ),
                                        errorBorder: OutlineInputBorder(
                                            borderSide: BorderSide(color: Colors.red)
                                        )
                                    ),
                                  )
                              );
                            }
                        )
                    );
                  })
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Dismiss')
            ),
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                  List<Member> members = [];
                  for(String name in member){
                    if(name != ''){
                      members.add(Member(name, members.length));
                    }
                  }

                  if(title != '' && members.length > 1) {
                    setState(() {
                      Item newItem = Item(title, members);
                      _items.add(newItem);
                      FileHandler fh = FileHandler('item_${newItem.id}');
                      fh.writeJsonFile(newItem);
                      Navigator.pop(context);
                    });
                  }
                }
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    setState(() {
      if(!_itemsLoaded){_loadItems(); _itemsLoaded=true;}
    });


    return Scaffold(
      backgroundColor: const Color(0xFF2B2B2B),
      appBar: AppBar(
        title: const Text('Splizz'),
        backgroundColor: Colors.transparent,
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showContent,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
  Widget _buildBody() {
    return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length*2,
        itemBuilder: (context, i) {
          if(i.isOdd){
            return const Divider();
          }
          return _buildDismissible(_items[i ~/ 2]);
        }
    );
  }

  Widget _buildDismissible(Item item){
    return Dismissible(
      key: UniqueKey(),
      direction: DismissDirection.endToStart,
      onDismissed: (context) async {
        Directory dir = await getApplicationSupportDirectory();
        setState(() {
          _items.remove(item);
          FileHandler fh = FileHandler.path('${dir.path}/item_${item.id}.json');
          fh.deleteFile();
        });
      },
      background: Container(
        color: Colors.red,
        margin: const EdgeInsets.symmetric(horizontal: 15),
        alignment: Alignment.centerRight,
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      child: _buildRow(item),
    );
  }

  Widget _buildRow(Item item) {
    final markedFav = _hearted.contains(item);
    return ListTile(
        title: Text(item.name, style: const TextStyle(fontSize: 20, color: Colors.white),),
        trailing: Icon(
          markedFav ? Icons.favorite : Icons.favorite_border,
          color: markedFav ? Colors.red : null,
        ),
        onTap: () {
          _pushDetailView(item);
        },
        onLongPress: () {
          setState(() {
            markedFav ? _hearted.remove(item) : _hearted.add(item);
          });
        }
    );
  }

  void _pushDetailView(Item i){
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context){
        return ViewGenerator(item: i,);
        },
      ),
    );
  }
}