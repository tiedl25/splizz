import 'package:flutter/material.dart';
import 'package:splizz/Dialogs/payoffdialog.dart';
import 'package:splizz/Dialogs/transactiondialog.dart';
import 'package:splizz/Dialogs/sharedialog.dart';
import 'package:splizz/Models/transaction.dart';
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

  List<Container> memberBar = <Container>[];
  List<ListTile> historyList = <ListTile>[];

  List<Container> _buildMemberBar(){
    List<Container> li = <Container>[];
    for (var element in item.members) {
      li.add(
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [element.color, element.color.withOpacity(1), element.color.withOpacity(1)]
              ),
              color: element.color,
              border: Border.all(color: const Color(0xFF343434)),
              borderRadius: const BorderRadius.all(Radius.circular(20)),
            ),
            //padding: const EdgeInsets.symmetric(horizontal: 5),
            margin: const EdgeInsets.all(2),
            child: Column(
              children: [
                Text(element.name, style: const TextStyle(fontSize: 20, color: Colors.black),),
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xAAD5D5D5),

                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(20))
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Row(
                    children: [
                      Icon(element.balance >= 0 ? Icons.arrow_upward : Icons.arrow_downward, color: element.balance >= 0 ? Colors.green[700] : Colors.red[700]),
                      Text('${element.balance.abs().toStringAsFixed(2)}€', style: TextStyle(fontSize: 20, color: element.balance >= 0 ? Colors.green[700] : Colors.red[700])),
                    ],
                  ),
                )

              ],
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
          return ShareDialog(item: item, setParentState: setState);
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
            color: const Color(0xFF282828),
            border: Border.all(color: const Color(0xFF303030)),
            borderRadius: const BorderRadius.all(Radius.circular(15)),
          ),
          margin: const EdgeInsets.all(5),
          child:
          ListView.builder(
            padding: const EdgeInsets.all(10),
            physics: const BouncingScrollPhysics(),
            shrinkWrap: true,
            itemCount: item.history.length,
            itemBuilder: (context, i) {
              Transaction transaction = item.history[item.history.length-1-i];
              return Container(
                margin: const EdgeInsets.only(bottom: 5),
                decoration: BoxDecoration(
                    color: item.members[memberMap[transaction.memberId]!].color,
                    borderRadius: const BorderRadius.all(Radius.circular(10))
                ),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 10),
                  childrenPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                  title: Text(transaction.description, style: const TextStyle(color: Colors.black),),
                  subtitle: Text('${transaction.value.toString()}€', style: const TextStyle(color: Colors.black),),
                  children: [
                    ListTile(
                      tileColor: item.members[memberMap[transaction.memberId]!].color,
                      title: Text(item.members[memberMap[transaction.memberId]!].name, style: const TextStyle(color: Colors.black),),
                      subtitle: Text(transaction.date(), style: const TextStyle(color: Colors.black),),
                    )
                  ],
                ),
              );
            },
          )
      ),
    );
  }

  Widget _buildBody() {
    return Column(
          children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            child: Image(
              image: const AssetImage('images/default.jpg'),
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height/5,
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
    unbalanced = _checkBalances();

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF2B2B2B),
      appBar: AppBar(
        title: Text(item.name),
        actions: [
          IconButton(
              onPressed: _showShareDialog,
              icon: const Icon(Icons.share)
          )
        ],
        backgroundColor: const Color(0x882B2B2B),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        tooltip: 'Add Transaction',
        child: const Icon(Icons.add),
      ),
    );
  }
}