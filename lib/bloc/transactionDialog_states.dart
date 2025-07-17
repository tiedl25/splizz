import 'package:splizz/bloc/detailview_bloc.dart';
import 'package:splizz/bloc/detailview_states.dart';
import 'package:splizz/models/item.model.dart';
import 'package:splizz/models/member.model.dart';

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
  });

  factory TransactionDialogLoaded.fromState(state) =>
    TransactionDialogLoaded(
      cubit: state.cubit,
      item: state.item,
      memberSelection: state.item.members.where((m) => !m.deleted).map((Member m) => m.active).toList(),
      memberBalances: List.generate(state.item.members.length, (index) => 0.0),
      involvedMembers: [],
      date: ["Today", "Yesterday", DateTime.now()]);

  @override
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