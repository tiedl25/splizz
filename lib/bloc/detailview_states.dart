import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:splizz/models/item.model.dart';
import 'package:splizz/models/member.model.dart';

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
  bool showPieChart;

  DetailViewLoaded({required super.item, this.unbalanced = false, this.showPieChart = false});

  factory DetailViewLoaded.fromState(DetailViewState state, {unbalanced = false, showPieChart = false}) =>
    DetailViewLoaded(item: state.item, unbalanced: unbalanced, showPieChart: showPieChart);

  factory DetailViewLoaded.fromPayoffDialog(DetailViewPayoffDialog state) =>
    DetailViewLoaded(item: state.item, unbalanced: state.unbalanced, showPieChart: state.showPieChart);

  factory DetailViewLoaded.fromShareDialog(DetailViewShareDialog state) =>
    DetailViewLoaded(item: state.item, unbalanced: state.unbalanced, showPieChart: state.showPieChart);

  factory DetailViewLoaded.from(final state, {unbalanced, showPieChart}) =>
    DetailViewLoaded(item: state.item, unbalanced: unbalanced ?? state.unbalanced, showPieChart: showPieChart ?? state.showPieChart);

  @override
  DetailViewLoaded copyWith({Item? item, bool? unbalanced, bool? showPieChart}) {
    return DetailViewLoaded(
      item: item ?? this.item, 
      unbalanced: unbalanced ?? this.unbalanced,
      showPieChart: showPieChart ?? this.showPieChart
    );
  }
}

class DetailViewEditMode extends DetailViewState {
  TextEditingController? name;
  Uint8List? imageFile;

  DetailViewEditMode({required super.item, this.name, this.imageFile});

  factory DetailViewEditMode.fromState(DetailViewState state) =>
    DetailViewEditMode(item: state.item, name: TextEditingController(text: state.item.name), imageFile: state.item.image);

  @override
  DetailViewEditMode copyWith({Item? item, TextEditingController? name, Uint8List? imageFile}) {
    return DetailViewEditMode(
      item: item ?? this.item,
      name: name ?? this.name,
      imageFile: imageFile ?? this.imageFile
      );
  }
}

class DetailViewShareDialog extends DetailViewLoaded {
  bool fullAccess;

  DetailViewShareDialog({required super.item, super.unbalanced, super.showPieChart, this.fullAccess = false});

  factory DetailViewShareDialog.fromLoaded(DetailViewLoaded state) =>
    DetailViewShareDialog(item: state.item, unbalanced: state.unbalanced, showPieChart: state.showPieChart);

  @override
  DetailViewShareDialog copyWith({Item? item, bool? unbalanced, bool? showPieChart, bool? fullAccess}) =>
    DetailViewShareDialog(
      item: item ?? this.item, 
      unbalanced: unbalanced ?? this.unbalanced, 
      showPieChart: showPieChart ?? this.showPieChart,
      fullAccess: fullAccess ?? this.fullAccess,
    );
}

class DetailViewPayoffDialog extends DetailViewLoaded {
  String? payoffId;
  bool past;
  List<bool> whatToShare;

  DetailViewPayoffDialog({required super.item, super.unbalanced, super.showPieChart, this.payoffId, this.past = false, this.whatToShare = const [true, false, false]});

  factory DetailViewPayoffDialog.fromLoaded(DetailViewLoaded state, {bool past = false, List<bool> whatToShare = const [true, false, false]}) =>
    DetailViewPayoffDialog(item: state.item, unbalanced: state.unbalanced, showPieChart: state.showPieChart, past: past, whatToShare: whatToShare);

  @override
  DetailViewPayoffDialog copyWith({Item? item, bool? unbalanced, bool? showPieChart, String? payoffId, bool? past, List<bool>? whatToShare}) =>
    DetailViewPayoffDialog(
      item: item ?? this.item, 
      unbalanced: unbalanced ?? this.unbalanced,
      showPieChart: showPieChart ?? this.showPieChart,
      payoffId: payoffId ?? this.payoffId,
      past: past ?? this.past,
      whatToShare: whatToShare ?? this.whatToShare
    );
}

class DetailViewMemberDialog extends DetailViewLoaded {
  Member member;
  bool editMode;
  TextEditingController? name;
  Color? color;

  DetailViewMemberDialog({required super.item, super.unbalanced, super.showPieChart, required this.member, this.editMode = false, this.name, this.color});

  factory DetailViewMemberDialog.fromState(final state, final Member member, final bool editMode, final TextEditingController name, final Color? color) =>
    DetailViewMemberDialog(item: state.item, unbalanced: state.unbalanced, showPieChart: state.showPieChart, member: member, editMode: editMode, name: name, color: color);

  @override
  DetailViewMemberDialog copyWith({Item? item, bool? unbalanced, bool? showPieChart, Member? member, bool? editMode, TextEditingController? name, Color? color}) =>
    DetailViewMemberDialog(
      item: item ?? this.item, 
      unbalanced: unbalanced ?? this.unbalanced, 
      showPieChart: showPieChart ?? this.showPieChart,
      member: member ?? this.member, 
      editMode: editMode ?? this.editMode,
      name: name ?? this.name,
      color: color ?? this.color
    );
}

class DetailViewAddMemberDialog extends DetailViewLoaded {
  Color color;

  DetailViewAddMemberDialog({required super.item, super.unbalanced, super.showPieChart, required this.color});

  factory DetailViewAddMemberDialog.fromState(final state, Color color) =>
    DetailViewAddMemberDialog(item: state.item, unbalanced: state.unbalanced, showPieChart: state.showPieChart, color: color);

  @override
  DetailViewAddMemberDialog copyWith({Item? item, bool? unbalanced, bool? showPieChart, Color? color}) =>
    DetailViewAddMemberDialog(
      item: item ?? this.item, 
      unbalanced: unbalanced ?? this.unbalanced,
      showPieChart: showPieChart ?? this.showPieChart,
      color: color ?? this.color
    );
}









abstract class DetailViewListener extends DetailViewState {
  DetailViewListener({required super.item});
}

class DetailViewShowTransactionDialog extends DetailViewListener {
  DetailViewShowTransactionDialog({required super.item});
}

class DetailViewShowShareDialog extends DetailViewListener {
  DetailViewShowShareDialog({required super.item});
}

class DetailViewShowSnackBar extends DetailViewListener {
  final String message;

  DetailViewShowSnackBar({required super.item, required this.message});
}

class DetailViewShowMemberDialog extends DetailViewListener {
  final Member member;
  final GlobalKey? memberKey;

  DetailViewShowMemberDialog({required super.item, required this.member, this.memberKey});
}

class DetailViewShareDialogShowSnackBar extends DetailViewShowSnackBar {
  DetailViewShareDialogShowSnackBar({required super.item, required super.message});
}

class DetailViewShareDialogShowLink extends DetailViewShowSnackBar {
  DetailViewShareDialogShowLink({required super.item, required super.message});
}

class DetailViewShowPayoffDialog extends DetailViewListener {
  DetailViewShowPayoffDialog({required super.item});
}

class DetailViewShowPastPayoffDialog extends DetailViewListener {
  DetailViewShowPastPayoffDialog({required super.item});
}