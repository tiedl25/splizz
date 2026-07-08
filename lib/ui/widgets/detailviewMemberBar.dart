import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:splizz/bloc/detailview_states.dart';
import 'package:splizz/resources/animations.dart';
import 'package:splizz/resources/strings.dart';
import 'package:splizz/ui/dialogs/addMemberDialog.dart';
import 'package:splizz/ui/dialogs/memberDialog.dart';
import 'package:splizz/bloc/detailview_bloc.dart';
import 'package:splizz/models/member.model.dart';

class DetailviewMemberBar extends StatelessWidget {
  late List<GlobalKey> memberKeys;
  late bool alreadyInit = false;

  DetailviewMemberBar();

  void showMemberDialog(Member member, BuildContext context, DetailViewCubit cubit) {
    showDialog(
      context: context,
      builder: (_) {
        return BlocProvider.value(
          value: cubit, 
          child: MemberDialog()
        );
      });
  }

  List<GlobalKey> createMemberKeys(state) {
    List<Member> members = state.item.members;

    return List.generate(members.length, (index) {
      return GlobalKey();
    });
  }

  void showAnimatedMemberDialog(Member member, GlobalKey memberKey, BuildContext context, DetailViewCubit cubit) {
    final RenderBox box = memberKey.currentContext?.findRenderObject() as RenderBox;
    final Offset buttonPosition = box.localToGlobal(Offset.zero);
    final Size buttonSize = box.size;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: dialogDismiss,
      anchorPoint: Offset(buttonPosition.dx, buttonPosition.dy),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Container(); // Empty, we use transitionBuilder
      },
      transitionBuilder: (context, anim1, anim2, child) {
        anim1 = anim1.drive(
          CurveTween(curve: SlowEndCurve()),
        );
        anim2 = anim1.drive(CurveTween(curve: SlowStartCurve()));
        Widget innerChild = MemberDialog(opacity: anim2);

        return Stack(
          children: [
            Positioned(
              left: buttonPosition.dx - (buttonPosition.dx) * (anim1.value),
              top: buttonPosition.dy + (MediaQuery.of(context).size.height/2 - buttonPosition.dy) * (anim1.value) - MediaQuery.of(context).viewInsets.bottom,
              width: buttonSize.width + (MediaQuery.of(context).size.width - buttonSize.width) * anim1.value,
              height: buttonSize.height + (MediaQuery.of(context).size.height/2 - buttonSize.height) * anim1.value + MediaQuery.of(context).viewInsets.bottom,
              child: Opacity(
                opacity: anim1.value,
                child: BlocProvider.value(
                  value: cubit, 
                  child: innerChild
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void showAddMemberDialog(BuildContext context, DetailViewCubit cubit) {
    cubit.showAddMemberDialog();
    showDialog(
      context: context,
      builder: (_) {
        return BlocProvider.value(value: cubit, child: AddMemberDialog());
      });
  }

  List<Widget> memberBar(state, DetailViewCubit cubit) {
    List<Member> members = state.item.members;
    members = members.where((m) => !m.deleted).toList();
    if (!alreadyInit) {
      alreadyInit = true;
      memberKeys = createMemberKeys(state);
    } else if (memberKeys.length != members.length) {
      memberKeys = createMemberKeys(state);
    }

    return List.generate(members.length, (index) {
      return MemberTile(
        member: members[index], 
        memberKey: memberKeys[index], 
        onPressed: () => cubit.showMemberDialog(members[index], key: memberKeys[index])
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    DetailViewCubit cubit = context.read<DetailViewCubit>();

    return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        child: BlocConsumer<DetailViewCubit, DetailViewState>(
          bloc: cubit,
          listener: (BuildContext context, DetailViewState state) {
            switch (state.runtimeType) {
              case DetailViewShowMemberDialog:
                showAnimatedMemberDialog((state as DetailViewShowMemberDialog).member, state.memberKey!, context, cubit);
                break;
            }
          },
          builder: (context, state) => Row(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: memberBar(state, cubit),
              ),
              Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    border: Border.all(style: BorderStyle.none, width: 0),
                    borderRadius: const BorderRadius.all(Radius.circular(20)),
                  ),
                  child: IconButton(
                      iconSize: 30,
                      onPressed: () => showAddMemberDialog(context, cubit),
                      icon: Icon(Icons.add, color: Colors.white)))
            ],
          ),
        ));
  }
}

class MemberTileExpandable extends StatelessWidget {
  const MemberTileExpandable({
    super.key,
    required this.member,
    required this.width,
  });

  final Member member;
  final dynamic width;

  @override
  Widget build(BuildContext context) {
    Color textColor = Color(member.color).computeLuminance() > 0.2
      ? Colors.black
      : Colors.white;

    return Container(
      foregroundDecoration: !member.active
          ? const BoxDecoration(
              color: Color(0x99000000),
              backgroundBlendMode: BlendMode.darken,
              borderRadius: BorderRadius.all(Radius.circular(20)))
          : null,
      decoration: BoxDecoration(
        color: Color(member.color),
        border: Border.all(style: BorderStyle.none, width: 0),
        borderRadius: const BorderRadius.all(Radius.circular(20)),
      ),
      margin: const EdgeInsets.all(2),
      child: Container(
        width: width,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                member.name,
                style: TextStyle(fontSize: 20, color: textColor),
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                  color: Color(0xAAD5D5D5),
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(20))),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                      member.balance >= 0
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      color: member.balance >= 0
                          ? Colors.green[700]
                          : Colors.red[700]),
                  Text('${member.balance.abs().toStringAsFixed(2)}€',
                      style: TextStyle(
                          fontSize: 20,
                          color: member.balance >= 0
                              ? Colors.green[700]
                              : Colors.red[700])),
                ],
              ),
            )
          ],
        )
      )
    );
  }
}

class MemberTile extends StatelessWidget {
  final Member member;
  final GlobalKey memberKey;
  final Function onPressed;

  const MemberTile({
    super.key, 
    required this.member, 
    required this.memberKey,
    required this.onPressed
    });

  @override
  Widget build(BuildContext context) {
    Color textColor = Color(member.color).computeLuminance() > 0.2
      ? Colors.black
      : Colors.white;

    return Container(
      foregroundDecoration: !member.active
          ? const BoxDecoration(
              color: Color(0x99000000),
              backgroundBlendMode: BlendMode.darken,
              borderRadius: BorderRadius.all(Radius.circular(20)))
          : null,
      decoration: BoxDecoration(
        color: Color(member.color),
        border: Border.all(style: BorderStyle.none, width: 0),
        borderRadius: const BorderRadius.all(Radius.circular(20)),
      ),
      margin: const EdgeInsets.all(2),
      child: IntrinsicWidth(
        key: memberKey,
        child: GestureDetector(
          onTap: () => onPressed(),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  member.name,
                  style: TextStyle(fontSize: 20, color: textColor),
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                    color: Color(0xAAD5D5D5),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(20))),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                        member.balance >= 0
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        color: member.balance >= 0
                            ? Colors.green[700]
                            : Colors.red[700]),
                    Text('${member.balance.abs().toStringAsFixed(2)}€',
                        style: TextStyle(
                            fontSize: 20,
                            color: member.balance >= 0
                                ? Colors.green[700]
                                : Colors.red[700])),
                  ],
                ),
              )
            ],
          ),
        )
      )
    );
  }
}