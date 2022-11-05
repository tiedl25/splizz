import 'package:currency_textfield/currency_textfield.dart';
import 'package:flutter/material.dart';
import 'package:splizz/transaction.dart';
import 'package:splizz/uielements.dart';

import 'filehandle.dart';
import 'item.dart';
import 'member.dart';

class AddTransactionDialog extends StatefulWidget {
  final Item item;
  final Function setParentState;

  const AddTransactionDialog({
    Key? key,
    required this.item,
    required this.setParentState
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _AddTransactionDialogState();
  }
}

class _AddTransactionDialogState extends State<AddTransactionDialog>{
  List<Container> memberSwitch = <Container>[];
  late Item _item;
  CurrencyTextFieldController currencyController = CurrencyTextFieldController(rightSymbol: '', decimalSymbol: ',');
  TextEditingController descriptionController = TextEditingController();
  late Member associatedController;
  List<bool> pressed = [];
  int previous=0;
  bool currency = false;
  
  void _init(){
    _item = widget.item;
    for (Member _ in _item.member) {
      pressed.add(false);
    }
    memberSwitch = _buildMemberSwitch();    
  }
  
  @override
  Widget build(BuildContext context) {
    _init();
    
    return AlertDialog(
      title: const Text('Add new Transaction', style: TextStyle(color: Colors.white),),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
      backgroundColor: const Color(0xFF2B2B2B),
      content: SingleChildScrollView(
        child: SizedBox(
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
                      decoration: UIElements.tfDecoration(title: 'Add a description')
                  ),
                    SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: memberSwitch,
                        )
                    ),
                    TextField(
                        style: const TextStyle(
                            color: Colors.white
                        ),
                        controller: currencyController,
                        onChanged: (value) {
                          setState(() {
                          });
                        },
                        decoration: UIElements.tfDecoration(
                            title: '0,00',
                            icon: IconButton(
                                onPressed: (){setState(() {
                                  currency = !currency;
                                });},
                                icon: currency==false ? const Icon(Icons.euro) : const Icon(Icons.attach_money), color: Colors.white
                            )
                        )
                    )
                  ]
              )
          )
      ),
      actions: _dialogButtons(),
    );
  }

  List<Widget> _dialogButtons(){
    return <Widget>[
      TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Dismiss')
      ),
      TextButton(
        child: const Text('OK'),
        onPressed: () {
          if(currencyController.doubleValue != 0 && descriptionController.text.isNotEmpty && associatedController.name.isNotEmpty) {
            setState(() {
              Transaction tract = Transaction(ShortMember.fromMember(associatedController) , descriptionController.text, currencyController.doubleValue, _item.history.length);

              _item.addTransaction(associatedController, tract);
              FileHandler fh = FileHandler('item_${_item.id}');
              fh.writeJsonFile(_item);
              Navigator.pop(context);
              previous=0;
              associatedController = Member('', 0, Item.colormap[0]);
            });
          }
        },
      ),
    ];
  }

  List<Container> _buildMemberSwitch(){
    List<Container> li = <Container>[];

    for (Member element in _item.member) {
      li.add(
          Container(
              decoration: BoxDecoration(
                color: pressed[element.id] ? element.color : const Color(0xFF282828),
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
                        pressed[element.id] = !pressed[element.id];
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
}