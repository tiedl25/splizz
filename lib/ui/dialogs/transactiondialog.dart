import 'package:currency_textfield/currency_textfield.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:splizz/Helper/circularSlider.dart';
import 'package:splizz/bloc/detailview_bloc.dart';
import 'package:splizz/models/item.model.dart';
import 'package:splizz/Helper/ui_model.dart';

class TransactionDialog extends StatelessWidget{
  final Item item;
  late BuildContext context;
  late DetailViewBloc detailViewBloc;

  final CurrencyTextFieldController currencyController = CurrencyTextFieldController(currencySymbol: '', decimalSymbol: ',');
  final TextEditingController descriptionController = TextEditingController();

  TransactionDialog({required this.item});

  Widget payerBar(state){
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 5),
      physics: const BouncingScrollPhysics(),
      itemCount: item.members.length,
      itemBuilder: (context, i) {
        Color color = state.selection==i ? Color(item.members[i].color) : Theme.of(context).colorScheme.surface;
        Color textColor = color.computeLuminance() > 0.2 ? Colors.black : Colors.white;

        return PillModel(
          color: color,
          child: TextButton(
            onPressed: () => detailViewBloc.changePayer(i),
            child: Text(item.members[i].name, style: TextStyle(color: textColor, fontSize: 20),),
          ),
        );
      },
    );
  }

  Widget memberBar(state){
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 5),
      physics: const BouncingScrollPhysics(),
      itemCount: item.members.length,
      itemBuilder: (context, i) {
        Color color = state.memberSelection[i] ? Color(item.members[i].color) : Theme.of(context).colorScheme.surface;
        Color textColor = color.computeLuminance() > 0.2 ? Colors.black : Colors.white;
        //if (_memberBalances.length < item.members.length) {
        //  _memberBalances.add(1.0);
        //}

        return Column(
          children: [
            PillModel(
              color: color, 
              child: TextButton(
                onPressed: () => detailViewBloc.selectMember(i),
                child: Text(item.members[i].name, style: TextStyle(color: textColor, fontSize: 20),),
              ),
            ),
            
            //RotatedBox(
            //  quarterTurns: 3,
            //  child: Slider(
            //    divisions: 10,
            //    activeColor: _memberSelection[i] ? item.members[i].color : Theme.of(context).colorScheme.surface,
            //    value: _memberBalances[i],
            //    label: _memberBalances[i].toString(),
            //    min: 0, 
            //    max: 1, 
            //    onChanged: (value){
            //      setState(() {
            //        _memberBalances[i] = value;
            //      });
            //    }
            //  )
            //)
          ],
        );
      },
    );
  }

  void showDateSelection(){
    BlocListener<DetailViewBloc, DetailViewState>(
      listenWhen: (previous, current) => current is DateSelectionDialog,
      listener: (context, state) {
        if (state is !DateSelectionDialog) return;

        showDialog(context: context, builder: (BuildContext context) {
          DateTime? pickedDate=state.day;
          return DialogModel(
            contentPadding: const EdgeInsets.only(bottom: 0),
            content: SizedBox(
              width: MediaQuery.of(context).size.width,
              child: CalendarDatePicker(
                initialDate: state.day,
                firstDate: state.day.subtract(const Duration(days: 60)),
                lastDate: state.day,
                onDateChanged: (DateTime value) { pickedDate=value; },
              ),
            ),
            onConfirmed: () => detailViewBloc.setDate(pickedDate),
          );
        });
      },
    );
  }

  Widget dateBar(state){
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 5),
      physics: const BouncingScrollPhysics(),
      itemCount: 3,
      itemBuilder: (context, i) {
        Color color = state.dateSelection==i ? Theme.of(context).colorScheme.surfaceTint : Theme.of(context).colorScheme.surface;
        Color textColor = color.computeLuminance() > 0.2 ? Colors.black : Colors.white;

        return PillModel(
            color: color,
            child: TextButton(
            onPressed: () => detailViewBloc.changeDate(i),
            child: Text(i==2 ? '${state.date[2].day}.${state.date[2].month}.${state.date[2].year}' : state.date[i], style: TextStyle(color: textColor ,fontSize: 15),),
          ),
        );
      },
    );
  }

  //Widget adjustCircle(){
  //  return 
  //}

  Widget dialog(state){
    return AnimatedScale(
      duration: const Duration(milliseconds: 100),
      scale: state.scale,
      child: DialogModel(
        title: 'Add new Transaction',
        content: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                            autofocus: true,
                            controller: descriptionController,
                            onChanged: (value) {
                              //setState(() {
                              //});
                            },
                            decoration: TfDecorationModel(context: context, title: 'Add a description')
                        ),
                        Container(
                          margin: const EdgeInsets.only(left: 5, top: 5),
                          alignment: Alignment.centerLeft,
                          child: const Text('Who payed?'),
                        ),
                        SizedBox(
                            height: 60,//MediaQuery.of(context).size.height/14,
                            child: payerBar(state)
                        ),
                        TextField(
                            controller: currencyController,
                            decoration: TfDecorationModel(
                                context: context,
                                title: '0,00',
                                icon: IconButton(
                                    onPressed: ()=> detailViewBloc.toggleCurrency(),
                                    icon: state.currency==false ? const Icon(Icons.euro) : const Icon(Icons.attach_money)
                                )
                            )
                        ),
                        SizedBox(
                          height: 50,
                          child: dateBar(state),
                        ),
                        Container(
                          //margin: const EdgeInsets.only(left: 0, top: 5),
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            child: Text('Show more'),
                            onPressed: (){
                              detailViewBloc.toggleExtend();
                              Future.delayed(const Duration(milliseconds: 100), (){
                                detailViewBloc.toggleExtendDelayed();
                              });
                            }
                          ),
                        ),
                      ]
                  ),
            )
        ),
        onConfirmed: () => detailViewBloc.addTransaction(currencyController.doubleValue, descriptionController.text),
        onDismissed: () => detailViewBloc.closeTranscationDialog(),     
      )
    );
  }

  Widget view(state){
    return ClipRRect(
      borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        extendBodyBehindAppBar: false,
        backgroundColor: Theme.of(context).colorScheme.background,
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
                  decoration: TfDecorationModel(context: context, title: 'Add a description')
              ),
              Container(
                margin: const EdgeInsets.only(left: 5, top: 5),
                alignment: Alignment.centerLeft,
                child: const Text('Who payed?'),
              ),
              SizedBox(
                  height: 60,//MediaQuery.of(context).size.height/14,
                  child: payerBar(state)
              ),
              TextField(
                  controller: currencyController,
                  onChanged: (value) {
                    //setState(() {
                    //});
                  },
                  decoration: TfDecorationModel(
                      context: context,
                      title: '0,00',
                      icon: IconButton(
                          onPressed: () => detailViewBloc.toggleCurrency(),
                          icon: state.currency==false ? const Icon(Icons.euro) : const Icon(Icons.attach_money)
                      )
                  )
              ),
              SizedBox(
                height: 50,
                child: dateBar(state),
              ),
              Container(
                margin: const EdgeInsets.only(left: 5, top: 5),
                alignment: Alignment.centerLeft,
                child: const Text('For whom?'),
              ),
              SizedBox(
                  height: 70,
                  child: memberBar(state)
              ),
              Spacer(),
              CircularSlider(
                sum: currencyController.doubleValue,
                members: item.members,
                memberBalances: state.memberBalances,
                memberSelection: state.memberSelection,
                getInvolvedMembers: (value) => detailViewBloc.getInvolvedMembers(value),
              ),
              Spacer(),
              Container(
                //margin: const EdgeInsets.only(left: 5, top: 5),
                alignment: Alignment.centerLeft,
                child: TextButton(
                  child: Text('Show less'),
                  onPressed: () => detailViewBloc.toggleShowLess(),
                ),
              ),
              //Spacer(),
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
                          child: Text("Cancel", style: Theme.of(context).textTheme.labelLarge,),
                          onPressed: () {
                            Navigator.of(context).pop(false);
                          },
                        )
                    ),
                    const VerticalDivider(
                      indent: 5,
                      endIndent: 5,
                    ),
                    Expanded(
                      child: CupertinoButton(
                          padding: const EdgeInsets.symmetric(vertical: 0),
                          child: Text("Add", style: Theme.of(context).textTheme.labelLarge,),
                          onPressed: () {
                            detailViewBloc.addTransaction(currencyController.doubleValue, descriptionController.text);
                            Navigator.of(context).pop(true);
                          }
                      ),
                    ),
                  ],
                )
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
    this.detailViewBloc = this.context.read<DetailViewBloc>();

    return BlocBuilder(
      bloc: detailViewBloc,
      buildWhen: (previous, current) => current is TransactionDialogState,
      builder: (context, state) { 
        if (state is! TransactionDialogState) return Container();

        return state.extend ? view(state) : dialog(state);
      },
    );
  }
}