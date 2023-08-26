import 'package:currency_textfield/currency_textfield.dart';
import 'package:flutter/material.dart';
import 'package:multi_dropdown/multiselect_dropdown.dart';
import 'package:splizz/Helper/database.dart';
import 'package:splizz/Models/transaction.dart';
import 'package:splizz/Helper/ui_model.dart';

import '../Models/item.dart';
import '../Models/member.dart';

class TransactionDialog extends StatefulWidget {
  final Item item;
  final Function setParentState;

  const TransactionDialog({
    super.key,
    required this.item,
    required this.setParentState
  });

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
  late final List<bool> _payerSelection;
  late final List<bool> _memberSelection;
  int _selection = -1;

  int? _dateSelection = 0;

  @override void initState() {
    _item = widget.item;
    _memberSelection = _item.members.map((Member m) => m.active).toList();
    _payerSelection = List.filled(_item.members.length, false);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return DialogModel(
      title: 'Add new Transaction',
      content: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                          controller: descriptionController,
                          onChanged: (value) {
                            setState(() {
                            });
                          },
                          decoration: TfDecorationModel(context: context, title: 'Add a description')
                      ),
                      Container(
                        margin: const EdgeInsets.only(left: 5, top: 5),
                        alignment: Alignment.centerLeft,
                        child: const Text('Who payed?'),
                      ),
                      SizedBox(
                          height: 60,//MediaQuery.of(context).size.height/14,
                          child: ListView.builder(
                            //shrinkWrap: true,
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            physics: const BouncingScrollPhysics(),
                            itemCount: _item.members.length,
                            itemBuilder: (context, i) {
                              return Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: _payerSelection[i] ? _item.members[i].color : Theme.of(context).colorScheme.surface,
                                  border: Border.all(style: BorderStyle.none, width: 0),
                                  borderRadius: const BorderRadius.all(Radius.circular(20)),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 5),
                                margin: const EdgeInsets.all(2),
                                child: TextButton(
                                  onPressed: (){
                                    setState(() {
                                      var selected = _payerSelection[i];
                                      if(_selection!=-1) _payerSelection[_selection] = false;
                                      _payerSelection[i] = !selected;
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
                      ),
                      Container(
                        margin: const EdgeInsets.only(left: 5, top: 5),
                        alignment: Alignment.centerLeft,
                        child: const Text('For whom?'),
                      ),
                      SizedBox(
                          height: 60,
                          child: ListView.builder(
                            //shrinkWrap: true,
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            physics: const BouncingScrollPhysics(),
                            itemCount: _item.members.length,
                            itemBuilder: (context, i) {
                              return Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: _memberSelection[i] ? _item.members[i].color : Theme.of(context).colorScheme.surface,
                                  border: Border.all(style: BorderStyle.none, width: 0),
                                  borderRadius: const BorderRadius.all(Radius.circular(20)),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 5),
                                margin: const EdgeInsets.all(2),
                                child: TextButton(
                                  onPressed: (){
                                    setState(() {
                                      var selected = _memberSelection[i];
                                      _memberSelection[i] = !selected;
                                    });
                                  },
                                  child: Text(_item.members[i].name, style: const TextStyle(fontSize: 20),),
                                ),
                              );
                            },
                          )
                      ),
                        /*MultiSelectDropDown(
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        borderWidth: 0,
                        borderRadius: 15,
                        borderColor: Colors.transparent,
                        hint: "All members selected",
                        hintStyle: const TextStyle(color: Colors.white, fontSize: 16),
                        onOptionSelected: (List<ValueItem> selectedOptions) {  },
                        options: _item.members.map((Member m) => ValueItem(label: m.name,
                        )).toList(),
                        optionsBackgroundColor: Theme.of(context).colorScheme.surface,
                        selectedOptionBackgroundColor: Theme.of(context).colorScheme.surface,
                        optionTextStyle: const TextStyle(color: Colors.white, fontSize: 16),
                        inputDecoration: const BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(15))
                        ),
                      ),
                      )*/
                      /*Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Choose a date", ),
                            Wrap(
                              spacing: 5.0,
                              children: List.generate(
                                  3,
                                  (index) {
                                return ChoiceChip(
                                    label: Text('Date $index'),
                                    selected: _dateSelection == index,
                                    onSelected: (bool selected){
                                      if(index==3){

                                      }
                                      setState(() {
                                        _dateSelection = selected ? index : null;
                                      });
                                    }
                                    );
                              })
                            )
                          ]
                      ),*/
                    ]
                ),
          )
      ),
      onConfirmed: () {
            if(currencyController.doubleValue != 0 && descriptionController.text.isNotEmpty && _selection!=-1 && _memberSelection.contains(true)) {
              widget.setParentState(() {
                int associatedId = _item.members[_selection].id!;
                Transaction tract = Transaction(descriptionController.text, currencyController.doubleValue, memberId: associatedId);
                List<int> involvedMembersListIds = [];//List.generate(_item.members.length, (index) => index);
                //List<int> involvedMembersDbIds = _item.members.map((e) => e.id!).toList();

                _memberSelection.asMap().forEach((index, value) {
                  if (value == true) {
                    involvedMembersListIds.add(index);
                  }
                });

                List<int> involvedMembersDbIds = involvedMembersListIds.map((e) => _item.members[e].id!).toList();

                //_item.addTransaction(_selection, tract, involvedMembersListIds);
                DatabaseHelper.instance.addTransactionCalculate(tract, _item.id!, associatedId, involvedMembersDbIds);
                //DatabaseHelper.instance.update(_item);
                _selection=-1;
              });
            }
          }
    );
  }
}