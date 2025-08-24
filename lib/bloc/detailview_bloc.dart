import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:splizz/bloc/masterview_bloc.dart';

import 'package:splizz/data/database.dart';
import 'package:splizz/bloc/detailview_states.dart';
import 'package:splizz/models/item.model.dart';
import 'package:splizz/models/member.model.dart';
import 'package:splizz/models/transaction.model.dart';
import 'package:splizz/models/user.model.dart';
import 'package:splizz/resources/colormap.dart';
import 'package:splizz/resources/strings.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

class DetailViewCubit extends Cubit<DetailViewState> {
  MasterViewCubit masterViewCubit;

  DetailViewCubit(Item item, {required this.masterViewCubit})
    : super(DetailViewLoading(item: item)) {
      fetchData();
    }

  fetchData() async {
    final newState = DetailViewLoaded(
      item: await DatabaseHelper.instance.getItem(state.item.id, sync: true),
      unbalanced: checkBalances(state.item.members)
    );

    emit(newState);
  }

  addDebugTransaction() async {
    final newState = (state as DetailViewLoaded).copyWith();

    final members = newState.item.members.where((m) => !m.deleted).toList();

    final int memberListIndex = Random().nextInt(members.length);

    List<Map<String, dynamic>> involvedMembers = members
      .asMap()
      .entries
      .map((entry) => {
            'listId': entry.key,
            'id': entry.value.id,
            'balance': double.parse(
                (22.00 / members.length).toStringAsFixed(2))
          })
      .toList();

    Transaction transaction = Transaction(
      description: 'test',
      value: 22.00,
      date: DateTime.now(),
      memberId: members[memberListIndex].id,
      itemId: newState.item.id
    );
    
    newState.item.addTransaction(memberListIndex, transaction, involvedMembers);

    newState.unbalanced = checkBalances(newState.item.members);

    await DatabaseHelper.instance.upsertTransaction(transaction);

    emit(newState);
  }

  addTransaction(Transaction transaction, selection, involvedMembers) async {
    final newState = (state as DetailViewLoaded).copyWith();

    newState.item.addTransaction(selection, transaction, involvedMembers);
    newState.unbalanced = checkBalances(newState.item.members);
    emit(newState);
  }

  updateTransaction(Transaction transaction) async {
    final newState = (state as DetailViewLoaded).copyWith();

    newState.item.history[newState.item.history.indexWhere((element) => element.id == transaction.id)] = transaction;
    newState.unbalanced = checkBalances(newState.item.members);
    emit(newState);
  }

  deleteTransaction(Transaction transaction, {List<Transaction>? payoffTransactions}) async {
    final whichState = state.runtimeType == DetailViewPayoffDialog ? state as DetailViewPayoffDialog : state as DetailViewLoaded;
    final newState = whichState.copyWith();

    if (payoffTransactions != null) {
      newState.item.history.where((element) => element.payoffId == transaction.id).forEach((element) {
        element.payoffId = null;
      });

      await Future.wait(
        payoffTransactions.map((t) {
          t.payoffId = null;
          return DatabaseHelper.instance.upsertTransaction(t);
        })
      );

      newState.item.history.removeWhere((element) => element.id == transaction.id);
      DatabaseHelper.instance.deleteTransaction(transaction);
    } else {
      newState.item.deleteTransaction(transaction);
      DatabaseHelper.instance.upsertTransaction(transaction);
    }
    
    newState.unbalanced = checkBalances(newState.item.members);
    emit(newState);
  }

  setMemberActivity(Member member, bool value) {
    final newState = (state as DetailViewMemberDialog).copyWith();

    member = Member.fromMember(member, active: value, timestamp: DateTime.now());
    DatabaseHelper.instance.upsertMember(member);

    newState.item.members[newState.item.members.indexWhere((element) => element.id == member.id)] = member;
    newState.member = member;

    emit(newState);
  }

  changeMemberColor(Member member, Color color) {
    final newState = (state as DetailViewMemberDialog).copyWith();

    //newState.item.members.firstWhere((m) => m.id == member.id).color = color.value;
    newState.color = color;

    emit(newState);
  }

  changeMemberName(String name) {
    final newState = (state as DetailViewMemberDialog).copyWith();

    //newState.item.members.firstWhere((m) => m.id == member.id).name = name;
    //newState.name = name;

    emit(newState);
  }

  changeNewMemberColor(Color color) {
    final newState = (state as DetailViewAddMemberDialog).copyWith();

    newState.color = color;

    emit(newState);
  }

  addMember(String name) async {
    final newState = (state as DetailViewLoaded).copyWith();
    final member = Member(name: name, color: (state as DetailViewAddMemberDialog).color.value, itemId: newState.item.id);
    newState.item.members.add(member);
    await DatabaseHelper.instance.upsertMember(member);

    emit(newState);
  }

  showTransactionDialog() {
    final newState = DetailViewLoaded.fromState(state);

    emit(DetailViewShowTransactionDialog(item: state.item));

    emit(newState);
  }

  closeTranscationDialog() async {
    final newState = DetailViewLoaded(
      item: state.item, 
      unbalanced: checkBalances(state.item.members)
    );

    emit(newState);
  }

  showShareDialog() async {
    final currentUser = Supabase.instance.client.auth.currentUser;

    if (currentUser != null) {
      User permission = await DatabaseHelper.instance.getPermission(state.item.id, currentUser.id);
      if (!permission.fullAccess) {
        emit(DetailViewShowSnackBar(
          item: state.item,
          message: notAuthorizedShareItem
        ));
        return;
      }
    }
    
    final newState = DetailViewShareDialog.fromLoaded((state as DetailViewLoaded));

    emit(DetailViewShowShareDialog(item: state.item));

    emit(newState);
  }

  closeShareDialog() {
    final newState = DetailViewLoaded.from(state);

    emit(newState);
  }

  toggleAccess() {
    final newState = (state as DetailViewShareDialog).copyWith();
    newState.fullAccess = !newState.fullAccess;

    emit(newState);
  }

  addPayoff() {
    final newState = (state as DetailViewLoaded).copyWith();

    newState.item.payoff();
    newState.unbalanced = checkBalances(newState.item.members);

    List<Transaction> payoffTransactions = newState.item.history.where((element) => element.payoffId == null && (element.description != "payoff" || element.memberId != null)).toList();

    DatabaseHelper.instance.upsertTransaction(newState.item.history.last, payoffTransactions: payoffTransactions);

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

  showLink(email) async {
    final newState = state.copyWith();
    if (email.isEmpty){
      emit(DetailViewShareDialogShowSnackBar(item: state.item, message: emailCannotBeEmpty));
      emit(newState);
      return;
    }

    User permission = User(
      itemId: state.item.id,
      fullAccess: (state as DetailViewShareDialog).fullAccess,
      userEmail: email,
      expirationDate: DateTime.now().add(const Duration(days: 1)));
    final result = await DatabaseHelper.instance.addPermission(permission);

    //final newState = state.copyWith();

    if (!result.isSuccess)
      emit(DetailViewShareDialogShowSnackBar(item: state.item, message: result.message!));
    else {
      permission = result.value!;
      String message = invitedToSplizz;
      message += 'https://tmc.tiedl.rocks/splizz?id=${permission.id}';
      emit(DetailViewShareDialogShowLink(item: state.item, message: message));
    }
    
    emit(newState);
  }

  showPayoffDialog() {
    if (!(state as DetailViewLoaded).unbalanced) {
      final newState = state.copyWith();

      emit(DetailViewShowSnackBar(
        item: state.item, 
        message: noUnbalancedTransactions)
      );
      
      emit(newState);
      return;
    }

    final newState = DetailViewPayoffDialog.fromLoaded(state as DetailViewLoaded);

    emit(DetailViewShowPayoffDialog(item: state.item));

    emit(newState);
  }

  showPastPayoffDialog(String id) {
    final newState = DetailViewPayoffDialog.fromLoaded(state as DetailViewLoaded, past: true)..payoffId = id;

    emit(DetailViewShowPastPayoffDialog(item: state.item));

    emit(newState);
  }

  dismissPayoffDialog() {
    final newState = DetailViewLoaded.fromPayoffDialog(state as DetailViewPayoffDialog);

    emit(newState);
  }

  showAddMemberDialog() {
    final newState = DetailViewAddMemberDialog.fromState(state, colormap[0]);
    emit(newState);
  }

  showMemberDialog(Member member, {GlobalKey? key}) {
    final newState = DetailViewMemberDialog.fromState(state, member, false, TextEditingController(text: member.name), Color(member.color));

    emit(DetailViewShowMemberDialog(item: state.item, member: member, memberKey: key));

    emit(newState);
  }

  closeMemberDialog() {
    final newState = DetailViewLoaded.from(state as DetailViewMemberDialog, unbalanced: checkBalances((state as DetailViewMemberDialog).item.members));

    emit(newState);
  }

  toggleMemberEditMode() {
    final newState = (state as DetailViewMemberDialog).copyWith(editMode: !(state as DetailViewMemberDialog).editMode, name: TextEditingController(text: (state as DetailViewMemberDialog).member.name), color: Color((state as DetailViewMemberDialog).member.color));
    emit(newState);
  }

  deleteMember() async {
    final newState = DetailViewLoaded.from(state as DetailViewMemberDialog);

    await DatabaseHelper.instance.markMemberDeleted((state as DetailViewMemberDialog).member);

    newState.item.members.firstWhere((element) => element.id == (state as DetailViewMemberDialog).member.id).deleted = true;

    emit(newState);
  }

  updateMember() async {
    final newMember = Member.fromMember((state as DetailViewMemberDialog).member, name: (state as DetailViewMemberDialog).name!.text, color: (state as DetailViewMemberDialog).color?.value);
    
    final newState = (state as DetailViewMemberDialog).copyWith(editMode: false, member: newMember);

    await DatabaseHelper.instance.upsertMember(newMember);

    int index = newState.item.members.indexOf((state as DetailViewMemberDialog).member);
    newState.item.members[index] = newMember;

    emit(newState);
  }

  toggleEditMode({bool update=false}) {
    final newState;

    if (state.runtimeType == DetailViewLoaded) {
      newState = DetailViewEditMode.fromState(state as DetailViewLoaded);
    } else if (state.runtimeType == DetailViewEditMode) {
      newState = DetailViewLoaded.fromState(state as DetailViewEditMode, unbalanced: checkBalances((state as DetailViewEditMode).item.members));

      if (update) {
        updateItem();
        return;
      }
    } else return;

    emit(newState);
  }

  changeImage(CroppedFile? image) async {
    if (image == null) return;

    final newState = (state as DetailViewEditMode).copyWith();

    newState.imageFile = await (image.readAsBytes());

    emit(newState);
  }

  updateItem() async {
    Item newItem = Item.copyWith(item: (state as DetailViewEditMode).item, 
      name: (state as DetailViewEditMode).name?.text, 
      image: (state as DetailViewEditMode).imageFile);

    final newState = DetailViewLoaded.fromState(state as DetailViewEditMode, unbalanced: checkBalances(newItem.members)).copyWith(item: newItem);

    emit(newState);

    await DatabaseHelper.instance.upsertItem(newItem);

    masterViewCubit.fetchData(destructive: false);
  }

  changeWhatToShare(List<bool> whatToShare) {
    final newState = (state as DetailViewPayoffDialog).copyWith(whatToShare: whatToShare);
    emit(newState);
  }

  togglePieChart({bool? showPieChart}) {
    final newState = (state as DetailViewLoaded).copyWith(showPieChart: showPieChart ??!(state as DetailViewLoaded).showPieChart);

    emit(newState);
  }
}
