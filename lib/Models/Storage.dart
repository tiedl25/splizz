import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../Helper/filehandle.dart';
import 'item.dart';

class Settings{
  Directory? wd; //Working Directory
  final items = <Item>[];

  bool itemsLoaded = false;

  Settings();

  Future<Directory> getWorkingDir() async {
    Directory dir = await getApplicationSupportDirectory();
    return dir;
  }

  getItem(final element, Function setState) async{
    FileHandler fh = FileHandler(element);
    Item item = Item.fromJson(await fh.readJsonFile());
    setState((){
      items.add(item);
    });
  }

  void loadItems(Function setState) async {
    if(itemsLoaded){
      return;
    }
    items.clear();

    if(wd == null){
      wd = await getWorkingDir();
      save();
    }

    //search Working Directory for all item files
    var li = wd!.listSync(followLinks: false);
    for (var element in li) {
      if(element.path.contains('item_'))
      {
        getItem(element.path, setState);
      }
    }

    itemsLoaded = true;
  }

  //save settings file to Working Directory
  void save(){
    FileHandler fh = FileHandler('settings.json', wd!.path);
    Settings tmp = this;
    fh.writeJsonFile(tmp);
    itemsLoaded = false;
  }


  //Convert from/to Json

  Settings.fromJson(Map<String, dynamic> data) {
    wd = Directory(data['wd']);
  }

  Map<String, dynamic> toJson() => {
    'wd': wd!.path,
  };
}