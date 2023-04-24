import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:splizz/Helper/drive.dart';
import 'package:splizz/Helper/filehandle.dart';
import 'package:sqflite/sqflite.dart' hide Transaction;
import 'package:path/path.dart' as p;

import '../Models/item.dart';
import '../Models/member.dart';
import '../Models/transaction.dart';

class DatabaseHelper {
  //Singleton Pattern
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async => _database ??= await _initDatabase();

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'splizz_items.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE splizz_items(
        id INTEGER PRIMARY KEY,
        name TEXT,
        sharedId TEXT,
        owner INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE item_members(
        id INTEGER PRIMARY KEY,
        name TEXT,
        color INTEGER,
        total INTEGER,
        balance INTEGER,        
        
        itemId INTEGER,
        FOREIGN KEY (itemId) REFERENCES splizz_items (id)
      )
    ''');
    await db.execute('''
      CREATE TABLE item_transactions(
        id INTEGER PRIMARY KEY,
        description TEXT,
        timestamp TEXT,
        value REAL,
        
        itemId INTEGER,
        memberId INTEGER,
        FOREIGN KEY (itemId) REFERENCES splizz_items (id),
        FOREIGN KEY (memberId) REFERENCES item_members (id)
      )
    ''');
  }

  Future<List<Transaction>> getMemberTransactions(int itemId, int memberId) async {
    Database db = await instance.database;
    var transaction = await db.query('item_transactions', orderBy: 'id', where: 'itemId = ? and memberId = ?', whereArgs: [itemId, memberId]);
    List<Transaction> transactionList = transaction.isNotEmpty ? transaction.map((e) => Transaction.fromMap(e)).toList() : [];
    return transactionList;
  }

  Future<List<Member>> getMembers(int id) async {
    Database db = await instance.database;

    var member = await db.query('item_members', orderBy: 'id', where: 'itemId = ?', whereArgs: [id]);
    List<Member> memberList = member.isNotEmpty ? member.map((e) => Member.fromMap(e)).toList() : [];

    for(Member m in memberList){
      m.history = await getMemberTransactions(id, m.id!);
    }

    return memberList;
  }

  Future<List<Transaction>> getTransactions(int id) async {
    Database db = await instance.database;
    var transaction = await db.query('item_transactions', orderBy: 'timestamp', where: 'itemId = ?', whereArgs: [id]);
    List<Transaction> transactionList = transaction.isNotEmpty ? transaction.map((e) => Transaction.fromMap(e)).toList() : [];
    return transactionList;
  }

  Future <List<Item>> getItems() async {
    Database db = await instance.database;
    var items = await db.query('splizz_items', orderBy: 'id');
    List<Item> itemList = items.isNotEmpty ? items.map((e) => Item.fromMap(e)).toList() : [];

    return itemList;
  }

  Future<Item> getItem(int id) async {
    Database db = await instance.database;
    var response = await db.query('splizz_items', orderBy: 'id', where: 'id = ?', whereArgs: [id]);
    Item item = (response.isNotEmpty ? (response.map((e) => Item.fromMap(e)).toList()) : [])[0];

    item.members = await getMembers(id);
    item.history = await getTransactions(id);

    if (item.sharedId == '') {
      return item;
    }

    String filename = FileHandler.instance.filename(item);
    File file = await GoogleDrive.instance.downloadFile(item.sharedId, filename);

    Item driveItem = Item.fromJson(await FileHandler.instance.readJsonFile(filename));
    driveItem.sharedId = item.sharedId;

    if (listEquals(item.history, driveItem.history)) {
      FileHandler.instance.deleteFile(file.path);
      return item;
    }
    item = await conflictManagement(item, driveItem);

    export(item.id!);
    GoogleDrive.instance.updateFile(file, item.sharedId);
    FileHandler.instance.deleteFile(file.path);

    return item;
  }

  Future<Item> conflictManagement(Item item, Item driveItem) async {
    Database db = await instance.database;
    for (Transaction t in driveItem.history) {
      if (!item.history.contains(t)) {
        int memberId = item.members[t.memberId!].id!;

        Transaction tNew = Transaction(t.description, t.value, memberId: memberId, timestamp: t.timestamp);
        item.addTransaction(t.memberId!, tNew);

        addTransaction(tNew, item.id!, memberId);
      }
    }
    update(item);
    item.history = await getTransactions(item.id!);

    return item;
  }

  add(Item item) async {
    Database db = await instance.database;
    int id = await db.insert('splizz_items', item.toMap());
    for (Member member in item.members){
      addMember(member, id);
    }
    item.members = await getMembers(id);

    for (Transaction transaction in item.history){
      print('hello${transaction.memberId!}');
      transaction.memberId = item.members[transaction.memberId!].id;
      addTransaction(transaction, id, transaction.memberId);
    }
  }

  import(String path, String sharedId) async {
    Item item = Item.fromJson(await FileHandler.instance.readJsonFile(p.basename(path)));
    item.sharedId = sharedId;

    Database db = await instance.database;
    int id = await db.insert('splizz_items', item.toMap());
    for (Member member in item.members){
      addMember(member, id);
    }
    for (Transaction transaction in item.history){
      addTransaction(transaction, id, item.members[transaction.memberId!].id);
    }
  }

  addMember(Member member, int itemId) async {
    Database db = await instance.database;
    var map = member.toMap();
    map.addAll({'itemId' : itemId});
    await db.insert('item_members', map);
  }

  addTransaction(Transaction transaction, int itemId, [int? memberId]) async {
    Database db = await instance.database;
    var map = transaction.toMap();
    map.addAll({'itemId' : itemId, 'memberId' : memberId});
    await db.insert('item_transactions', map);
  }

  remove(int id) async {
    Database db = await instance.database;
    await db.delete('splizz_items', where: 'id = ?', whereArgs: [id]);
    await db.delete('item_members', where: 'itemId = ?', whereArgs: [id]);
    await db.delete('item_transactions', where: 'itemId = ?', whereArgs: [id]);
  }

  update(Item item) async {
    Database db = await instance.database;
    await db.update('splizz_items', item.toMap(), where: 'id = ?', whereArgs: [item.id]);
    for (Member member in item.members){
      updateMember(member);
    }
    for (Transaction transaction in item.history){
      updateTransaction(transaction);
    }
  }

  updateMember(Member member) async {
    Database db = await instance.database;
    await db.update('item_members', member.toMap(), where: 'id = ?', whereArgs: [member.id]);
  }

  updateTransaction(Transaction transaction) async {
    Database db = await instance.database;
    await db.update('item_transactions', transaction.toMap(), where: 'id = ?', whereArgs: [transaction.id]);
  }

  Future<File> export(int id) async {
    Database db = await instance.database;
    var response = await db.query('splizz_items', orderBy: 'id', where: 'id = ?', whereArgs: [id]);
    Item? item = Item.fromMap(response[0]);
    item.members = await getMembers(item.id!);
    item.history = await getTransactions(item.id!);

    //Map the memberId to a value between 0 and the count of the members so that in another database each transaction can be correctly mapped
    //The memberId is database specific
    Map<int, int> map = {};
    for (int i=0; i<item.members.length; i++) {
      map.addAll({item.members[i].id! : i});
    }
    for (int i=0; i<item.history.length; i++) {
      item.history[i].memberId = map[item.history[i].memberId];
    }

    String filename = FileHandler.instance.filename(item);

    File file = await FileHandler.instance.writeJsonFile(filename, item.toJson());

    return file;
  }
}