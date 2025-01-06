import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:splizz/Helper/database.dart';
import 'package:splizz/models/item.model.dart';
import 'package:splizz/models/member.model.dart';
import 'package:splizz/models/transaction.model.dart';

abstract class DetailViewState {
  final Item item;

  const DetailViewState(this.item);
}

class DetailViewLoading extends DetailViewState {
  const DetailViewLoading(super.item);
}

class DetailViewLoaded extends DetailViewState {
  bool unbalanced;

  DetailViewLoaded(super.item, this.unbalanced);
}

class TransactionDialogState extends DetailViewState {
  final bool currency;
  final bool extend;
  final double scale;
  final int selection;
  final int dateSelection;
  final List<dynamic> date;
  final List<bool> memberSelection;
  final List<double> memberBalances;
  final List<Map<String, dynamic>> involvedMembers;

  const TransactionDialogState(super.item, this.memberSelection, this.memberBalances, this.involvedMembers, this.date, {this.currency=false, this.extend=false, this.scale=1.0, this.selection=-1, this.dateSelection=0});
}

class DateSelectionDialog extends DetailViewState {
  final DateTime day;

  const DateSelectionDialog(super.item, this.day);
}

class DetailViewBloc extends Cubit<DetailViewState> {
  Item item;

  bool unbalanced = false;

  bool currency = false;
  bool extend = false;
  double scale = 1.0;
  int selection = -1;
  int _dateSelection = 0;
  List<bool> _memberSelection = [];
  List<double> _memberBalances = [];
  List<Map<String, dynamic>> _involvedMembers = [];
  List<dynamic> date = ["Today", "Yesterday"];

  DetailViewBloc(this.item) : super(DetailViewLoading(item));

  fetchData () async {
    item = await DatabaseHelper.instance.getItem(state.item.id);
    emit(DetailViewLoaded(item, checkBalances(item.members)));
  }

  addDebugTransaction() async {
    int memberListIndex = Random().nextInt(state.item.members.length);
    List<Map<String, dynamic>> involvedMembers = state.item.members.asMap().entries.map((entry) {
      int index = entry.key;  // This is the index
      var e = entry.value;    // This is the item at that index
      return {'listId': index, 'id': e.id, 'balance': double.parse((22.00/state.item.members.length).toStringAsFixed(2))};
    }).toList();

    Transaction t = Transaction(description: 'test', value: 22.00, date: DateTime.now(), memberId: state.item.members[memberListIndex].id , itemId: state.item.id);
    state.item.addTransaction(memberListIndex, t, involvedMembers);
    await DatabaseHelper.instance.upsertTransaction(t);

    emit(state);
  }

  deleteTransaction(Transaction transaction, memberMap, memberListIndex) {
    state.item.deleteTransaction(transaction, memberMap, memberListIndex);
    DatabaseHelper.instance.deleteTransaction(transaction);
    emit(state);
  }

  setMemberActivity(Member member, bool value) {
    member = Member.fromMember(member, active: value, timestamp: DateTime.now());
    DatabaseHelper.instance.upsertMember(member);
    state.item.members[state.item.members.indexWhere((element) => element.id == member.id)] = member;
    emit(state);
  }

  toggleCurrency() {
    currency = !currency;

    TransactionDialogState newState = TransactionDialogState(state.item, _memberSelection, _memberBalances, _involvedMembers, date, currency: currency, extend: extend, scale: scale, selection: selection, dateSelection: _dateSelection);
    emit(newState);
  }

  toggleShowLess() {
    extend = !extend;
    scale = 1.0;

    TransactionDialogState dialog = TransactionDialogState(state.item, _memberSelection, _memberBalances, _involvedMembers, date, currency: currency, extend: extend, scale: scale, selection: selection, dateSelection: _dateSelection);

    emit(dialog);
  }

  toggleExtend() {
    scale = 0.7;

    TransactionDialogState dialog = TransactionDialogState(state.item, _memberSelection, _memberBalances, _involvedMembers, date, currency: currency, extend: extend, scale: scale, selection: selection, dateSelection: _dateSelection);

    emit(dialog);
  }

  toggleExtendDelayed() {
    extend = !extend;

    TransactionDialogState dialog = TransactionDialogState(state.item, _memberSelection, _memberBalances, _involvedMembers, date, currency: currency, extend: extend, scale: scale, selection: selection, dateSelection: _dateSelection);

    emit(dialog);
  }

  changeDate(int index) {
    DateTime day = DateTime.now().subtract(Duration(days: index));

    if(index==2){
      DateSelectionDialog dialog = DateSelectionDialog(state.item, day);
      emit(dialog);
    } else {
      date[2] = day;
    }
    _dateSelection = index;

    TransactionDialogState dialog = TransactionDialogState(state.item, _memberSelection, _memberBalances, _involvedMembers, date, currency: currency, extend: extend, scale: scale, selection: selection, dateSelection: _dateSelection);

    emit(dialog);
  }

  setDate(DateTime? day) {
    if (day == null) return;

    date[2] = date;
    TransactionDialogState dialog = TransactionDialogState(state.item, _memberSelection, _memberBalances, _involvedMembers, date, currency: currency, extend: extend, scale: scale, selection: selection, dateSelection: _dateSelection);

    emit(dialog);
  }

  selectMember(int index) {
    _memberSelection[index] = !_memberSelection[index];
    TransactionDialogState dialog = TransactionDialogState(state.item, _memberSelection, _memberBalances, _involvedMembers, date, currency: currency, extend: extend, scale: scale, selection: selection, dateSelection: _dateSelection);

    emit(dialog);
  }

  changePayer(int index) {
    selection = index;
    TransactionDialogState dialog = TransactionDialogState(state.item, _memberSelection, _memberBalances, _involvedMembers, date, currency: currency, extend: extend, scale: scale, selection: selection, dateSelection: _dateSelection);

    emit(dialog);
  }

  addTransaction(double value, String description) async {
    if(value != 0 && description.isNotEmpty && selection!=-1 && _memberSelection.contains(true)) {
      if (_involvedMembers.isEmpty) {
        updateBalances(item, value);
      }
      
      String associatedId = item.members[selection].id;
      Transaction transaction = Transaction(description: description, value: value, date: date[2], memberId: associatedId, itemId: item.id);
      item.addTransaction(selection, transaction, _involvedMembers);
      
      DatabaseHelper.instance.upsertTransaction(transaction);

      selection=-1;

      DetailViewLoaded newState = DetailViewLoaded(item, checkBalances(item.members));

      emit(newState);
    }
  }

  updateBalances(Item item, double value){
    int memberCount = _memberSelection.where((element) => element==true).length;
    for (int i=0; i<_memberSelection.length; i++){
      if (_memberSelection[i]){
        _involvedMembers.add({'listId': i, 'id': item.members[i].id, 'balance': value/memberCount});
      }
    } 
  }

  addPayoff() {
    item.payoff();
    DatabaseHelper.instance.upsertTransaction(item.history.last);

    emit(DetailViewLoaded(item, checkBalances(item.members)));
  }

  getInvolvedMembers(final involvedMembers) {
    _involvedMembers = involvedMembers;
    TransactionDialogState dialog = TransactionDialogState(state.item, _memberSelection, _memberBalances, _involvedMembers, date, currency: currency, extend: extend, scale: scale, selection: selection, dateSelection: _dateSelection);

    emit(dialog);
  }

  showTransactionDialog() {
    _memberSelection = item.members.map((Member m) => m.active).toList();
    _memberBalances = List.generate(_memberSelection.length, (index) => 0.0);
    date.add(DateTime.now()); 

    emit(TransactionDialogState(state.item, _memberSelection, _memberBalances, _involvedMembers, date, currency: currency, extend: extend, scale: scale, selection: selection, dateSelection: _dateSelection));
  }

  closeTranscationDialog() async {
    emit(DetailViewLoaded(state.item, checkBalances(state.item.members)));
  }

  bool checkBalances(members){
    for(var m in members){
      if(m.balance > 1e-6 || m.balance < -1e-6){
        return true;
      }
    }
    return false;
  }
}
