import 'package:currency_textfield/currency_textfield.dart';
import 'package:flutter/material.dart';
import 'package:splizz/Helper/database.dart';
import 'package:splizz/Models/transaction.dart';
import 'package:splizz/Helper/ui_model.dart';

import '../Models/item.dart';
import '../Models/member.dart';

class TransactionDialog extends StatefulWidget {
  final Item item;
  final Function updateItem;

  const TransactionDialog({
    super.key,
    required this.item,
    required this.updateItem
  });

  @override
  State<StatefulWidget> createState() {
    return _TransactionDialogState();
  }
}

class _TransactionDialogState extends State<TransactionDialog>{
  late Item item;
  CurrencyTextFieldController currencyController = CurrencyTextFieldController(currencySymbol: '', decimalSymbol: ',');
  TextEditingController descriptionController = TextEditingController();
  bool currency = false;
  //late final List<bool> _payerSelection;
  late final List<bool> _memberSelection;
  List<dynamic> date = ["Today", "Yesterday"];
  int selection = -1;
  int _dateSelection = 0;

  @override void initState() {
    item = widget.item;
    _memberSelection = item.members.map((Member m) => m.active).toList();
    date.add(DateTime.now());

    super.initState();
  }

  Widget payerBar(){
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 5),
      physics: const BouncingScrollPhysics(),
      itemCount: item.members.length,
      itemBuilder: (context, i) {
        Color color = selection==i ? item.members[i].color : Theme.of(context).colorScheme.surface;
        Color textColor = color.computeLuminance() > 0.2 ? Colors.black : Colors.white;

        return PillModel(
          color: color,
          child: TextButton(
            onPressed: (){
              setState(() {
                selection = i;
              });
            },
            child: Text(item.members[i].name, style: TextStyle(color: textColor, fontSize: 20),),
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
      itemCount: item.members.length,
      itemBuilder: (context, i) {
        Color color = _memberSelection[i] ? item.members[i].color : Theme.of(context).colorScheme.surface;
        Color textColor = color.computeLuminance() > 0.2 ? Colors.black : Colors.white;

        return PillModel(color: color, child: TextButton(
            onPressed: (){
              setState(() {
                _memberSelection[i] = !_memberSelection[i];
              });
            },
            child: Text(item.members[i].name, style: TextStyle(color: textColor, fontSize: 20),),
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
                          autofocus: true,
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
        if(currencyController.doubleValue != 0 && descriptionController.text.isNotEmpty && selection!=-1 && _memberSelection.contains(true)) {
          List<int> involvedMembersListIds = [];//List.generate(_item.members.length, (index) => index);
          //List<int> involvedMembersDbIds = _item.members.map((e) => e.id!).toList();

          _memberSelection.asMap().forEach((index, value) {
            if (value == true) {
              involvedMembersListIds.add(index);
            }
          });

          List<int> involvedMembersDbIds = involvedMembersListIds.map((e) => item.members[e].id!).toList();
          
          int associatedId = item.members[selection].id!;
          Transaction transaction = Transaction(descriptionController.text, currencyController.doubleValue, date[2], memberId: associatedId, itemId: item.id);
          item.addTransaction(selection, transaction, involvedMembersListIds, involvedMembersDbIds);
          //DatabaseHelper.instance.addTransactionCalculate(transaction, item.id!, associatedId, involvedMembersDbIds);
          DatabaseHelper.instance.update(item);
          selection=-1;
          widget.updateItem(item);
        }
      }
    );
  }
}