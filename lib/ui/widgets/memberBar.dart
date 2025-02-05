import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:splizz/ui/widgets/uiModels.dart';
import 'package:splizz/ui/widgets/customDialog.dart';
import 'package:splizz/bloc/detailview_bloc.dart';
import 'package:splizz/bloc/detailview_states.dart';
import 'package:splizz/models/member.model.dart';

class MemberBar extends StatelessWidget {
  late final DetailViewCubit cubit;
  late final BuildContext context;

  MemberBar();

  void showMemberDialog(Member member) {
    showDialog(
      context: context,
      builder: (_) {
        return BlocProvider.value(
          value: cubit,
          child: MemberDialog(memberId: member.id));
      });
  }

  List<Container> memberBar(state) {
    List<Member> members = state.item.members;

    return List.generate(members.length, (index) {
      Member member = members[index];
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
          child: GestureDetector(
            onTap: () => showMemberDialog(member),
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
    });
  }

  @override
  Widget build(BuildContext context) {
    this.context = context;
    this.cubit = context.read<DetailViewCubit>();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      scrollDirection: Axis.horizontal,
      child: BlocBuilder(
        bloc: cubit,
        builder: (context, state) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: memberBar(state),
        ),
      ));
  }
}

class MemberDialog extends StatelessWidget {
  const MemberDialog({
    super.key,
    required this.memberId,
  });

  final String memberId;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DetailViewCubit>();

    return BlocBuilder<DetailViewCubit, DetailViewState>(
      bloc: cubit,
      builder: (context, state) {
        Member member = state.item.members.firstWhere((element) => element.id == memberId);

        return CustomDialog(
          content: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Name'), 
                        Text(member.name)
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total'),
                        Text(member.total.toString())
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Balance'),
                        Text(member.balance.toString())
                      ],
                    ),
                  ),
                  SwitchListTile(
                    title: const Text("Active"),
                    value: member.active,
                    onChanged: (bool value) => cubit.setMemberActivity(member, value),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
