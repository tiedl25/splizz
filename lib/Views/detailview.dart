import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'dart:math';

import 'package:splizz/Dialogs/payoffdialog.dart';
import 'package:splizz/Dialogs/transactiondialog.dart';
import 'package:splizz/Dialogs/sharedialog.dart';
import 'package:splizz/Models/transaction.dart';
import 'package:splizz/Helper/database.dart';
import 'package:splizz/Helper/ui_model.dart';
import 'package:splizz/Models/item.dart';
import 'package:splizz/Models/member.dart';

class DetailView extends StatefulWidget{
  final Item item;
  const DetailView({Key? key, required this.item}) : super(key:key);

  @override
  State<StatefulWidget> createState() => _DetailViewState();
}

class _DetailViewState extends State<DetailView>{
  late Item item;
  bool unbalanced = false;
  bool first = true;

  // Important to grey out payoff button
  bool _checkBalances(){
    for(var m in item.members){
      if(m.balance > 1e-6 || m.balance < -1e-6){//!= 0){
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
        return TransactionDialog(item: item, updateItem: (data) => setState(() => item = data));
      },
    );
  }

  void _showShareDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return item.sharedId=='' ? ShareDialog(item: item, setParentState: setState) : ManageDialog(item: item, setParentState: setState);
      },
    );
  }
  
  //Custom Widgets

  List<Container> memberBar(){
    return List.generate(
        item.members.length,
        (index) {
          Member m = item.members[index];
          Color textColor = m.color.computeLuminance() > 0.2 ? Colors.black : Colors.white;

          return Container(
              foregroundDecoration: !m.active ? const BoxDecoration(
                  color: Color(0x99000000),
                  backgroundBlendMode: BlendMode.darken,
                  borderRadius: BorderRadius.all(Radius.circular(20))
              ) : null,
              decoration: BoxDecoration(
                color: m.color,
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
                                          DatabaseHelper.instance.updateMember(m);
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
                      return PayoffDialog(item: item, setParentState: setState, updateItem: (data) => setState(() => item = data));
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
    Map <int, int> memberMap = {};

    int a=0;
    for(Member m in item.members){
      memberMap.addAll({m.id! : a});
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
              setState(() {});
              return Future(() => null);
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
                  return Container(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Payoff'),
                        Text(transaction.formatDate())
                      ],
                    ),
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

  Widget dismissibleTile(Transaction transaction, Map <int, int> memberMap, int index) {
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
                    content: const Text('Do you really want to remove this Item', style: TextStyle(fontSize: 20),),
                    onConfirmed: (){
                      setState(() {
                         if (item.deleteTransaction(transaction, memberMap, index)){
                          DatabaseHelper.instance.update(item);
                         } else {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not delete transaction. Please try again')));
                         }
                        //List transactionMemberList = transaction.operations.map((e) => e.memberId).toList();
                        //List<Member> memberList = item.members.where((element) => transactionMemberList.contains(element.id)).toList();
                        //transaction.memberId = item.members.indexWhere((element) => element.id == transaction.memberId);
                        //item.deleteTransactionFromOperations(transaction, memberList);
                        
                        //DatabaseHelper.instance.deleteTransaction(transaction, item.id!);
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

  Widget expansionTile(Transaction transaction, Map <int, int> memberMap){
    Color color = item.members[memberMap[transaction.memberId]!].color;
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
          /*ListTile(
            title: Text(item.members[memberMap[transaction.memberId]!].name, style: const TextStyle(color: Colors.black),),
            subtitle: Text(transaction.date(), style: const TextStyle(color: Colors.black),),
          ),*/
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
                              color: m.color,
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

  Future<Item> getItem(String sharedId) async {
    
    if (sharedId == '' || first==true){
      item = await DatabaseHelper.instance.getItem(item.id!);
      if (first && sharedId != '') setState(() {});
      first = false;
    } else {
      item = await DatabaseHelper.instance.itemSync(item);
    }

    return item;
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
            future: getItem(item.sharedId),
            builder: (BuildContext context, AsyncSnapshot<Item> snapshot) {
              if (!snapshot.hasData && first) {
                return const Center(child: CircularProgressIndicator(),);
              } else {
                if (snapshot.hasData) {
                  item = snapshot.data!;
                  unbalanced = _checkBalances();
                }
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
    item = widget.item;

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
              List<int> involvedMembers = List.generate(item.members.length, (index) => index);
              List<int> involvedDbMembers = item.members.map((e) => e.id!).toList();
              setState(() {
                Transaction t = Transaction('test', 23.45, DateTime.now(), memberId: item.members[memberListIndex].id , itemId: item.id);
                item.addTransaction(memberListIndex, t, involvedMembers, involvedDbMembers);
              });
                
              DatabaseHelper.instance.update(item);
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