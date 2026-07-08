import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:splizz/resources/strings.dart';

class DismissTile extends StatelessWidget {
  const DismissTile({
    super.key,
    required this.id,
    required this.context,
    required this.child,
    required this.onPressed,
  });

  final String id;
  final BuildContext context;
  final Widget child;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      decoration: const BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      clipBehavior: Clip.hardEdge,
        child: Slidable(
          key: ValueKey(id),
          endActionPane: ActionPane(
            motion: const DrawerMotion(),
            extentRatio: 0.25,
            children: [
              SlidableAction(
                onPressed: (_) => onPressed(),
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                icon: Icons.delete,
                label: dismissText,
              ),
            ],
          ),
          child: this.child,
      ),
    );
  }
}