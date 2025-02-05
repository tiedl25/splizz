import 'package:currency_textfield/currency_textfield.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:splizz/ui/widgets/circularSlider.dart';
import 'package:splizz/bloc/detailview_bloc.dart';
import 'package:splizz/Helper/ui_model.dart';
import 'package:splizz/bloc/detailview_states.dart';

class TransactionDialog extends StatelessWidget {
  late BuildContext context;
  late DetailViewCubit cubit;

  final CurrencyTextFieldController currencyController = CurrencyTextFieldController(currencySymbol: '', decimalSymbol: ',');
  final TextEditingController descriptionController = TextEditingController();

  TransactionDialog();

  Widget payerBar(state) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 5),
      physics: const BouncingScrollPhysics(),
      itemCount: state.item.members.length,
      itemBuilder: (context, i) {
        Color color = state.selection == i
            ? Color(state.item.members[i].color)
            : Theme.of(context).colorScheme.surfaceContainer;
        Color textColor = color.computeLuminance() > 0.2 ? Colors.black : Colors.white;

        return PillModel(
          color: color,
          child: TextButton(
            onPressed: () => cubit.changePayer(i),
            child: Text(
              state.item.members[i].name,
              style: TextStyle(color: textColor, fontSize: 20),
            ),
          ),
        );
      },
    );
  }

  Widget memberBar(state) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 5),
      physics: const BouncingScrollPhysics(),
      itemCount: state.item.members.length,
      itemBuilder: (context, i) {
        Color color = state.memberSelection[i]
            ? Color(state.item.members[i].color)
            : Theme.of(context).colorScheme.surfaceContainer;
        Color textColor = color.computeLuminance() > 0.2 ? Colors.black : Colors.white;

        return Column(
          children: [
            PillModel(
              color: color,
              child: TextButton(
                onPressed: () => cubit.selectMember(i),
                child: Text(
                  state.item.members[i].name,
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
        return DialogModel(
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

  Widget dialog(state) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 100),
      scale: state.scale,
      child: DialogModel(
        title: 'Add new Transaction',
        content: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(
                  autofocus: true,
                  controller: descriptionController,
                  onChanged: (value) {},
                  decoration: TfDecorationModel(context: context, title: 'Add a description')),
                Container(
                  margin: const EdgeInsets.only(left: 5, top: 5),
                  alignment: Alignment.centerLeft,
                  child: const Text('Who payed?'),
                ),
                SizedBox(
                  height: 60, //MediaQuery.of(context).size.height/14,
                  child: payerBar(state)),
                TextField(
                  controller: currencyController,
                  keyboardType: TextInputType.number,
                  onChanged: (value) => cubit.updateTransactionValue(double.parse(value.replaceFirst(",", "."))),
                  decoration: TfDecorationModel(
                    context: context,
                    title: '0,00',
                    icon: IconButton(
                      onPressed: () => cubit.toggleCurrency(),
                      icon: state.currency == false
                        ? const Icon(Icons.euro)
                        : const Icon(Icons.attach_money)))),
                SizedBox(
                  height: 50,
                  child: dateBar(state),
                ),
                Container(
                  //margin: const EdgeInsets.only(left: 0, top: 5),
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    child: Text('Show more'),
                    onPressed: () => cubit.showMore(),
                  ),
                ),
              ]),
            )),
        onConfirmed: () => cubit.addTransaction(descriptionController.text),
        onDismissed: () => cubit.closeTranscationDialog(),
      ));
  }

  Widget view(state) {
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
        ),
        body: Container(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              TextField(
                autofocus: true,
                controller: descriptionController,
                onChanged: (value) {
                  //setState(() {
                  //});
                },
                decoration: TfDecorationModel(
                    context: context, title: 'Add a description')),
              Container(
                margin: const EdgeInsets.only(left: 5, top: 5),
                alignment: Alignment.centerLeft,
                child: const Text('Who payed?'),
              ),
              SizedBox(
                height: 60, //MediaQuery.of(context).size.height/14,
                child: payerBar(state)),
              TextField(
                controller: currencyController,
                keyboardType: TextInputType.number,
                onChanged: (value) => cubit.updateTransactionValue(double.parse(value.replaceFirst(",", "."))),
                decoration: TfDecorationModel(
                  context: context,
                  title: '0,00',
                  icon: IconButton(
                    onPressed: () => cubit.toggleCurrency(),
                    icon: state.currency == false
                      ? const Icon(Icons.euro)
                      : const Icon(Icons.attach_money)))),
              SizedBox(
                height: 50,
                child: dateBar(state),
              ),
              Container(
                margin: const EdgeInsets.only(left: 5, top: 5),
                alignment: Alignment.centerLeft,
                child: const Text('For whom?'),
              ),
              SizedBox(height: 70, child: memberBar(state)),
              Spacer(),
              CircularSlider(),
              Spacer(),
              Container(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  child: Text('Show less'),
                  onPressed: () => cubit.showLess(),
                ),
              ),
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
                        onPressed: () {
                          cubit.addTransaction(descriptionController.text);
                          Navigator.of(context).pop(true);
                        }),
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

    return BlocBuilder(
      bloc: cubit,
      buildWhen: (_, current) => current is DetailViewTransactionDialog,
      builder: (context, state) {
        return (state as DetailViewTransactionDialog).extend ? view(state) : dialog(state);
      },
    );
  }
}
