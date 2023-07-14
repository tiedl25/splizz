import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:splizz/Helper/drive.dart';
import 'package:splizz/Helper/filehandle.dart';
import 'package:synchronized/synchronized.dart';
import 'package:sqflite/sqflite.dart' hide Transaction;

import '../Models/item.dart';
import '../Models/member.dart';
import '../Models/transaction.dart';

class DatabaseHelper {
  //Singleton Pattern
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async => _database ??= await _initDatabase();

  static var lock = Lock();

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
        active INTEGER,
        
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
        deleted INTEGER,
        
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

  Future<List<Transaction>> getUniqueTransactions(int id) async {
    Database db = await instance.database;
    var transaction = await db.query('item_transactions', orderBy: 'timestamp', where: 'itemId = ?', whereArgs: [id], distinct: true, groupBy: 'timestamp');
    List<Transaction> transactionList = transaction.isNotEmpty ? transaction.map((e) => Transaction.fromMap(e)).toList() : [];
    return transactionList;
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
    Item item = await lock.synchronized(() async {
      var response = await db.query('splizz_items', orderBy: 'id', where: 'id = ?', whereArgs: [id]);
      Item item = (response.isNotEmpty ? (response.map((e) => Item.fromMap(e)).toList()) : [])[0];

      item.members = await getMembers(id);
      item.history = await getUniqueTransactions(id);
      return item;
    });
    return item;
  }

  Future<Item> itemSync(Item item) async {
    await lock.synchronized(() async{
      if (item.sharedId != '')
      {
        // download item from GoogleDrive and import it
        String filename = FileHandler.instance.filename(item);
        File file = await GoogleDrive.instance.downloadFile(item.sharedId, filename);
        Item driveItem = Item.fromJson(await FileHandler.instance.readJsonFile(filename));
        driveItem.sharedId = item.sharedId;

        var history = item.history;
        //assure that history contains all transactions not only the unique ones
        item.history = await getTransactions(item.id!);

        if (listEquals(item.history, driveItem.history)) {
          FileHandler.instance.deleteFile(file.path);
          item.history = history;
        } else {
          item = await conflictManagement(item, driveItem);

          await export(item.id!);
          GoogleDrive.instance.updateFile(file, item.sharedId).then((value) => FileHandler.instance.deleteFile(file.path));
        }
      }
    });
    return item;
  }

  Future<Item> conflictManagement(Item item, Item driveItem) async {
    for (Transaction t in driveItem.history) {
      if (!item.history.contains(t)) {
        Transaction tNew;
        if(t.description != 'payoff') {
            int memberId = item.members[t.memberId!].id!;
            tNew = Transaction(t.description, t.value, memberId: memberId, timestamp: t.timestamp);
            item.addTransaction(t.memberId!, tNew);
            addTransaction(tNew, item.id!, memberId);
        } else {
          int memberId = item.members[t.memberId!].id!;
          tNew = Transaction.payoff(t.value, timestamp: t.timestamp);
          item.addPayoff(t.memberId!, tNew);
          addTransaction(tNew, item.id!, memberId);
        }

      }
    }

    //update(item);
    item.history = await getUniqueTransactions(item.id!);

    return item;
  }

  add(Item item) async {
    Database db = await instance.database;

    await lock.synchronized(() async {
      int id = await db.insert('splizz_items', item.toMap());
      for (int i = 0; i < item.members.length; i++) {
        item.members[i] = Member.fromMember(
            item.members[i], await addMember(item.members[i], id));
      }

      for (Transaction transaction in item.history) {
        if (transaction.memberId != null) {
          transaction.memberId = item.members[transaction.memberId!].id;
          addTransaction(transaction, id, transaction.memberId);
        } else {
          addTransaction(transaction, id, transaction.memberId);
        }
      }
    });
  }

  import(String path, String sharedId) async {
    Item item = Item.fromJson(await FileHandler.instance.readJsonFile(basename(path)));
    item.sharedId = sharedId;
    item.owner = await GoogleDrive.instance.checkOwner(sharedId);
    add(item);
  }

  migrate(String name) async {
    Directory dir = await getApplicationSupportDirectory();
    for (var file in dir.listSync()){
      Item item = Item.fromOld(await FileHandler.instance.readJsonFile(basename(file.path), dir.path));
      item.owner = true;
      add(item);
    }
  }
  
  Future<bool> checkSharedId(String sharedId) async {
    Database db = await instance.database;

    List<Map<String, dynamic>> response = await db.query('splizz_items', where: 'sharedId = ?', whereArgs: [sharedId]);
    return response.isEmpty;
  }

  Future<int> addMember(Member member, int itemId, [Database? db]) async {
    db = db ?? await instance.database;

    var map = member.toMap();
    map.addAll({'itemId' : itemId});
    return await db.insert('item_members', map);
  }

  Future<int> addTransaction(Transaction transaction, int itemId, [int? memberId, Database? db]) async {
    db = db ?? await instance.database;

    var map = transaction.toMap();
    map.addAll({'itemId' : itemId, 'memberId' : memberId});
    return await db.insert('item_transactions', map);
  }

  Future<int> addTransactionCalculate(Transaction transaction, int itemId, int memberId) async {
    Database db = await instance.database;

    await lock.synchronized(() async {
      await db.rawUpdate('UPDATE item_members SET total = total + ${transaction.value} WHERE id = $memberId');
      await db.rawUpdate('UPDATE item_members SET balance = balance + ${transaction.value} WHERE id = $memberId');
      int len = (await getMembers(itemId)).length;
      double val = transaction.value/len;
      await db.rawUpdate('UPDATE item_members SET balance = balance - $val WHERE itemId = $itemId');
      addTransaction(transaction, itemId, memberId, db);
    });

    return 1;
  }

  Future<int> payoff(Item item, DateTime timestamp) async {
    Database db = await instance.database;

    await lock.synchronized(() async {
      for(Member e in item.members){
        Transaction t = Transaction.payoff(-e.balance, memberId: e.id, timestamp: timestamp);
        await addTransaction(t, item.id!, e.id, db);
        await db.rawUpdate('UPDATE item_members SET balance = balance - ${e.balance} WHERE id = ${e.id}');
      }
    });

    return 1;
  }

  remove(int id) async {
    Database db = await instance.database;

    await lock.synchronized(() async {
      await db.delete('splizz_items', where: 'id = ?', whereArgs: [id]);
      await db.delete('item_members', where: 'itemId = ?', whereArgs: [id]);
      await db.delete('item_transactions', where: 'itemId = ?', whereArgs: [id]);
    });
  }

  update(Item item) async {
    Database db = await instance.database;

    await lock.synchronized(() async {
      await db.update(
          'splizz_items', item.toMap(), where: 'id = ?', whereArgs: [item.id]);
      for (Member member in item.members) {
        updateMember(member);
      }
      for (Transaction transaction in item.history) {
        updateTransaction(transaction);
      }
    });
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
    for (int i = 0; i < item.members.length; i++) {
      map.addAll({item.members[i].id!: i});
    }
    for (int i = 0; i < item.history.length; i++) {
      item.history[i].memberId = map[item.history[i].memberId];
    }

    String filename = FileHandler.instance.filename(item);

    File file = await FileHandler.instance.writeJsonFile(filename, item.toJson());
    return file;
  }
}