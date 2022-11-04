import 'package:flutter/material.dart';
import 'package:splizz/filehandle.dart';
import 'package:splizz/member.dart';
import 'package:splizz/transaction.dart';
import 'package:splizz/uielements.dart';
import 'item.dart';
import 'package:currency_textfield/currency_textfield.dart';

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

  late Member associatedController;
  
  Map<int, bool> pressed = {};
  int previous=0;

  List<Container> _buildMemberBar(){
    List<Container> li = <Container>[];
    for (var element in item.member) {
      pressed[element.id] = element.id==0 ? true : false;
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
                  decoration: BoxDecoration(
                    //color: Colors.white.withAlpha(150),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [element.color, Colors.white.withAlpha(150), Colors.white.withAlpha(150)]
                    ),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20))
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

  List<Container> _buildMemberSwitch(BuildContext context, StateSetter setState){
    List<Container> li = <Container>[];

    for (Member element in item.member) {
      li.add(
          Container(
            decoration: BoxDecoration(
              color: pressed[element.id]! ? element.color : const Color(0xFF282828),
              border: Border.all(color: const Color(0xFF343434)),
              borderRadius: const BorderRadius.all(Radius.circular(20)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 5),
            margin: const EdgeInsets.all(2),
            child: TextButton(
              child: Text(element.name, style: const TextStyle(fontSize: 20, color: Colors.white),),
              onPressed: () => {
              if(element.id != previous){
                setState(() {
                    pressed[element.id] = !pressed[element.id]!;
                    pressed[previous] = false;
                    previous = element.id;
                    associatedController = element;
                  })
                }
              }
            )
          )
      );
    }
    return li;
  }

  void _addTransaction() {
    var ccontroller = CurrencyTextFieldController(rightSymbol: '', decimalSymbol: ',');
    var descriptionController = TextEditingController();

    showDialog(
      context: context, barrierDismissible: true, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add new Transaction', style: TextStyle(color: Colors.white),),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
          backgroundColor: const Color(0xFF2B2B2B),
          content: SingleChildScrollView(
            child: StatefulBuilder(builder: (context, setState) {
              memberBar = _buildMemberSwitch(context, setState);
              return SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [TextField(
                          controller: descriptionController,
                          onChanged: (value) {
                            setState(() {
                            });
                          },
                          style: const TextStyle(
                              color: Colors.white
                          ),
                          decoration: UIElements.tfDecoration('Add a description')
                      ),
                        SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: memberBar,
                            )
                        ),
                        TextField(
                          style: const TextStyle(
                            color: Colors.white
                          ),
                          controller: ccontroller,
                            onChanged: (value) {
                              setState(() {
                              });
                            },
                            decoration: UIElements.tfDecoration('0,00', IconButton(onPressed: (){ }, icon: const Icon(Icons.euro), color: Colors.white))
                        )
                      ]
                  )
              );}
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
                if(ccontroller.doubleValue != 0 && descriptionController.text.isNotEmpty && associatedController.name.isNotEmpty) {
                  setState(() {
                    Transaction tract = Transaction(ShortMember.fromMember(associatedController) , descriptionController.text, ccontroller.doubleValue, item.history.length);

                    item.addTransaction(associatedController, tract);
                    FileHandler fh = FileHandler('item_${item.id}');
                    fh.writeJsonFile(item);
                    Navigator.pop(context);
                    previous=0;
                    associatedController = Member('', 0, Item.colormap[0]);
                  });
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildBody() {
    memberBar = _buildMemberBar();
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
              children: memberBar,
            )
          ),
          const Spacer(flex: 5,),
          const Text('Transactions', style: TextStyle(fontSize: 30, color: Colors.white),),
          const Spacer(),
          Expanded(
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
          ),

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
        onPressed: _addTransaction,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}