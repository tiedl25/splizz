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
  //late final List<bool> _payerSelection;
  late final List<bool> _memberSelection;
  List<dynamic> date = ["Today", "Yesterday"];
  int _selection = -1;
  int _dateSelection = 0;

  @override void initState() {
    _item = widget.item;
    _memberSelection = _item.members.map((Member m) => m.active).toList();
    date.add(DateTime.now());

    super.initState();
  }

  Widget payerBar(){
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 5),
      physics: const BouncingScrollPhysics(),
      itemCount: _item.members.length,
      itemBuilder: (context, i) {
        Color color = _selection==i ? _item.members[i].color : Theme.of(context).colorScheme.surface;
        Color textColor = color.computeLuminance() > 0.2 ? Colors.black : Colors.white;

        return PillModel(
          color: color,
          child: TextButton(
            onPressed: (){
              setState(() {
                _selection = i;
              });
            },
            child: Text(_item.members[i].name, style: TextStyle(color: textColor, fontSize: 20),),
          ),
        );
      },
    );
  }

  Widget memberBar(){
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 5),
      physics: const BouncingScrollPhysics(),
      itemCount: _item.members.length,
      itemBuilder: (context, i) {
        Color color = _memberSelection[i] ? _item.members[i].color : Theme.of(context).colorScheme.surface;
        Color textColor = color.computeLuminance() > 0.2 ? Colors.black : Colors.white;

        return PillModel(color: color, child: TextButton(
            onPressed: (){
              setState(() {
                _memberSelection[i] = !_memberSelection[i];
              });
            },
            child: Text(_item.members[i].name, style: TextStyle(color: textColor, fontSize: 20),),
          ),
        );
      },
    );
  }

  Future _showDateSelection(DateTime day){
    return showDialog(context: context, builder: (BuildContext context) {
      DateTime? pickedDate=day;
      return DialogModel(
        contentPadding: const EdgeInsets.only(bottom: 0),
        content: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: CalendarDatePicker(
            initialDate: day,
            firstDate: day.subtract(const Duration(days: 60)),
            lastDate: day,
            onDateChanged: (DateTime value) { pickedDate=value; },
          ),
        ),
        onConfirmed: (){
          if(pickedDate != null){
            setState(() {
              date[2] = pickedDate;
            });
          }
        },
      );
    },);
  }

  Widget dateBar(){
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 5),
      physics: const BouncingScrollPhysics(),
      itemCount: 3,
      itemBuilder: (context, i) {
        Color color = _dateSelection==i ? Theme.of(context).colorScheme.surfaceTint : Theme.of(context).colorScheme.surface;
        Color textColor = color.computeLuminance() > 0.2 ? Colors.black : Colors.white;

        return PillModel(
            color: color,
            child: TextButton(
            onPressed: (){
              DateTime day = DateTime.now().subtract(Duration(days: i));
              if(i==2){
                _showDateSelection(day);
              } else {
                date[2] = day;
              }
              setState(() {
                _dateSelection = i;
              });
            },
            child: Text(i==2 ? '${date[2].day}.${date[2].month}.${date[2].year}' : date[i], style: TextStyle(color: textColor ,fontSize: 15),),
          ),
        );
      },
    );
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
                          child: payerBar()
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
                          child: memberBar()
                      ),
                      SizedBox(
                        height: 50,
                        child: dateBar(),
                      )
                    ]
                ),
          )
      ),
      onConfirmed: () {
            if(currencyController.doubleValue != 0 && descriptionController.text.isNotEmpty && _selection!=-1 && _memberSelection.contains(true)) {
              widget.setParentState(() {
                int associatedId = _item.members[_selection].id!;
                Transaction tract = Transaction(descriptionController.text, currencyController.doubleValue, date[2], memberId: associatedId);
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