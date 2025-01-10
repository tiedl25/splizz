import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:splizz/Helper/database.dart';
import 'package:splizz/models/item.model.dart';
import 'package:splizz/models/member.model.dart';
import 'package:splizz/models/transaction.model.dart';

abstract class DetailViewState {
  Item item;

  DetailViewState({required this.item});

  DetailViewState copyWith({Item? item}) {
    this.item = item ?? this.item;

    return this;
  }
}

class DetailViewLoading extends DetailViewState {
  DetailViewLoading({required super.item});
}

class DetailViewLoaded extends DetailViewState {
  bool unbalanced;

  DetailViewLoaded({required super.item, this.unbalanced = false});

  factory DetailViewLoaded.fromDetailViewState(DetailViewState state,
          {unbalanced = false}) =>
      DetailViewLoaded(item: state.item, unbalanced: unbalanced);

  @override
  DetailViewLoaded copyWith({Item? item, bool? unbalanced}) {
    return DetailViewLoaded(
        item: item ?? this.item, unbalanced: unbalanced ?? this.unbalanced);
  }
}

class TransactionDialogState extends DetailViewLoaded {
  bool currency;
  bool extend;
  double scale;
  int selection;
  int dateSelection;
  List<dynamic> date;
  List<bool> memberSelection;
  List<double> memberBalances;
  List<Map<String, dynamic>> involvedMembers;

  TransactionDialogState(
      {required super.item,
      super.unbalanced,
      required this.memberSelection,
      required this.memberBalances,
      required this.involvedMembers,
      required this.date,
      this.currency = false,
      this.extend = false,
      this.scale = 1.0,
      this.selection = -1,
      this.dateSelection = 0});

  factory TransactionDialogState.fromDetailViewState(DetailViewState state) =>
      TransactionDialogState(
          item: state.item,
          memberSelection:
              state.item.members.map((Member m) => m.active).toList(),
          memberBalances:
              List.generate(state.item.members.length, (index) => 0.0),
          involvedMembers: [],
          date: ["Today", "Yesterday", DateTime.now()]);

  @override
  TransactionDialogState copyWith(
      {Item? item,
      bool? unbalanced,
      bool? currency,
      bool? extend,
      double? scale,
      int? selection,
      int? dateSelection,
      List<bool>? memberSelection,
      List<double>? memberBalances,
      List<Map<String, dynamic>>? involvedMembers,
      List<dynamic>? date}) {
    return TransactionDialogState(
        item: item ?? this.item,
        unbalanced: unbalanced ?? this.unbalanced,
        currency: currency ?? this.currency,
        extend: extend ?? this.extend,
        scale: scale ?? this.scale,
        selection: selection ?? this.selection,
        dateSelection: dateSelection ?? this.dateSelection,
        memberSelection: memberSelection ?? this.memberSelection,
        memberBalances: memberBalances ?? this.memberBalances,
        involvedMembers: involvedMembers ?? this.involvedMembers,
        date: date ?? this.date);
  }
}

class DetailViewCubit extends Cubit<DetailViewState> {
  DetailViewCubit(Item item) : super(DetailViewLoading(item: item));

  fetchData() async {
    final newState = DetailViewLoaded(
        item: await DatabaseHelper.instance.getItem(state.item.id),
        unbalanced: checkBalances(state.item.members));

    emit(newState);
  }

  addDebugTransaction() async {
    final newState = (state as DetailViewLoaded).copyWith();

    final int memberListIndex = Random().nextInt(newState.item.members.length);

    List<Map<String, dynamic>> involvedMembers = newState.item.members
        .asMap()
        .entries
        .map((entry) => {
              'listId': entry.key,
              'id': entry.value.id,
              'balance': double.parse(
                  (22.00 / newState.item.members.length).toStringAsFixed(2))
            })
        .toList();

    Transaction transaction = Transaction(
        description: 'test',
        value: 22.00,
        date: DateTime.now(),
        memberId: newState.item.members[memberListIndex].id,
        itemId: newState.item.id);
    newState.item.addTransaction(memberListIndex, transaction, involvedMembers);

    newState.unbalanced = checkBalances(newState.item.members);

    await DatabaseHelper.instance.upsertTransaction(transaction);

    emit(newState);
  }

  deleteTransaction(Transaction transaction, memberMap, memberListIndex) {
    final newState = (state as DetailViewLoaded).copyWith();

    newState.item.deleteTransaction(transaction, memberMap, memberListIndex);
    DatabaseHelper.instance.deleteTransaction(transaction);
    emit(newState);
  }

  setMemberActivity(Member member, bool value) {
    final newState = (state as DetailViewLoaded).copyWith();

    member =
        Member.fromMember(member, active: value, timestamp: DateTime.now());
    DatabaseHelper.instance.upsertMember(member);
    newState.item.members[newState.item.members
        .indexWhere((element) => element.id == member.id)] = member;
    emit(newState);
  }

  showTransactionDialog() {
    final newState = TransactionDialogState.fromDetailViewState(state);

    emit(newState);
  }

  closeTranscationDialog() async {
    final newState = DetailViewLoaded(
        item: state.item, unbalanced: checkBalances(state.item.members));

    emit(newState);
  }

  toggleCurrency() {
    final newState = (state as TransactionDialogState).copyWith();
    newState.currency = !newState.currency;

    emit(state);
  }

  showLess() {
    final newState = (state as TransactionDialogState).copyWith(scale: 1.0);
    newState.extend = !newState.extend;

    emit(newState);
  }

  showMore() async {
    final newState = (state as TransactionDialogState).copyWith(scale: 0.9);

    emit(newState);

    await Future.delayed(const Duration(milliseconds: 100), () {
      final newState2 = newState.copyWith();
      newState2.scale = 1.0;
      newState2.extend = !newState.extend;
      emit(newState2);
    });
  }

  changeDay(int index) {
    final newState =
        (state as TransactionDialogState).copyWith(dateSelection: index);
    newState.date[2] = DateTime.now().subtract(Duration(days: index));

    emit(newState);
  }

  setDate(DateTime? day) {
    if (day == null) return;

    final newState =
        (state as TransactionDialogState).copyWith(dateSelection: 2);
    newState.date[2] = day;

    DateTime now = DateTime.now();

    if (day.day == now.day && day.month == now.month && day.year == now.year) {
      newState.dateSelection = 0;
    } else if (day.day == now.subtract(Duration(days: 1)).day &&
        day.month == now.subtract(Duration(days: 1)).month &&
        day.year == now.subtract(Duration(days: 1)).year) {
      newState.dateSelection = 1;
    }

    emit(newState);
  }

  selectMember(int index) {
    final newState = (state as TransactionDialogState).copyWith();
    newState.memberSelection[index] = !newState.memberSelection[index];

    emit(newState);
  }

  changePayer(int index) {
    final newState =
        (state as TransactionDialogState).copyWith(selection: index);

    emit(newState);
  }

  getInvolvedMembers(final involvedMembers) {
    final newState = (state as TransactionDialogState)
        .copyWith(involvedMembers: involvedMembers);

    emit(newState);
  }

  addTransaction(double value, String description) async {
    final newState = (state as TransactionDialogState).copyWith();

    if (value != 0 &&
        description.isNotEmpty &&
        newState.selection != -1 &&
        newState.memberSelection.contains(true)) {
      if (newState.involvedMembers.isEmpty) {
        updateBalances(newState, value);
      }

      String associatedId = newState.item.members[newState.selection].id;
      Transaction transaction = Transaction(
          description: description,
          value: value,
          date: newState.date[2],
          memberId: associatedId,
          itemId: newState.item.id);

      newState.item.addTransaction(
          newState.selection, transaction, newState.involvedMembers);

      DatabaseHelper.instance.upsertTransaction(transaction);

      newState.selection = -1;

      final newState2 = DetailViewLoaded(
          item: state.item, unbalanced: checkBalances(state.item.members));

      emit(newState2);
    }
  }

  updateBalances(TransactionDialogState state, double value) {
    int memberCount =
        state.memberSelection.where((element) => element == true).length;
    for (int i = 0; i < state.memberSelection.length; i++) {
      if (state.memberSelection[i]) {
        state.involvedMembers.add({
          'listId': i,
          'id': state.item.members[i].id,
          'balance': value / memberCount
        });
      }
    }
  }

  addPayoff() {
    final newState = (state as DetailViewLoaded).copyWith();

    newState.item.payoff();
    newState.unbalanced = checkBalances(newState.item.members);

    DatabaseHelper.instance.upsertTransaction(newState.item.history.last);

    emit(newState);
  }

  updateDetailViewLoaded() {
    final newState = (state as DetailViewLoaded).copyWith();

    emit(newState);
  }

  bool checkBalances(members) {
    for (var m in members) {
      if (m.balance > 1e-6 || m.balance < -1e-6) {
        return true;
      }
    }
    return false;
  }
}
