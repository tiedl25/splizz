import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:splizz/bloc/masterview_states.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:splizz/bloc/detailview_bloc.dart';
import 'package:splizz/bloc/masterview_bloc.dart';
import 'package:splizz/bloc/settingsview_bloc.dart';

import 'package:splizz/ui/views/authview.dart';
import 'package:splizz/ui/views/detailview.dart';
import 'package:splizz/ui/views/settingsview.dart';
import 'package:splizz/ui/dialogs/itemdialog.dart';

import 'package:splizz/models/item.model.dart';
import 'package:splizz/ui/widgets/uiModels.dart';
import 'package:splizz/ui/widgets/customDialog.dart';

var activeSession = Supabase.instance.client.auth.currentSession;

class SplashView extends StatelessWidget {
  final Function updateTheme;
  final SharedPreferences prefs;

  const SplashView({
    super.key,
    required this.updateTheme,
    required this.prefs,
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
              child: MasterView()
            ),
      ),
    );
  }
}

class MasterView extends StatelessWidget {
  late final BuildContext context;
  late final MasterViewCubit cubit;

  //Dialogs

  void showInvitationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomDialog(
          content: Text(
            'You are invited to a Splizz. Do you want to join?',
            style: TextStyle(fontSize: 20),
          ),
          onConfirmed: () async => cubit.acceptInvitation(),
          onDismissed: () async => cubit.declineInvitation(),
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
            child: ItemDialog(),
          );
        });
  }

  void showDismissDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomDialog(
          title: 'Confirm Dismiss',
          content: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                child: const Text(
                  'Do you really want to remove this Item',
                  style: TextStyle(fontSize: 20),
                ),
              ),
            ],
          ),
          onConfirmed: null
        );
      },
    );
  }

  //Navigation

  void pushSettingsView() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return BlocProvider(
            create: (context) => SettingsViewCubit(),
            child: SettingsView(),
          );
        },
      ),
    );
  }

  void pushDetailView(Item item) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return BlocProvider(
            create: (context) => DetailViewCubit(item)..fetchData(),
            child: DetailView()
          );
        },
      ),
    );
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
        onDismissed: (_) async => cubit.deleteItem(item),
        confirmDismiss: (_) => cubit.showDismissDialog(),
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
        color: Theme.of(context).colorScheme.surfaceContainer,
        border: Border.all(style: BorderStyle.none),
        borderRadius: const BorderRadius.all(Radius.circular(20)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        tileColor: Theme.of(context).colorScheme.surfaceContainer,
        title: Text(
          item.name,
          style: const TextStyle(fontSize: 20),
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
              onTap: () => cubit.addDebugItem()),
          SpeedDialChild(
              child: const Icon(Icons.remove),
              onTap: () => cubit.removeAll()),
          // add more options as needed
        ],
      )
    : FloatingActionButton(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        onPressed: cubit.showItemDialog,
        tooltip: 'Add Transaction',
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
                  children: const [
                    Center(
                      child: Text(
                        'No items in list',
                        style: TextStyle(fontSize: 20),
                      ),
                    )
                  ],
                )
              : ListView.builder(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                padding: const EdgeInsets.all(16),
                itemCount: state.items.length,
                itemBuilder: (context, i) {
                  return dismissTile(state.items[i]);
                }),
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Splizz'),
        actions: [
          IconButton(onPressed: pushSettingsView, icon: const Icon(Icons.settings))
        ],
        systemOverlayStyle: SystemUiOverlayStyle(
          systemNavigationBarColor:
              Theme.of(context).colorScheme.surface, // Navigation bar
        ),
      ),
      body: BlocListener<MasterViewCubit, MasterViewState>(
        bloc: cubit,
        listenWhen: (_, current) => current is MasterViewListener,
        listener: (context, state) {
          switch (state.runtimeType) {
            case MasterViewShowSnackBar:
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text((state as MasterViewShowSnackBar).message)));
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
            case MasterViewShowDismissDialog:
              showDismissDialog();
              break;
          }
        },
        child: body,
      ),
      floatingActionButton: speedDial(),
    );
  }
}
