import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:splizz/bloc/detailview_bloc.dart';
import 'package:splizz/bloc/detailview_states.dart';
import 'package:splizz/models/member.model.dart';
import 'package:splizz/resources/colormap.dart';
import 'package:splizz/ui/widgets/customDialog.dart';
import 'package:splizz/ui/widgets/uiModels.dart';

class MemberDialog extends StatelessWidget {
  late BuildContext context;
  late DetailViewCubit cubit;

  TextEditingController? textController;
  Color? color;

  MemberDialog({
    super.key,
  });

  showDeleteMemberDialog(){
    showDialog(
      context: context,
      builder: (_) {
        return BlocProvider.value(
          value: cubit, 
          child: CustomDialog(
            title: 'Delete Member',
            content: Container(
                padding: const EdgeInsets.all(5),
                child: const Text(
                  'Are you sure you want to delete this member?',
                  style: TextStyle(fontSize: 20),
                ),
              ),
            rightText: 'Delete',
            onConfirmed: () => cubit.deleteMember(),
          )
        );
      }
    );
  }

  void showColorPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomDialog(
          content: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: BlockPicker(
                availableColors: colormap,
                pickerColor: color,
                onColorChanged: (Color color) {
                  Navigator.of(context).pop();
                  this.color = color;
                  cubit.changeNewMemberColor();
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget content(Member member, bool editMode){
    Color textColor = Color(member.color).computeLuminance() > 0.2
        ? Colors.black
        : Colors.white;

    return Expanded(
      flex: 7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.only(
                left: 15, right: 15, top: 5, bottom: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Name', style: TextStyle(fontSize: 20, color: textColor)),
                IntrinsicWidth(
                  child: TextField(
                    textAlign: TextAlign.right,
                    controller: textController,
                    style: TextStyle(fontSize: editMode ? 20 : 15, color: textColor),
                    decoration: InputDecoration(
                      prefixIcon: editMode 
                        ? Padding(
                            padding: const EdgeInsets.only(right: 10), 
                            child: IconButton(
                              onPressed: () => showColorPicker(),
                              icon: Icon(Icons.color_lens, size: 30, color: textColor),
                            )
                          ) 
                        : null,
                      prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
                      border: InputBorder.none, 
                    ),
                    enabled: editMode,
                    onChanged: (String value) => null,
                  ),
                )
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.only(
                left: 15, right: 15, top: 5, bottom: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total', style: TextStyle(fontSize: 20, color: textColor)),
                Text("${member.total.toStringAsFixed(2)} €",
                    style: TextStyle(fontSize: 15, color: textColor))
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.only(
                left: 15, right: 15, top: 5, bottom: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Balance', style: TextStyle(fontSize: 20, color: textColor)),
                Text("${member.balance.toStringAsFixed(2)} €",
                    style: TextStyle(fontSize: 15, color: textColor))
              ],
            ),
          ),
          SwitchListTile(
            contentPadding: const EdgeInsets.only(left: 15, right: 10),
            title: Text("Active", style: TextStyle(fontSize: 20, color: textColor)),
            value: member.active,
            onChanged: (bool value) =>
                cubit.setMemberActivity(member, value),
          ),
        ],
      ),
    );
  }

  Widget buttons(bool editMode, balance){
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(20)),
        color: Color.fromARGB(80, 32, 32, 32),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            GestureDetector(
              onTap: () => editMode ? cubit.updateMember(textController!.text, color!) : cubit.toggleMemberEditMode(),
              child: Icon(
                editMode ? Icons.check_circle : Icons.edit,
                size: 25,
                color: Colors.red,
              ),
            ),
            SizedBox(
              width: 20, // Adjust the width as needed
              child: Divider(
                thickness: 1,
                color: Colors.black,
              ),
            ),
            GestureDetector(
              onTap: () => editMode 
                ? {color = null, textController = null, cubit.toggleMemberEditMode()} 
                : balance == 0 
                  ? showDeleteMemberDialog() 
                  : showOverlayMessage(
                      context: context, 
                      message: 'You cannot delete a member with a non-zero balance', 
                      backgroundColor: Theme.of(context).colorScheme.surface
                    ),
              child: Icon(
                editMode ? Icons.cancel : Icons.delete,
                size: 25,
                color: balance == 0 ? Colors.blue : Colors.blueGrey,
              ),
            ),
          ],
        ),
    );
  }

  @override
  Widget build(BuildContext context) {
    this.context = context;
    this.cubit = context.read<DetailViewCubit>();

    return BlocBuilder<DetailViewCubit, DetailViewState>(
      bloc: cubit,
      buildWhen: (_, current) => current is DetailViewMemberDialog,
      builder: (context, state) {
        Member member = (state as DetailViewMemberDialog).member;
        textController = TextEditingController(text: textController == null ? member.name : textController!.text);
        color = color ?? Color(member.color);

        return CustomDialog(
          color: color,
          content: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  content(member, state.editMode),
                  buttons(state.editMode, member.balance),
                ],
              ),
            ),
          ),
          onDismissed: () => cubit.closeMemberDialog(),
        );
      },
    );
  }
}