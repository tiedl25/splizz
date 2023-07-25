import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:splizz/Views/detailview.dart';
import 'package:splizz/Models/item.dart';
import 'package:splizz/Views/settingsview.dart';

import '../Dialogs/importdialog.dart';
import '../Dialogs/itemdialog.dart';
import '../Helper/database.dart';
import '../Helper/uielements.dart';

class MasterView extends StatefulWidget{
  const MasterView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _MasterViewState();
}


class _MasterViewState extends State<MasterView>{
  List<Item> items = [];

  _showAddDialog(){
    showDialog(
        context: context,
        barrierDismissible: true, // user must tap button!
        builder: (BuildContext context){
          return ItemDialog(items: items, setParentState: setState,);
        });
  }

  _showImportDialog(){
    showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context){
          return ImportDialog(setParentState: setState,);
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2B2B2B),
      appBar: AppBar(
        title: const Text('Splizz'),
        actions: [
          IconButton(
              onPressed: _pushSettingsView,
              icon: const Icon(Icons.settings
              )
          )
        ],
        backgroundColor: Colors.transparent,
      ),
      body: _buildBody(),
      floatingActionButton: SpeedDial(
        spacing: 5,
        animatedIcon: AnimatedIcons.menu_close,
        animatedIconTheme: const IconThemeData(size: 22.0),
        curve: Curves.bounceIn,
        overlayColor: Colors.black,
        overlayOpacity: 0.5,
        children: [
          SpeedDialChild(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            child: const Icon(Icons.add),
            onTap: _showAddDialog,
          ),
          SpeedDialChild(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            child: const Icon(Icons.import_export),
            onTap: _showImportDialog,
          ),
          // add more options as needed
        ],
        child: const Icon(Icons.add),
      )
    );
  }

  Widget _buildBody() {
    return Center(
      child: FutureBuilder<List<Item>>(
        future: DatabaseHelper.instance.getItems(),
        builder: (BuildContext context, AsyncSnapshot<List<Item>> snapshot) {
          if (!snapshot.hasData){
            return const Center(child: Text('Loading...', style: TextStyle(fontSize: 20, color: Colors.white),),);
          }
          return snapshot.data!.isEmpty ?
              const Center(child: Text('No items in list', style: TextStyle(fontSize: 20, color: Colors.white),),)
              : RefreshIndicator(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(parent:AlwaysScrollableScrollPhysics()),
                  padding: const EdgeInsets.all(16),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, i) {
                    return _buildDismissible(snapshot.data![i]);
                  }
              ),
              onRefresh: (){
                setState(() {

                });
                return Future(() => null);
              });
        }
      ),
    );
  }

  Widget _buildDismissible(Item item){
    return Dismissible(
      key: UniqueKey(),
      direction: DismissDirection.endToStart,
      onDismissed: (context) async {
        setState(() {
          DatabaseHelper.instance.remove(item.id!);
        });
      },
      confirmDismiss: (direction){
        return showDialog(
          context: context,
          builder: (BuildContext context) {
            return UIElements.dialog(
                title: 'Confirm Dismiss',
                content: const Text('Do you really want to remove this Item', style: TextStyle(color: Colors.white, fontSize: 20),),
                context: context,
                onConfirmed: (){}
            );
          },
        );
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          tileColor: const Color(0xFF383838),
          title: Text(item.name, style: const TextStyle(fontSize: 20, color: Colors.white),),
          onTap: () {
            _pushDetailView(item);
          },
      ),
    );
  }

  void _pushSettingsView(){
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context){
          return SettingsView(setParentState: setState);
        },
      ),
    );
  }

  _pushDetailView(Item i) {
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