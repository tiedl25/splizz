import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:splizz/bloc/detailview_bloc.dart';
import 'package:splizz/bloc/detailview_states.dart';
import 'package:widgets_to_image/widgets_to_image.dart';
import 'package:excel/excel.dart';

import 'package:splizz/models/transaction.model.dart';
import 'package:splizz/models/item.model.dart';
import 'package:splizz/models/member.model.dart';
import 'package:splizz/ui/widgets/customDialog.dart';

class PayoffDialog extends StatelessWidget {
  late final context;
  late final cubit;

  late final Item item;

  late final WidgetsToImageController controller = WidgetsToImageController();
  late final ScreenshotController screenshotController = ScreenshotController();

  PayoffDialog();

  setBalance(Transaction transaction) {
    List<Member> members = [];
    for (var member in item.members) {
      double balance = transaction.operations
          .where((element) => element.memberId == member.id)
          .fold(0, (a, b) => a + b.value);
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
        TextCellValue(item.members
            .firstWhere((element) => element.id == row.memberId)
            .name),
        TextCellValue(row.operations
            .where((element) => element.value != row.value)
            .map((e) => item.members.firstWhere((m) => m.id == e.memberId).name)
            .toList()
            .join(', '))
      ];
    }).toList();

    // Add data rows
    for (var row in rows) {
      sheet.appendRow(row);
    }

    return Uint8List.fromList(excel.save()!);
  }

  Future<List<Transaction>> getPayoffTransactions(Transaction payoff) async {
    List<Transaction> payoffBefore = item.history
        .where((element) =>
            element.timestamp.compareTo(payoff.timestamp) < 0 &&
            element.description == "payoff")
        .toList();

    if (payoffBefore.isNotEmpty)
      payoffBefore.sort(
          (element, other) => element.timestamp.compareTo(other.timestamp));

    List<Transaction> transactions = item.history
        .where((element) =>
            element.timestamp.compareTo(payoff.timestamp) < 0 &&
            (payoffBefore.isNotEmpty
                ? element.timestamp.compareTo(payoffBefore.last.timestamp) > 0
                : true) &&
            element.description != "payoff" &&
            element.deleted == false)
        .toList();

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
          DataCell(Text(item.members
              .firstWhere((element) => element.id == row.memberId)
              .name)),
          DataCell(Text(row.operations
              .where((element) => element.value != row.value)
              .map((e) =>
                  item.members.firstWhere((m) => m.id == e.memberId).name)
              .toList()
              .join(', ')))
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

  //Future<File> widgetToImageFile(Uint8List capturedImage, String filename) async {
  //  return await File(path + filename).writeAsBytes(capturedImage);
  //}

  Widget paymapRelation(Member m, List<Member> paylist) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
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
                Text(
                  m.name,
                  style: const TextStyle(color: Colors.black),
                ),
                const Icon(
                  Icons.arrow_forward,
                  color: Colors.black,
                ),
                Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.white54),
                    child: Text('${m.total.abs().toStringAsFixed(2)}€',
                        style: TextStyle(color: Colors.red.shade700))),
              ],
            ),
          ),
          Column(
              children: List.generate(paylist.length, (index) {
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
                          color: Colors.white54),
                      child: Text('${e.balance.abs().toStringAsFixed(2)}€',
                          style: TextStyle(color: Colors.green.shade700))),
                  const Icon(
                    Icons.arrow_forward,
                    color: Colors.black,
                  ),
                  Text(
                    e.name,
                    style: const TextStyle(color: Colors.black),
                  ),
                ],
              ),
            );
          }))
        ],
      ),
    );
  }

  Widget paymapWidget(paymap) {
    return WidgetsToImage(
      controller: controller,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(paymap.length, (i) {
          Member m = paymap.keys.toList()[i];
          return paymapRelation(m, paymap[m]!);
        }),
      ),
    );
  }

  void sharePayoff(Transaction payoff) async {
    final payoffBytes = await controller.capture();
    final transactionsBytes = await transactionTable(payoff);
    final excelBytes = await exportTransactionTableToExcel(payoff);

    await Share.shareXFiles(
        [
          XFile.fromData(payoffBytes!, mimeType: 'image/png'),
          XFile.fromData(transactionsBytes,
              mimeType: 'image/png'),
          XFile.fromData(excelBytes,
              mimeType:
                  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
        ],
        text: 'Payoff',
        fileNameOverrides: [
          'Payoff',
          'Transactions (Image)',
          'Transactions (Excel)'
        ]);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    this.context = context;
    this.cubit = context.read<DetailViewCubit>();

    return BlocBuilder<DetailViewCubit, DetailViewState>(
      bloc: cubit,
      buildWhen: (_, current) => current is DetailViewPayoffDialog,
      builder: (context, state) {
        state as DetailViewPayoffDialog;
        item = Item.copy(state.item);

        Transaction payoff;
        

        if (state.past){
          final index = state.index!;
          setBalance(item.history[index]);
          payoff = item.history[index];
        } else {
          final i = Item.copy(state.item);
          i.payoff();
          payoff = i.history.last;
        }
        

        var paymap = item.calculatePayoff();

        //getApplicationDocumentsDirectory().then((value) {
        //  path = value.path;
        //});

        return CustomDialog(
          header: Row(children: [
            const Text('Payoff'),
            const Spacer(),
            IconButton(
                onPressed: () async => sharePayoff(payoff),
                icon: Icon(Icons.import_export))
          ]),
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
          ),
          onConfirmed: !state.past ? () => cubit.addPayoff() : null,
          onDismissed: () => cubit.dismissPayoffDialog(),
        );
      },
    );
  }
}
