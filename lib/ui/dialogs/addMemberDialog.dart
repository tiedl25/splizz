import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:splizz/bloc/detailview_bloc.dart';
import 'package:splizz/bloc/detailview_states.dart';
import 'package:splizz/resources/colormap.dart';
import 'package:splizz/ui/widgets/customDialog.dart';

class AddMemberDialog extends StatelessWidget {
  late BuildContext context;
  late DetailViewCubit cubit;

  final TextEditingController controller = TextEditingController();
  Color color = colormap[0];

  AddMemberDialog({super.key});

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
                pickerColor: colormap[0],
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

  @override
  Widget build(BuildContext context) {
    this.context = context;
    this.cubit = context.read<DetailViewCubit>();

    return CustomDialog(
      title: "Add Member",
      content: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
              labelText: 'Name',
              suffixIcon: IconButton(
                onPressed: () => showColorPicker(),
                icon: BlocBuilder<DetailViewCubit, DetailViewState>(
                  bloc: cubit,
                  buildWhen: (_, current) => current is DetailViewLoaded,
                  builder: (context, state) {
                    return Icon(Icons.color_lens, color: color);
                  },
                ))),
        ),
      ),
      onConfirmed: () => cubit.addMember(controller.text, color),
    );
  }
}