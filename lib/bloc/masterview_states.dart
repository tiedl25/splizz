import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:splizz/models/item.model.dart';

abstract class MasterViewState {
  final SharedPreferences sharedPreferences;

  MasterViewState({required this.sharedPreferences});
}

class MasterViewLoading extends MasterViewState {
  MasterViewLoading({required super.sharedPreferences});
}

class MasterViewLoaded extends MasterViewState {
  List<Item> items;
  double? balance;

  MasterViewLoaded({required this.items, required this.balance, required super.sharedPreferences});

  MasterViewLoaded copyWith({List<Item>? items, double? balance, SharedPreferences? sharedPreferences}) {
    return MasterViewLoaded(
      items: items ?? this.items, 
      balance: balance ?? this.balance,
      sharedPreferences: sharedPreferences ?? this.sharedPreferences
    );
  }

  factory MasterViewLoaded.fromItemDialog(MasterViewItemDialog state) {
    return MasterViewLoaded(items: state.items, balance: state.balance, sharedPreferences: state.sharedPreferences);
  }
}



abstract class MasterViewListener extends MasterViewState {
  MasterViewListener({required super.sharedPreferences});
}  

class MasterViewShowItemDialog extends MasterViewListener {
  MasterViewShowItemDialog({required super.sharedPreferences});
}

class MasterViewShowInvitationDialog extends MasterViewListener {
  MasterViewShowInvitationDialog({required super.sharedPreferences});
}

class MasterViewShowSnackBar extends MasterViewListener {
  final String message;

  MasterViewShowSnackBar({required super.sharedPreferences, required this.message});
}

class MasterViewItemDialogShowSnackBar extends MasterViewShowSnackBar {
  MasterViewItemDialogShowSnackBar({required super.sharedPreferences, required super.message});
}

class MasterViewPushAuthView extends MasterViewListener {
  MasterViewPushAuthView({required super.sharedPreferences});
}



class MasterViewItemDialogShowImagePicker extends MasterViewListener {
  MasterViewItemDialogShowImagePicker({required super.sharedPreferences});
}

class MasterViewItemDialogShowColorPicker extends MasterViewListener {
  MasterViewItemDialogShowColorPicker({required super.sharedPreferences});
}



class MasterViewInvitationDialog extends MasterViewState {
  final String permissionId;
  
  MasterViewInvitationDialog({required super.sharedPreferences, required this.permissionId});
}


class MasterViewItemDialog extends MasterViewLoaded {
  String title = "";
  List<String> members;
  int count = 3;
  int image = 1;
  Uint8List? imageFile;

  MasterViewItemDialog({
    required super.items, 
    required super.balance,
    required super.sharedPreferences, 
    required this.members, 
    this.title="", 
    this.count=3, 
    this.image=1,
    this.imageFile
  });

  MasterViewItemDialog copyWith({
    List<Item>? items, 
    double? balance,
    SharedPreferences? sharedPreferences, 
    String? title, 
    List<String>? members, 
    int? count, 
    int? image,
    Uint8List? imageFile
    }) {
      return MasterViewItemDialog(
        items: items ?? this.items, 
        balance: balance ?? this.balance,
        sharedPreferences: sharedPreferences ?? this.sharedPreferences, 
        title: title ?? this.title, 
        members: members ?? this.members, 
        count: count ?? this.count, 
        image: image ?? this.image,
        imageFile: imageFile ?? this.imageFile
      );
  }

  factory MasterViewItemDialog.fromLoaded(MasterViewLoaded state) {
    return MasterViewItemDialog(
      items: state.items, 
      balance: state.balance,
      sharedPreferences: state.sharedPreferences,
      members: [],
    );
  }

  factory MasterViewItemDialog.fromColorPicker(MasterViewItemDialogColorPicker state) {
    return MasterViewItemDialog(
      items: state.items, 
      balance: state.balance,
      sharedPreferences: state.sharedPreferences,
      title: state.title, 
      members: state.members, 
      count: state.count, 
      image: state.image,
      imageFile: state.imageFile
    );
  }

  factory MasterViewItemDialog.fromImagePicker(MasterViewItemDialogImagePicker state) {
    return MasterViewItemDialog(
      items: state.items, 
      balance: state.balance,
      sharedPreferences: state.sharedPreferences,
      title: state.title, 
      members: state.members, 
      count: state.count, 
      image: state.image,
      imageFile: state.imageFile
    );
  }
}

class MasterViewItemDialogColorPicker extends MasterViewItemDialog {
  int i;

  MasterViewItemDialogColorPicker({
    required super.items, 
    required super.balance,
    required super.sharedPreferences, 
    required super.title, 
    required super.members, 
    required super.count, 
    required super.image,
    super.imageFile,
    required this.i
  });

  factory MasterViewItemDialogColorPicker.from(MasterViewItemDialog state, {required int i}) {
    return MasterViewItemDialogColorPicker(
      items: state.items, 
      balance: state.balance,
      sharedPreferences: state.sharedPreferences,
      title: state.title, 
      members: state.members, 
      count: state.count, 
      image: state.image,
      imageFile: state.imageFile,
      i: i,
    );
  }
}

class MasterViewItemDialogImagePicker extends MasterViewItemDialog {
  MasterViewItemDialogImagePicker({
    required super.items, 
    required super.balance,
    required super.sharedPreferences, 
    required super.title, 
    required super.members, 
    required super.count, 
    required super.image,
    super.imageFile
  });

  factory MasterViewItemDialogImagePicker.from(MasterViewItemDialog state) {
    return MasterViewItemDialogImagePicker(
      items: state.items, 
      balance: state.balance,
      sharedPreferences: state.sharedPreferences,
      title: state.title, 
      members: state.members, 
      count: state.count, 
      image: state.image,
      imageFile: state.imageFile
    );
  }

  @override
  MasterViewItemDialogImagePicker copyWith({
    List<Item>? items, 
    double? balance,
    SharedPreferences? sharedPreferences, 
    String? title, 
    List<String>? members, 
    int? count, 
    int? image,
    Uint8List? imageFile
    }) {
      return MasterViewItemDialogImagePicker(
        items: items ?? this.items, 
        balance: balance ?? this.balance,
        sharedPreferences: sharedPreferences ?? this.sharedPreferences, 
        title: title ?? this.title, 
        members: members ?? this.members, 
        count: count ?? this.count, 
        image: image ?? this.image,
        imageFile: imageFile ?? this.imageFile
      );
  }
}