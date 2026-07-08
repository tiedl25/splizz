import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:splizz/bloc/transactionDialog_bloc.dart';
import 'package:splizz/bloc/transactionDialog_states.dart';
import 'package:splizz/models/member.model.dart';
import 'package:splizz/resources/money_divisions.dart';
import 'package:splizz/resources/strings.dart';
import 'package:splizz/ui/widgets/circularSlider.dart';
import 'package:splizz/ui/widgets/uiModels.dart';
import 'package:splizz/ui/widgets/customDialog.dart';

class TransactionDialog extends StatelessWidget {
  const TransactionDialog({
    this.edit = false
  });

  final bool edit;

  @override
  Widget build(BuildContext context) {
    TransactionDialogCubit cubit = context.read<TransactionDialogCubit>();

    return BlocConsumer(
      bloc: cubit,
      listenWhen: (_, current) => current is TransactionDialogShowSnackBar,
      listener: (context, state) {
        if (state is TransactionDialogShowSnackBar) {
          showOverlayMessage(
            context: context, 
            message: state.message,
            backgroundColor: Theme.of(context).colorScheme.primary,
          );
        }
      },
      buildWhen: (_, current) => current is TransactionDialogLoaded,
      builder: (context, state) {
        state as TransactionDialogLoaded;
        List<Member> members = state.item.members;
        members = members.where((m) => !m.deleted).toList();
        
        return state.extend ? ExtendedContent(context: context, edit: edit, cubit: cubit, state: state, members: members) : CollapsedContent(edit: edit, context: context, cubit: cubit, state: state, members: members);
      },
    );
  }
}

class DateBar extends StatelessWidget {
  const DateBar({
    super.key,
    required this.date,
    required this.dateSelection,
    required this.cubit
  });

  final List date;
  final int dateSelection;
  final TransactionDialogCubit cubit;

  void showDateSelection(date, context) {
    DateTime now = DateTime.now();
    DateTime newDate = date[2];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomDialog(
          contentPadding: const EdgeInsets.only(bottom: 0),
          content: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: CalendarDatePicker(
              initialDate: date[2],
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

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 5),
      physics: const BouncingScrollPhysics(),
      itemCount: 3,
      itemBuilder: (context, i) {
        Color color = dateSelection == i
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.surfaceContainer;
        Color textColor = color.computeLuminance() > 0.2 ? Colors.black : Colors.white;

        return PillModel(
          color: color,
          child: TextButton(
            onPressed: () => i == 2
                ? showDateSelection(date, context)
                : cubit.changeDay(i),
            child: Text(
              i == 2
                ? '${date[2].day}.${date[2].month}.${date[2].year}'
                : date[i],
              style: TextStyle(color: textColor, fontSize: 15),
            ),
          ),
        );
      },
    );
  }
}

class MemberBar extends StatelessWidget {
  const MemberBar({
    super.key,
    required this.members,
    required this.memberSelection,
    required this.onSelected,
  });

  final List<Member> members;
  final dynamic memberSelection;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
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
                onPressed: () => onSelected(i),
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
}

class PayerBar extends StatelessWidget {
  const PayerBar({
    super.key,
    required this.members,
    required this.selection,
    required this.onSelected,
  });

  final List<Member> members;
  final dynamic selection;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
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
            onPressed: () => onSelected(i),
            child: Text(
              this.members[i].name,
              style: TextStyle(color: textColor, fontSize: 20),
            ),
          ),
        );
      },
    );
  }
}


// A list of widgets that is used in the transaction dialog. This is a mixin that can be used in both the extended and collapsed content of the dialog.
mixin TransactionDialogContent {
  List<Widget> dialogContent(state, context, cubit, members) {
    return [
      TextField(
        autofocus: true,
        controller: state.descriptionController,
        onChanged: (value) {},
        decoration: TfDecorationModel(context: context, title: addDescription)
      ),
      SizedBox(
        height: 7.5,
      ),
      TextField(
        controller: state.currencyController,
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
        child: Text(selectPayingPerson),
      ),
      SizedBox(
        height: 60, //MediaQuery.of(context).size.height/14,
        child: PayerBar(
          selection: state.selection,
          members: members,
          onSelected: (index) => cubit.changePayer(index)
        )),
      SizedBox(
        height: 50,
        child: DateBar(
          date: state.date,
          dateSelection: state.dateSelection,
          cubit: cubit
        ),
      ),
    ];
  }
}

// The content of the transaction dialog when it is extended. This includes everything the collapsed version has, plus the circular slider, the vertical slider, and the switch to toggle between the two.
class ExtendedContent extends StatelessWidget with TransactionDialogContent {
  const ExtendedContent({
    super.key,
    required this.context,
    required this.edit,
    required this.cubit,
    required this.state,
    required this.members,
  });

  final BuildContext context;
  final bool edit;
  final TransactionDialogCubit cubit;
  final dynamic state;
  final List<Member> members;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        extendBodyBehindAppBar: false,
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          backgroundColor: Colors.black26,
          title: Text(this.edit ? transactionDialogEditTitle : transactionDialogAddTitle),
          leading: GestureDetector(
            child: const Icon(
              Icons.arrow_back,
            ),
            onTap: () => Navigator.of(context).pop(false),
          ),
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
        body: body(context),
      ),
    );
  }

  SingleChildScrollView body(BuildContext context) {
    return SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height - 120,
          padding: const EdgeInsets.all(10),
          child: Column(
            children: dialogContent(state, context, cubit, members) + [
              if (state.help) Container(
                margin: const EdgeInsets.only(left: 5, top: 5),
                alignment: Alignment.centerLeft,
                child: Text(transactionDialogHelpMembers),
              ),
              SizedBox(
                height: 70, 
                child: MemberBar(
                  memberSelection: state.memberSelection, 
                  members: members, 
                  onSelected: (index) => cubit.selectMember(index)
                )
              ),
              if (state.help ) Container(
                margin: const EdgeInsets.only(left: 5, top: 5),
                alignment: Alignment.centerLeft,
                child: Text(transactionDialogHelpCircularSlider),
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
              Spacer(flex: 5),
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
                        dialogCancel,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      onPressed: () => Navigator.of(context).pop(false),
                    )),
                    const VerticalDivider(
                      indent: 5,
                      endIndent: 5,
                    ),
                    Expanded(
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 0),
                        child: Text(edit ? dialogOk : dialogAdd, style: Theme.of(context).textTheme.labelLarge,),
                        onPressed: () async => await (edit ? cubit.editTransaction() : cubit.addTransaction()).then(
                          (value) => value.isSuccess ? Navigator.of(context).pop(true) : null)
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
  }
}

// The content of the transaction dialog when it is collapsed. This includes the description and currency text fields, the payer bar, and the date bar.
class CollapsedContent extends StatelessWidget with TransactionDialogContent {
  const CollapsedContent({
    super.key,
    required this.edit,
    required this.context,
    required this.cubit,
    required this.state,
    required this.members,
  });

  final bool edit;
  final BuildContext context;
  final TransactionDialogCubit cubit;
  final dynamic state;
  final List<Member> members;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 100),
      scale: state.scale,
      child: CustomDialog(
        pop: false,
        rightText: edit ? dialogOk : dialogAdd,
        header: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              edit ? transactionDialogEditTitle : transactionDialogAddTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Spacer(),
            GestureDetector(
              child: const Icon(
                Icons.question_mark,
              ),
              onTap: () => !state.help ? cubit.toggleHelp() : null,
            ),
            SizedBox(width: 10),
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
                children: dialogContent(state, context, cubit, members)
              ),
            )),
        onConfirmed: () => showLoadingEntry(
          context: context, 
          onWait: () async => await (edit ? cubit.editTransaction() : cubit.addTransaction()).then(
            (value) => value.isSuccess ? Navigator.of(context).pop(true) : null)
        ),
      ));
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
