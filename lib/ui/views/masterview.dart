import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:splizz/bloc/masterview_states.dart';
import 'package:splizz/data/app_config.dart';
import 'package:splizz/resources/utils.dart';
import 'package:splizz/resources/strings.dart';
import 'package:splizz/ui/widgets/dismissTile.dart';
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
  final themeMode;

  MasterView({super.key, this.themeMode});

  //Dialogs

  void showInvitationDialog(BuildContext context) {
    final cubit = context.read<MasterViewCubit>();

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

  void showItemDialog(BuildContext context) {
    final cubit = context.read<MasterViewCubit>();

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return BlocProvider.value(
            value: cubit,
            child: ItemDialog(themeMode: themeMode),
          );
        });
  }

  //Navigation

  void pushSettingsView(BuildContext context) {
    Navigator.pushNamed(context, '/settings');
  }

  void pushDetailView(Item item, BuildContext context) {
    final cubit = context.read<MasterViewCubit>();

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return BlocProvider(
            create: (context) => DetailViewCubit(item, masterViewCubit: cubit),
            child: DetailView(themeMode: themeMode,)
          );
        },
      ),
    ).then((value) => cubit.fetchData(),);
  }

  Widget speedDial(BuildContext context) {
    final cubit = context.read<MasterViewCubit>();

    return AppConfig.isDebug
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
          SpeedDialChild(
              child: const Icon(Icons.remove),
              onTap: () => cubit.removeAll()),
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
  }

  body(BuildContext context) {
    final cubit = context.read<MasterViewCubit>();

    return Center(
    child: BlocBuilder<MasterViewCubit, MasterViewState>(
      bloc: cubit,
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
                        return DismissTile(
                          id: state.items[i].id, 
                          context: context, 
                          child: ItemTile(
                            item: state.items[i], 
                            context: context, 
                            themeMode: themeMode, 
                            onTap: () => pushDetailView(state.items[i], context)
                          ),
                          onPressed: () => cubit.deleteItem(state.items[i])
                        );
                      }),
                  ),
                ],
              ),
            onRefresh: () async => cubit.fetchData(),
          )
        : const Center(child: CircularProgressIndicator())
    ),
  );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MasterViewCubit>();

    return Scaffold(
      extendBody: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(appTitle),
        actions: [
          IconButton(onPressed: () => pushSettingsView(context), icon: const Icon(Icons.settings))
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
              showInvitationDialog(context);
              break;
            case MasterViewShowItemDialog:
              showItemDialog(context);
              break;
          }
        },
        child: body(context),
      ),
      floatingActionButton: speedDial(context),
    );
  }
}

class ItemTile extends StatelessWidget {
  const ItemTile({
    super.key,
    required this.item,
    required this.context,
    required this.themeMode,
    required this.onTap,
  });

  final Item item;
  final BuildContext context;
  final themeMode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
        onTap: onTap,
      ),
    );
  }
}
