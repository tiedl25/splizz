import 'package:flutter/material.dart';
import 'package:splizz/Dialogs/payoffdialog.dart';
import 'package:splizz/Dialogs/transactiondialog.dart';
import 'package:splizz/Dialogs/sharedialog.dart';
import 'package:splizz/Models/transaction.dart';
import '../Helper/database.dart';
import '../Helper/ui_model.dart';
import '../Models/item.dart';
import '../Models/member.dart';

class DetailView extends StatefulWidget{
  final Item item;
  const DetailView({Key? key, required this.item}) : super(key:key);

  @override
  State<StatefulWidget> createState() => _DetailViewState();
}

class _DetailViewState extends State<DetailView>{
  late Item item;
  bool unbalanced = false;
  bool synced = false;

  List<Container> memberBar = <Container>[];
  List<ListTile> historyList = <ListTile>[];

  List<Container> _buildMemberBar(){
    List<Container> li = <Container>[];
    for (var element in item.members) {
      li.add(
          Container(
            decoration: BoxDecoration(
              color: element.color,
              border: Border.all(style: BorderStyle.none, width: 0),
              borderRadius: const BorderRadius.all(Radius.circular(20)),
            ),
            margin: const EdgeInsets.all(2),
            child: IntrinsicWidth(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(element.name, style: const TextStyle(fontSize: 20, color: Colors.black),),
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
                            element.balance >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                            color: element.balance >= 0 ? Colors.green[700] : Colors.red[700]),
                        Text(
                            '${element.balance.abs().toStringAsFixed(2)}€',
                            style: TextStyle(fontSize: 20, color: element.balance >= 0 ? Colors.green[700] : Colors.red[700])),
                      ],
                    ),
                  )

                ],
              ),
            )
          )
      );
    }
    return li;
  }

  Widget _payoffButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
              'Transactions',
              style: TextStyle(fontSize: 30, color: Colors.white),
              textAlign: TextAlign.center
            ),
          Container(
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: unbalanced ? Colors.green : const Color(0x00000000)
            ),
            child: IconButton(
              splashRadius: 25,
              onPressed: (){
                if(unbalanced){
                  showDialog(
                    context: context, barrierDismissible: true, // user must tap button!
                    builder: (BuildContext context) {
                      return PayoffDialog(item: item, setParentState: setState);
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

  void _showAddDialog() {
    showDialog(
      context: context, barrierDismissible: true, // user must tap button!
      builder: (BuildContext context) {
        return TransactionDialog(item: item, setParentState: setState);
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

  Widget _transactionList() {
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
          margin: const EdgeInsets.all(5),
            child: RefreshIndicator(
              onRefresh: (){
                setState(() {

                });
                return Future(() => null);
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(10),
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                shrinkWrap: true,
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
                          Text(transaction.date())
                        ],
                      ),
                    );
                  } else {
                    return transaction.deleted ?
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      child: _expansionTile(transaction, memberMap),
                    ) :
                    _dismissibleTile(transaction, memberMap);
                  }

                },
              ),
            )
      ),
    );
  }

  Widget _dismissibleTile(Transaction transaction, Map <int, int> memberMap) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
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
                        // Todo item.deleteTransaction(memberMap[transaction.memberId]!, transaction);
                        transaction.delete();
                        DatabaseHelper.instance.deleteTransaction(transaction, item.id!);
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
          child: _expansionTile(transaction, memberMap)
      ),
    );
  }

  Widget _expansionTile(Transaction transaction, Map <int, int> memberMap){
    return Container(
      foregroundDecoration: transaction.deleted ? const BoxDecoration(
          color: Color(0x99000000),
          backgroundBlendMode: BlendMode.darken,
          borderRadius: BorderRadius.all(Radius.circular(15))
      ) : null,
      decoration: BoxDecoration(
          color: item.members[memberMap[transaction.memberId]!].color,
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
        title: Text(transaction.description, style: const TextStyle(color: Colors.black),),
        subtitle: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${transaction.value.toString()}€', style: TextStyle(
                decoration: transaction.deleted ? TextDecoration.lineThrough : null,
                color: Colors.black),
            ),
            Text(transaction.date(), style: const TextStyle(color: Colors.black),)
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
                          Member m = item.members.singleWhere((Member m) => m.id == transaction.operations[index-1].memberId );
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

  Widget _buildBody() {
    return Center(
      child: FutureBuilder<Item>(
        future: DatabaseHelper.instance.getItem(item.id!),
        builder: (BuildContext context, AsyncSnapshot<Item> snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: Text('Loading...', style: TextStyle(fontSize: 20, color: Colors.white),),);
          } else {
            item = snapshot.data!;
            unbalanced = _checkBalances();
            return FutureBuilder<Item>(
                future: DatabaseHelper.instance.itemSync(item),
                builder: (BuildContext context, AsyncSnapshot<Item> syncSnapshot) {
                  if (syncSnapshot.hasData) {
                    item = syncSnapshot.data!;
                    unbalanced = _checkBalances();
                  }
                  return Column(
                    children: [
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  bottom: Radius.circular(20)),
                              child: Image(
                                  image: AssetImage('images/image_${item.image}.jpg'),
                                  width: MediaQuery
                                      .of(context)
                                      .size
                                      .width,
                                  height: MediaQuery
                                      .of(context)
                                      .size
                                      .height / 5,
                                  fit: BoxFit.fill
                              ),
                            )
                          ]
                      ),
                      const Spacer(),
                      SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: _buildMemberBar(),
                          )
                      ),
                      const Spacer(flex: 5,),
                      _payoffButton(),
                      const Spacer(),
                      _transactionList(),
                    ],
                  );
                }
            );

          }

        }
      ),
    );
  }

  bool _checkBalances(){
    for(var m in item.members){
      if(m.balance != 0){
        return true;
      }
    }
    return false;
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
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        tooltip: 'Add Transaction',
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}