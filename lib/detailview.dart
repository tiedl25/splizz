import 'package:flutter/material.dart';
import 'package:splizz/filehandle.dart';
import 'package:splizz/member.dart';
import 'package:splizz/transaction.dart';
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
  int previous=-1;

  List<Container> _buildMemberBar(){
    List<Container> li = <Container>[];
    for (var element in item.member) {
      pressed[element.id] = false;
      li.add(
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.primaries[element.id], const Color(0xFF282828)]
              ),
              color: Colors.primaries[element.id],
              border: Border.all(color: const Color(0xFF343434)),
              borderRadius: const BorderRadius.all(Radius.circular(20)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 5),
            margin: const EdgeInsets.all(2),
            child: Column(
              children: [
                Text(element.name, style: const TextStyle(fontSize: 20, color: Colors.white),),
                Row(
                  children: [
                    Icon(element.balance >= 0 ? Icons.arrow_upward : Icons.arrow_downward, color: element.balance >= 0 ? Colors.green : Colors.red),
                    Text('${element.balance.abs().toStringAsFixed(2)}€', style: TextStyle(fontSize: 20, color: element.balance >= 0 ? Colors.green : Colors.red)),
                  ],
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
              color: pressed[element.id]! ? Colors.primaries[element.id] : const Color(0xFF282828),
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

  InputDecoration _tfDecoration(String hintText){
    return InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white),
        labelStyle: const TextStyle(color: Colors.white),
        enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white)
        ),
        focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white)
        ),
        errorBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.red)
        )
    );
  }

  void _addTransaction() {
    var ccontroller = CurrencyTextFieldController(rightSymbol: '€', decimalSymbol: ',');
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
                          decoration: _tfDecoration('Set a description')
                      ),
                        SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: memberBar,
                            )
                        ),
                        TextField(
                          controller: ccontroller,
                            onChanged: (value) {
                              setState(() {
                              });
                            },
                            decoration: _tfDecoration('Set the amount of money')
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
                    previous=-1;
                    associatedController = Member('', 0);
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
                  border: Border.all(color: const Color(0xFF343434)),
                  borderRadius: const BorderRadius.all(Radius.circular(15)),
                ),
                margin: const EdgeInsets.all(5),
                child:
                ListView.builder(
                  padding: const EdgeInsets.all(10),
                  shrinkWrap: true,
                  itemCount: item.history.length*2,
                  itemBuilder: (context, i) {
                    if(i.isOdd){
                      return const Divider(color: Colors.white, thickness: 1,);
                    }
                    Transaction transaction = item.history[i ~/ 2];
                    return ExpansionTile(
                      title: Text(transaction.description, style: const TextStyle(color: Colors.white),),
                      subtitle: Text(transaction.value.toString(), style: const TextStyle(color: Colors.white),),
                      children: [
                        ListTile(
                          title: Text(transaction.associated.name, style: const TextStyle(color: Colors.white),),
                          subtitle: Text(transaction.date(), style: const TextStyle(color: Colors.white),),
                        )
                      ],
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