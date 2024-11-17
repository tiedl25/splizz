import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:splizz/Helper/database.dart';
import 'package:splizz/Views/detailview.dart';
import 'package:splizz/brick/repository.dart';
import 'package:splizz/models/item.model.dart';
import 'package:splizz/Views/settingsview.dart';

import 'package:splizz/Dialogs/itemdialog.dart';
import 'package:splizz/Helper/colormap.dart';
import 'package:splizz/Helper/ui_model.dart';
import 'package:splizz/models/member.model.dart';

import 'package:brick_core/query.dart';
import 'package:splizz/models/operation.model.dart';
import 'package:splizz/models/transaction.model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;
final activeSession = supabase.auth.currentSession;

class MasterView extends StatefulWidget{
  final Function updateTheme;

  const MasterView({
    super.key,
    required this.updateTheme,
  });

  @override
  State<StatefulWidget> createState() => _MasterViewState();
}


class _MasterViewState extends State<MasterView>{
  List<Item> items = [];
  late Future<List<Item>> itemListFuture;
  bool removeDriveFile = false;
  late PackageInfo packageInfo;

  @override
  void initState() {
    super.initState();
    if (activeSession == null) {
      Navigator.pushNamed(context, '/auth');
    }

    itemListFuture = DatabaseHelper.instance.getItems();
    //DatabaseHelper.instance.getItems();
    PackageInfo.fromPlatform().then((value) => packageInfo = value);
  }

  Future<void> addDebugItem(members) async {
    ByteData data = await rootBundle.load('images/image_${Random().nextInt(6)+1}.jpg');
    final imageBytes = data.buffer.asUint8List();
    Item newItem = Item(name: 'Test ${Random().nextInt(9999)}', members: members, image: imageBytes);

    for (Member m in members){
      m.itemId = newItem.id;
    }

    DatabaseHelper.instance.upsertItem(newItem);

    setState(() {
      items.add(newItem);
    });
  }

  //Dialogs

  void _showAddDialog(){
    showDialog(
        context: context,
        barrierDismissible: true, // user must tap button!
        builder: (BuildContext context){
          return ItemDialog(items: items, updateItemList: (item) => setState(() => items.add(item)));
        });
  }

  void _showImportDialog(){
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not complete payoff. Please try again')));
    //showDialog(
    //    context: context,
    //    barrierDismissible: true,
    //    builder: (BuildContext context){
    //      return ImportDialog();
    //    });
  }

  Future<bool?> _showDismissDialog(String sharedId) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
            builder: (context, setState){
              return DialogModel(
                  title: 'Confirm Dismiss',
                  content: Column(
                    children: [
                      Container(
                          padding: const EdgeInsets.all(5),
                          child: const Text('Do you really want to remove this Item', style: TextStyle(fontSize: 20),),
                      ),

                      //if(sharedId != '') Container(
                      //  padding: const EdgeInsets.all(5),
                      //  child: Row(
                      //    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      //    children: [
                      //      const Text('Remove file in Google Drive'),
                      //      Switch(
                      //          value: removeDriveFile,
                      //          onChanged: (value){
                      //            setState((){
                      //              removeDriveFile = value;
                      //            });
                      //          })
                      //    ],
                      //  ),
                      //)
                    ],
                  ),
                  onConfirmed: (){}
              );
            }
        );
      },
    );
  }

  //Navigation

  void _pushSettingsView(){
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context){
          return SettingsView(updateTheme: widget.updateTheme, version: packageInfo.version);
        },
      ),
    );
  }

  Future<void> _pushDetailView(Item i) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context){
        return DetailView(item: i,);
        },
      ),
    );
    itemListFuture = DatabaseHelper.instance.getItems();
    //DatabaseHelper.instance.getItems();
    setState(() {
      
    });
  }

  Future<void> deleteItem(Item i) async {
    final memberQuery = Query(where: [Where('itemId').isExactly(i.id)]);
    final members = await Repository.instance.get<Member>(query: memberQuery);

    final transactionQuery = Query(where: [Where('itemId').isExactly(i.id)]);
    final transactions = await Repository.instance.get<Transaction>(query: transactionQuery);

    final operationQuery = Query(where: [Where('itemId').isExactly(i.id)]);
    final operations = await Repository.instance.get<Operation>(query: operationQuery);

    for(Operation o in operations){
      await DatabaseHelper.instance.deleteOperation(o);
    }
    for(Transaction t in transactions){
      await DatabaseHelper.instance.deleteTransaction(t);
    }
    for(Member m in members){
      await DatabaseHelper.instance.deleteMember(m);
    }

    await DatabaseHelper.instance.deleteImage(i.id);
    
    await DatabaseHelper.instance.deleteItem(i);

    await DatabaseHelper.instance.deleteUser(i.id);
  }

  Widget dismissTile(Item item) {
    //removeDriveFile = item.owner;

    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      decoration: const BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.all(Radius.circular(15)),
      ),
      child: Dismissible(
        key: UniqueKey(),
        direction: DismissDirection.endToStart,
        onDismissed: (dismissDirection) async {
          setState(() {

            deleteItem(item).then((value) => setState(() {
              itemListFuture = DatabaseHelper.instance.getItems();
              //DatabaseHelper.instance.getItems();
            }));
            //if(item.sharedId != '' && removeDriveFile && item.owner){
            //  GoogleDrive.instance.deleteFile(item.sharedId);
            //  GoogleDrive.instance.deleteFile(item.imageSharedId);
            //}
          });
        },
        confirmDismiss: (direction){
          return _showDismissDialog("");
        },
        background: Container(
          padding: const EdgeInsets.only(right: 20),
          alignment: Alignment.centerRight,
          child: const Icon(
            Icons.delete,
          ),
        ),
        child: itemTile(item),
      ),
    );
  }

  Widget itemTile(Item item) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(style: BorderStyle.none),
        borderRadius: const BorderRadius.all(Radius.circular(15)),
      ),
      child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(15)),
          ),
          tileColor: Theme.of(context).colorScheme.surface,
          title: Text(item.name, style: const TextStyle(fontSize: 20),),
          onTap: () {
            _pushDetailView(item);
          },
      ),
    );
  }

  Widget speedDial() {
    return SpeedDial(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
      spacing: 5,
      animatedIcon: AnimatedIcons.menu_close,
      animatedIconTheme: const IconThemeData(size: 22.0),
      foregroundColor: Colors.white,
      curve: Curves.bounceIn,
      overlayColor: Colors.black,
      overlayOpacity: 0.5,
      children: [
        SpeedDialChild(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(15)),
          ),
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add),
          onTap: _showAddDialog,
        ),
        SpeedDialChild(
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
          child: const Icon(Icons.import_export),
          onTap: _showImportDialog,
        ),
        if(kDebugMode) SpeedDialChild(
          child: const Icon(Icons.bug_report),
          onTap: () async {
            List<Member> members = [];
            for(int i=0; i<Random().nextInt(6)+2; ++i){
              members.add(Member(name: names[Random().nextInt(100)], color: colormap[Random().nextInt(16)].value));
            }
            addDebugItem(members);
          }
        ),
        if(kDebugMode) SpeedDialChild(
          child: const Icon(Icons.remove),
          onTap: () async {
            for(int i=0; i<items.length; ++i){
              DatabaseHelper.instance.deleteItem(items[i]).then((value) => setState(() {
                itemListFuture = DatabaseHelper.instance.getItems();
                //DatabaseHelper.instance.getItems();
              }));
            }
            setState(() {
              items = [];
            });
          }
        ),
        // add more options as needed
      ],
    );
  }

  Widget body() {
    return Center(
      child: FutureBuilder<List<Item>>(
        future: itemListFuture,
        builder: (BuildContext context, AsyncSnapshot<List<Item>> snapshot) {
          if (!snapshot.hasData){
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data!.isNotEmpty) {
            items = snapshot.data!;
            //items.sort((a, b) => b.date.compareTo(a.date));
          }
          return RefreshIndicator(
              child: snapshot.data!.isEmpty ?
              ListView(
                physics: const BouncingScrollPhysics(parent:AlwaysScrollableScrollPhysics()),
                padding: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.height/2.5),
                children: const [Center(child: Text('No items in list', style: TextStyle(fontSize: 20),),)],
              )
                  : ListView.builder(
                physics: const BouncingScrollPhysics(parent:AlwaysScrollableScrollPhysics()),
                padding: const EdgeInsets.all(16),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, i) {
                  return dismissTile(snapshot.data![i]);
                }
              ),
              onRefresh: (){
                setState(() {
                  itemListFuture = DatabaseHelper.instance.getItems();
                  //DatabaseHelper.instance.getItems();
                });
                return itemListFuture;
              });
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Splizz'),
        actions: [
          IconButton(
              onPressed: _pushSettingsView,
              icon: const Icon(Icons.settings
              )
          )
        ],
        systemOverlayStyle: SystemUiOverlayStyle(
          systemNavigationBarColor: Theme.of(context).colorScheme.background, // Navigation bar
        ),
      ),
      body: body(),
      floatingActionButton: speedDial(),
    );
  }
}