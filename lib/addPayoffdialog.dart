import 'package:flutter/material.dart';

import 'item.dart';
import 'member.dart';

class AddPayoffDialog extends StatefulWidget {
  final Item item;
  final Function setParentState;

  const AddPayoffDialog({
    Key? key,
    required this.item,
    required this.setParentState
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _AddPayoffDialogState();
  }
}

class _AddPayoffDialogState extends State<AddPayoffDialog>{
  late Item _item;

  @override
  Widget build(BuildContext context) {
    _item = widget.item;
    var paymap = _item.payoff();
    return AlertDialog(
      title: const Text('Payoff', style: TextStyle(color: Colors.white),),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
      backgroundColor: const Color(0xFF2B2B2B),
      content: SingleChildScrollView(
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height/4,
          child: ListView.builder(
                itemCount: paymap.length,
                itemBuilder: (context, i) {
                  Member m = paymap.keys.toList()[i];
                  return _listElement(m, paymap[m]!);
                }
            ),
        ),
      ),
      actions: _dialogButtons(),
    );
  }

  Widget _listElement(Member m, List<Member> paylist){
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF444444),
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
                  Text(m.name),
                  const Icon(Icons.arrow_forward),
                  Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.white54
                      ),
                      child: Text('${m.balance.abs().toStringAsFixed(2)}€', style: TextStyle(color: Colors.red.shade700))),
                ],
              ),
            ),
            Column(
              children: _buildPayoffRelation(paylist),
            )
          ],
        ),
      );
  }
  
  List<Widget> _buildPayoffRelation(List<Member> paylist){
    List<Container> payoffRelation = [];
    
    for(var e in paylist){
      payoffRelation.add(
        Container(
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
              const Icon(Icons.arrow_forward),
              Text(e.name),

            ],
          ),
        )
      );
    }
    
    return payoffRelation;
  }

  List<Widget> _dialogButtons(){
    return <Widget>[
      TextButton(
          child: const Text('Dismiss'),
          onPressed: () {
            Navigator.pop(context);
          },
      ),
      TextButton(
          child: const Text('OK'),
          onPressed: () {
              Navigator.pop(context);
          }
      ),
    ];
  }

}