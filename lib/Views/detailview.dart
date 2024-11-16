import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'dart:math';

import 'package:splizz/Dialogs/payoffdialog.dart';
import 'package:splizz/Dialogs/transactiondialog.dart';
import 'package:splizz/Helper/database.dart';
import 'package:splizz/models/transaction.model.dart';
import 'package:splizz/Helper/ui_model.dart';
import 'package:splizz/models/item.model.dart';
import 'package:splizz/models/member.model.dart';

class DetailView extends StatefulWidget{
  final Item item;
  const DetailView({Key? key, required this.item}) : super(key:key);

  @override
  State<StatefulWidget> createState() => _DetailViewState();
}

class _DetailViewState extends State<DetailView>{
  late Item item;
  late List<Member> members;

  bool unbalanced = false;
  late Future<Item> itemFuture;

  Future<Item> getData() async {
    item.members = await DatabaseHelper.instance.getMembers(item.id);
    item.history = await DatabaseHelper.instance.getTransactions(item.id);

    return item;
  }

  @override
  void initState() {
    super.initState();

    item = widget.item;

    itemFuture = getData();
    
    //itemFuture = DatabaseHelper.instance.getItem(item.id!).then((item) {
    //  setState(() {
    //    itemFuture = syncItem(item);
    //  });
    //  return item;
    //});
  }

  //Future<Item> syncItem(Item item) async {
  //  try{
  //    Item i = await DatabaseHelper.instance.itemSync(item);
  //    return i;
  //  }catch(e){
  //    if (e is gd.DetailedApiRequestError && e.status == 404) {
  //      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(duration: Duration(seconds: 1), content: Text('Item not found in GoogleDrive')));
  //      Future.delayed(const Duration(seconds: 1)).then((_) => _showNotFoundDialog());
  //    } else {
  //      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item sync failed')));
  //    }
  //  }finally{
  //    return item;
  //  }
  //}

  // Important to grey out payoff button
  bool _checkBalances(){
    for(var m in item.members){
      if(m.balance > 1e-6 || m.balance < -1e-6){
        return true;
      }
    }
    return false;
  }

  // Show Dialog Methods

  void _showAddDialog() {
    showDialog(
      context: context, barrierDismissible: true, // user must tap button!
      builder: (BuildContext context) {
        return TransactionDialog(item: item, updateItem: (data) => setState((){item = data;}));
      },
    );
  }

  void _showShareDialog() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not Implemented')));

    //showDialog(
    //  context: context,
    //  builder: (BuildContext context) {
    //    return item.sharedId=='' ? ShareDialog(item: item) : ManageDialog(item: item);
    //  },
    //);
  }

  void _showPastPayoffDialog(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return PastPayoffDialog(item: item, index: index,);
      },
    );
  }
  
  //void _showNotFoundDialog() {
  //  showDialog(
  //    context: context,
  //    builder: (BuildContext context) {
  //      return NotFoundDialog(item: item);
  //    },
  //  ).then((value) {
  //    if(value) Navigator.of(context).pop();
  //    }
  //  );
  //}
  
  //Custom Widgets

  List<Container> memberBar(){
    return List.generate(
        item.members.length,
        (index) {
          Member m = item.members[index];
          Color textColor = Color(m.color).computeLuminance() > 0.2 ? Colors.black : Colors.white;

          return Container(
              foregroundDecoration: !m.active ? const BoxDecoration(
                  color: Color(0x99000000),
                  backgroundBlendMode: BlendMode.darken,
                  borderRadius: BorderRadius.all(Radius.circular(20))
              ) : null,
              decoration: BoxDecoration(
                color: Color(m.color),
                border: Border.all(style: BorderStyle.none, width: 0),
                borderRadius: const BorderRadius.all(Radius.circular(20)),
              ),
              margin: const EdgeInsets.all(2),
              child: IntrinsicWidth(
                child: GestureDetector(
                  onTap: (){
                    showDialog(context: context, builder: (BuildContext context){
                      final Function setParentState = setState;
                      return StatefulBuilder(builder: (context, setState){
                        return DialogModel(
                            content: SizedBox(
                              width: MediaQuery.of(context).size.width,
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(15),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text('Name'),
                                          Text(m.name)
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(15),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text('Total'),
                                          Text(m.total.toString())
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(15),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text('Balance'),
                                          Text(m.balance.toString())
                                        ],
                                      ),
                                    ),
                                    SwitchListTile(
                                      title: const Text("Active"),
                                      value: m.active,
                                      onChanged: (bool value) {
                                        setState(() {
                                          m = Member.fromMember(m, active: value, timestamp: DateTime.now());
                                          DatabaseHelper.instance.upsertMember(m);
                                          //DatabaseHelper.instance.updateMember(m);
                                          setParentState((){});
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        );
                      });
                    });
                  },
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(m.name, style: TextStyle(fontSize: 20, color: textColor),),
                      ),
                      Container(
                        decoration: const BoxDecoration(
                            color: Color(0xAAD5D5D5),
                            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20))
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                                m.balance >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                                color: m.balance >= 0 ? Colors.green[700] : Colors.red[700]),
                            Text(
                                '${m.balance.abs().toStringAsFixed(2)}€',
                                style: TextStyle(fontSize: 20, color: m.balance >= 0 ? Colors.green[700] : Colors.red[700])),
                          ],
                        ),
                      )
                    ],
                  ),
                )
              )
          );
        }
    );
  }

  Widget payoffButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
              'Transactions',
              style: TextStyle(fontSize: 30),
              textAlign: TextAlign.center
            ),
          Container(
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: unbalanced ? Colors.green : Theme.of(context).colorScheme.surface
            ),
            child: IconButton(
              splashRadius: 25,
              onPressed: (){
                if(unbalanced){
                  showDialog(
                    context: context, barrierDismissible: true, // user must tap button!
                    builder: (BuildContext context) {
                      return PayoffDialog(item: item, updateItem: (data) => setState(() => item = data));
                    },
                  );
                }
              },
              icon: const Icon(Icons.handshake, color: Colors.white,)
            ),
          )
        ],
      ),
    );
  }

  Widget transactionList() {
    Map <String, int> memberMap = {};

    int a=0;
    for(Member m in item.members){
      memberMap.addAll({m.id : a});
      a++;
    }

    return Expanded(
      flex: 50,
      child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border.all(style: BorderStyle.none),
            borderRadius: const BorderRadius.all(Radius.circular(15)),
          ),
          margin: const EdgeInsets.all(10),
          child: RefreshIndicator(
            onRefresh: (){
              setState(() {
                getData();
              });
              return itemFuture;
            },
            child: item.history.isEmpty ?
            ListView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              padding: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.height/4),
              children: const [Center(child: Text("No transactions in list", style: TextStyle(fontSize: 20),),),]
            ) :
            ListView.builder(
              padding: const EdgeInsets.all(10),
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              shrinkWrap: false,
              itemCount: item.history.length,
              itemBuilder: (context, i) {
                Transaction transaction = item.history[item.history.length-1-i];
                if (transaction.description == 'payoff'){
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _showPastPayoffDialog(item.history.length-i-1), 
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Payoff'),
                          Text(transaction.formatDate())
                        ],
                      ),
                    )
                  );
                } else {
                  return transaction.deleted ?
                  Container(
                    margin: const EdgeInsets.only(bottom: 5),
                    child: expansionTile(transaction, memberMap),
                  ) :
                  dismissibleTile(transaction, memberMap, i);
                }
              },
            ),
          )
      ),
    );
  }

  Widget dismissibleTile(Transaction transaction, Map <String, int> memberMap, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(15)),
        color: Colors.red,
      ),
      child: Dismissible(
          key: UniqueKey(),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction){
            return showDialog(
              context: context,
              builder: (BuildContext context) {
                return DialogModel(
                    title: 'Confirm Dismiss',
                    content: const Text('Do you really want to remove this Transaction', style: TextStyle(fontSize: 20),),
                    onConfirmed: (){
                      setState(() {
                        item.deleteTransaction(transaction, memberMap, index);
                        DatabaseHelper.instance.upsertTransaction(transaction);
                      });
                    }
                );
              },
            );
          },
          background: Container(
            padding: const EdgeInsets.only(right: 20),
            alignment: Alignment.centerRight,
            child: const Icon(
              Icons.delete,
            ),
          ),
          child: expansionTile(transaction, memberMap)
      ),
    );
  }

  Widget expansionTile(Transaction transaction, Map <String, int> memberMap){
    Color color = Color(item.members[memberMap[transaction.memberId]!].color);
    Color textColor = color.computeLuminance() > 0.2 ? Colors.black : Colors.white;

    return Container(
      foregroundDecoration: transaction.deleted ? const BoxDecoration(
          color: Color(0x99000000),
          backgroundBlendMode: BlendMode.darken,
          borderRadius: BorderRadius.all(Radius.circular(15))
      ) : null,
      decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.all(Radius.circular(15))
      ),
      child: ExpansionTile(
        //expandedCrossAxisAlignment: CrossAxisAlignment.start,
        expandedAlignment: Alignment.centerLeft,
        shape: const Border(),
        collapsedIconColor: Colors.black,
        iconColor: Colors.black,
        tilePadding: const EdgeInsets.symmetric(horizontal: 15),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 15),
        title: Text(transaction.description, style: TextStyle(color: textColor),),
        subtitle: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${transaction.value.toString()}€', style: TextStyle(
                decoration: transaction.deleted ? TextDecoration.lineThrough : null,
                color: textColor),
            ),
            Text(transaction.formatDate(), style: TextStyle(color: textColor),)
          ],
        ),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Container(
                  padding: const EdgeInsets.all(5),
                  margin: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: const Color(0xAAD5D5D5),
                    border: Border.all(style: BorderStyle.none, width: 0),
                    borderRadius: const BorderRadius.all(Radius.circular(20)),
                  ),
                  child: Row(
                    children: List.generate(
                        transaction.operations.length,
                            (index) {
                          if(index==0){
                            return Container(
                              padding: const EdgeInsets.only(right: 20, left: 5, top: 5, bottom: 5),
                              margin: const EdgeInsets.all(2),
                              child:Text(item.members[memberMap[transaction.memberId]!].name, style: const TextStyle(color: Colors.black),),
                            );
                          }
                          // if payer is not in involved in transactions except for paying
                          if(transaction.value == transaction.operations[index-1].value){
                            return Container();
                          }
                          Member m = item.members.firstWhere((Member m) => m.id == transaction.operations[index-1].memberId );
                          return Container(
                            padding: const EdgeInsets.all(5),
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Color(m.color),
                              border: Border.all(style: BorderStyle.none, width: 0),
                              borderRadius: const BorderRadius.all(Radius.circular(20)),
                            ),
                            child: Text(m.name, style: const TextStyle(color: Colors.black),),
                          );
                        }),
                  ),
                ),
          )
        ],
      ),
    );
  }

  Widget body() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20)),
              child: Image.memory(
                  item.image!,
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height/5,
                  fit: BoxFit.fill
              ),
            ),
            const Spacer(),
          ]
        ),
        FutureBuilder<Item>(
            future: itemFuture,
            builder: (BuildContext context, AsyncSnapshot<Item> snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator(),);
              } else {
                item = snapshot.data!;
                unbalanced = _checkBalances();

                return Expanded(
                  child: Column(                 
                  children: [
                    const Spacer(),
                    SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: memberBar(),
                        ),
                    ),
                    const Spacer(flex: 2,),
                    payoffButton(),
                    const Spacer(),
                    transactionList(),
                  ],
                )
                );
              }

            }
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.black26,
        title: Text(item.name),
        actions: [
          IconButton(
              onPressed: _showShareDialog,
              icon: const Icon(Icons.share)
          ),
        ],
      ),
      body: body(),
      floatingActionButton: kDebugMode ? SpeedDial(
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
            child: const Icon(Icons.bug_report),
            onTap: () async {
              int memberListIndex = Random().nextInt(item.members.length);
              //List<int> involvedMembers = List.generate(item.members.length, (index) => index);
              List<Map<String, dynamic>> involvedMembers = item.members.asMap().entries.map((entry) {
                int index = entry.key;  // This is the index
                var e = entry.value;    // This is the item at that index
                return {'listId': index, 'id': e.id, 'balance': double.parse((22.00/item.members.length).toStringAsFixed(2))};
              }).toList();
              setState(() {
                Transaction t = Transaction(description: 'test', value: 22.00, date: DateTime.now(), memberId: item.members[memberListIndex].id , itemId: item.id);
                item.addTransaction(memberListIndex, t, involvedMembers);
                DatabaseHelper.instance.upsertTransaction(t);
              });
                
              //DatabaseHelper.instance.update(item);
            }
          ),
          // add more options as needed
        ],
      ) : FloatingActionButton(
        onPressed: _showAddDialog,
        tooltip: 'Add Transaction',
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),

    );
  }
}