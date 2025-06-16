import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:splizz/bloc/detailview_states.dart';
import 'package:splizz/ui/dialogs/addMemberDialog.dart';
import 'package:splizz/ui/dialogs/memberDialog.dart';
import 'package:splizz/bloc/detailview_bloc.dart';
import 'package:splizz/models/member.model.dart';

class MemberBar extends StatelessWidget {
  late final DetailViewCubit cubit;
  late final BuildContext context;
  late final animationController;
  late final List<GlobalKey> memberKeys;
  late bool alreadyInit = false;

  MemberBar();

  void showMemberDialog(Member member) {
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

  void showAddMemberDialog() {
    showDialog(
      context: context,
      builder: (_) {
        return BlocProvider.value(value: cubit, child: AddMemberDialog());
      });
  }

  Container memberTileExpandable(Member member, width) {
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

  Container memberTile(Member member, GlobalKey key) {
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
        key: key,
        child: GestureDetector(
          onTap: () => cubit.showMemberDialog(member),
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

  List<Container> memberBar(state) {
    List<Member> members = state.item.members;
    members = members.where((m) => !m.deleted).toList();
    if (!alreadyInit) {
      alreadyInit = true;
      memberKeys = createMemberKeys(state);
    }

    return List.generate(members.length, (index) {
      return memberTile(members[index], memberKeys[index]);
    });
  }

  @override
  Widget build(BuildContext context) {
    this.context = context;
    this.cubit = context.read<DetailViewCubit>();

    return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        child: BlocConsumer<DetailViewCubit, DetailViewState>(
          bloc: cubit,
          listener: (BuildContext context, DetailViewState state) {
            switch (state.runtimeType) {
              case DetailViewShowMemberDialog:
                showMemberDialog((state as DetailViewShowMemberDialog).member);
                break;
            }
          },
          builder: (context, state) => Row(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: memberBar(state),
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
                      onPressed: () => showAddMemberDialog(),
                      icon: Icon(Icons.add, color: Colors.white)))
            ],
          ),
        ));
  }
}