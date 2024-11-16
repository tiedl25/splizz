import 'package:currency_textfield/currency_textfield.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:splizz/Helper/circularSlider.dart';
import 'package:splizz/Helper/database.dart';
import 'package:splizz/models/transaction.model.dart';
import 'package:splizz/models/member.model.dart';
import 'package:splizz/models/item.model.dart';
import 'package:splizz/Helper/ui_model.dart';

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
  late final List<double> _memberBalances;
  List<Map<String, dynamic>> _involvedMembers = [];

  List<dynamic> date = ["Today", "Yesterday"];
  int selection = -1;
  int _dateSelection = 0;
  bool extend = false;
  double _scale = 1.0;

  @override void initState() {
    item = widget.item;
    _memberSelection = item.members.map((Member m) => m.active).toList();
    _memberBalances = List.generate(_memberSelection.length, (index) => 0.0);
    date.add(DateTime.now());

    super.initState();
  }

    
  add() {
    if(currencyController.doubleValue != 0 && descriptionController.text.isNotEmpty && selection!=-1 && _memberSelection.contains(true)) {
      if (_involvedMembers.isEmpty) {
        updateBalances();
      }
      
      String associatedId = item.members[selection].id;
      Transaction transaction = Transaction(description: descriptionController.text, value: currencyController.doubleValue, date: date[2], memberId: associatedId, itemId: item.id);
      item.addTransaction(selection, transaction, _involvedMembers);
      
      DatabaseHelper.instance.upsertTransaction(transaction);
      //DatabaseHelper.instance.update(item);
      widget.updateItem(item);
      selection=-1;
    }
  }

  updateBalances(){
    int memberCount = _memberSelection.where((element) => element==true).length;
    for (int i=0; i<_memberSelection.length; i++){
      if (_memberSelection[i]){
        _involvedMembers.add({'listId': i, 'id': item.members[i].id, 'balance': currencyController.doubleValue/memberCount});
      }
    } 
  }


  Widget payerBar(){
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 5),
      physics: const BouncingScrollPhysics(),
      itemCount: item.members.length,
      itemBuilder: (context, i) {
        Color color = selection==i ? Color(item.members[i].color) : Theme.of(context).colorScheme.surface;
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
        Color color = _memberSelection[i] ? Color(item.members[i].color) : Theme.of(context).colorScheme.surface;
        Color textColor = color.computeLuminance() > 0.2 ? Colors.black : Colors.white;
        //if (_memberBalances.length < item.members.length) {
        //  _memberBalances.add(1.0);
        //}

        return Column(
          children: [
            PillModel(
              color: color, 
              child: TextButton(
                onPressed: (){
                  setState(() {
                      _memberSelection[i] = !_memberSelection[i];
                  });
                },
                child: Text(item.members[i].name, style: TextStyle(color: textColor, fontSize: 20),),
              ),
            ),
            
            //RotatedBox(
            //  quarterTurns: 3,
            //  child: Slider(
            //    divisions: 10,
            //    activeColor: _memberSelection[i] ? item.members[i].color : Theme.of(context).colorScheme.surface,
            //    value: _memberBalances[i],
            //    label: _memberBalances[i].toString(),
            //    min: 0, 
            //    max: 1, 
            //    onChanged: (value){
            //      setState(() {
            //        _memberBalances[i] = value;
            //      });
            //    }
            //  )
            //)
          ],
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

  //Widget adjustCircle(){
  //  return 
  //}

  Widget dialog(){
    return AnimatedScale(
      duration: const Duration(milliseconds: 100),
      scale: _scale,
      child: DialogModel(
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
                        SizedBox(
                          height: 50,
                          child: dateBar(),
                        ),
                        Container(
                          //margin: const EdgeInsets.only(left: 0, top: 5),
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            child: Text('Show more'),
                            onPressed: (){
                              setState(() {
                                _scale = 1.07;
                              });
                              Future.delayed(const Duration(milliseconds: 100), (){
                                setState(() {
                                  extend = !extend;
                                });
                              });
                            }
                          ),
                        ),
                      ]
                  ),
            )
        ),
        onConfirmed: () => add(),
          
      )
    );
  }

  Widget view(){
    return ClipRRect(
      borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        extendBodyBehindAppBar: false,
        backgroundColor: Theme.of(context).colorScheme.background,
        appBar: AppBar(
          backgroundColor: Colors.black26,
          title: Text("Add new Transaction"),
        ),
        body: Container(
          padding: const EdgeInsets.all(10),
          child: Column(
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
              SizedBox(
                height: 50,
                child: dateBar(),
              ),
              Container(
                margin: const EdgeInsets.only(left: 5, top: 5),
                alignment: Alignment.centerLeft,
                child: const Text('For whom?'),
              ),
              SizedBox(
                  height: 70,
                  child: memberBar()
              ),
              Spacer(),
              CircularSlider(
                sum: currencyController.doubleValue,
                members: item.members,
                memberBalances: _memberBalances,
                memberSelection: _memberSelection,
                getInvolvedMembers: (value){_involvedMembers = value;},
              ),
              Spacer(),
              Container(
                //margin: const EdgeInsets.only(left: 5, top: 5),
                alignment: Alignment.centerLeft,
                child: TextButton(
                  child: Text('Show less'),
                  onPressed: (){
                    setState(() {
                      extend = !extend;
                      _scale = 1;
                    });
                  }
                ),
              ),
              //Spacer(),
              const Divider(
                thickness: 0.5,
                indent: 0,
                endIndent: 0,
              ),
              IntrinsicHeight(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                        child: CupertinoButton(
                          padding: const EdgeInsets.symmetric(vertical: 0),
                          child: Text("Cancel", style: Theme.of(context).textTheme.labelLarge,),
                          onPressed: () {
                            Navigator.of(context).pop(false);
                          },
                        )
                    ),
                    const VerticalDivider(
                      indent: 5,
                      endIndent: 5,
                    ),
                    Expanded(
                      child: CupertinoButton(
                          padding: const EdgeInsets.symmetric(vertical: 0),
                          child: Text("Add", style: Theme.of(context).textTheme.labelLarge,),
                          onPressed: () {
                            add();
                            Navigator.of(context).pop(true);
                          }
                      ),
                    ),
                  ],
                )
              ),
            ],    
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {    
    return extend ? view() : dialog();
  }
}