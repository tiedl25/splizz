import 'dart:async';
import 'dart:math';

import 'package:app_links/app_links.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:splizz/data/result.dart';
import 'package:splizz/resources/colormap.dart';
import 'package:splizz/resources/names.dart';
import 'package:splizz/data/database.dart';
import 'package:splizz/bloc/masterview_states.dart';
import 'package:splizz/models/item.model.dart';
import 'package:splizz/models/member.model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MasterViewCubit extends Cubit<MasterViewState> {
  bool _initialLinkProcessed = false;

  MasterViewCubit(SharedPreferences sharedPreferences) : super(MasterViewLoading(sharedPreferences: sharedPreferences)) {
    if (!checkAuth()) {
      return;
    }
    fetchData(destructive: false);
    //recover();
    //handleIncomingLinks();
  }

  void recover() async {
    final items = await DatabaseHelper.instance.getItems();
    for (Item item in items) {
      final i = await DatabaseHelper.instance.getItem(item.id);
      await DatabaseHelper.instance.upsertItem(i);
    }
    final newState = MasterViewLoaded(
      items: items, 
      sharedPreferences: state.sharedPreferences
    );

    emit(newState);
  }

  void fetchData({bool destructive=true}) async {
    if (destructive) DatabaseHelper.instance.destructiveSync();
    final items = await DatabaseHelper.instance.getItems();

    final newState = MasterViewLoaded(
      items: items, 
      sharedPreferences: state.sharedPreferences
    );

    handleIncomingLinks();
    
    emit(newState);
  }

  void showInvitationDialog(final String? permissionId) {
    if (permissionId != null) {
      final newState = MasterViewInvitationDialog(
        sharedPreferences: state.sharedPreferences,
        permissionId: permissionId
      );

      emit(MasterViewShowInvitationDialog(sharedPreferences: state.sharedPreferences));

      emit(newState);
    }
  }

  void handleIncomingLinks() {
    final appLinks = AppLinks();

    if (!_initialLinkProcessed) {
      appLinks.getInitialLink().then((Uri? uri) async {
        if (uri != null) showInvitationDialog(uri.queryParameters['id']);
      });
      _initialLinkProcessed = true;
    }

    appLinks.uriLinkStream.listen((Uri? uri) async {
      if (uri != null) {
        if (state.runtimeType == MasterViewInvitationDialog) {
          return;
        }

        showInvitationDialog(uri.queryParameters['id']);
      }
    }, onError: (err) {
      print('Error occurred: $err');
    });
  }

  Future<void> acceptInvitation() async {
    final id = (state as MasterViewInvitationDialog).permissionId;
    final result = await DatabaseHelper.instance.confirmPermission(id);
    if (result.isSuccess) {
      final newState = MasterViewLoading(sharedPreferences: state.sharedPreferences);
      emit(newState);

      fetchData(destructive: false);
    } else {
      final newState = MasterViewShowSnackBar(
        sharedPreferences: state.sharedPreferences, 
        message: result.message!
      );

      emit(newState);
    }
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

  addItem() async {
    final newState = (state as MasterViewItemDialog).copyWith();

    if (newState.title == '') {
      final String message = 'Please enter a title!';
      emit(MasterViewItemDialogShowSnackBar(
        sharedPreferences: state.sharedPreferences, 
        message: message
      ));
      emit(newState);
      return Result.failure(message);
    }

    List<Member> membersNew = [];
    for (String name in newState.members) {
      if (name != '') {
        membersNew.add(Member(name: name, color: colormap[membersNew.length].value));
      }
    }

    if (membersNew.length < 2) {
      final String message = 'Please add at least two members!';
      emit(MasterViewItemDialogShowSnackBar(
        sharedPreferences: state.sharedPreferences, 
        message: message
      ));
      emit(newState);
      return Result.failure(message);
    }

    final newState2 = MasterViewLoaded(sharedPreferences: newState.sharedPreferences, items: newState.items);
    newState2.items.add(await saveItem(membersNew));

    emit(newState2);

    return Result.success(null);
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

  void deleteItem(Item item) async {
    final newState = (state as MasterViewLoaded).copyWith();

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
