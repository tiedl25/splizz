import 'package:currency_textfield/currency_textfield.dart';
import 'package:flutter/material.dart';
import 'package:splizz/bloc/detailview_bloc.dart';
import 'package:splizz/models/item.model.dart';
import 'package:splizz/models/member.model.dart';
import 'package:splizz/models/transaction.model.dart';

abstract class TransactionDialogState {
  DetailViewCubit cubit;

  TransactionDialogState({required this.cubit});
}

class TransactionDialogLoaded extends TransactionDialogState {
  Item item;
  bool currency;
  bool extend;
  double scale;
  int selection;
  int dateSelection;
  List<dynamic> date;
  List<bool> memberSelection;
  List<double> memberBalances;
  List<Map<String, dynamic>> involvedMembers;
  final CurrencyTextFieldController currencyController;
  final TextEditingController descriptionController;
  double sum;
  bool lock;
  double sliderIndex;
  double euros;
  bool zoomEnabled;
  int lastChangedMemberIndex;
  bool help;

  TransactionDialogLoaded({
    required super.cubit,
    required this.item,
    required this.memberSelection,
    required this.memberBalances,
    required this.involvedMembers,
    required this.date,
    currencyController,
    descriptionController,
    this.currency = false,
    this.extend = false,
    this.scale = 1.0,
    this.selection = -1,
    this.dateSelection = 0,
    this.sum = 0.0,
    this.lock = false,
    this.sliderIndex = 3, 
    this.euros = 0.1,
    this.zoomEnabled = false,
    this.lastChangedMemberIndex = 0,
    this.help = false
  }) : 
    descriptionController = descriptionController ?? TextEditingController(), 
    currencyController = currencyController ?? CurrencyTextFieldController(currencySymbol: '', decimalSymbol: ',', enableNegative: true); 

  factory TransactionDialogLoaded.fromState(state) =>
    TransactionDialogLoaded(
      cubit: state.cubit,
      item: state.item,
      memberSelection: state.item.members.where((m) => !m.deleted).map((Member m) => m.active).toList(),
      memberBalances: List.generate(state.item.members.length, (index) => 0.0),
      involvedMembers: [],
      date: ["Today", "Yesterday", DateTime.now()]);

  TransactionDialogLoaded copyWith({
    DetailViewCubit? cubit,
    Item? item,
    bool? unbalanced,
    bool? currency,
    bool? extend,
    double? scale,
    int? selection,
    int? dateSelection,
    List<bool>? memberSelection,
    List<double>? memberBalances,
    List<Map<String, dynamic>>? involvedMembers,
    List<dynamic>? date,
    CurrencyTextFieldController? currencyController,
    TextEditingController? descriptionController,
    double? sum,
    bool? lock,
    double? sliderIndex,
    double? euros,
    bool? zoomEnabled,
    int? lastChangedMemberIndex,
    bool? help}) =>
      TransactionDialogLoaded(
        cubit: cubit ?? this.cubit,
        item: item ?? this.item,
        currency: currency ?? this.currency,
        extend: extend ?? this.extend,
        scale: scale ?? this.scale,
        selection: selection ?? this.selection,
        dateSelection: dateSelection ?? this.dateSelection,
        memberSelection: memberSelection ?? this.memberSelection,
        memberBalances: memberBalances ?? this.memberBalances,
        involvedMembers: involvedMembers ?? this.involvedMembers,
        date: date ?? this.date,
        currencyController: currencyController ?? this.currencyController,
        descriptionController: descriptionController ?? this.descriptionController,
        sum: sum ?? this.sum,
        lock: lock ?? this.lock,
        sliderIndex: sliderIndex ?? this.sliderIndex,
        euros: euros ?? this.euros,
        zoomEnabled: zoomEnabled ?? this.zoomEnabled,
        lastChangedMemberIndex: lastChangedMemberIndex ?? this.lastChangedMemberIndex,
        help: help ?? this.help
      );
}

class TransactionDialogEdit extends TransactionDialogLoaded {
  Transaction transaction;

  TransactionDialogEdit({
    required this.transaction,
    required super.cubit,
    required super.item,
    required super.memberSelection,
    required super.memberBalances,
    required super.involvedMembers,
    required super.date,
    super.currencyController,
    super.descriptionController,
    super.currency = false,
    super.extend = false,
    super.scale = 1.0,
    super.selection = -1,
    super.dateSelection = 0,
    super.sum = 0.0,
    super.lock = false,
    super.sliderIndex = 3, 
    super.euros = 0.1,
    super.zoomEnabled = false,
    super.lastChangedMemberIndex = 0,
    super.help = false
  });

  factory TransactionDialogEdit.fromState(state) =>
    TransactionDialogEdit(
      transaction: state.transaction,
      cubit: state.cubit,
      item: state.item,
      memberSelection: state.item.members.where((m) => !m.deleted).map((Member m) => m.active).toList(),
      memberBalances: List.generate(state.item.members.length, (index) => 0.0),
      involvedMembers: [],
      date: ["Today", "Yesterday", DateTime.now()]);

  @override
  TransactionDialogEdit copyWith({
    Transaction? transaction,
    DetailViewCubit? cubit,
    Item? item,
    bool? unbalanced,
    bool? currency,
    bool? extend,
    double? scale,
    int? selection,
    int? dateSelection,
    List<bool>? memberSelection,
    List<double>? memberBalances,
    List<Map<String, dynamic>>? involvedMembers,
    List<dynamic>? date,
    CurrencyTextFieldController? currencyController,
    TextEditingController? descriptionController,
    double? sum,
    bool? lock,
    double? sliderIndex,
    double? euros,
    bool? zoomEnabled,
    int? lastChangedMemberIndex,
    bool? help}) =>
      TransactionDialogEdit(
        transaction: transaction ?? this.transaction,
        cubit: cubit ?? this.cubit,
        item: item ?? this.item,
        currency: currency ?? this.currency,
        extend: extend ?? this.extend,
        scale: scale ?? this.scale,
        selection: selection ?? this.selection,
        dateSelection: dateSelection ?? this.dateSelection,
        memberSelection: memberSelection ?? this.memberSelection,
        memberBalances: memberBalances ?? this.memberBalances,
        involvedMembers: involvedMembers ?? this.involvedMembers,
        date: date ?? this.date,
        currencyController: currencyController ?? this.currencyController,
        descriptionController: descriptionController ?? this.descriptionController,
        sum: sum ?? this.sum,
        lock: lock ?? this.lock,
        sliderIndex: sliderIndex ?? this.sliderIndex,
        euros: euros ?? this.euros,
        zoomEnabled: zoomEnabled ?? this.zoomEnabled,
        lastChangedMemberIndex: lastChangedMemberIndex ?? this.lastChangedMemberIndex,
        help: help ?? this.help
      );    
}

abstract class TransactionDialogListener extends TransactionDialogState {
  TransactionDialogListener({required super.cubit});
}

class TransactionDialogShowSnackBar extends TransactionDialogListener {
  final String message;

  TransactionDialogShowSnackBar({required super.cubit, required this.message});
}