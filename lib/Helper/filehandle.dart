import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../Models/Storage.dart';
import '../Models/item.dart';

class FileHandlerOutdated{
  String name = '';
  String path = '';

  FileHandlerOutdated(this.name);
  FileHandlerOutdated.path(this.path);

  Future<String> get _directoryPath async {
    Directory dir = await getApplicationSupportDirectory();
    return dir.path;
  }

  Future<File> get _file async {
    final path = await _directoryPath;
    return File('$path/$name.txt');
  }

  Future<File> get _jsonFile async {
    final path = await _directoryPath;
    return File('$path/$name.json');
  }

  Future<File> writeContent(var data) async {
    final file = await _file;
    // Write the file

    return file.writeAsString(data);
  }

  Future<String> readTextFile() async {
    File file = await _file;

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

  Future<File> get _jsonPath async {
    return File(path);
  }

  Future<Map<String, dynamic>> readJsonFile() async {
    File file = await _jsonPath;


    var content = await file.readAsString();
    return json.decode(content);
  }

  writeTextFile(var data) async {
    final file = await _file;
    file.writeAsString(data);
  }

  writeJsonFile(Item item) async {
    final file = await _jsonFile;
    await file.writeAsString(json.encode(item));
  }

  writeStorageJsonFile(Settings st) async {
    final file = await _jsonFile;
    await file.writeAsString(json.encode(st));
  }

  Future<int> deleteFile() async {
    try {
      final file = await _jsonPath;

      await file.delete();
    } catch (e) {
      return 0;
    }
    return 1;
  }
}

class FileHandler{
  String name;
  String path;

  FileHandler(this.name, [this.path='']);
  FileHandler.path(this.path) : name='';

  Future<String> get _directoryPath async {
    Directory dir = await getApplicationSupportDirectory();
    return dir.path;
  }

  Future<File> get _file async {
    if(name == ''){
      return File(path);
    }else{
      path = await _directoryPath;
      return File('$path/$name');
    }
  }

  Future<File> writeContent(var data) async {
    final file = await _file;
    // Write the file

    return file.writeAsString(data);
  }

  Future<String> readTextFile() async {
    File file = await _file;

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

  Future<Map<String, dynamic>> readJsonFile() async {
    File file = File('$path/$name');

    var content = await file.readAsString();
    return json.decode(content);
  }

  writeTextFile(var data) async {
    final file = await _file;
    file.writeAsString(data);
  }

  writeJsonFile(var data) async {
    final file = await _file;
    await file.writeAsString(json.encode(data));
  }

  Future<int> deleteFile() async {
    try {
      final file = File(path);

      await file.delete();
    } catch (e) {
      return 0;
    }
    return 1;
  }
}