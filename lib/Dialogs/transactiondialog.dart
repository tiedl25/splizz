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
  late Item _item;
  CurrencyTextFieldController currencyController = CurrencyTextFieldController(currencySymbol: '', decimalSymbol: ',');
  TextEditingController descriptionController = TextEditingController();
  bool currency = false;
  final List<bool> _isSelected = [];
  int _selection = -1;
  
  void _init(){
    _item = widget.item;
    for (Member _ in _item.members) {
      _isSelected.add(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    _init();
    
    return UIElements.dialog(
      title: 'Add new Transaction',
      context: context,
      content: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height/4,
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
                            SizedBox(
                              height: MediaQuery.of(context).size.height/12,
                              child: ListView.builder(
                                shrinkWrap: true,
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(vertical: 5),
                                physics: const BouncingScrollPhysics(),
                                itemCount: _item.members.length,
                                itemBuilder: (context, i) {
                                  return Container(
                                    alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                      color: _isSelected[i] ? _item.members[i].color : const Color(0xFF282828),
                                      border: Border.all(color: const Color(0xFF343434)),
                                      borderRadius: const BorderRadius.all(Radius.circular(20)),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 5),
                                      margin: const EdgeInsets.all(2),
                                      child: TextButton(
                                        child: Text(_item.members[i].name, style: const TextStyle(fontSize: 20, color: Colors.white),),
                                        onPressed: (){
                                          setState(() {
                                            var selected = _isSelected[i];
                                            _isSelected.fillRange(0, _isSelected.length, false);
                                            _isSelected[i] = !selected;
                                            _selection = i;
                                          });
                                        },
                                    ),
                                  );
                                },
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
      onConfirmed: () {
            if(currencyController.doubleValue != 0 && descriptionController.text.isNotEmpty && _selection!=-1) {
              widget.setParentState(() {
                int associatedId = _item.members[_selection].id!;
                Transaction tract = Transaction(descriptionController.text, currencyController.doubleValue, memberId: associatedId);

                _item.addTransaction(_selection, tract);
                DatabaseHelper.instance.addTransaction(tract, _item.id!, associatedId);
                //DatabaseHelper.instance.update(_item);
                _selection=-1;
              });
            }
          }
    );
  }
}