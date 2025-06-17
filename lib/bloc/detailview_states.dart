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

  DetailViewLoaded({required super.item, this.unbalanced = false});

  factory DetailViewLoaded.fromState(DetailViewState state, {unbalanced = false}) =>
    DetailViewLoaded(item: state.item, unbalanced: unbalanced);

  factory DetailViewLoaded.fromPayoffDialog(DetailViewPayoffDialog state) =>
    DetailViewLoaded(item: state.item, unbalanced: state.unbalanced);

  factory DetailViewLoaded.fromShareDialog(DetailViewShareDialog state) =>
    DetailViewLoaded(item: state.item, unbalanced: state.unbalanced);

  factory DetailViewLoaded.from(final state) =>
    DetailViewLoaded(item: state.item, unbalanced: state.unbalanced);

  @override
  DetailViewLoaded copyWith({Item? item, bool? unbalanced}) {
    return DetailViewLoaded(
      item: item ?? this.item, 
      unbalanced: unbalanced ?? this.unbalanced
    );
  }
}

class DetailViewTransactionDialog extends DetailViewLoaded {
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

  DetailViewTransactionDialog({
    required super.item,
    super.unbalanced,
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
    this.sliderIndex = 0, 
    this.euros = 0.1,
    this.zoomEnabled = false,
    this.lastChangedMemberIndex = 0,
  });

  factory DetailViewTransactionDialog.fromState(DetailViewState state) =>
    DetailViewTransactionDialog(
      item: state.item,
      memberSelection: state.item.members.where((m) => !m.deleted).map((Member m) => m.active).toList(),
      memberBalances: List.generate(state.item.members.length, (index) => 0.0),
      involvedMembers: [],
      date: ["Today", "Yesterday", DateTime.now()]);

  @override
  DetailViewTransactionDialog copyWith({
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
    int? lastChangedMemberIndex}) =>
      DetailViewTransactionDialog(
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
        date: date ?? this.date,
        sum: sum ?? this.sum,
        lock: lock ?? this.lock,
        sliderIndex: sliderIndex ?? this.sliderIndex,
        euros: euros ?? this.euros,
        zoomEnabled: zoomEnabled ?? this.zoomEnabled,
        lastChangedMemberIndex: lastChangedMemberIndex ?? this.lastChangedMemberIndex,
      );
}

class DetailViewShareDialog extends DetailViewLoaded {
  bool fullAccess;

  DetailViewShareDialog({required super.item, super.unbalanced, this.fullAccess = false});

  factory DetailViewShareDialog.fromLoaded(DetailViewLoaded state) =>
    DetailViewShareDialog(item: state.item, unbalanced: state.unbalanced);

  @override
  DetailViewShareDialog copyWith({Item? item, bool? unbalanced, bool? fullAccess}) =>
    DetailViewShareDialog(
      item: item ?? this.item, 
      unbalanced: unbalanced ?? this.unbalanced, 
      fullAccess: fullAccess ?? this.fullAccess
    );
}

class DetailViewPayoffDialog extends DetailViewLoaded {
  int? index;
  bool past;

  DetailViewPayoffDialog({required super.item, super.unbalanced, this.index, this.past = false});

  factory DetailViewPayoffDialog.fromLoaded(DetailViewLoaded state, {bool past = false}) =>
    DetailViewPayoffDialog(item: state.item, unbalanced: state.unbalanced, past: past);
}

class DetailViewMemberDialog extends DetailViewLoaded {
  Member member;
  bool editMode;

  DetailViewMemberDialog({required super.item, super.unbalanced, required this.member, this.editMode = false});

  factory DetailViewMemberDialog.fromState(final state, final Member member, final bool editMode) =>
    DetailViewMemberDialog(item: state.item, unbalanced: state.unbalanced, member: member, editMode: editMode);

  @override
  DetailViewMemberDialog copyWith({Item? item, bool? unbalanced, Member? member, bool? editMode}) =>
    DetailViewMemberDialog(
      item: item ?? this.item, 
      unbalanced: unbalanced ?? this.unbalanced, 
      member: member ?? this.member, 
      editMode: editMode ?? this.editMode
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

class DetailViewTransactionDialogShowSnackBar extends DetailViewShowSnackBar {
  DetailViewTransactionDialogShowSnackBar({required super.item, required super.message});
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