import 'package:flutter/material.dart';
import 'package:splizz/addPayoffdialog.dart';
import 'package:splizz/addtransactiondialog.dart';
import 'package:splizz/transaction.dart';
import 'item.dart';

class ViewGenerator extends StatefulWidget{
  final Item item;
  const ViewGenerator({Key? key, required this.item}) : super(key:key);

  @override
  State<StatefulWidget> createState() => DetailView();
}

class DetailView extends State<ViewGenerator>{
  late Item item;

  List<Container> memberBar = <Container>[];
  List<ListTile> historyList = <ListTile>[];

  List<Container> _buildMemberBar(){
    List<Container> li = <Container>[];
    for (var element in item.member) {
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
                      Icon(element.balance >= 0 ? Icons.arrow_upward : Icons.arrow_downward, color: element.balance >= 0 ? Colors.green : Colors.red),
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

  void _showPayoffDialog(){
    showDialog(
      context: context, barrierDismissible: true, // user must tap button!
      builder: (BuildContext context) {
        return AddPayoffDialog(item: item, setParentState: setState);
      },
    );
  }

  Widget _payoffButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Transactions', style: TextStyle(fontSize: 30, color: Colors.white),textAlign: TextAlign.center,),
          Container(
            margin: const EdgeInsets.only(left: 50),
            decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green
            ),
            child: IconButton(
                onPressed: _showPayoffDialog,
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
        return AddTransactionDialog(item: item, setParentState: setState);
      },
    );
  }

  Widget _transactionList() {
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
            shrinkWrap: true,
            itemCount: item.history.length,
            itemBuilder: (context, i) {
              Transaction transaction = item.history[item.history.length-1-i];
              return Container(
                margin: const EdgeInsets.only(bottom: 5),
                decoration: BoxDecoration(
                    color: item.member[transaction.associated.id].color,
                    borderRadius: const BorderRadius.all(Radius.circular(10))
                ),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 10),
                  childrenPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                  title: Text(transaction.description, style: const TextStyle(color: Colors.black),),
                  subtitle: Text('${transaction.value.toString()}€', style: const TextStyle(color: Colors.black),),
                  children: [
                    ListTile(
                      tileColor: item.member[transaction.associated.id].color,
                      title: Text(transaction.associated.name, style: const TextStyle(color: Colors.black),),
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

  @override
  Widget build(BuildContext context) {
    item = widget.item;
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF2B2B2B),
      appBar: AppBar(
        title: Text(item.name),
        backgroundColor: const Color(0x882B2B2B),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}