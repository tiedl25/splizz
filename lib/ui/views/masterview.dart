import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:splizz/bloc/masterview_states.dart';
import 'package:splizz/resources/helper.dart';
import 'package:splizz/resources/strings.dart';
import 'package:splizz/ui/widgets/uiModels.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:splizz/bloc/detailview_bloc.dart';
import 'package:splizz/bloc/masterview_bloc.dart';

import 'package:splizz/ui/views/authview.dart';
import 'package:splizz/ui/views/detailview.dart';
import 'package:splizz/ui/dialogs/itemdialog.dart';

import 'package:splizz/models/item.model.dart';
import 'package:splizz/ui/widgets/customDialog.dart';

var activeSession = Supabase.instance.client.auth.currentSession;

class SplashView extends StatelessWidget {
  final SharedPreferences prefs;
  final themeMode;

  const SplashView({
    super.key,
    required this.prefs,
    this.themeMode,
  });

  @override
  Widget build(BuildContext context) {
    activeSession = Supabase.instance.client.auth.currentSession;
    return Scaffold(
      body: Center(
        child: activeSession == null && prefs.getBool('offline') == false
          ? AuthView(prefs: prefs)
          : BlocProvider(
              create: (context) => MasterViewCubit(prefs,), 
              child: MasterView(themeMode: themeMode,)
            ),
      ),
    );
  }
}

class MasterView extends StatelessWidget {
  late final BuildContext context;
  late final MasterViewCubit cubit;
  
  final themeMode;

  MasterView({super.key, this.themeMode});

  //Dialogs

  void showInvitationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomDialog(
          content: Text(
            invitedToSplizz2,
            style: TextStyle(fontSize: 20),
          ),
          onConfirmed: () async => await cubit.acceptInvitation(),
          onDismissed: () => cubit.declineInvitation(),
        );
      },
    );
  }

  void showItemDialog() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return BlocProvider.value(
            value: cubit,
            child: ItemDialog(themeMode: themeMode),
          );
        });
  }

  Future<bool?> showDismissDialog(Item item) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomDialog(
          title: dismissDialogTitle,
          content: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                child: Text(
                  dismissDialogTextItem,
                  style: TextStyle(fontSize: 20),
                ),
              ),
            ],
          ),
          onConfirmed: () => cubit.deleteItem(item),
        );
      },
    ) as bool?;
  }

  //Navigation

  void pushSettingsView() {
    Navigator.pushNamed(context, '/settings');
  }

  void pushDetailView(Item item) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return BlocProvider(
            create: (context) => DetailViewCubit(item, masterViewCubit: cubit)..fetchData(),
            child: DetailView(themeMode: themeMode,)
          );
        },
      ),
    ).then((value) => cubit.fetchData(destructive: false),);
  }

  Widget dismissTile(Item item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      decoration: const BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: Dismissible(
        key: UniqueKey(),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) => showDismissDialog(item),
        background: Container(
          padding: const EdgeInsets.only(right: 20),
          alignment: Alignment.centerRight,
          child: const Icon(
            Icons.delete,
          ),
        ),
        child: itemTile(item),
      ),
    );
  }

  Widget itemTile(Item item) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: item.balance == null || approximatelyZero(item.balance!)
          ? Theme.of(context).colorScheme.surfaceContainer
          : item.balance! > 0
            ? Colors.green.shade300
            : Colors.red.shade300,
        border: Border.all(style: BorderStyle.none),
        borderRadius: const BorderRadius.all(Radius.circular(20)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        tileColor: item.balance == null || approximatelyZero(item.balance!)
          ? Theme.of(context).colorScheme.surfaceContainer
          : item.balance! > 0
            ? Colors.green.shade300
            : Colors.red.shade300,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              item.name,
              style: const TextStyle(fontSize: 20),
            ),
            if(item.balance != null) Text(
              item.balance!.toStringAsFixed(2) + '€',
            )
          ],
        ),
        onTap: () => pushDetailView(item),
      ),
    );
  }

  Widget speedDial() => kDebugMode
    ? SpeedDial(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20))),
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
            onTap: cubit.showItemDialog,
          ),
          SpeedDialChild(
              child: const Icon(Icons.bug_report),
              onTap: () async => await showLoadingEntry(context: context, onWait: () async => await cubit.addDebugItem())),
          //SpeedDialChild(
          //    child: const Icon(Icons.remove),
          //    onTap: () => cubit.removeAll()),
          // add more options as needed
        ],
      )
    : FloatingActionButton(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        onPressed: cubit.showItemDialog,
        tooltip: addItem,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      );

  get body => Center(
    child: BlocBuilder<MasterViewCubit, MasterViewState>(
      bloc: this.cubit,
      buildWhen: (_, current) => current.runtimeType == MasterViewLoaded || current.runtimeType == MasterViewLoading,
      builder: (context, state) => state.runtimeType == MasterViewLoaded
        ? RefreshIndicator(
            child: (state as MasterViewLoaded).items.isEmpty
              ? ListView(
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  padding: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.height / 2.5),
                  children: [
                    Center(
                      child: Text(
                        noItemsInList,
                        style: TextStyle(fontSize: 20),
                      ),
                    )
                  ],
                )
              : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if(state.balance != null) ListTile(
                    title: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          currentBalance,
                          style: TextStyle(fontSize: 20),
                        ),
                        Text(
                          '${state.balance!.toStringAsFixed(2)}€',
                          style: TextStyle(fontSize: 20),
                        )
                      ],
                    )
                  ),
                  Expanded(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                      padding: const EdgeInsets.all(16),
                      itemCount: state.items.length,
                      itemBuilder: (context, i) {
                        return dismissTile(state.items[i]);
                      }),
                  ),
                ],
              ),
            onRefresh: () async => cubit.fetchData(destructive: false),
          )
        : const Center(child: CircularProgressIndicator())
    ),
  );

  @override
  Widget build(BuildContext context) {
    this.context = context;
    this.cubit = BlocProvider.of<MasterViewCubit>(context);

    return Scaffold(
      extendBody: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(appTitle),
        actions: [
          IconButton(onPressed: pushSettingsView, icon: const Icon(Icons.settings))
        ],
        systemOverlayStyle: SystemUiOverlayStyle(
            systemNavigationBarColor: Colors.transparent
        ),
      ),
      body: BlocListener<MasterViewCubit, MasterViewState>(
        bloc: cubit,
        listenWhen: (_, current) => current is MasterViewListener,
        listener: (context, state) {
          switch (state.runtimeType) {
            case MasterViewShowSnackBar:
              showOverlayMessage(
                context: context, 
                message: (state as MasterViewShowSnackBar).message,
                backgroundColor: Theme.of(context).colorScheme.primary,
              );
              break;
            case MasterViewPushAuthView:
              Navigator.pushReplacementNamed(context, '/auth');
              break;
            case MasterViewShowInvitationDialog:
              showInvitationDialog();
              break;
            case MasterViewShowItemDialog:
              showItemDialog();
              break;
          }
        },
        child: body,
      ),
      floatingActionButton: speedDial(),
    );
  }
}
