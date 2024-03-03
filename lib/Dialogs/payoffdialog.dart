import 'package:flutter/material.dart';
import 'package:splizz/Helper/database.dart';

import '../Models/item.dart';
import '../Models/member.dart';
import '../Helper/ui_model.dart';

class PayoffDialog extends StatefulWidget {
  final Item item;
  final Function setParentState;
  final Function updateItem;

  const PayoffDialog({
    Key? key,
    required this.item,
    required this.setParentState,
    required this.updateItem
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _PayoffDialogState();
  }
}

class _PayoffDialogState extends State<PayoffDialog>{
  late Item item;

  @override
  Widget build(BuildContext context) {
    item = widget.item;
    var paymap = item.calculatePayoff();
    return DialogModel(
      title: 'Payoff',
      scrollable: false,
      content: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: FittedBox(
            fit: BoxFit.fitWidth,
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            child: Column(
              children: List.generate(
                  paymap.length,
                      (i) {
                    Member m = paymap.keys.toList()[i];
                    return _listElement(m, paymap[m]!);
                  }
              ),
          ),
        ),
        ),
      ),
      onConfirmed: (){
        if (item.payoff()){
          DatabaseHelper.instance.update(item);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not complete payoff. Please try again')));
        }
        widget.updateItem(item);
        }
    );
  }

  Widget _listElement(Member m, List<Member> paylist){
      return Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.only(left: 10),
                margin: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: m.color,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(m.name, style: const TextStyle(color: Colors.black),),
                    const Icon(Icons.arrow_forward, color: Colors.black,),
                    Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.white54
                        ),
                        child: Text('${m.total.abs().toStringAsFixed(2)}€', style: TextStyle(color: Colors.red.shade700))),
                  ],
                ),
              ),
              Column(
                children: List.generate(
                    paylist.length,
                    (index) {
                      final e = paylist[index];
                      return Container(
                        padding: const EdgeInsets.only(right: 10),
                        margin: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: e.color,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: Colors.white54
                                ),
                                child: Text('${e.balance.abs().toStringAsFixed(2)}€', style: TextStyle(color: Colors.green.shade700))),
                            const Icon(Icons.arrow_forward, color: Colors.black,),
                            Text(e.name, style: const TextStyle(color: Colors.black),),

                          ],
                        ),
                      );
                    }
                )
              )
            ],
          ),
      );
  }
}