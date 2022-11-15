import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:splizz/Views/detailview.dart';
import 'package:splizz/Models/item.dart';
import 'package:splizz/Helper/filehandle.dart';
import 'package:splizz/Views/settingsview.dart';

import '../Dialogs/itemdialog.dart';

class MasterView extends StatefulWidget{
  const MasterView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _MasterViewState();
}


class _MasterViewState extends State<MasterView>{
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

  _showAddDialog(){
    showDialog(
        context: context,
        barrierDismissible: true, // user must tap button!
        builder: (BuildContext context){
          return ItemDialog(items: _items, setParentState: setState,);
        });
  }

  @override
  Widget build(BuildContext context) {

    setState(() {
      if(!_itemsLoaded){_items.clear(); _loadItems(); _itemsLoaded=true;}
    });

    return Scaffold(
      backgroundColor: const Color(0xFF2B2B2B),
      appBar: AppBar(
        title: const Text('Splizz'),
        actions: [
          IconButton(
              onPressed: _pushSettingsView,
              icon: const Icon(Icons.settings)
          )
        ],
        backgroundColor: Colors.transparent,
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        tooltip: 'Add Splizz',
        child: const Icon(Icons.add),
      ),
    );
  }
  Widget _buildBody() {
    return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        itemBuilder: (context, i) {
          return _buildDismissible(_items[i]);
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
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: const BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          tileColor: const Color(0xFF383838),
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
      ),
    );
  }

  void _pushSettingsView(){
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context){
          return SettingsView();
        },
      ),
    );
  }

  void _pushDetailView(Item i){
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context){
        return DetailView(item: i,);
        },
      ),
    );
  }
}