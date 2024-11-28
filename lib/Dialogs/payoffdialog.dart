import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:splizz/Helper/database.dart';
import 'package:widgets_to_image/widgets_to_image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart';

import 'package:splizz/models/transaction.model.dart';
import 'package:splizz/models/item.model.dart';
import 'package:splizz/models/member.model.dart';
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
        item.payoff();
        DatabaseHelper.instance.upsertTransaction(item.history.last);
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
                  color: Color(m.color),
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
                          color: Color(e.color),
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

  Future<Uint8List> exportTransactionTableToExcel(Transaction payoff) async {
    List<Transaction> transactions = await getPayoffTransactions(payoff);

    // Create a new Excel document
    var excel = Excel.createExcel();
    var sheet = excel['Sheet1'];

    List<CellValue> headers = [
      TextCellValue('Date'),
      TextCellValue('Description'),
      TextCellValue('Value'),
      TextCellValue('Person who payed'),
      TextCellValue('Member')
    ];

    // Add column headers
    sheet.appendRow(headers);

    List<List<CellValue>> rows = transactions.map<List<CellValue>>((row) {
      return [
          DateTimeCellValue.fromDateTime(row.timestamp),
          TextCellValue(row.description),
          DoubleCellValue(row.value),
          TextCellValue(item.members.firstWhere((element) => element.id == row.memberId).name),
          TextCellValue(row.operations.where((element) => element.value != row.value).map((e) => item.members.firstWhere((m) => m.id == e.memberId).name).toList().join(', '))
        ];
    }).toList();

    // Add data rows
    for (var row in rows) {
      sheet.appendRow(row);
    }
    
    return Uint8List.fromList(excel.save()!); 
  }

  Future<List<Transaction>> getPayoffTransactions(Transaction payoff) async {
    List<Transaction> payoffBefore = item.history.where((element) => element.timestamp.compareTo(payoff.timestamp) < 0 && element.description == "payoff").toList();
    if (payoffBefore.isNotEmpty) payoffBefore.sort((element, other) => element.timestamp.compareTo(other.timestamp));
    List<Transaction> transactions = item.history.where((element) => element.timestamp.compareTo(payoff.timestamp) < 0 && 
      (payoffBefore.isNotEmpty ? element.timestamp.compareTo(payoffBefore.last.timestamp) > 0 : true) && 
      element.description != "payoff" &&
      element.deleted == false).toList();

    return transactions;
  }

  Future<Uint8List> transactionTable(Transaction payoff) async {
    List<Transaction> transactions = await getPayoffTransactions(payoff);
 
    List<DataColumn> columns = [
      const DataColumn(label: Text('Date')),
      const DataColumn(label: Text('Description')),
      const DataColumn(label: Text('Value')),
      const DataColumn(label: Text('Person who payed')),
      const DataColumn(label: Text('Member')) 
    ];
    List<DataRow> rows = transactions.map<DataRow>((row) {
      return DataRow(
        cells: [
          DataCell(Text(row.timestamp.toString())),
          DataCell(Text(row.description)),
          DataCell(Text(row.value.toString())),
          DataCell(Text(item.members.firstWhere((element) => element.id == row.memberId).name)),
          DataCell(Text(row.operations.where((element) => element.value != row.value).map((e) => item.members.firstWhere((m) => m.id == e.memberId).name).toList().join(', ')))
        ],
      );
    }).toList();

    return await screenshotController.captureFromWidget(
      FittedBox(
        fit: BoxFit.fitWidth,
        child: DataTable(
          headingRowColor: WidgetStatePropertyAll(Colors.grey),
          dataRowColor: WidgetStatePropertyAll(Colors.white),
          columns: columns,
          rows: rows,
        ),
      ),
    );
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
                color: Color(m.color),
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
                        color: Color(e.color),
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
    getApplicationDocumentsDirectory().then((value) {path = value.path;});
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
                final payoffBytes = await controller.capture();
                final transactionsBytes = await transactionTable(item.history[widget.index]);
                final excelBytes = await exportTransactionTableToExcel(item.history[widget.index]);
                
                await Share.shareXFiles([XFile.fromData(payoffBytes!, mimeType: 'image/png'), 
                                          XFile.fromData(transactionsBytes, mimeType: 'image/png'), 
                                          XFile.fromData(excelBytes, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')], 
                                          text: 'Payoff',
                                          fileNameOverrides: ['Payoff', 'Transactions (Image)', 'Transactions (Excel)']);
                Navigator.of(context).pop();
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