import 'package:currency_textfield/currency_textfield.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:splizz/models/member.model.dart';
import 'package:splizz/ui/widgets/circularSlider.dart';
import 'package:splizz/bloc/detailview_bloc.dart';
import 'package:splizz/ui/widgets/uiModels.dart';
import 'package:splizz/ui/widgets/customDialog.dart';
import 'package:splizz/bloc/detailview_states.dart';

class TransactionDialog extends StatelessWidget {
  late BuildContext context;
  late DetailViewCubit cubit;
  late List<Member> members;

  final CurrencyTextFieldController currencyController = CurrencyTextFieldController(currencySymbol: '', decimalSymbol: ',', enableNegative: true);
  final TextEditingController descriptionController = TextEditingController();

  TransactionDialog();

  Widget payerBar(selection) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 5),
      physics: const BouncingScrollPhysics(),
      itemCount: this.members.length,
      itemBuilder: (context, i) {
        Color color = selection == i
            ? Color(this.members[i].color)
            : Theme.of(context).colorScheme.surfaceContainer;
        Color textColor = color.computeLuminance() > 0.2 ? Colors.black : Colors.white;

        return PillModel(
          color: color,
          child: TextButton(
            onPressed: () => cubit.changePayer(i),
            child: Text(
              this.members[i].name,
              style: TextStyle(color: textColor, fontSize: 20),
            ),
          ),
        );
      },
    );
  }

  Widget memberBar(memberSelection) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 5),
      physics: const BouncingScrollPhysics(),
      itemCount: this.members.length,
      itemBuilder: (context, i) {
        Color color = memberSelection[i]
            ? Color(this.members[i].color)
            : Theme.of(context).colorScheme.surfaceContainer;
        Color textColor = color.computeLuminance() > 0.2 ? Colors.black : Colors.white;

        return Column(
          children: [
            PillModel(
              color: color,
              child: TextButton(
                onPressed: () => cubit.selectMember(i),
                child: Text(
                  this.members[i].name,
                  style: TextStyle(color: textColor, fontSize: 20),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void showDateSelection(state) {
    if (state is! DetailViewTransactionDialog) return;

    DateTime now = DateTime.now();
    DateTime newDate = state.date[2];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomDialog(
          contentPadding: const EdgeInsets.only(bottom: 0),
          content: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: CalendarDatePicker(
              initialDate: state.date[2],
              firstDate: now.subtract(const Duration(days: 60)),
              lastDate: now,
              onDateChanged: (DateTime pickedDate) => newDate = pickedDate,
            ),
          ),
          onConfirmed: () => cubit.setDate(newDate),
          onDismissed: () => cubit.closeDateSelection(),
        );
      });
  }

  Widget dateBar(state) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 5),
      physics: const BouncingScrollPhysics(),
      itemCount: 3,
      itemBuilder: (context, i) {
        Color color = state.dateSelection == i
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.surfaceContainer;
        Color textColor = color.computeLuminance() > 0.2 ? Colors.black : Colors.white;

        return PillModel(
          color: color,
          child: TextButton(
            onPressed: () => i == 2
                ? showDateSelection(state)
                : cubit.changeDay(i),
            child: Text(
              i == 2
                ? '${state.date[2].day}.${state.date[2].month}.${state.date[2].year}'
                : state.date[i],
              style: TextStyle(color: textColor, fontSize: 15),
            ),
          ),
        );
      },
    );
  }

  //Widget adjustCircle(){
  //  return
  //}

  List<Widget> dialogContent(state) {
    return [
      TextField(
        autofocus: true,
        controller: descriptionController,
        onChanged: (value) {},
        decoration: TfDecorationModel(context: context, title: 'Add a description')
      ),
      SizedBox(
        height: 7.5,
      ),
      TextField(
        controller: currencyController,
        keyboardType: TextInputType.number,
        onChanged: (value) => cubit.updateTransactionValue(value),
        decoration: TfDecorationModel(
          context: context,
          title: '0,00',
          icon: IconButton(
            onPressed: () => cubit.toggleCurrency(),
            icon: state.currency == false
              ? const Icon(Icons.euro)
              : const Icon(Icons.attach_money)
          )
        )
      ),
      if (state.help) Container(
        margin: const EdgeInsets.only(left: 5, top: 5),
        alignment: Alignment.centerLeft,
        child: const Text('Select the person who paid'),
      ),
      SizedBox(
        height: 60, //MediaQuery.of(context).size.height/14,
        child: payerBar(state.selection)),
      SizedBox(
        height: 50,
        child: dateBar(state),
      ),
    ];
  }

  Widget dialog(state) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 100),
      scale: state.scale,
      child: CustomDialog(
        pop: false,
        header: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Add new Transaction",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            GestureDetector(
              child: const Icon(
                Icons.question_mark,
              ),
              onTap: () => !state.help ? cubit.toggleHelp() : null,
            ),
            GestureDetector(
              onTap: () => cubit.showMore(), 
                child: Transform.rotate(
                angle: 45 * 3.14159 / 180, // 45 degrees in radians
                child: Icon(Icons.unfold_more, color: Theme.of(context).colorScheme.primary, size: 30),
                )
            )
          ]
        ),
        content: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min, 
                children: dialogContent(state)
              ),
            )),
        onConfirmed: () => showLoadingEntry(
          context: context, 
          onWait: () async => await cubit.addTransaction(descriptionController.text).then(
            (value) => value.isSuccess ? [cubit.closeTranscationDialog(), Navigator.of(context).pop(true)] : null)
        ),
        onDismissed: () => cubit.closeTranscationDialog(),
      ));
  }

  Widget view(state) {
    final divisions = [
      0.01,
      0.02,
      0.05,
      0.10,
      0.20,
      0.50,
      1.00,
    ];

    return ClipRRect(
      borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        extendBodyBehindAppBar: false,
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          backgroundColor: Colors.black26,
          title: Text("Add new Transaction"),
          actions: [
            GestureDetector(
              child: const Icon(
                Icons.question_mark,
              ),
              onTap: () => !state.help ? cubit.toggleHelp() : null,
            ),
            GestureDetector(
              child: Transform.rotate(
                angle: 45 * 3.14159 / 180, // 45 degrees in radians
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Icon(Icons.unfold_less, color: Theme.of(context).colorScheme.primary, size: 30)
                )
              ),
              onTap: () => cubit.showLess(),
            ),
          ],
        ),
        body: Container(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: dialogContent(state) + [
              if (state.help) Container(
                margin: const EdgeInsets.only(left: 5, top: 5),
                alignment: Alignment.centerLeft,
                child: const Text('Select the members that are involved'),
              ),
              SizedBox(height: 70, child: memberBar(state.memberSelection)),
              if (state.help ) Container(
                margin: const EdgeInsets.only(left: 5, top: 5),
                alignment: Alignment.centerLeft,
                child: const Text("Customize how you want to divide the amount\nThe slider on the right can be used to adjust the stepsize \nAlternatively, for a more granular control toggle the switch"),
              ),
              Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  CircularSlider(),
                  Column(
                    children: [
                      VerticalSlider(
                        value: state.zoomEnabled ? state.involvedMembers[state.lastChangedMemberIndex]['angle'].toDouble() : state.sliderIndex.toDouble(),
                        divisions: state.zoomEnabled ? state.sliderIndex : divisions,
                        onChanged: (value) => state.zoomEnabled
                          ? cubit.granularUpdateCircularSliderPosition(value)
                          : cubit.changeCircularStepsize(divisions[value.toInt()], value),
                      ),
                      SizedBox.fromSize(
                        size: const Size(0, 10),
                      ),
                      Switch(
                        value: state.zoomEnabled, 
                        onChanged: (value) => cubit.toggleZoom(value),
                      )
                    ],
                  )
                ],
              ),
              Spacer(),
              const Divider(
                thickness: 0.5,
                indent: 0,
                endIndent: 0,
              ),
              IntrinsicHeight(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 0),
                      child: Text(
                        "Cancel",
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      onPressed: () {
                        cubit.closeTranscationDialog();
                        Navigator.of(context).pop(false);
                      },
                    )),
                    const VerticalDivider(
                      indent: 5,
                      endIndent: 5,
                    ),
                    Expanded(
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 0),
                        child: Text("Add", style: Theme.of(context).textTheme.labelLarge,),
                        onPressed: () => cubit.addTransaction(descriptionController.text).then((value) => value.isSuccess ? [cubit.closeTranscationDialog(), Navigator.of(context).pop(true)] : null),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    this.context = context;
    this.cubit = context.read<DetailViewCubit>();

    return BlocConsumer(
      bloc: cubit,
      listenWhen: (_, current) => current is DetailViewTransactionDialogShowSnackBar,
      listener: (context, state) {
        if (state is DetailViewTransactionDialogShowSnackBar) {
          showOverlayMessage(
            context: context, 
            message: state.message,
            backgroundColor: Theme.of(context).colorScheme.primary,
          );
        }
      },
      buildWhen: (_, current) => current is DetailViewTransactionDialog,
      builder: (context, state) {
        state as DetailViewTransactionDialog;
        this.members = state.item.members;
        this.members = this.members.where((m) => !m.deleted).toList();
        
        return state.extend ? view(state) : dialog(state);
      },
    );
  }
}

class VerticalSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double>? onChanged;
  final divisions;

  const VerticalSlider({Key? key, required this.value, required this.onChanged, required this.divisions}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RotatedBox(
      quarterTurns: 3,
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          showValueIndicator: ShowValueIndicator.always,
          valueIndicatorShape: PaddleSliderValueIndicatorShape(),
          trackHeight: 7,
          thumbShape: const RoundSliderThumbShape(
            enabledThumbRadius: 15,
          ),
        ),
        child: Builder(
          builder: (context) {
        return SliderTheme(
          data: SliderTheme.of(context).copyWith(
            showValueIndicator: ShowValueIndicator.always,
            valueIndicatorShape: const PaddleSliderValueIndicatorShape(),
          ),
            child: Container(
            width: 150,
            child: Slider(
              min: divisions is List<double> ? 0 : divisions - 0.07,
              max: divisions is List<double> ? divisions.length.toDouble() - 1 : divisions + 0.07,
              divisions: divisions is List<double> ? divisions.length - 1 : null,
              padding: const EdgeInsets.symmetric(horizontal: 0),
              value: value,
              onChanged: onChanged,
              label: divisions is List<double> ? "${divisions[value.toInt()].toStringAsFixed(2)} €" : null,
            ),
            ),
        );
          },
        ),
      ),
      );
  }
}
