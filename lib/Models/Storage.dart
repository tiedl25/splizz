import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../Helper/filehandle.dart';
import 'item.dart';

class Settings{
  Directory? wd;
  List<String> locations = <String>[];
  final items = <Item>[];
  final hearted = <Item>{};

  bool itemsLoaded = false;

  Future<void> init() async {
    wd = await getWorkingDir();

    if(await File('${wd!.path}/settings.json').exists()){
      await loadLocations();
    } else {
      save();
    }
  }

  Settings();

  Future<Directory> getWorkingDir() async {
    Directory dir = await getApplicationSupportDirectory();
    return dir;
  }

  Future<void> loadLocations() async {
    FileHandler fh = FileHandler('settings.json', wd!.path);
    Settings tmp = Settings.fromJson(await fh.readJsonFile());
    wd = tmp.wd;
    locations = tmp.locations;
  }

  getItem(final element, Function setState) async{
    FileHandlerOutdated fh = FileHandlerOutdated.path(element);
    Item item = Item.fromJson(await fh.readJsonFile(), element);
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
      await init();
    }

    var li = wd!.listSync(followLinks: false);
    for (var element in li) {
      if(element.path.contains('item_'))
      {
        getItem(element.path, setState);
      }
    }

    for (var element in locations){
      getItem(element, setState);
    }

    itemsLoaded = true;
  }

  void save(){
    FileHandler fh = FileHandler('settings.json', wd!.path);
    Settings tmp = this;
    fh.writeJsonFile(tmp);
    itemsLoaded = false;
  }

  Settings.fromJson(Map<String, dynamic> data) {
    final locationsData = data['locations'] as List<dynamic>;

    for(var e in locationsData){
      locations.add(e);
    }

    wd = Directory(data['wd']);
  }

  Map<String, dynamic> toJson() => {
    'wd': wd!.path,
    'locations': locations.map((m) => m).toList(),
  };
}