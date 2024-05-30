import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:widgets_to_image/widgets_to_image.dart';

import 'package:splizz/Helper/database.dart';
import 'package:splizz/Models/transaction.dart';
import 'package:splizz/Models/item.dart';
import 'package:splizz/Models/member.dart';
import 'package:splizz/Helper/ui_model.dart';

class PayoffDialog extends StatefulWidget {
  final Item item;
  final Function updateItem;

  const PayoffDialog({
    Key? key,
    required this.item,
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

class PastPayoffDialog extends StatefulWidget {
  final Item item;
  final int index;

  const PastPayoffDialog({
    Key? key,
    required this.item,
    required this.index
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _PastPayoffDialogState();
  }
}

class _PastPayoffDialogState extends State<PastPayoffDialog>{
  late Item item;
  Uint8List? bytes;
  WidgetsToImageController controller = WidgetsToImageController();

  setBalance(Transaction transaction){
    List<Member> members = [];
    for (var member in item.members){
      double balance = transaction.operations.where((element) => element.memberId == member.id).fold(0, (a,b) => a+b.value);
      Member m = Member.fromMember(member);
      m.balance = -balance;
      members.add(m);
    }

    item.members = members;
  }

  Future<File> widgetToImageFile(Uint8List capturedImage) async {
    String downloadPath = "/storage/emulated/0/Download";
    String ts = DateTime.now().millisecondsSinceEpoch.toString();
    String path = '$downloadPath/$ts.png';
    return await File(path).writeAsBytes(capturedImage);
  }

  Widget paymapRelation(Member m, List<Member> paylist){
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

  @override
  Widget build(BuildContext context) {
    item = Item.copy(widget.item);
    setBalance(item.history[widget.index]);
    var paymap = item.calculatePayoff();

    return DialogModel(
        header: Row(
          children: [
            const Text('Payoff'), 
            const Spacer(), 
            IconButton(
              onPressed: () async {
                final bytes = await controller.capture();
                await widgetToImageFile(bytes!);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exported image to Download folder')));
              },
              icon: Icon(Icons.import_export)
            )
          ]
        ),
        scrollable: false,
        content: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: FittedBox(
              fit: BoxFit.fitWidth,
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              child: WidgetsToImage(
              controller: controller,
              child: Column(
                children: [
                  ...List.generate(
                    paymap.length,
                        (i) {
                      Member m = paymap.keys.toList()[i];
                      return paymapRelation(m, paymap[m]!);
                    }
                  ),
                  if(bytes != null) Image.memory(bytes!),
                ],
            ),
          ),
          ),
        ),
      )
    );
  }
}