import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:splizz/resources/strings.dart';

Future<void> imagePickCropper(imageSource, context, cubit, {bool update = false, bool isDarkTheme = false}) async {
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

  update ? cubit.changeImage(croppedImage) : cubit.setImage(croppedImage);
}