import 'dart:math';

import 'package:currency_textfield/currency_textfield.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:splizz/bloc/detailview_bloc.dart';
import 'package:splizz/bloc/transactionDialog_states.dart';
import 'package:splizz/data/database.dart';
import 'package:splizz/data/result.dart';
import 'package:splizz/models/item.model.dart';
import 'package:splizz/models/member.model.dart';
import 'package:splizz/models/operation.model.dart';
import 'package:splizz/models/transaction.model.dart';
import 'package:splizz/resources/money_divisions.dart';
import 'package:splizz/resources/strings.dart';

class TransactionDialogCubit extends Cubit<TransactionDialogState> {
  TransactionDialogCubit(DetailViewCubit detailViewCubit, Item item)
    : super(TransactionDialogLoaded(
      cubit: detailViewCubit,
      item: item,
      memberSelection: item.members.where((m) => !m.deleted).map((Member m) => m.active).toList(),
      memberBalances: List.generate(item.members.length, (index) => 0.0),
      involvedMembers: [],
      date: [today, yesterday, DateTime.now()]
    ));

  TransactionDialogCubit.edit(DetailViewCubit detailViewCubit, Item item, Transaction transaction)
    : super(TransactionDialogEdit(
      transaction: transaction,
      cubit: detailViewCubit,
      item: item,
      memberSelection: item.members.map((m) => transaction.operations.sublist(1).any((op) => op.memberId == m.id) ? true : false).toList(),
      memberBalances: item.members.map((m) => 
        transaction.operations.sublist(1).firstWhere((op) => op.memberId == m.id, orElse: () => Operation(memberId: m.id, value: 0.0)).value.abs()
      ).toList(),
      involvedMembers: [],//transaction.operations.sublist(1).map((op) => {"id": op.memberId, "balance": op.value, "listId": item.members.indexWhere((m) => m.id == op.memberId)}).toList(),
      date: [today, yesterday, transaction.date],
      selection: item.members.indexWhere((m) => m.id == transaction.memberId),
      sum: transaction.value,
      descriptionController: TextEditingController(text: transaction.description),
      currencyController: CurrencyTextFieldController(
        currencySymbol: '',
        decimalSymbol: ',',
        enableNegative: true,
        initDoubleValue: transaction.value
      ),
      dateSelection: transaction.date.day == DateTime.now().day
        ? 0 : transaction.date.day == DateTime.now().subtract(Duration(days: 1)).day
        ? 1 : 2,
    )){
      (super.state as TransactionDialogEdit).involvedMembers = getCircularMembers((super.state as TransactionDialogEdit).sum, (super.state as TransactionDialogEdit).memberSelection, (super.state as TransactionDialogEdit).item.members.where((m) => !m.deleted).toList(), (super.state as TransactionDialogEdit).memberBalances);
    }

  get whichState => state is TransactionDialogEdit ? (state as TransactionDialogEdit) : (state as TransactionDialogLoaded);

  toggleCurrency() {
    final newState = whichState.copyWith();
    newState.currency = !newState.currency;

    emit(newState);
  }

  showLess() {
    final newState = whichState.copyWith(
      scale: 1.0,
      extend: !whichState.extend
    );

    emit(newState);
  }

  showMore() async {
    final newState = whichState.copyWith(scale: 0.9);

    emit(newState);

    await Future.delayed(const Duration(milliseconds: 100), () {
      final newState2 = newState.copyWith(
        scale: 1.0,
        extend: !newState.extend,
        involvedMembers: getCircularMembers(newState.sum, newState.memberSelection, newState.item.members.where((m) => !m.deleted).toList(), newState is TransactionDialogEdit ? newState.memberBalances : null)
      );

      emit(newState2);
    });
  }

  changeDay(int index) {
    final newState = whichState.copyWith(dateSelection: index);
    newState.date[2] = DateTime.now().subtract(Duration(days: index));

    emit(newState);
  }

  setDate(DateTime? day) {
    if (day == null) return;

    final newState = whichState.copyWith(dateSelection: 2);
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
    final newState = whichState.copyWith();

    emit(newState);
  }

  selectMember(int index) {
    final newState = whichState.copyWith();
    newState.memberSelection[index] = !newState.memberSelection[index];

    emit(newState);
  }

  changePayer(int index) {
    final newState = whichState.copyWith(selection: index);

    emit(newState);
  }

  updateTransactionValue(String value) {
    bool negative = value.startsWith('-');
    if (negative) value = value.replaceFirst("-", "");
    double newValue = double.parse(value.replaceFirst(",", "."));

    if (negative) newValue *= -1;
    final newState = whichState.copyWith(sum: newValue);

    updateBalances(newState, newState.sum);

    emit(newState);
  }

  updateCircularSlider() {
    final newState = whichState.copyWith();
    newState.involvedMembers = getCircularMembers(newState.sum, newState.memberSelection, newState.item.members.where((m) => !m.deleted).toList());

    emit(newState);
  }

  getCircularMembers(double sum, memberSelection, members, [memberBalances]) {
    List<Map<String, dynamic>> circularMembers = [];

    double val = 0;
    double angle = (2*pi) / memberSelection.where((e) => e==true).length;
    double balance = sum / memberSelection.where((e) => e==true).length;
    
    for (int i=0; i<members.length; i++) {
      if(!memberSelection[i]) continue;

      double newBalance = balance;
      double newAngle = angle;

      if (memberBalances != null) {
        newBalance = memberBalances[i];
        newAngle = angle * (memberBalances[i]/balance);
      }

      val = newAngle + val;
      
      circularMembers.add({
        'listId': i,
        'id': members[i].id,
        'color': members[i].color,
        'balance': newBalance,
        'angle': val
      });
    }

    if (circularMembers.length == 1) circularMembers.clear() ;

    return circularMembers;
  }

  updateCircularSliderPosition(DragUpdateDetails details, RenderBox renderBox) {
    final newState = whichState.copyWith();
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
    final newState = whichState.copyWith();
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
    final newState = whichState.copyWith();
    newState.sliderIndex = sliderIndex;
    newState.euros = value;

    emit(newState);
  }

  toggleZoom(bool value) {
    final newState = whichState.copyWith(zoomEnabled: value);
    newState.sliderIndex = value ? newState.involvedMembers[newState.lastChangedMemberIndex]['angle'] : divisions.indexWhere((e) => e == newState.euros).toDouble();
    emit(newState);
  }

  granularUpdateCircularSliderPosition(double value) {
    final newState = whichState.copyWith();
    final members = newState.involvedMembers;

    members[newState.lastChangedMemberIndex]['angle'] = value;

    emit(newState);
  }

  editTransaction() async {
    final newState = whichState.copyWith();

    if (newState.descriptionController.text.isEmpty) {
      final String message = enterDescription;
      emit(TransactionDialogShowSnackBar(
        cubit: newState.cubit,
        message: message
      ));
      emit(newState);
      return Result.failure(message);
    }
    if (newState.sum == 0) {
      final String message = transactionCannotBeZero;
      emit(TransactionDialogShowSnackBar(
        cubit: newState.cubit,
        message: message
      ));
      emit(newState);
      return Result.failure(message);
    }
    if (newState.selection == -1) {
      final String message = selectPayer;
      emit(TransactionDialogShowSnackBar(
        cubit: newState.cubit,
        message: message
      ));
      emit(newState);
      return Result.failure(message);
    }
    if (newState.memberSelection.contains(true) == false) {
      final String message = selectMin1Member;
      emit(TransactionDialogShowSnackBar(
        cubit: newState.cubit, 
        message: message
      ));
      emit(newState);
      return Result.failure(message);
    }

    // Update Balances if they are not set with the CircularSlider
    if (newState.involvedMembers.isEmpty) {
      updateBalances(newState, newState.sum);
    }

    // Update the main operation
    Operation transactionOperation = newState.transaction.operations.removeAt(0);
    //newState.item.members.firstWhere((member) => member.id == transactionOperation.memberId).deleteTransaction(newState.transaction);
    transactionOperation.memberId = newState.item.members[newState.selection].id;
    transactionOperation.value = newState.sum;
    //newState.item.members.firstWhere((member) => member.id == transactionOperation.memberId).addTransaction(newState.transaction);
    
    // Update the involved operations
    List<Operation> toBeDeleted = newState.transaction.operations.where((op) => !newState.involvedMembers.any((m) => m['id'] == op.memberId)).toList();
    List<Operation> toBeAdded = newState.involvedMembers.where((m) => !newState.transaction.operations.any((op) => op.memberId == m['id'])).map<Operation>((m) {
      newState.item.members.firstWhere((member) => member.id == m['id']).add(-m['balance']);
      return Operation(
        memberId: m['id'],
        value: -m['balance'],
        itemId: newState.item.id,
        transactionId: newState.transaction.id
      );
    }).toList();
    List<Operation> nothingToDo = newState.transaction.operations.where((op) => newState.involvedMembers.any((m) => m['id'] == op.memberId && m['balance'] == op.value) as bool).toList();
    List toBeUpdated = newState.transaction.operations.where((op) => newState.involvedMembers.any((m) => m['id'] == op.memberId && m['balance'] != op.value) as bool).map((op) {
      newState.item.members.firstWhere((member) => member.id == op.memberId).add(-op.value);
      op.value = -newState.involvedMembers.firstWhere((m) => m['id'] == op.memberId)['balance'];
      newState.item.members.firstWhere((member) => member.id == op.memberId).add(op.value);
      return op;
    }).toList();
    
    List<Operation> operations = [transactionOperation, ...nothingToDo, ...toBeAdded, ...toBeUpdated];

    if (toBeDeleted.isNotEmpty) {
      await Future.wait(
        toBeDeleted.map((operation) => DatabaseHelper.instance.deleteOperation(operation))
      );
    }

    newState.transaction.description = newState.descriptionController.text;
    newState.transaction.value = newState.sum;
    newState.transaction.date = newState.date[2];
    newState.transaction.memberId = newState.item.members[newState.selection].id;
    newState.transaction.operations = operations;
    
    newState.cubit.updateTransaction(newState.transaction);
    DatabaseHelper.instance.upsertTransaction(newState.transaction);

    return Result.success(newState.transaction);
  }

  addTransaction() async {
    final newState = whichState.copyWith();

    if (newState.descriptionController.text.isEmpty) {
      final String message = enterDescription;
      emit(TransactionDialogShowSnackBar(
        cubit: newState.cubit,
        message: message
      ));
      emit(newState);
      return Result.failure(message);
    }
    if (newState.sum == 0) {
      final String message = transactionCannotBeZero;
      emit(TransactionDialogShowSnackBar(
        cubit: newState.cubit,
        message: message
      ));
      emit(newState);
      return Result.failure(message);
    }
    if (newState.selection == -1) {
      final String message = selectPayer;
      emit(TransactionDialogShowSnackBar(
        cubit: newState.cubit,
        message: message
      ));
      emit(newState);
      return Result.failure(message);
    }
    if (newState.memberSelection.contains(true) == false) {
      final String message = selectMin1Member;
      emit(TransactionDialogShowSnackBar(
        cubit: newState.cubit,
        message: message
      ));
      emit(newState);
      return Result.failure(message);
    }
    
    // Update Balances if they are not set with the CircularSlider
    if (newState.involvedMembers.isEmpty) {
      updateBalances(newState, newState.sum);
    }

    final members = newState.item.members.where((m) => !m.deleted).toList();

    String associatedId = members[newState.selection].id;
    Transaction transaction = Transaction(
      description: newState.descriptionController.text,
      value: newState.sum,
      date: newState.date[2],
      memberId: associatedId,
      itemId: newState.item.id
    );

    newState.cubit.addTransaction(transaction, newState.selection, newState.involvedMembers);

    DatabaseHelper.instance.upsertTransaction(transaction);

    newState.selection = -1;

    return Result.success(transaction);
  }

  updateBalances(state, double value) {
    int memberCount = state.memberSelection.where((element) => element == true).length;
    final members = state.item.members.where((m) => !m.deleted).toList();
    state.involvedMembers.clear();
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

  toggleHelp() async {
    final newState = whichState.copyWith(help: !whichState.help);
    emit(newState);

    await Future.delayed(const Duration(seconds: 3));
    if (newState.help) {
      emit(whichState.copyWith(help: !whichState.help));
    }
  }
}