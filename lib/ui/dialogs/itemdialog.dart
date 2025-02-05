import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import 'package:splizz/bloc/masterview_bloc.dart';

import 'package:splizz/ui/widgets/uiModels.dart';
import 'package:splizz/ui/widgets/customDialog.dart';
import 'package:splizz/Helper/colormap.dart';
import 'package:splizz/bloc/masterview_states.dart';

class ItemDialog extends StatelessWidget {
  late BuildContext context;
  late MasterViewCubit cubit;

  Image? croppedImage;
  final ImagePicker picker = ImagePicker();

  Future<void> showImagePicker() async {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return BlocBuilder<MasterViewCubit, MasterViewState>(
            bloc: cubit,
            buildWhen: (_, current) => current is MasterViewItemDialogImagePicker,
            builder: (context, state) {
              return CustomDialog(
                content: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height / 3,
                    child: GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 200,
                        childAspectRatio: 1.5,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 20,
                      ),
                      itemCount: 10,
                      itemBuilder: (BuildContext context, int index) {
                        return BlocBuilder<MasterViewCubit, MasterViewState>(
                          bloc: cubit,
                          buildWhen: (_, current) =>
                              current is MasterViewItemDialogImagePicker,
                          builder: (context, state) {
                            return imageTile(index, state);
                          },
                        );
                      },
                    )),
                onConfirmed: () => cubit.dismissImagePicker(),
                onDismissed: () => cubit.dismissImagePicker(),
              );
            },
          );
        });
  }

  Widget imageTile(int index, state) {
    int image = state.image;
    Uint8List? imageFile = state.imageFile;

    return Container(
        decoration: BoxDecoration(
            border: image == index
                ? Border.all(color: Colors.red, width: 3)
                : Border.all(
                    style: index == 0 && imageFile == null
                        ? BorderStyle.solid
                        : BorderStyle.none,
                    width: 2,
                    color: Colors.black45),
            borderRadius: const BorderRadius.all(Radius.circular(17)),
            image: index > 0 || imageFile == null
                ? null
                : DecorationImage(
                    image: MemoryImage(imageFile), //croppedImage!.image,
                    fit: BoxFit.cover)),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(15)),
          child: index > 0
              ? GestureDetector(
                  onTap: () => cubit.changeImage(index),
                  child: Image(
                      fit: BoxFit.cover,
                      image: AssetImage('images/image_${index}.jpg')),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                      GestureDetector(
                        onTap: () async {
                          await imagePickCropper(ImageSource.camera);
                          if (imageFile == null) return;
                          cubit.changeImage(index);
                        },
                        child: Icon(Icons.camera_alt,
                            color: imageFile == null
                                ? Colors.black45
                                : Colors.black87,
                            size: 50),
                      ),
                      GestureDetector(
                        onTap: () async {
                          await imagePickCropper(ImageSource.gallery);
                          if (imageFile == null) return;
                          cubit.changeImage(index);
                        },
                        child: Icon(Icons.image,
                            color: imageFile == null
                                ? Colors.black45
                                : Colors.black87,
                            size: 50),
                      )
                    ]),
        ));
  }

  Future<void> imagePickCropper(imageSource) async {
    final imageFilePath = (await picker.pickImage(source: imageSource));
    if (imageFilePath == null) return;

    final croppedImage = await ImageCropper().cropImage(
      sourcePath: imageFilePath.path,
      aspectRatio: const CropAspectRatio(ratioX: 2.2, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
            toolbarTitle: 'Crop',
            toolbarColor: Theme.of(context).colorScheme.surface,
            toolbarWidgetColor: Colors.white,
            backgroundColor: Theme.of(context).colorScheme.surface),
        IOSUiSettings(
          title: 'Crop',
        ),
      ],
    );

    cubit.setImage(croppedImage);
  }

  void showColorPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BlocBuilder<MasterViewCubit, MasterViewState>(
          bloc: cubit,
          buildWhen: (_, current) => current is MasterViewItemDialogColorPicker,
          builder: (context, state) {
            state as MasterViewItemDialogColorPicker;
            return CustomDialog(
              content: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: BlockPicker(
                      availableColors: colormap,
                      pickerColor: colormap[state.i - 1],
                      onColorChanged: (Color color) {
                        cubit.changeColorMap(color);
                        Navigator.of(context).pop();
                      }),
                ),
              ),
            );
          },
        );
      }
    );
  }

  Container textField(int i) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: TextField(
        onChanged: (name) => cubit.addMember(i, name),
        decoration: TfDecorationModel(
          context: context,
          title: 'Member $i',
          icon: IconButton(
            icon: const Icon(Icons.color_lens),
            color: colormap[i - 1],
            onPressed: () => cubit.showColorPicker(i),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    this.context = context;
    this.cubit = context.read<MasterViewCubit>();

    return BlocConsumer<MasterViewCubit, MasterViewState>(
      bloc: cubit,
      listenWhen: (previous, current) => current is MasterViewListener,
      listener: (context, state) {
        switch (state.runtimeType) {
          case MasterViewItemDialogShowColorPicker:
            showColorPicker();
            break;
          case MasterViewItemDialogShowImagePicker:
            showImagePicker();
            break;
        }
      },
      buildWhen: (_, current) => current is MasterViewItemDialog,
      builder: (context, state) {
        state as MasterViewItemDialog;

        return CustomDialog(
          title: 'Create a new Splizz',
          content: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: List.generate(state.count, (i) {
                  if (i == 0) {
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: TextField(
                        onChanged: (value) => cubit.updateItemTitle(value),
                        decoration: TfDecorationModel(
                          context: context,
                          title: 'Title',
                          icon: IconButton(
                              onPressed: cubit.showImagePicker,
                              icon: const Icon(
                                Icons.camera_alt,
                                color: Colors.black45,
                              )),
                        ),
                      ),
                    );
                  }
                  return textField(i);
                }),
              ),
            ),
          ),
          onConfirmed: () async => cubit.addItem(),
          onDismissed: () => cubit.dismissItemDialog(),
        );
      },
    );
  }
}
