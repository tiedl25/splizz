import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:splizz/bloc/masterview_bloc.dart';


import 'package:splizz/data/database.dart';
import 'package:splizz/bloc/detailview_states.dart';
import 'package:splizz/data/result.dart';
import 'package:splizz/models/item.model.dart';
import 'package:splizz/models/member.model.dart';
import 'package:splizz/models/transaction.model.dart';
import 'package:splizz/models/user.model.dart';
import 'package:splizz/resources/colormap.dart';
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

  deleteTransaction(Transaction transaction, memberMap, memberListIndex) {
    final newState = (state as DetailViewLoaded).copyWith();

    newState.item.deleteTransaction(transaction, memberMap, memberListIndex);
    DatabaseHelper.instance.upsertTransaction(transaction);
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
    final newState = DetailViewTransactionDialog.fromState(state);

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
          message: "You are not authorized to share this item!"
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

  toggleCurrency() {
    final newState = (state as DetailViewTransactionDialog).copyWith();
    newState.currency = !newState.currency;

    emit(newState);
  }

  toggleAccess() {
    final newState = (state as DetailViewShareDialog).copyWith();
    newState.fullAccess = !newState.fullAccess;

    emit(newState);
  }

  showLess() {
    final newState = (state as DetailViewTransactionDialog).copyWith(
      scale: 1.0,
      extend: !(state as DetailViewTransactionDialog).extend
    );

    emit(newState);
  }

  showMore() async {
    final newState = (state as DetailViewTransactionDialog).copyWith(scale: 0.9);

    emit(newState);

    await Future.delayed(const Duration(milliseconds: 100), () {
      final newState2 = newState.copyWith(
        scale: 1.0,
        extend: !newState.extend,
        involvedMembers: getCircularMembers(newState.sum, newState.memberSelection, newState.item.members.where((m) => !m.deleted).toList())
      );

      emit(newState2);
    });
  }

  changeDay(int index) {
    final newState = (state as DetailViewTransactionDialog).copyWith(dateSelection: index);
    newState.date[2] = DateTime.now().subtract(Duration(days: index));

    emit(newState);
  }

  setDate(DateTime? day) {
    if (day == null) return;

    final newState = (state as DetailViewTransactionDialog).copyWith(dateSelection: 2);
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

  closeDateSelection() {
    final newState = (state as DetailViewTransactionDialog).copyWith();

    emit(newState);
  }

  selectMember(int index) {
    final newState = (state as DetailViewTransactionDialog).copyWith();
    newState.memberSelection[index] = !newState.memberSelection[index];

    emit(newState);
  }

  changePayer(int index) {
    final newState = (state as DetailViewTransactionDialog).copyWith(selection: index);

    emit(newState);
  }

  updateTransactionValue(String value) {
    bool negative = value.startsWith('-');
    if (negative) value = value.replaceFirst("-", "");
    double newValue = double.parse(value.replaceFirst(",", "."));

    if (negative) newValue *= -1;
    final newState = (state as DetailViewTransactionDialog).copyWith(sum: newValue);

    emit(newState);
  }

  updateCircularSlider() {
    final newState = (state as DetailViewTransactionDialog).copyWith();
    newState.involvedMembers = getCircularMembers(newState.sum, newState.memberSelection, newState.item.members.where((m) => !m.deleted).toList());

    emit(newState);
  }

  getCircularMembers(double sum, memberSelection, members) {
    List<Map<String, dynamic>> circularMembers = [];

    double val = 0;
    double angle = (2*pi) / memberSelection.where((e) => e==true).length;
    double balance = sum / memberSelection.where((e) => e==true).length;
    
    for (int i=0; i<members.length; i++) {
      if(!memberSelection[i]) continue;
      val = angle + val;
      
      circularMembers.add({
        'listId': i,
        'id': members[i].id,
        'color': members[i].color,
        'balance': balance,
        'angle': val
      });
    }

    if (circularMembers.length == 1) circularMembers.clear() ;

    return circularMembers;
  }

  updateCircularSliderPosition(DragUpdateDetails details, RenderBox renderBox) {
    final newState = (state as DetailViewTransactionDialog).copyWith();
    final members = newState.involvedMembers;

    final offset = renderBox.globalToLocal(details.globalPosition);
    final center = Offset(renderBox.size.width / 2, renderBox.size.height / 2);
    final angle = (atan2(offset.dy - center.dy, offset.dx - center.dx) + 2 * pi) % (2 * pi);

    double minDistance = 0.3;
    double arreaToMove = pi / 2;

    for (int i = 0; i < members.length; i++) {
      double mAngle = members[i]['angle'];

      if ((angle - mAngle).abs() < 0.25 ||
          (angle - mAngle + 2 * pi).abs() < 0.25 ||
          (angle - mAngle - 2 * pi).abs() < 0.25) {
        bool clockwise =
            ((angle - mAngle > 0 && angle - mAngle < arreaToMove) ||
                angle - mAngle < -arreaToMove);
        bool counterClockwise =
            ((angle - mAngle < 0 && angle - mAngle > -arreaToMove) ||
                angle - mAngle > arreaToMove);

        double nextMAngle =members[i + 1 >= members.length ? 0 : i + 1]['angle'];
        double prevMAngle =members[i - 1 < 0 ? members.length - 1 : i - 1]['angle'];

        // break if nextAngle is too close
        if ((nextMAngle - mAngle) < minDistance &&
            nextMAngle - mAngle > 0 &&
            clockwise) {
          break;
        }

        // break if nextAngle is too close but with the next angle bigger than 2pi, appearing as a smaller angle
        if (-(nextMAngle - mAngle) > 2 * pi - minDistance &&
            (nextMAngle - mAngle) < 2 * pi &&
            clockwise) {
          break;
        }

        // break if prevAngle is too close
        if ((mAngle - prevMAngle) < minDistance &&
            mAngle - prevMAngle > 0 &&
            counterClockwise) {
          break;
        }

        // break if prevAngle is too close but with the prev angle smaller than 0, appearing as a bigger angle
        if (-(mAngle - prevMAngle) > 2 * pi - minDistance &&
            (mAngle - prevMAngle) < 2 * pi &&
            counterClockwise) {
          break;
        }

        members[i]['angle'] = angle;
        break;
      }
    }

    newState.involvedMembers = members;

    emit(newState);
  }

  updateCircularSliderPositionStepwise(DragUpdateDetails details, RenderBox renderBox) {
    final newState = (state as DetailViewTransactionDialog).copyWith();
    final members = newState.involvedMembers;

    final offset = renderBox.globalToLocal(details.globalPosition);
    final center = Offset(renderBox.size.width / 2, renderBox.size.height / 2);
    final angle = (atan2(offset.dy - center.dy, offset.dx - center.dx) + 2 * pi) % (2 * pi);

    // Define the step size in radians (e.g., for 1 euro steps)
    final double stepSize = (2 * pi) / (newState.sum / newState.euros); // Adjust for 1 euro steps

    double threshold = max(stepSize, 0.25);
    double minDistance = threshold + 0.05;
    double arreaToMove = pi / 2;
 
    for (int i = 0; i < members.length; i++) {
      double mAngle = members[i]['angle'];

      if ((angle - mAngle).abs() < threshold ||
          (angle - mAngle + 2 * pi).abs() < threshold ||
          (angle - mAngle - 2 * pi).abs() < threshold) {
        bool clockwise =
            ((angle - mAngle > 0 && angle - mAngle < arreaToMove) ||
                angle - mAngle < -arreaToMove);
        bool counterClockwise =
            ((angle - mAngle < 0 && angle - mAngle > -arreaToMove) ||
                angle - mAngle > arreaToMove);

        double nextMAngle = members[i + 1 >= members.length ? 0 : i + 1]['angle'];
        double prevMAngle = members[i - 1 < 0 ? members.length - 1 : i - 1]['angle'];

        // Break if nextAngle is too close
        if ((nextMAngle - mAngle) < minDistance &&
            nextMAngle - mAngle > 0 &&
            clockwise) {
          break;
        }

        // Break if nextAngle is too close but with the next angle bigger than 2pi, appearing as a smaller angle
        if (-(nextMAngle - mAngle) > 2 * pi - minDistance &&
            (nextMAngle - mAngle) < 2 * pi &&
            clockwise) {
          break;
        }

        // Break if prevAngle is too close
        if ((mAngle - prevMAngle) < minDistance &&
            mAngle - prevMAngle > 0 &&
            counterClockwise) {
          break;
        }

        // Break if prevAngle is too close but with the prev angle smaller than 0, appearing as a bigger angle
        if (-(mAngle - prevMAngle) > 2 * pi - minDistance &&
            (mAngle - prevMAngle) < 2 * pi &&
            counterClockwise) {
          break;
        }

        // Snap the angle to the nearest step
        double snappedAngle = (angle / stepSize).round() * stepSize;

        double amount = double.parse((newState.sum/((2*pi) / angle)).toStringAsFixed(2));
        if (amount % newState.euros > newState.euros - 1e-32) {

          int direction = (angle - mAngle).abs() < (angle - snappedAngle).abs() ? 1 : -1;
          double nextValue;
          // Calculate the next value based on the direction
          if (direction == 1) {
            nextValue = double.parse(((amount / newState.euros).ceil() * newState.euros).toStringAsFixed(2));
          } else {
            nextValue = double.parse(((amount / newState.euros).floor() * newState.euros).toStringAsFixed(2));
          }

          snappedAngle = (nextValue / (newState.sum / ((2 * pi) / angle))) * stepSize;
        }

        members[i]['angle'] = snappedAngle;
        newState.lastChangedMemberIndex = i; // Store the index of the member whose position was changed
        if (newState.zoomEnabled) newState.sliderIndex = snappedAngle; // Store the angle of the last changed member
        break;
      }
    }

    newState.involvedMembers = members;

    emit(newState);
  }

  changeCircularStepsize(double value, double sliderIndex) {
    final newState = (state as DetailViewTransactionDialog).copyWith();
    newState.sliderIndex = sliderIndex;
    newState.euros = value;

    emit(newState);
  }

  toggleZoom(bool value) {
    final newState = (state as DetailViewTransactionDialog).copyWith(zoomEnabled: value);
    newState.sliderIndex = value ? newState.involvedMembers[newState.lastChangedMemberIndex]['angle'] : 3;
    emit(newState);
  }

  granularUpdateCircularSliderPosition(double value) {
    final newState = (state as DetailViewTransactionDialog).copyWith();
    final members = newState.involvedMembers;

    members[newState.lastChangedMemberIndex]['angle'] = value;

    emit(newState);
  }

  addTransaction(String description) async {
    final newState = (state as DetailViewTransactionDialog).copyWith();

    if (description.isEmpty) {
      final String message = 'Please enter a description!';
      emit(DetailViewTransactionDialogShowSnackBar(
        item: state.item,
        message: message
      ));
      emit(newState);
      return Result.failure(message);
    }
    if (newState.sum == 0) {
      final String message = 'Transaction value cannot be zero!';
      emit(DetailViewTransactionDialogShowSnackBar(
        item: state.item,
        message: message
      ));
      emit(newState);
      return Result.failure(message);
    }
    if (newState.selection == -1) {
      final String message = 'Please select a payer!';
      emit(DetailViewTransactionDialogShowSnackBar(
        item: state.item,
        message: message
      ));
      emit(newState);
      return Result.failure(message);
    }
    if (newState.memberSelection.contains(true) == false) {
      final String message = 'Please select at least one member!';
      emit(DetailViewTransactionDialogShowSnackBar(
        item: state.item,
        message: message
      ));
      emit(newState);
      return Result.failure(message);
    }
    
    if (newState.involvedMembers.isEmpty) {
      updateBalances(newState, newState.sum);
    }

    final members = newState.item.members.where((m) => !m.deleted).toList();

    String associatedId = members[newState.selection].id;
    Transaction transaction = Transaction(
      description: description,
      value: newState.sum,
      date: newState.date[2],
      memberId: associatedId,
      itemId: newState.item.id
    );

    newState.item.addTransaction(newState.selection, transaction, newState.involvedMembers);

    DatabaseHelper.instance.upsertTransaction(transaction);

    newState.selection = -1;

    return Result.success(transaction);
  }

  updateBalances(DetailViewTransactionDialog state, double value) {
    int memberCount = state.memberSelection.where((element) => element == true).length;
    final members = state.item.members.where((m) => !m.deleted).toList();
    for (int i = 0; i < state.memberSelection.length; i++) {
      if (state.memberSelection[i]) {
        state.involvedMembers.add({
          'listId': i,
          'id': members[i].id,
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
      emit(DetailViewShareDialogShowSnackBar(item: state.item, message: 'Email cannot be empty!'));
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
      String message = 'You are invited to a Splizz. Accept by opening this link.\n\n';
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
        message: "There are no unbalanced transactions!")
      );
      
      emit(newState);
      return;
    }

    final newState = DetailViewPayoffDialog.fromLoaded(state as DetailViewLoaded);

    emit(DetailViewShowPayoffDialog(item: state.item));

    emit(newState);
  }

  showPastPayoffDialog(int index) {
    final newState = DetailViewPayoffDialog.fromLoaded(state as DetailViewLoaded, past: true)..index = index;

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
    final newState = DetailViewLoaded.from(state as DetailViewMemberDialog);

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
      newState = DetailViewLoaded.from(state as DetailViewEditMode);

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

    final newState = DetailViewLoaded.from(state as DetailViewEditMode).copyWith(item: newItem);

    emit(newState);

    await DatabaseHelper.instance.upsertItem(newItem);

    masterViewCubit.fetchData(destructive: false);
  }
}
