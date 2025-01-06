import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:splizz/Helper/database.dart';
import 'package:splizz/Helper/result.dart';
import 'package:splizz/Views/authview.dart';
import 'package:splizz/bloc/detailview_bloc.dart';
import 'package:splizz/ui/views/detailview.dart';
import 'package:splizz/models/item.model.dart';
import 'package:splizz/Views/settingsview.dart';

import 'package:splizz/Dialogs/itemdialog.dart';
import 'package:splizz/Helper/colormap.dart';
import 'package:splizz/Helper/ui_model.dart';
import 'package:splizz/models/member.model.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';

var activeSession = Supabase.instance.client.auth.currentSession;

class SplashView extends StatelessWidget {
  final Function updateTheme;
  final SharedPreferences prefs;

  const SplashView({
    super.key,
    required this.updateTheme,
    required this.prefs,
    });

  @override
  Widget build(BuildContext context) {
    activeSession = Supabase.instance.client.auth.currentSession;
    return Scaffold(
      body: Center(child: activeSession == null && prefs.getBool('offline') == false ? AuthView(prefs: prefs) : MasterView(updateTheme: updateTheme, prefs: prefs,)),
    );
  }
}

class MasterView extends StatefulWidget{
  final Function updateTheme;
  final SharedPreferences prefs;

  const MasterView({
    super.key,
    required this.updateTheme,
    required this.prefs,
  });

  @override
  State<StatefulWidget> createState() => _MasterViewState();
}


class _MasterViewState extends State<MasterView>{
  List<Item> items = [];
  late Future<List<Item>> itemListFuture;
  bool removeDriveFile = false;
  late PackageInfo packageInfo;
  final appLinks = AppLinks();

  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    if (activeSession == null && widget.prefs.getBool('offline') == false) {
      Navigator.pushReplacementNamed(context, '/auth');
    }

    DatabaseHelper.instance.destructiveSync();
    
    itemListFuture = DatabaseHelper.instance.getItems();

    PackageInfo.fromPlatform().then((value) => packageInfo = value);

    _handleIncomingLinks();
  }



  void _handleIncomingLinks() {
    _sub = appLinks.uriLinkStream.listen((Uri? uri) async {
      if (uri != null) {
        final permissionId = uri.queryParameters['id'];

        if (permissionId != null) {
          showDialog(
            context: context, builder: (BuildContext context){
              return DialogModel(
                content: Text('You are invited to a Splizz. Do you want to join?', style: TextStyle(fontSize: 20),), 
                onConfirmed: () async {
                  final Result result = await DatabaseHelper.instance.confirmPermission(permissionId);
                  if (!result.isSuccess){
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message!)));
                  }
                }
              );
            },
          );
        }
      }
    }, onError: (err) {
      print('Error occurred: $err');
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }





  Future<Item> addDebugItem(members) async {
    ByteData data = await rootBundle.load('images/image_${Random().nextInt(9)+1}.jpg');
    final imageBytes = data.buffer.asUint8List();
    Item newItem = Item(name: 'Test ${Random().nextInt(9999)}', members: members, image: imageBytes);

    for (Member m in members){
      m.itemId = newItem.id;
    }

    DatabaseHelper.instance.upsertItem(newItem);

    return newItem;
  }

  //Dialogs

  void _showAddDialog(){
    showDialog(
      context: context,
      barrierDismissible: true, // user must tap button!
      builder: (BuildContext context){
        return ItemDialog(items: items, updateItemList: (item) => setState(() => items.add(item)));
      }
    );
  }

  Future<bool?> _showDismissDialog() {
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
                ],
              ),
              onConfirmed: () {}
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
          return SettingsView(updateTheme: widget.updateTheme, version: packageInfo.version, prefs: widget.prefs,);
        },
      ),
    );
  }

  Future<void> _pushDetailView(Item i) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context){
        return BlocProvider(
          create: (context) => DetailViewBloc(i)..fetchData(),
          child: DetailView(item: i,));
        },
      ),
    );
  }

  Widget dismissTile(Item item) {
    //removeDriveFile = item.owner;

    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      decoration: const BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: Dismissible(
        key: UniqueKey(),
        direction: DismissDirection.endToStart,
        onDismissed: (dismissDirection) async {
          DatabaseHelper.instance.deleteItem(item).then((value) => setState(() {
            items.remove(item);
          }));
        },
        confirmDismiss: (direction){
          return _showDismissDialog();
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
        borderRadius: const BorderRadius.all(Radius.circular(20)),
      ),
      child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
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
    return kDebugMode ? SpeedDial(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
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
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add),
          onTap: _showAddDialog,
        ),
        SpeedDialChild(
          child: const Icon(Icons.bug_report),
          onTap: () {
            List<Member> members = [];
            for(int i=0; i<Random().nextInt(6)+2; ++i){
              members.add(Member(name: names[Random().nextInt(100)], color: colormap[Random().nextInt(16)].value));
            }
            addDebugItem(members).then((item) => setState(() {items.add(item);}));
          }
        ),
        SpeedDialChild(
          child: const Icon(Icons.remove),
          onTap: () {
            for(int i=0; i<items.length; ++i){
              DatabaseHelper.instance.deleteItem(items[i]).then((value) => setState(() {
                itemListFuture = DatabaseHelper.instance.getItems();
              }));
            }
            setState(() {
              items = [];
            });
          }
        ),
        // add more options as needed
      ],
    ) : FloatingActionButton(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        onPressed: _showAddDialog,
        tooltip: 'Add Transaction',
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
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