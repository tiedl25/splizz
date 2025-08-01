import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:splizz/bloc/detailview_states.dart';
import 'package:splizz/bloc/transactionDialog_bloc.dart';
import 'package:splizz/models/item.model.dart';

import 'package:splizz/ui/dialogs/payoffdialog.dart';
import 'package:splizz/ui/dialogs/sharedialog.dart';
import 'package:splizz/ui/dialogs/transactiondialog.dart';
import 'package:splizz/ui/widgets/memberBar.dart';
import 'package:splizz/bloc/detailview_bloc.dart';
import 'package:splizz/models/transaction.model.dart';
import 'package:splizz/ui/widgets/uiModels.dart';
import 'package:splizz/ui/widgets/customDialog.dart';
import 'package:splizz/models/member.model.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

class DetailView extends StatelessWidget {
  late BuildContext context;
  late DetailViewCubit cubit;

  List<ExpansibleController> exController = [];

  Image? croppedImage;
  final ImagePicker picker = ImagePicker();

  DetailView();

  // Show Dialog Methods

  void showTransactionDialog(state) async {
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

  void showTransactionEditDialog(Item item, Transaction transaction) async {
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

  void showShareDialog() {
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

  void showPayoffDialog() {
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

  void showPastPayoffDialog() {
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

  Future<bool?> showDismissDialog(transaction, memberMap, index) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomDialog(
          title: 'Confirm Dismiss',
          content: const Text(
            'Do you really want to remove this Transaction',
            style: TextStyle(fontSize: 20),
          ),
          onConfirmed: () => cubit.deleteTransaction(transaction, memberMap, index),
        );
      },
    ) as bool?;
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

  Widget transactionList(state) {
    Map<String, int> memberMap = {};

    int a = 0;
    for (Member m in state.item.members) {
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
            onRefresh: () => cubit.fetchData(),
            child: state.item.history.isEmpty
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
                    itemCount: state.item.history.length,
                    itemBuilder: (context, i) {
                      Transaction transaction = state.item.history[state.item.history.length - 1 - i];

                      if (exController.length < state.item.history.length) {
                        exController.add(ExpansibleController());
                      }

                      if (transaction.description == 'payoff') {
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => cubit.showPastPayoffDialog(state.item.history.length - i - 1),
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
                                child: expansionTile(state, transaction, i),
                              )
                            : dismissibleTile(state, transaction, memberMap, i);
                      }
                    },
                  ),
          )),
    );
  }

  Widget dismissibleTile(state, Transaction transaction, Map<String, int> memberMap, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(20)),
        color: Colors.red,
      ),
      child: Dismissible(
        key: ValueKey(transaction.id),
        //key: UniqueKey(),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) => showDismissDialog(transaction, memberMap, index),
        background: Container(
          padding: const EdgeInsets.only(right: 20),
          alignment: Alignment.centerRight,
          child: const Icon(
            Icons.delete,
          ),
        ),
        child: expansionTile(state, transaction, index)),
    );
  }

  Widget expansionTile(state, Transaction transaction, int index) {
    Color color = Color(state.item.members.firstWhere((m) => m.id == transaction.memberId).color);
    Color textColor = color.computeLuminance() > 0.2 ? Colors.black : Colors.white;

    if (exController.length <= index) {
      exController.add(ExpansibleController());
    }

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
              child: state.showPieChart
                ? transactionPieChart(state, transaction, textColor)
                : transactionMemberBar(state, transaction, textColor)
            ),
          ),
          Padding(
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
                  onPressed: () => showTransactionEditDialog(state.item, transaction),
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

  Widget transactionMemberBar(state, Transaction transaction, Color textColor) {
    return SingleChildScrollView(
      key: const ValueKey('memberBar'),
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Container(
        padding: const EdgeInsets.all(5),
        margin: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: textColor.withAlpha(96),
          border: Border.all(style: BorderStyle.none, width: 0),
          borderRadius: const BorderRadius.all(Radius.circular(20)),
        ),
        child: Row(
          children: List.generate(transaction.operations.length, (index) {
            Member m = state.item.members.firstWhere((element) => element.id == transaction.operations[index].memberId);
            if (index == 0) {
              return Container(
                  padding: const EdgeInsets.only(right: 20, left: 5, top: 5, bottom: 5),
                  margin: const EdgeInsets.all(2),
                  child: Text(
                    m.name,
                    style: TextStyle(color: textColor),
                  ));
            }
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
                style: TextStyle(color: Color(m.color).computeLuminance() > 0.2 ? Colors.black : Colors.white),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget transactionPieChart(state, Transaction transaction, Color textColor) {
    return Container(
      key: const ValueKey('pieChart'),
      decoration: BoxDecoration(
        color: textColor.withAlpha(96),
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(10),
      child: PieChart(
        dataMap: Map.fromIterable(
          transaction.operations,
          key: (e) => state.item.members.firstWhere((m) => m.id == e.memberId).name,
          value: (e) => e.value.abs(),
        ),
        legendOptions: LegendOptions(
          legendPosition: LegendPosition.right,
          showLegends: true,
          legendTextStyle: TextStyle(
            color: textColor,
          ),
        ),
        chartType: ChartType.disc,
        ringStrokeWidth: 20,
        animationDuration: const Duration(milliseconds: 700),
        chartLegendSpacing: 32,
        chartRadius: MediaQuery.of(context).size.width / 2.5,
        colorList: state.item.members.map<Color>((e) => Color(e.color)).toList(),
        initialAngleInDegree: 0,
        formatChartValues: (value) => "${value.toStringAsFixed(2)}€",
        chartValuesOptions: const ChartValuesOptions(
          showChartValues: true,
          showChartValuesInPercentage: false,
          showChartValuesOutside: false,
          decimalPlaces: 2,
          chartValueStyle: TextStyle(
            color: Colors.black,
            fontSize: 16,
          ),
          chartValueBackgroundColor: Colors.transparent,
        )
      )
    );
  }

  Widget imageEdit(DetailViewEditMode state) {
    Uint8List? imageFile = state.imageFile ?? state.item.image;

    return Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.width / 2.2,
        decoration: BoxDecoration(
            image: DecorationImage(
                    image: MemoryImage(imageFile!), //croppedImage!.image,
                    fit: BoxFit.fill)),
        child: Padding(
          padding: const EdgeInsets.only(top: 100),
          child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                      GestureDetector(
                        onTap: () async => await imagePickCropper(ImageSource.camera),
                        child: Icon(Icons.camera_alt,
                            color: Colors.black54,
                            size: 50),
                      ),
                      GestureDetector(
                        onTap: () async => await imagePickCropper(ImageSource.gallery),
                        child: Icon(Icons.image,
                            color: Colors.black54,
                            size: 50),
                      )
                    ]),
        ));
  }

  Future<void> imagePickCropper(imageSource) async {
    final imageFilePath = (await picker.pickImage(source: imageSource));
    if (imageFilePath == null) return;

    final croppedImage = await ImageCropper().cropImage(
      sourcePath: imageFilePath.path,
      aspectRatio: const CropAspectRatio(ratioX: 2.2, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
            toolbarTitle: 'Crop',
            toolbarColor: Theme.of(context).colorScheme.surface,
            toolbarWidgetColor: Colors.white,
            backgroundColor: Theme.of(context).colorScheme.surface),
        IOSUiSettings(
          title: 'Crop',
        ),
      ],
    );

    cubit.changeImage(croppedImage);
  }

  Widget body() {
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
                child: state is DetailViewEditMode ? imageEdit(state) : Image.memory(state.item.image!,
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.width / 2.2,
                  fit: BoxFit.fill),
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
                showTransactionDialog(state);
                break;
              case DetailViewShowShareDialog:
                showShareDialog();
                break;
              case DetailViewShowSnackBar:
                showOverlayMessage(
                  context: context, 
                  message: (state as DetailViewShowSnackBar).message,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                );
                break;
              case DetailViewShowPayoffDialog:
                showPayoffDialog();
                break;
              case DetailViewShowPastPayoffDialog:
                showPastPayoffDialog();
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
                  MemberBar(),
                  const Spacer(flex: 2,),
                  payoffButton(state.unbalanced),
                  const Spacer(),
                  transactionList(state),
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
    this.cubit = context.read<DetailViewCubit>(); //BlocProvider.of<DetailViewBloc>(context);
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
          body: body(),
          floatingActionButton: state.runtimeType == DetailViewEditMode ? null : kDebugMode
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
                tooltip: 'Add Item',
                foregroundColor: Colors.white,
                child: const Icon(Icons.add),
              ),
        );
      },
    );
  }
}
