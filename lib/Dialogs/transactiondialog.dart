import 'dart:ui';

import 'package:currency_textfield/currency_textfield.dart';
import 'package:flutter/material.dart';
import 'package:splizz/Helper/database.dart';
import 'package:splizz/Models/transaction.dart';
import 'package:splizz/Helper/uielements.dart';

import '../Models/item.dart';
import '../Models/member.dart';

class TransactionDialog extends StatefulWidget {
  final Item item;
  final Function setParentState;

  const TransactionDialog({
    Key? key,
    required this.item,
    required this.setParentState
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _TransactionDialogState();
  }
}

class _TransactionDialogState extends State<TransactionDialog>{
  List<Container> memberSwitch = <Container>[];
  late Item _item;
  CurrencyTextFieldController currencyController = CurrencyTextFieldController(currencySymbol: '', decimalSymbol: ',');
  TextEditingController descriptionController = TextEditingController();
  late Member associatedController;
  List<bool> pressed = [];
  int previous=-1;
  bool currency = false;
  
  void _init(){
    _item = widget.item;
    for (Member _ in _item.members) {
      pressed.add(false);
    }
    memberSwitch = _buildMemberSwitch();    
  }

  List<Container> _buildMemberSwitch(){
    List<Container> li = <Container>[];

    for (Member element in _item.members) {
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
                        if (previous != -1){
                          pressed[previous] = false;
                        }
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

  @override
  Widget build(BuildContext context) {
    _init();
    
    return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
        child: AlertDialog(
      title: const Text('Add new Transaction', style: TextStyle(color: Colors.white),),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
      backgroundColor: const Color(0xFF2B2B2B),
      content: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
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
                        physics: const BouncingScrollPhysics(),
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
      actions: UIElements.dialogButtons(
          context: context,
          callback: () {
            if(currencyController.doubleValue != 0 && descriptionController.text.isNotEmpty && associatedController.name.isNotEmpty) {
              setState(() {
                Transaction tract = Transaction(associatedController.id , descriptionController.text, currencyController.doubleValue, _item.history.length);

                _item.addTransaction(associatedController, tract);
                DatabaseHelper.instance.addTransaction(tract, _item.id);
                DatabaseHelper.instance.update(_item);
                previous=-1;
                associatedController = Member(0, '', Item.colormap[0]);
              });
            }
          }),
    ));
  }
}