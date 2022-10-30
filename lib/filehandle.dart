import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'item.dart';

class FileHandler{
  String name = '';
  String path = '';

  FileHandler(this.name);
  FileHandler.path(this.path);

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