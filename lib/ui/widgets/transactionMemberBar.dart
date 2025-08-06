import 'package:flutter/material.dart';
import 'package:splizz/models/member.model.dart';
import 'package:splizz/models/transaction.model.dart';

class TransactionMemberBar extends StatelessWidget {
  const TransactionMemberBar({
    super.key,
    required this.members,
    required this.transaction,
    required this.textColor,
  });

  final dynamic members;
  final Transaction transaction;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey('memberBar'),
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Container(
        padding: const EdgeInsets.all(5),
        margin: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: textColor.withAlpha(96),
          border: Border.all(style: BorderStyle.none, width: 0),
          borderRadius: const BorderRadius.all(Radius.circular(20)),
        ),
        child: Row(
          children: List.generate(transaction.operations.length, (index) {
            Member m = members.firstWhere((element) => element.id == transaction.operations[index].memberId);
            if (index == 0) {
              return Container(
                  padding: const EdgeInsets.only(right: 20, left: 5, top: 5, bottom: 5),
                  margin: const EdgeInsets.all(2),
                  child: Text(
                    m.name,
                    style: TextStyle(color: textColor),
                  ));
            }
            return Container(
              padding: const EdgeInsets.all(5),
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Color(m.color),
                border: Border.all(style: BorderStyle.none, width: 0),
                borderRadius: const BorderRadius.all(Radius.circular(20)),
              ),
              child: Text(
                m.name,
                style: TextStyle(color: Color(m.color).computeLuminance() > 0.2 ? Colors.black : Colors.white),
              ),
            );
          }),
        ),
      ),
    );
  }
}