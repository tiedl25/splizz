import 'dart:ui';

import 'package:currency_textfield/currency_textfield.dart';
import 'package:flutter/material.dart';
import 'package:splizz/Helper/database.dart';
import 'package:splizz/Models/transaction.dart';
import 'package:splizz/Helper/ui_model.dart';

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
    
    return DialogModel(
      title: 'Add new Transaction',
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
                              decoration: TfDecorationModel(context: context, title: 'Add a description')
                            ),
                            /*ToggleButtons(
                              direction: Axis.horizontal,
                              isSelected: _isSelected,
                              onPressed: (int index){
                                for (int i=0; i < _item.members.length; ++i){
                                  _isSelected[i] = i == index;
                                }
                              },
                              children: _item.members.map((Member m){
                                return Container(
                                    decoration: BoxDecoration(
                                      //color: _isSelected ? _item.members[i].color : Theme.of(context).colorScheme.surface,
                                      border: Border.all(style: BorderStyle.none, width: 0),
                                      borderRadius: const BorderRadius.all(Radius.circular(20)),
                                    ),
                                  child: Text(m.name),
                                );
                              }).toList(),
                            ),*/
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
                                      color: _isSelected[i] ? _item.members[i].color : Theme.of(context).colorScheme.surface,
                                      border: Border.all(style: BorderStyle.none, width: 0),
                                      borderRadius: const BorderRadius.all(Radius.circular(20)),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 5),
                                      margin: const EdgeInsets.all(2),
                                      child: TextButton(
                                        onPressed: (){
                                          setState(() {
                                            var selected = _isSelected[i];
                                            _isSelected.fillRange(0, _isSelected.length, false);
                                            _isSelected[i] = !selected;
                                            _selection = i;
                                          });
                                        },
                                        child: Text(_item.members[i].name, style: const TextStyle(fontSize: 20),),
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
                              decoration: TfDecorationModel(
                                context: context,
                                title: '0,00',
                                icon: IconButton(
                                  onPressed: (){setState(() {
                                    currency = !currency;
                                  });},
                                  icon: currency==false ? const Icon(Icons.euro) : const Icon(Icons.attach_money)
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
                List<int> involvedMembersListIds = List.generate(_item.members.length, (index) => index);
                List<int> involvedMembersDbIds = _item.members.map((e) => e.id!).toList();

                _item.addTransaction(_selection, tract, involvedMembersListIds);
                DatabaseHelper.instance.addTransactionCalculate(tract, _item.id!, associatedId, involvedMembersDbIds);
                //DatabaseHelper.instance.update(_item);
                _selection=-1;
              });
            }
          }
    );
  }
}