import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:splizz/models/item.model.dart';

import 'package:splizz/ui/dialogs/payoffdialog.dart';
import 'package:splizz/Dialogs/sharedialog.dart';
import 'package:splizz/ui/dialogs/transactiondialog.dart';
import 'package:splizz/Helper/database.dart';
import 'package:splizz/ui/widgets/memberBar.dart';
import 'package:splizz/bloc/detailview_bloc.dart';
import 'package:splizz/models/transaction.model.dart';
import 'package:splizz/Helper/ui_model.dart';
import 'package:splizz/models/member.model.dart';
import 'package:splizz/models/user.model.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

class DetailView extends StatelessWidget {
  late BuildContext context;
  late DetailViewCubit detailViewCubit;

  DetailView();

  // Show Dialog Methods

  void _showAddDialog() {
    detailViewCubit.showTransactionDialog();

    showDialog(
      context: context, barrierDismissible: true, // user must tap button!
      builder: (_) {
        return BlocProvider.value(
            value: detailViewCubit, child: TransactionDialog());
      },
    );
  }

  Future<void> _showShareDialog(String itemId) async {
    final currentUser = Supabase.instance.client.auth.currentUser;

    if (currentUser != null) {
      User permission =
          await DatabaseHelper.instance.getPermission(itemId, currentUser.id);
      if (!permission.fullAccess) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("You are not authorized to share this item!")));
        return;
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Supabase.instance.client.auth.currentUser == null
            ? const AuthDialog()
            : BlocProvider.value(
                value: detailViewCubit,
                child: ShareDialog(),
              );
      },
    );
  }

  void _showPayoffDialog() {
    showDialog(
      context: context, barrierDismissible: true, // user must tap button!
      builder: (BuildContext context) {
        return BlocProvider.value(
            value: detailViewCubit, child: PayoffDialog(context: context));
      },
    );
  }

  void _showPastPayoffDialog(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BlocProvider.value(
          value: detailViewCubit,
          child: PastPayoffDialog(
            index: index,
          ),
        );
      },
    );
  }

  //Custom Widgets

  Widget payoffButton(unbalanced) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Transactions', style: TextStyle(fontSize: 30), textAlign: TextAlign.center),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: unbalanced
                ? Colors.green
                : Theme.of(context).colorScheme.surface),
            child: IconButton(
              splashRadius: 25,
              onPressed: () {
                if (unbalanced) {
                  _showPayoffDialog();
                }
              },
              icon: const Icon(
                Icons.handshake,
                color: Colors.white,
              )),
          )
        ],
      ),
    );
  }

  Widget transactionList(Item item) {
    Map<String, int> memberMap = {};

    int a = 0;
    for (Member m in item.members) {
      memberMap.addAll({m.id: a});
      a++;
    }

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
            onRefresh: () => detailViewCubit.fetchData(),
            child: item.history.isEmpty
                ? ListView(
                    physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics()),
                    padding: EdgeInsets.symmetric(
                        vertical: MediaQuery.of(context).size.height / 4),
                    children: const [
                        Center(
                          child: Text(
                            "No transactions in list",
                            style: TextStyle(fontSize: 20),
                          ),
                        ),
                      ])
                : ListView.builder(
                    padding: const EdgeInsets.all(10),
                    physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics()),
                    shrinkWrap: false,
                    itemCount: item.history.length,
                    itemBuilder: (context, i) {
                      Transaction transaction =
                          item.history[item.history.length - 1 - i];
                      if (transaction.description == 'payoff') {
                        return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _showPastPayoffDialog(
                                item.history.length - i - 1),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Payoff'),
                                  Text(transaction.formatDate())
                                ],
                              ),
                            ));
                      } else {
                        return transaction.deleted
                            ? Container(
                                margin: const EdgeInsets.only(bottom: 5),
                                child: expansionTile(transaction, memberMap, item),
                              )
                            : dismissibleTile(transaction, memberMap, i, item);
                      }
                    },
                  ),
          )),
    );
  }

  Widget dismissibleTile(Transaction transaction, Map<String, int> memberMap, int index, Item item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(20)),
        color: Colors.red,
      ),
      child: Dismissible(
          key: UniqueKey(),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) {
            return showDialog(
              context: context,
              builder: (BuildContext context) {
                return DialogModel(
                  title: 'Confirm Dismiss',
                  content: const Text(
                    'Do you really want to remove this Transaction',
                    style: TextStyle(fontSize: 20),
                  ),
                  onConfirmed: () => detailViewCubit.deleteTransaction(
                      transaction, memberMap, index),
                );
              },
            );
          },
          background: Container(
            padding: const EdgeInsets.only(right: 20),
            alignment: Alignment.centerRight,
            child: const Icon(
              Icons.delete,
            ),
          ),
          child: expansionTile(transaction, memberMap, item)),
    );
  }

  Widget expansionTile(Transaction transaction, Map<String, int> memberMap, Item item) {
    Color color = Color(item.members[memberMap[transaction.memberId]!].color);
    Color textColor = color.computeLuminance() > 0.2 ? Colors.black : Colors.white;

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
        //expandedCrossAxisAlignment: CrossAxisAlignment.start,
        expandedAlignment: Alignment.centerLeft,
        shape: const Border(),
        collapsedIconColor: Colors.black,
        iconColor: Colors.black,
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
              '${transaction.value.toString()}€',
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
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Container(
              padding: const EdgeInsets.all(5),
              margin: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: const Color(0xAAD5D5D5),
                border: Border.all(style: BorderStyle.none, width: 0),
                borderRadius: const BorderRadius.all(Radius.circular(20)),
              ),
              child: Row(
                children: List.generate(transaction.operations.length, (index) {
                  if (index == 0) {
                    return Container(
                        padding: const EdgeInsets.only(right: 20, left: 5, top: 5, bottom: 5),
                        margin: const EdgeInsets.all(2),
                        child: Text(
                          item.members[memberMap[transaction.memberId]!].name,
                          style: const TextStyle(color: Colors.black),
                        ));
                  }
                  Member m = item.members[memberMap[transaction.operations[index].memberId]!];
                  return Container(
                    padding: const EdgeInsets.all(5),
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Color(m.color),
                      border: Border.all(style: BorderStyle.none, width: 0),
                      borderRadius: const BorderRadius.all(Radius.circular(20)),
                    ),
                    child: Text(
                      m.name,
                      style: const TextStyle(color: Colors.black),
                    ),
                  );
                }),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget body(BuildContext context) {
    //double imageRadius = window.viewPadding.top - AppBar().preferredSize.height - MediaQuery.of(context).viewPadding.top;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center, 
          children: [
            BlocBuilder<DetailViewCubit, DetailViewState>(
              buildWhen: (previous, current) =>
                current.item.image != previous.item.image,
              builder: (context, state) => ClipRRect(
                borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(25)),
                child: Image.memory(state.item.image!,
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.width / 2.2,
                  fit: BoxFit.fill),
              ),
            ),
            const Spacer(),
          ]
        ),
        BlocBuilder<DetailViewCubit, DetailViewState>(
          bloc: detailViewCubit,
          buildWhen: (previous, current) =>
            current.runtimeType == DetailViewLoading ||
            current.runtimeType == DetailViewLoaded,
          builder: (BuildContext context, DetailViewState state) {
            if (state.runtimeType == DetailViewLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            } else if (state.runtimeType == DetailViewLoaded) {
              state = state as DetailViewLoaded;

              return Expanded(
                  child: Column(
                children: [
                  const Spacer(),
                  MemberBar(context: context,),
                  const Spacer(flex: 2,),
                  payoffButton(state.unbalanced),
                  const Spacer(),
                  transactionList(state.item),
                ],
              ));
            } else {
              return const Center();
            }
          }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    this.context = context;
    this.detailViewCubit = context.read<DetailViewCubit>(); //BlocProvider.of<DetailViewBloc>(context);

    detailViewCubit.fetchData();

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.black26,
        title: BlocBuilder<DetailViewCubit, DetailViewState>(
          bloc: detailViewCubit,
          builder: (context, state) {
            return Text(state.item.name);
          },
        ),
        actions: [
          BlocBuilder<DetailViewCubit, DetailViewState>(
            bloc: detailViewCubit,
            builder: (context, state) {
              return IconButton(
                  onPressed: () => _showShareDialog(state.item.id), icon: const Icon(Icons.share));
            },
          ),
        ],
      ),
      body: body(context),
      floatingActionButton: kDebugMode
        ? SpeedDial(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
            spacing: 5,
            animatedIcon: AnimatedIcons.menu_close,
            animatedIconTheme: const IconThemeData(size: 22.0),
            foregroundColor: Colors.white,
            curve: Curves.bounceIn,
            overlayColor: Colors.black,
            overlayOpacity: 0.5,
            children: [
              SpeedDialChild(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                child: const Icon(Icons.add),
                onTap: _showAddDialog,
              ),
              SpeedDialChild(
                child: const Icon(Icons.bug_report),
                onTap: () => detailViewCubit.addDebugTransaction(),
              ),
              // add more options as needed
            ],
          )
        : FloatingActionButton(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
            onPressed: _showAddDialog,
            tooltip: 'Add Item',
            foregroundColor: Colors.white,
            child: const Icon(Icons.add),
          ),
    );
  }
}
