import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'package:splizz/Models/item.dart';

class FileHandler{
  //Singleton Pattern
  FileHandler._privateConstructor();

  static final FileHandler instance = FileHandler._privateConstructor();

  Future<String> get _directoryPath async {
    Directory dir = await getApplicationDocumentsDirectory();
    dir = Directory('${dir.path}/shared');
    if(!await dir.exists()){
      dir.create();
    }
    return dir.path;
  }

  Future<File> _file(String name) async {
    String path = await _directoryPath;
    return File('$path/$name');
  }

  String filename(Item item){
    return 'splizz_item{${item.name}}';
  }

  String imageFilename(Item item){
    return "splizz_image";
  }

  Future<String> readTextFile(String name) async {
    File file = await _file(name);

    String content = '';

    if (await file.exists()) {
      try {
        content = await file.readAsString();
      } catch (e) {
        if (kDebugMode) {
          print(e);
        }
      }
    }
    return content;
  }

  Future<Map<String, dynamic>> readJsonFile(String name, [String? path]) async {
    File file;
    if (path == null) {
      file = await _file(name);
    } else {
      file = File('$path/$name');
    }
    String content = await file.readAsString();
    return json.decode(content);
  }

  Future<Uint8List> readImageFile(String name, [String? path]) async {
    File file;
    if (path == null) {
      file = await _file(name);
    } else {
      file = File('$path/$name');
    }
    Uint8List content = await file.readAsBytes();
    return content;
  }

  Future<File> writeTextFile(String name, var data) async {
    File file = await _file(name);
    file.writeAsString(data);
    return file;
  }

  Future<File> writeJsonFile(String name, Map<String, dynamic> data) async {
    File file = await _file(name);
    await file.writeAsString(json.encode(data));
    return file;
  }

  Future<File> writeImageFile(String name, Uint8List data) async {
    File file = await _file(name);
    await file.writeAsBytes(data);
    return file;
  }

  Future<File> writeBytestream(String filename, stream) async {
    String dirPath = await _directoryPath;
    final file = File('$dirPath/$filename');

    List<int> dataStore = [];
    stream?.stream.listen((data) {
      dataStore.insertAll(dataStore.length, data);
    }, onDone: () {
      file.writeAsBytes(dataStore);
      print("File saved at ${file.path}");
    }, onError: (error) {
      print("Some Error");
    });

    return file;
  }

  Future<int> deleteFile(String path) async {
    try {
      File file = File(path);
      await file.delete();
    } catch (e) {
      return 0;
    }
    return 1;
  }
}