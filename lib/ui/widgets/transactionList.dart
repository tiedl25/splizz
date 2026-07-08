import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:splizz/bloc/detailview_bloc.dart';
import 'package:splizz/bloc/transactionDialog_bloc.dart';
import 'package:splizz/models/item.model.dart';
import 'package:splizz/models/member.model.dart';
import 'package:splizz/models/transaction.model.dart';
import 'package:splizz/resources/strings.dart';
import 'package:splizz/ui/dialogs/transactiondialog.dart';
import 'package:splizz/ui/widgets/customDialog.dart';
import 'package:splizz/ui/widgets/dismissTile.dart';
import 'package:splizz/ui/widgets/transactionMemberBar.dart';
import 'package:splizz/ui/widgets/transactionPieChart.dart';

class TransactionList extends StatelessWidget {
  TransactionList({
    super.key,
    required this.item,
    required this.showPieChart,
    required this.context,
  });

  final List<ExpansibleController> exController = [];
  final List<dynamic> payoffExController = [];
  final Item item;
  final bool showPieChart;
  final BuildContext context;


  void showTransactionEditDialog(Item item, Transaction transaction, BuildContext context) async {
    final cubit = context.read<DetailViewCubit>();

    showDialog(
      useSafeArea: false,
      context: context, 
      barrierDismissible: true,
      builder: (_) {
        return SafeArea(
          top: true,
          bottom: false,
          child: BlocProvider(
            create: (context) => TransactionDialogCubit.edit(cubit, item, transaction),
            child: TransactionDialog(edit: true)
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DetailViewCubit>();

    List<Transaction> transactions = item.history.where((t) => t.payoffId == null).toList();

    return Expanded(
      flex: 50,
      child: Container(
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            border: Border.all(style: BorderStyle.none),
            borderRadius: const BorderRadius.all(Radius.circular(25)),
          ),
          margin: const EdgeInsets.all(10),
          child: RefreshIndicator(
            onRefresh: () => cubit.fetchData(),
            child: transactions.isEmpty
                ? ListView(
                    physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics()),
                    padding: EdgeInsets.symmetric(
                        vertical: MediaQuery.of(context).size.height / 4),
                    children: [
                        Center(
                          child: Text(
                            noTransactionsInList,
                            style: TextStyle(fontSize: 20),
                          ),
                        ),
                      ])
                : ListView.builder(
                    padding: const EdgeInsets.all(10),
                    physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics()),
                    shrinkWrap: false,
                    itemCount: transactions.length,
                    itemBuilder: (context, i) {
                      Transaction transaction = transactions[transactions.length - 1 - i];

                      if (exController.length < transactions.length) {
                        exController.add(ExpansibleController());
                      }

                      if (transaction.description == 'payoff' && transaction.memberId == null) {
                        return PayoffTile(transaction: transaction, context: context);
                      } else {
                        return transaction.deleted
                            ? Container(
                                margin: const EdgeInsets.only(bottom: 5),
                                child: TransactionTile(
                                  exController: exController, 
                                  payoffExController: payoffExController, 
                                  item: item, 
                                  transaction: transaction, 
                                  showPieChart: showPieChart,
                                  context: context, 
                                  onPressed: () => showTransactionEditDialog(item, transaction, context), 
                                  i: i
                                ),
                              )
                            : DismissTile(
                              id: transaction.id, 
                              context: context, 
                              child: TransactionTile(
                                exController: exController, 
                                payoffExController: payoffExController, 
                                item: item, 
                                transaction: transaction, 
                                showPieChart: showPieChart,
                                context: context, 
                                onPressed: () => showTransactionEditDialog(item, transaction, context), 
                                i: i
                              ), 
                              onPressed: () => cubit.deleteTransaction(transaction)
                            );
                      }
                    },
                  ),
          )),
    );
  }
}

class PayoffExpansionListTile extends StatelessWidget {
  const PayoffExpansionListTile({
    super.key,
    required this.payoffExController,
    required this.exController,
    required this.item,
    required this.payoff,
    required this.showPieChart,
    required this.index,
    required this.context,
    required this.onEditPressed,
  });

  final List<dynamic> payoffExController;
  final List<ExpansibleController> exController;
  final Item item;
  final Transaction payoff;
  final bool showPieChart;
  final dynamic index;
  final BuildContext context;
  final VoidCallback onEditPressed;

  Future<bool?> showDismissDialog(transaction, BuildContext context, {List<Transaction>? payoffTransactions}) async {
    final cubit = context.read<DetailViewCubit>();

    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomDialog(
          title: dismissDialogTitle,
          content: Text(
            dismissDialogText,
            style: TextStyle(fontSize: 20),
          ),
          onConfirmed: () => cubit.deleteTransaction(transaction, payoffTransactions: payoffTransactions),
        );
      },
    ) as bool?;
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DetailViewCubit>();

    final transactions = item.history.where((Transaction e) => e.payoffId == payoff.id).toList();

    if (payoffExController.length < transactions.length) {
      payoffExController.add([]);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 5),
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          color: Color.fromARGB(255, 64, 64, 88),
        ),
        child: ExpansionTile(
          clipBehavior: Clip.hardEdge,
          maintainState: true,
          controller: exController[index],
          onExpansionChanged: (value) => exController[index].isExpanded
              ? exController.where((e) => e != exController[index]).forEach((e) => e.collapse())
              : payoffExController[index].forEach((e) => e.collapse()),
          dense: true,
          minTileHeight: 10,
          shape: const Border(),
          tilePadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 0),
          childrenPadding: const EdgeInsets.all(0),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(payoffDialogTitle),
              Text(payoff.formatDate())
            ],
          ),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  onPressed: () => showDismissDialog(payoff, context, payoffTransactions: transactions),
                  icon: const Icon(
                    Icons.delete,
                  ),
                ),
                IconButton(
                  onPressed: () => cubit.showPastPayoffDialog(payoff.id),
                  icon: const Icon(
                    Icons.handshake,
                  ),
                )
              ],
            ),
            ListView.builder(
              padding: const EdgeInsets.fromLTRB(0, 5, 0, 0),
              physics: const BouncingScrollPhysics(),
              shrinkWrap: true,
              itemCount: transactions.length,
              itemBuilder: (context, i) {
                if (payoffExController[index].length < transactions.length) {
                  payoffExController[index].add(ExpansibleController());
                }
        
                Transaction transaction = transactions[transactions.length - 1 - i];
                return Container(
                  margin: EdgeInsets.only(bottom: i != transactions.length - 1 ? 5 : 0, left: 0, right: 0),
                  child: TransactionTile(
                    exController: exController, 
                    payoffExController: payoffExController, 
                    item: item,
                    transaction: transaction, 
                    showPieChart: showPieChart,
                    context: context, 
                    onPressed: onEditPressed, 
                    i: index, 
                    j: i
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.exController,
    required this.payoffExController,
    required this.item,
    required this.transaction,
    required this.showPieChart,
    required this.context,
    required this.onPressed,
    required this.i,
    this.j,
  });

  final List<ExpansibleController> exController;
  final List<dynamic> payoffExController;
  final Item item;
  final Transaction transaction;
  final bool showPieChart;
  final BuildContext context;
  final VoidCallback onPressed;
  final int i;
  final int? j;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DetailViewCubit>();

    Color color = Color(item.members.firstWhere((m) => m.id == transaction.memberId).color);
    Color textColor = color.computeLuminance() > 0.2 ? Colors.black : Colors.white;

    List<Member> members = item.members.where((m) => transaction.operations.any((e) => e.memberId == m.id)).toList();

    ExpansibleController exco = j == null ? exController[i] : payoffExController[i][j];

    return Container(
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
        maintainState: true,
        controller: exco,
        onExpansionChanged: (value) => exco.isExpanded ? (j == null ? exController : payoffExController[i]).where((e) => e != exco).forEach((e) => e.collapse()) : cubit.togglePieChart(showPieChart: false),
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
          AnimatedSize(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              reverseDuration: const Duration(milliseconds: 200),
              switchInCurve: Curves.easeInOut,
              switchOutCurve: Curves.easeInOut,
              transitionBuilder: (child, animation) {
                return ScaleTransition(
                  scale: animation,
                  child: child,
                );
              },
              child: showPieChart
                ? TransactionPieChart(context: context, members: members, transaction: transaction, textColor: textColor)
                : TransactionMemberBar(members: members, transaction: transaction, textColor: textColor)
            ),
          ),
          if (!transaction.deleted) Padding(
            padding: const EdgeInsets.all(5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  onPressed: () => cubit.togglePieChart(),
                  icon: Icon(
                    Icons.pie_chart,
                    color: textColor
                  ),
                ),
                IconButton(
                  onPressed: onPressed,
                  icon: Icon(
                    Icons.edit,
                    color: textColor
                  ),
                )
              ],
            ),
          )
          
        ],
      ),
    );
  }
}

class PayoffTile extends StatelessWidget {
  const PayoffTile({
    super.key,
    required this.transaction,
    required this.context,
  });

  final dynamic transaction;
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DetailViewCubit>();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => cubit.showPastPayoffDialog(transaction.id),
      child: Container(
        decoration: BoxDecoration(
          //color: const Color.fromARGB(255, 64, 64, 88),
          borderRadius: BorderRadius.all(Radius.circular(25)),
        ),
        margin: const EdgeInsets.only(bottom: 5),
        padding: const EdgeInsets.fromLTRB(15, 7, 15, 7),
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
          children: [
            Text(payoffDialogTitle),
            Row(
              children: [
                Text(transaction.formatDate()),
                const SizedBox(width: 15),
                Transform.rotate(
                angle: 45 * 3.14159 / 180, // 45 degrees in radians
                child: Icon(Icons.unfold_more),
                )
              ],
            )
          ],
        ),
      )
    );
  }
}