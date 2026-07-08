import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:splizz/bloc/detailview_states.dart';
import 'package:splizz/resources/strings.dart';

Future<void> imagePickCropper(imageSource, context, Function(CroppedFile?) onImageCropped, {bool isDarkTheme = false}) async {
  final picker = ImagePicker();
  final imageFilePath = (await picker.pickImage(source: imageSource));
  if (imageFilePath == null) return;

  final croppedImage = await ImageCropper().cropImage(
    sourcePath: imageFilePath.path,
    aspectRatio: const CropAspectRatio(ratioX: 2.2, ratioY: 1),
    uiSettings: [
      AndroidUiSettings(
        toolbarTitle: imageCropperTitle,
        toolbarColor: Theme.of(context).colorScheme.surface,
        toolbarWidgetColor: isDarkTheme ? Colors.white : Colors.black,
        statusBarColor: Theme.of(context).colorScheme.surface,
        dimmedLayerColor: Colors.transparent,
        backgroundColor: Theme.of(context).colorScheme.surface),
      IOSUiSettings(
        title: imageCropperTitle,
      ),
    ],
  );

  onImageCropped(croppedImage);
}

class ImageSelection extends StatelessWidget {
  const ImageSelection({
    super.key,
    required this.themeMode,
    required this.state,
    required this.context,
    required this.onImageSelected,
  });

  final dynamic themeMode;
  final DetailViewEditMode state;
  final BuildContext context;
  final Function(CroppedFile?) onImageSelected;

  @override
  Widget build(BuildContext context) {

    Uint8List? imageFile = state.imageFile ?? state.item.image;

    bool isDarkTheme = themeMode == ThemeMode.system
      ? MediaQuery.of(context).platformBrightness == Brightness.dark
      : themeMode == ThemeMode.dark;

    return Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.width / 2.2,
        decoration: BoxDecoration(
            image: DecorationImage(
                    image: MemoryImage(imageFile!), //croppedImage!.image,
                    fit: BoxFit.fill)),
        child: Padding(
          padding: const EdgeInsets.only(top: 100),
          child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                      GestureDetector(
                        onTap: () async => await imagePickCropper(ImageSource.camera, context, onImageSelected, isDarkTheme: isDarkTheme),
                        child: Icon(Icons.camera_alt,
                            color: Colors.black54,
                            size: 50),
                      ),
                      GestureDetector(
                        onTap: () async => await imagePickCropper(ImageSource.gallery, context, onImageSelected, isDarkTheme: isDarkTheme),
                        child: Icon(Icons.image,
                            color: Colors.black54,
                            size: 50),
                      )
                    ]),
        ));
  }
}