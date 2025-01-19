import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:app_links/app_links.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:splizz/Helper/colormap.dart';
import 'package:splizz/Helper/database.dart';
import 'package:splizz/models/item.model.dart';
import 'package:splizz/models/member.model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class MasterViewState {
  final SharedPreferences sharedPreferences;

  MasterViewState({required this.sharedPreferences});
}

class MasterViewLoading extends MasterViewState {
  MasterViewLoading({required super.sharedPreferences});
}

class MasterViewLoaded extends MasterViewState {
  List<Item> items;

  MasterViewLoaded({required this.items, required super.sharedPreferences});

  MasterViewLoaded copyWith({List<Item>? items, SharedPreferences? sharedPreferences}) {
    return MasterViewLoaded(
      items: items ?? this.items, 
      sharedPreferences: sharedPreferences ?? this.sharedPreferences
    );
  }

  factory MasterViewLoaded.fromItemDialog(MasterViewItemDialog state) {
    return MasterViewLoaded(items: state.items, sharedPreferences: state.sharedPreferences);
  }

  factory MasterViewLoaded.fromDismissDialog(MasterViewDismissDialog state) {
    return MasterViewLoaded(items: state.items, sharedPreferences: state.sharedPreferences);
  }
}



abstract class MasterViewListener extends MasterViewState {
  MasterViewListener({required super.sharedPreferences});
}  

class MasterViewShowItemDialog extends MasterViewListener {
  MasterViewShowItemDialog({required super.sharedPreferences});
}

class MasterViewShowDismissDialog extends MasterViewListener {
  MasterViewShowDismissDialog({required super.sharedPreferences});
}

class MasterViewShowInvitationDialog extends MasterViewListener {
  MasterViewShowInvitationDialog({required super.sharedPreferences});
}

class MasterViewShowSnackBar extends MasterViewListener {
  final String message;

  MasterViewShowSnackBar({required super.sharedPreferences, required this.message});
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


class MasterViewDismissDialog extends MasterViewLoaded {
  MasterViewDismissDialog({required super.items, required super.sharedPreferences});

  factory MasterViewDismissDialog.fromLoaded(MasterViewLoaded state) {
    return MasterViewDismissDialog(items: state.items, sharedPreferences: state.sharedPreferences);
  }
}

class MasterViewItemDialog extends MasterViewLoaded {
  String title = "";
  List<String> members;
  int count = 3;
  int image = 1;
  Uint8List? imageFile;

  MasterViewItemDialog({
    required super.items, 
    required super.sharedPreferences, 
    required this.members, 
    this.title="", 
    this.count=3, 
    this.image=1,
    this.imageFile
  });

  MasterViewItemDialog copyWith({
    List<Item>? items, 
    SharedPreferences? sharedPreferences, 
    String? title, 
    List<String>? members, 
    int? count, 
    int? image,
    Uint8List? imageFile
    }) {
      return MasterViewItemDialog(
        items: items ?? this.items, 
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
      sharedPreferences: state.sharedPreferences,
      members: [],
    );
  }

  factory MasterViewItemDialog.fromColorPicker(MasterViewItemDialogColorPicker state) {
    return MasterViewItemDialog(
      items: state.items, 
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
    SharedPreferences? sharedPreferences, 
    String? title, 
    List<String>? members, 
    int? count, 
    int? image,
    Uint8List? imageFile
    }) {
      return MasterViewItemDialogImagePicker(
        items: items ?? this.items, 
        sharedPreferences: sharedPreferences ?? this.sharedPreferences, 
        title: title ?? this.title, 
        members: members ?? this.members, 
        count: count ?? this.count, 
        image: image ?? this.image,
        imageFile: imageFile ?? this.imageFile
      );
  }
}




class MasterViewCubit extends Cubit<MasterViewState> {
  MasterViewCubit(SharedPreferences sharedPreferences) : super(MasterViewLoading(sharedPreferences: sharedPreferences)) {
    if (!checkAuth()) {
      return;
    }
    fetchData();
    handleIncomingLinks();
  }

  void fetchData({bool destructive=true}) async {
    if (destructive) DatabaseHelper.instance.destructiveSync();
    final items = await DatabaseHelper.instance.getItems();

    final newState = MasterViewLoaded(
      items: items, 
      sharedPreferences: state.sharedPreferences
    );

    emit(newState);
  }

  void handleIncomingLinks() {
    final appLinks = AppLinks();
    StreamSubscription? sub;

    sub = appLinks.uriLinkStream.listen((Uri? uri) async {
      if (uri != null) {
        final permissionId = uri.queryParameters['id'];

        if (permissionId != null) {
          final newState = MasterViewInvitationDialog(
            sharedPreferences: state.sharedPreferences,
            permissionId: permissionId
          );

          emit(MasterViewShowInvitationDialog(sharedPreferences: state.sharedPreferences));

          emit(newState);
        }
      }
    }, onError: (err) {
      print('Error occurred: $err');
    });
  }

  void acceptInvitation() async {
    final id = (state as MasterViewInvitationDialog).permissionId;
    final result = await DatabaseHelper.instance.confirmPermission(id);
    if (result.isSuccess) {
      fetchData(destructive: false);
    } else {
      final newState = MasterViewShowSnackBar(
        sharedPreferences: state.sharedPreferences, 
        message: result.message!
      );

      emit(newState);
    }

    emit(state);
  }

  void declineInvitation() {
    final newState = MasterViewLoading(sharedPreferences: state.sharedPreferences);
    emit(newState);

    fetchData(destructive: false);
  }

  bool checkAuth() {
    final bool offline = state.sharedPreferences.getBool('offline')!;
    final activeSession = Supabase.instance.client.auth.currentSession;

    if (!offline && activeSession == null) {
      final newState = MasterViewPushAuthView(sharedPreferences: state.sharedPreferences);

      emit(newState);
      emit(state);
      return false;
    } else {
      return true;
    }
  }

  void showItemDialog() {
    final newState = MasterViewItemDialog.fromLoaded(state as MasterViewLoaded);

    emit(MasterViewShowItemDialog(sharedPreferences: state.sharedPreferences));

    emit(newState);
  }

  void dismissItemDialog() {
    final newState = MasterViewLoaded.fromItemDialog(state as MasterViewItemDialog);

    emit(newState);
  }

  void addItem() async {
    final newState = (state as MasterViewItemDialog).copyWith();

    List<Member> membersNew = [];
    for (String name in newState.members) {
      if (name != '') {
        membersNew.add(Member(name: name, color: colormap[membersNew.length].value));
      }
    }
    if (newState.title != '' && membersNew.length > 1) {
      final newState2 = MasterViewLoaded(sharedPreferences: newState.sharedPreferences, items: newState.items);
      newState2.items.add(await saveItem(membersNew));

      emit(newState2);
    } else {
      emit(newState);
    }
  }

  void addMember(int i, String name) {
    final newState = (state as MasterViewItemDialog).copyWith();

    if (newState.members.length < i) {
      newState.members.add(name);
    } else {
      newState.members[i-1] = name;
    }
    if (newState.count <= newState.members.length + 1 && newState.count <= 12) {
      newState.count++;
    }

    emit(newState);
  }

  void showColorPicker(int i) {
    final newState = MasterViewItemDialogColorPicker.from(state as MasterViewItemDialog, i: i);

    emit(MasterViewItemDialogShowColorPicker(sharedPreferences: state.sharedPreferences));

    emit(newState);
  }

  void changeColorMap(Color color) {
    final newState = MasterViewItemDialog.fromColorPicker(state as MasterViewItemDialogColorPicker);
    int i = (state as MasterViewItemDialogColorPicker).i;

    for (int a = 0; a < colormap.length; a++) {
      if (colormap[a] == color) {
        Color tmp = colormap[i-1];
        colormap[i-1] = colormap[a];
        colormap[a] = tmp;
      }
    }

    emit(newState);
  }

  void showImagePicker() {
    final newState = MasterViewItemDialogImagePicker.from(state as MasterViewItemDialog);

    emit(MasterViewItemDialogShowImagePicker(sharedPreferences: state.sharedPreferences));

    emit(newState);
  }

  void changeImage(int i) {
    final newState = (state as MasterViewItemDialogImagePicker).copyWith();
    newState.image = i;
    emit(newState);
  }

  void setImage(CroppedFile? image) async {
    if (image == null) return;

    final newState = (state as MasterViewItemDialogImagePicker).copyWith(
      imageFile: await (image.readAsBytes()),
      image: 0
    );

    emit(newState);
  }

  void dismissImagePicker() {
    final newState = MasterViewItemDialog.fromImagePicker(state as MasterViewItemDialogImagePicker);

    emit(newState);
  }

  Future<Item> saveItem(members) async {
    final newState = (state as MasterViewItemDialog).copyWith();

    Uint8List? imageBytes;

    if (newState.image == 0) {
      imageBytes = newState.imageFile;
    } else {
      ByteData data = await rootBundle.load('images/image_${newState.image}.jpg');
      imageBytes = data.buffer.asUint8List();
    }

    Item newItem = Item(name: newState.title, members: members, image: imageBytes);
    for (Member m in members) {
      m.itemId = newItem.id;
    }

    //DatabaseHelper.instance.add(newItem);
    await DatabaseHelper.instance.upsertItem(newItem);

    return newItem;
  }

  void updateItemTitle(String title) {
    final newState = (state as MasterViewItemDialog).copyWith(title: title);
    emit(newState);
  }

  Future<bool?> showDismissDialog() {
    final newState = MasterViewDismissDialog.fromLoaded(state as MasterViewLoaded);

    emit(MasterViewShowDismissDialog(sharedPreferences: state.sharedPreferences));

    emit(newState);

    return Future<bool?>.value(true);
  }

  void deleteItem(Item item) async {
    final newState = MasterViewLoaded.fromDismissDialog(state as MasterViewDismissDialog);

    await DatabaseHelper.instance.deleteItem(item);

    newState.items.remove(item);
    emit(newState);
  }

  void addDebugItem() async {
    List<Member> members = [];
    for (int i = 0; i < Random().nextInt(6) + 2; ++i) {
      members.add(Member(
        name: names[Random().nextInt(100)],
        color: colormap[Random().nextInt(16)].value)
      );
    }

    ByteData data = await rootBundle.load('images/image_${Random().nextInt(9) + 1}.jpg');
    final imageBytes = data.buffer.asUint8List();
    Item newItem = Item(
      name: 'Test ${Random().nextInt(9999)}',
      members: members,
      image: imageBytes
    );

    for (Member m in members) {
      m.itemId = newItem.id;
    }

    DatabaseHelper.instance.upsertItem(newItem);

    final newState = (state as MasterViewLoaded).copyWith();
    newState.items.add(newItem);

    emit(newState);
  }

  void removeAll() {
    final newState = (state as MasterViewLoaded).copyWith(items: []);

    DatabaseHelper.instance.deleteDatabase();

    //for (int i = 0; i < items.length; ++i) {
    //  DatabaseHelper.instance
    //      .deleteItem(items[i])
    //      .then((value) => setState(() {
    //            itemListFuture =
    //                DatabaseHelper.instance.getItems();
    //          }));
    //}

    emit(newState);
  }
}
