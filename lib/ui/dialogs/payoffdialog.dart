import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:splizz/bloc/detailview_bloc.dart';
import 'package:splizz/bloc/detailview_states.dart';
import 'package:splizz/resources/strings.dart';
import 'package:splizz/ui/widgets/overlayLoadingScreen.dart';
import 'package:splizz/ui/widgets/transactionPieChart.dart';
import 'package:widgets_to_image/widgets_to_image.dart';
import 'package:excel/excel.dart' hide Border, BorderStyle;

import 'package:splizz/models/transaction.model.dart';
import 'package:splizz/models/item.model.dart';
import 'package:splizz/models/member.model.dart';
import 'package:splizz/ui/widgets/customDialog.dart';

class PayoffDialog extends StatelessWidget {
  late final context;
  late final cubit;

  late Item item;

  late final WidgetsToImageController controller = WidgetsToImageController();
  late final ScreenshotController screenshotController = ScreenshotController();

  List<ExpansibleController> exController = [];

  PayoffDialog();

  Future<bool?> showDismissDialog(transaction, {List<Transaction>? payoffTransactions}) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomDialog(
          title: dismissDialogTitle,
          content: Text(
            dismissDialogText,
            style: TextStyle(fontSize: 20),
          ),
          onConfirmed: () async => await cubit.deleteTransaction(transaction, payoffTransactions: payoffTransactions),
        );
      },
    ) as bool?;
  }

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
      TextCellValue(date),
      TextCellValue(description),
      TextCellValue(value),
      TextCellValue(personWhoPayed),
      TextCellValue(member)
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
      DataColumn(label: Text(date)),
      DataColumn(label: Text(description)),
      DataColumn(label: Text(value)),
      DataColumn(label: Text(personWhoPayed)),
      DataColumn(label: Text(member))
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
              crossAxisAlignment: CrossAxisAlignment.end,
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
    return FittedBox(
      fit: BoxFit.scaleDown,
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      child: WidgetsToImage(
        controller: controller,
        child: IntrinsicWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.generate(paymap.length, (i) {
              Member m = paymap.keys.toList()[i];
              return paymapRelation(m, paymap[m]!);
            }),
          ),
        ),
      ),
    );
  }

  void sharePayoff(state, Transaction payoff) async {
    final overlayEntry = OverlayLoadingScreen();
    Overlay.of(context).insert(overlayEntry);

    final payoffBytes = await controller.capture();
    final transactionsBytes = await transactionTable(payoff);
    final excelBytes = await exportTransactionTableToExcel(payoff);

    if (overlayEntry.mounted) {
      overlayEntry.remove();
    }

    await Share.shareXFiles(
        [
          if (state.whatToShare[0])
            XFile.fromData(payoffBytes!, mimeType: 'image/png'),
          if (state.whatToShare[1])
            XFile.fromData(transactionsBytes, mimeType: 'image/png'),
          if (state.whatToShare[2])
            XFile.fromData(excelBytes,
                mimeType:
                    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
        ],
        text: payoffDialogTitle,
        fileNameOverrides: [
          if (state.whatToShare[0]) payoffDialogTitle + '.png',
          if (state.whatToShare[1]) transactions + '.png',
          if (state.whatToShare[2]) transactions + '.xlsx'
        ]);

    Navigator.of(context).pop();
  }

  showSelectionDialog(state, Transaction payoff) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return BlocProvider<DetailViewCubit>.value(
            value: cubit,
            child: BlocBuilder<DetailViewCubit, DetailViewState>(
              builder: (context, state) {
                state as DetailViewPayoffDialog;

                return CustomDialog(
                  title: shareSelectionDialogTitle,
                  content: Container(
                    width: MediaQuery.of(context).size.width,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CheckboxListTile(
                          checkboxShape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          title: Text(shareSelectionDialogCheckbox1),
                          value: state.whatToShare[0],
                          onChanged: (value) => cubit
                              .changeWhatToShare(<bool>[
                            value!,
                            state.whatToShare[1],
                            state.whatToShare[2]
                          ]),
                        ),
                        CheckboxListTile(
                          checkboxShape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          title: Text(shareSelectionDialogCheckbox2),
                          value: state.whatToShare[1],
                          onChanged: (value) => cubit
                              .changeWhatToShare(<bool>[
                            state.whatToShare[0],
                            value!,
                            state.whatToShare[2]
                          ]),
                        ),
                        CheckboxListTile(
                          checkboxShape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          title: Text(shareSelectionDialogCheckbox3),
                          value: state.whatToShare[2],
                          onChanged: (value) => cubit
                              .changeWhatToShare(<bool>[
                            state.whatToShare[0],
                            state.whatToShare[1],
                            value!
                          ]),
                        )
                      ],
                    ),
                  ),
                  onConfirmed: () => sharePayoff(state, payoff),
                );
              },
            ),
          );
        });
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
        item = Item.copyWith(item: state.item);

        Transaction payoff;

        if (state.past) {
          payoff = state.item.history.firstWhere((e) => e.id == state.payoffId);
          setBalance(payoff);
        } else {
          final i = Item.copyWith(item: state.item);
          i.payoff();
          payoff = i.history.last;
        }

        var paymap = item.calculatePayoff();
        final transactions = item.history.where((Transaction e) => e.payoffId == payoff.id).toList();

        return CustomDialog(
          header: Row(children: [
            Text(payoffDialogTitle),
            const Spacer(),
            if(state.past) IconButton(
              onPressed: () => showDismissDialog(payoff, payoffTransactions: transactions).then((value) => value! ? Navigator.of(context).pop() : null),
              icon: Icon(Icons.delete)
            ),
            IconButton(
                onPressed: () async => await showSelectionDialog(state, payoff),
                icon: Icon(Icons.share))
          ]),
          contentPadding: const EdgeInsets.all(5),
          scrollable: false,
          content: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Container(
                margin: const EdgeInsets.all(10),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height / 1.5,
                ),
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: transactions.length + 1,
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      return paymapWidget(paymap);
                    }
                        
                    Transaction transaction = transactions[transactions.length - i];
                    return transaction.deleted
                      ? Container(
                          child: expansionTile(state, transaction, i-1),
                        )
                      : expansionTile(state, transaction, i-1);
                  },
                ),
              ),
          ),
          onConfirmed: !state.past ? () => cubit.addPayoff() : null,
          onDismissed: () => cubit.dismissPayoffDialog(),
        );
      },
    );
  }

  Widget expansionTile(state, Transaction transaction, int index) {
    Color color = Color(state.item.members.firstWhere((m) => m.id == transaction.memberId).color);
    Color textColor = color.computeLuminance() > 0.2 ? Colors.black : Colors.white;

    List<Member> members = state.item.members.where((m) => transaction.operations.any((e) => e.memberId == m.id)).toList();

    if (exController.length <= index) {
      exController.add(ExpansibleController());
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      clipBehavior: Clip.hardEdge,
      foregroundDecoration: transaction.deleted
        ? const BoxDecoration(
            color: Color(0x99000000),
            backgroundBlendMode: BlendMode.darken,
            borderRadius: BorderRadius.all(Radius.circular(20))
          )
        : null,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.all(Radius.circular(20))),
      child: ExpansionTile(
        key: ValueKey(transaction.id),
        maintainState: true,
        controller: exController[index],
        onExpansionChanged: (value) => exController[index].isExpanded ? exController.where((e) => e != exController[index]).forEach((e) => e.collapse()) : cubit.togglePieChart(showPieChart: false),
        expandedAlignment: Alignment.centerLeft,
        shape: const Border(),
        collapsedIconColor: textColor,
        iconColor: textColor,
        tilePadding: const EdgeInsets.symmetric(horizontal: 15),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 15),
        title: Text(
          transaction.description,
          style: TextStyle(color: textColor),
        ),
        subtitle: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${transaction.value.toStringAsFixed(2)}€',
              style: TextStyle(
                  decoration:
                      transaction.deleted ? TextDecoration.lineThrough : null,
                  color: textColor),
            ),
            Text(
              transaction.formatDate(),
              style: TextStyle(color: textColor),
            )
          ],
        ),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: TransactionPieChart(context: context, members: members, transaction: transaction, textColor: textColor),
          ),
        ],
      ),
    );
  }
}
