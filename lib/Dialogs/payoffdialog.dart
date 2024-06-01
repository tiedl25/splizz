import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screenshot/screenshot.dart';
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
  late Transaction transaction;
  late String path;

  Uint8List? bytes;
  WidgetsToImageController controller = WidgetsToImageController();
  ScreenshotController screenshotController = ScreenshotController();

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

  void transactionTable(int tId, int firstTId) async{
    var response = await DatabaseHelper.instance.exportTransactionsSinceLastPayoff(item.id!, tId, firstTId);
    List<String> columnLabels = response.isNotEmpty ? response[0].keys.toList() : [];
    List<DataColumn> columns = columnLabels.map<DataColumn>((column) => DataColumn(label: Text(column))).toList();
    List<DataRow> rows = response.map<DataRow>((row) {
          return DataRow(
            cells: columnLabels.map<DataCell>((label) {
              return DataCell(Text(row[label].toString()));
            }).toList(),
          );
        }).toList();

    await screenshotController.captureFromWidget(
      FittedBox(
        fit: BoxFit.fitWidth,
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(Colors.grey),
          dataRowColor: MaterialStateProperty.all(Colors.white),
          columns: columns,
          rows: rows,
        )
      )
    ).then((value) async {
      print(await widgetToImageFile(value, 'transactions.png'));
    });
    
  }

  Future<File> widgetToImageFile(Uint8List capturedImage, String filename) async {   
    return await File(path + filename).writeAsBytes(capturedImage);
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
  void initState() {
    super.initState();
    item = Item.copy(widget.item);
    transaction = item.history[widget.index];
    setBalance(transaction);
    createDir();
  }

  createDir() async {
    DateTime d = transaction.date;
    String date = '${d.day}.${d.month}.${d.year}';
    path = '/storage/emulated/0/Download/splizzPayoff_${date}/';

    await Permission.manageExternalStorage.request();
    var status = await Permission.manageExternalStorage.status;
    if (status.isDenied) {
      return;
    }

    // You can can also directly ask the permission about its status.
    if (await Permission.manageExternalStorage.isRestricted) {
      return;
    }
    if (status.isGranted) {
      if(!Directory(path).existsSync()){
        Directory(path).createSync(recursive: true);
      }
    }
  }

  Widget paymapWidget(paymap){
    return WidgetsToImage(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    var paymap = item.calculatePayoff();

    return DialogModel(
        header: Row(
          children: [
            const Text('Payoff'), 
            const Spacer(), 
            IconButton(
              onPressed: () async {
                final bytes = await controller.capture();
                await widgetToImageFile(bytes!, 'payoff.png');
                transactionTable(item.history[widget.index].id!, item.history[0].id!);
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
              child: paymapWidget(paymap),
          ),
        ),
      )
    );
  }
}