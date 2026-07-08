import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:splizz/bloc/detailview_states.dart';
import 'package:splizz/bloc/transactionDialog_bloc.dart';
import 'package:splizz/data/app_config.dart';
import 'package:splizz/resources/strings.dart';

import 'package:splizz/ui/dialogs/payoffdialog.dart';
import 'package:splizz/ui/dialogs/sharedialog.dart';
import 'package:splizz/ui/dialogs/transactiondialog.dart';
import 'package:splizz/ui/widgets/imageSelection.dart';
import 'package:splizz/ui/widgets/detailviewMemberBar.dart';
import 'package:splizz/bloc/detailview_bloc.dart';
import 'package:splizz/ui/widgets/transactionList.dart';
import 'package:splizz/ui/widgets/uiModels.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

class DetailView extends StatelessWidget { 
  const DetailView({super.key, this.themeMode});

  final themeMode;

  // Show Dialog Methods

  void showTransactionDialog(state, BuildContext context) async {
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
            create: (context) => TransactionDialogCubit(cubit, state.item),
            child: TransactionDialog()
          ),
        );
      },
    );
  }

  void showShareDialog(BuildContext context) {
    final cubit = context.read<DetailViewCubit>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BlocProvider.value(
          value: cubit,
          child: Supabase.instance.client.auth.currentUser == null
            ? const AuthDialog()
            : ShareDialog(),
        );
      },
    );
  }

  void showPayoffDialog(BuildContext context) {
    final cubit = context.read<DetailViewCubit>();

    showDialog(
      context: context, 
      barrierDismissible: true, // user must tap button!
      builder: (BuildContext context) {
        return BlocProvider.value(
          value: cubit, 
          child: PayoffDialog()
        );
      },
    );
  }

  void showPastPayoffDialog(BuildContext context) {
    final cubit = context.read<DetailViewCubit>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BlocProvider.value(
          value: cubit,
          child: PayoffDialog(),
        );
      },
    );
  }

  //Custom Widgets

  Widget payoffButton(unbalanced, BuildContext context) {
    final cubit = context.read<DetailViewCubit>();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(transactions, style: TextStyle(fontSize: 30), textAlign: TextAlign.center),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: unbalanced
                ? Colors.green
                : Theme.of(context).colorScheme.surface),
            child: IconButton(
              splashRadius: 25,
              onPressed: () => cubit.showPayoffDialog(),
              icon: const Icon(
                Icons.handshake,
                color: Colors.white,
              )),
          )
        ],
      ),
    );
  }

  Widget body(BuildContext context) {
    final cubit = context.read<DetailViewCubit>();

    bool isDarkTheme = themeMode == ThemeMode.system
      ? MediaQuery.of(context).platformBrightness == Brightness.dark
      : themeMode == ThemeMode.dark;
    //double imageRadius = window.viewPadding.top - AppBar().preferredSize.height - MediaQuery.of(context).viewPadding.top;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center, 
          children: [
            BlocBuilder<DetailViewCubit, DetailViewState>(
              buildWhen: (previous, current) => 
                current.runtimeType != previous.runtimeType || current.item.image != previous.item.image || current.runtimeType == DetailViewEditMode,
              builder: (context, state) => ClipRRect(
                borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(25)),
                child: state is DetailViewEditMode
                  ? ImageSelection(themeMode: themeMode, state: state, context: context, onImageSelected: (croppedImage) => cubit.changeImage(croppedImage))
                  : state.item.image == null
                    ? Container(
                      color: isDarkTheme ? Colors.white24 : Colors.black26,
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.width / 2.2,
                      child: Icon(Icons.image_not_supported, size: 100, color: const Color.fromARGB(179, 128, 8, 8)))
                    : Image.memory(state.item.image!,
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.width / 2.2,
                        fit: BoxFit.fill
                      ),
              ),
            ),
            const Spacer(),
          ]
        ),
        BlocConsumer<DetailViewCubit, DetailViewState>(
          bloc: cubit,
          listenWhen: (_, current) => current is DetailViewListener,
          listener: (context, state) {
            switch (state.runtimeType) {
              case DetailViewShowTransactionDialog:
                showTransactionDialog(state, context);
                break;
              case DetailViewShowShareDialog:
                showShareDialog(context);
                break;
              case DetailViewShowSnackBar:
                showOverlayMessage(
                  context: context, 
                  message: (state as DetailViewShowSnackBar).message,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                );
                break;
              case DetailViewShowPayoffDialog:
                showPayoffDialog(context);
                break;
              case DetailViewShowPastPayoffDialog:
                showPastPayoffDialog(context);
                break;
            }
          },
          buildWhen: (_, current) =>
            current.runtimeType == DetailViewLoading ||
            current.runtimeType == DetailViewLoaded ||
            current.runtimeType == DetailViewEditMode,
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
                  DetailviewMemberBar(),
                  const Spacer(flex: 2,),
                  payoffButton(state.unbalanced, context),
                  const Spacer(),
                  TransactionList(
                    item: state.item, 
                    showPieChart: state.showPieChart, 
                    context: context),
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
    final cubit = context.read<DetailViewCubit>();

    return BlocBuilder<DetailViewCubit, DetailViewState>(
      bloc: cubit,
      builder: (context, state) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            backgroundColor: Colors.black26,
            title: BlocBuilder<DetailViewCubit, DetailViewState>(
              bloc: cubit,
              builder: (context, state) {
                return state is DetailViewEditMode
                  ? TextField(
                    controller: state.name,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                    ),
                    style: Theme.of(context).textTheme.titleLarge,
                  )
                  : Text(state.item.name);
              },
            ),
            actions: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () { if(state.runtimeType == DetailViewLoaded || state.runtimeType == DetailViewEditMode) cubit.toggleEditMode(update: state.runtimeType == DetailViewEditMode); },
                        icon: state.runtimeType == DetailViewEditMode ? const Icon(Icons.done) : const Icon(Icons.edit)
                      ),
                      IconButton(
                        onPressed: () { 
                          if(state.runtimeType == DetailViewLoaded) cubit.showShareDialog(); 
                          else if (state.runtimeType == DetailViewEditMode) cubit.toggleEditMode();
                        },
                        icon: state.runtimeType == DetailViewEditMode ? const Icon(Icons.cancel_outlined) : const Icon(Icons.share)
                      ),
                    ],
                  )
            ],
          ),
          body: body(context),
          floatingActionButton: state.runtimeType == DetailViewEditMode ? null : AppConfig.isDebug
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
                    onTap: cubit.showTransactionDialog,
                  ),
                  SpeedDialChild(
                    child: const Icon(Icons.bug_report),
                    onTap: () => showLoadingEntry(context: context, onWait: () async => await cubit.addDebugTransaction()),
                  ),
                  // add more options as needed
                ],
              )
            : FloatingActionButton(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
                onPressed: cubit.showTransactionDialog,
                tooltip: addTransaction,
                foregroundColor: Colors.white,
                child: const Icon(Icons.add),
              ),
        );
      },
    );
  }
}
