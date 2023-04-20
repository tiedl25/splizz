import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../Models/item.dart';

class FileHandler{
  //Singleton Pattern
  FileHandler._privateConstructor();

  static final FileHandler instance = FileHandler._privateConstructor();

  Future<String> get _directoryPath async {
    Directory dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  Future<File> _file(String name) async {
    String path = await _directoryPath;
    return File('$path/$name');
  }

  String filename(Item item){
    return 'item{${item.name}}';
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

  Future<Map<String, dynamic>> readJsonFile(String name) async {
    File file = await _file(name);
    String content = await file.readAsString();
    return json.decode(content);
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

  Future<int> deleteFile(String name) async {
    try {
      File file = File(name);
      await file.delete();
    } catch (e) {
      return 0;
    }
    return 1;
  }
}