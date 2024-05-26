import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:splizz/Helper/drive.dart';
import 'package:splizz/Helper/file_handle.dart';
import 'package:synchronized/synchronized.dart';
import 'package:sqflite/sqflite.dart' hide Transaction;

import 'package:splizz/Models/item.dart';
import 'package:splizz/Models/member.dart';
import 'package:splizz/Models/operation.dart';
import 'package:splizz/Models/transaction.dart';

class DatabaseHelper {
  //Singleton Pattern
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async => _database ??= await _initDatabase();

  static var lock = Lock(reentrant: true);

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
        imageSharedId TEXT,
        owner INTEGER,
        image BLOB,
        timestamp TEXT
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
        timestamp TEXT,
        
        itemId INTEGER,
        FOREIGN KEY (itemId) REFERENCES splizz_items (id)
      )
    ''');
    await db.execute('''
      CREATE TABLE item_transactions(
        id INTEGER PRIMARY KEY,
        description TEXT,
        timestamp TEXT,
        date TEXT,  
        value REAL,
        deleted INTEGER,
        
        itemId INTEGER,
        memberId INTEGER,
        FOREIGN KEY (itemId) REFERENCES splizz_items (id),
        FOREIGN KEY (memberId) REFERENCES item_members (id)
      )
    ''');
    await db.execute('''
      CREATE TABLE transaction_operations(
        id INTEGER PRIMARY KEY,
        value REAL,
        
        itemId INTEGER,
        memberId INTEGER,
        transactionId INTEGER,
        FOREIGN KEY (itemId) REFERENCES splizz_items (id),
        FOREIGN KEY (memberId) REFERENCES item_members (id),
        FOREIGN KEY (transactionId) REFERENCES item_transactions (id)
      )
    ''');
  }

  Future<List<Operation>> getTransactionOperations(int itemId, int transactionId, [Database? db]) async {
    db = db ?? await instance.database;
    var operations = await db.query('transaction_operations', orderBy: 'id', where: 'itemId = ? and transactionId = ?', whereArgs: [itemId, transactionId]);
    //List<Operation> operationList = operations.isNotEmpty ? operations.map((e) => Operation.fromMap(e)).toList() : [];
    List<Operation> operationList = operations.isNotEmpty ? List.generate(operations.length, (index) => Operation.fromMap(operations[index])) : [];
    return operationList;
  }

  Future<List<Operation>> getOperations(int id, [Database? db]) async {
    db = db ?? await instance.database;
    var operations = await db.query('transaction_operations', orderBy: 'id', where: 'itemId = ?', whereArgs: [id]);
    //List<Operation> operationList = operations.isNotEmpty ? operations.map((e) => Operation.fromMap(e)).toList() : [];
    List<Operation> operationList = operations.isNotEmpty ? List.generate(operations.length, (index) => Operation.fromMap(operations[index])) : [];
    return operationList;
  }

  Future<List<Transaction>> getMemberTransactions(int itemId, int memberId, [Database? db]) async {
    db = db ?? await instance.database;
    var transactions = await db.query('item_transactions', orderBy: 'id', where: 'itemId = ? and memberId = ?', whereArgs: [itemId, memberId]);
    List<Transaction> transactionList = transactions.isNotEmpty ? transactions.map((e) => Transaction.fromMap(e)).toList() : [];
    for(Transaction t in transactionList){
      t.operations = await getTransactionOperations(itemId, t.id!, db);
    }
    return transactionList;
  }

  // Returns all transactions corresponding to a given id, that are unique by their timestamp
  Future<List<Transaction>> getUniqueTransactions(int id, [Database? db]) async {
    db = db ?? await instance.database;
    var transactions = await db.query('item_transactions', orderBy: 'timestamp', where: 'itemId = ?', whereArgs: [id], distinct: true, groupBy: 'timestamp');
    List<Transaction> transactionList = transactions.isNotEmpty ? transactions.map((e) => Transaction.fromMap(e)).toList() : [];

    for(Transaction t in transactionList){
      t.operations = await getTransactionOperations(id, t.id!, db);
    }

    return transactionList;
  }

  Future<List<Transaction>> getTransactions(int id, [Database? db]) async {
    db = db ?? await instance.database;
    var transactions = await db.query('item_transactions', orderBy: 'timestamp', where: 'itemId = ?', whereArgs: [id]);
    List<Transaction> transactionList = transactions.isNotEmpty ? transactions.map((e) => Transaction.fromMap(e)).toList() : [];

    for(Transaction t in transactionList){
      t.operations = await getTransactionOperations(id, t.id!, db);
    }

    return transactionList;
  }

  Future<List<Member>> getMembers(int id, [Database? db]) async {
    db = db ?? await instance.database;

    var members = await db.query('item_members', orderBy: 'id', where: 'itemId = ?', whereArgs: [id]);
    List<Member> memberList = members.isNotEmpty ? members.map((e) => Member.fromMap(e)).toList() : [];

    for(Member m in memberList){
      m.history = await getMemberTransactions(id, m.id!);
    }

    return memberList;
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

    item.members = await getMembers(id, db);
    item.history = await getUniqueTransactions(id, db);
    return item;
  }

  // Synchronize a given item with it's corresponding json-file in GoogleDrive
  Future<Item> itemSync(Item item) async {
    await lock.synchronized(() async{

      if (item.sharedId != '')
      {
        //var response = (await GoogleDrive.instance.lastModifiedByMe(item.sharedId));

        // download item from GoogleDrive and import it
        String filename = FileHandler.instance.filename(item);
        dynamic jsonContent;
        File file;
        do{
          file = await GoogleDrive.instance.downloadFile(item.sharedId, filename);
          jsonContent = await FileHandler.instance.readJsonFile(filename);
        } while (jsonContent == 1);
        
        Item driveItem = Item.fromJson(jsonContent);
        driveItem.sharedId = item.sharedId;

        item = await getItem(item.id!);

        var history = item.history;
        //assure that history contains all transactions not only the unique ones
        item.history = await getTransactions(item.id!);

        bool equalHistory = listEquals(item.history, driveItem.history);
        bool equalMembers = listEquals(item.members, driveItem.members);

        if (equalHistory && equalMembers) {
          FileHandler.instance.deleteFile(file.path);
          item.history = history;
        } else {
          if(!equalHistory) item = await conflictManagement(item, driveItem);
          if(!equalMembers) item = await memberConflict(item, driveItem);

          // item history contains all transactions/deletions that appeared in the conflict management --> upload it also to GoogleDrive
          File file = (await export(item.id!, image: false)).first;
          GoogleDrive.instance.updateFile(file, item.sharedId).then((value) => value==1 ? FileHandler.instance.deleteFile(file.path) : 
            GoogleDrive.instance.updateFile(file, item.sharedId).then((value) => FileHandler.instance.deleteFile(file.path)));
        }
      }
    });
    return item;
  }

  // Resolve conflicts when syncing 2 items
  Future<Item> conflictManagement(Item item, Item driveItem) async {
    for (Transaction t in driveItem.history) {
      List<Transaction> equalTransactions = item.history.where((obj) => obj == t).toList();
      List<Transaction> similarTransactions = item.history.where((obj) => obj.isSimilar(t)).toList();

      // Add transaction from driveTransactions when it is completely new
      if(equalTransactions.isEmpty && similarTransactions.isEmpty){
        Transaction tNew;

        if(t.description != 'payoff') {
          int memberId = item.members[t.memberId!].id!; //Get correct memberId because in the exported json file the memberIds are set from 0 to n-1
          tNew = Transaction(t.description, t.value, t.date, memberId: memberId, timestamp: t.timestamp, deleted: t.deleted, operations: t.operations);
          
          tNew.itemId = item.id;
          tNew.memberId = memberId;
          //pushTransaction(tNew, item.members);
          item.addTransactionFromDatabase(tNew, item.members);
        } else {
          tNew = Transaction.payoff(date: t.date, timestamp: t.timestamp, operations: t.operations);
          tNew.itemId = item.id;
          tNew.memberId = -1;
          //pushTransaction(tNew, item.members);
          item.addTransactionFromDatabase(tNew, item.members);
          //addPayoff(tNew, item.id!, memberId);
        }
      }
      // Update Transaction as deleted if so in driveTransactions
      else if (similarTransactions.isNotEmpty && t.deleted){
        Transaction tNew = similarTransactions[0];
        
        item.deleteTransactionFromDatabase(tNew);
        tNew.delete();
        //deleteTransaction(tNew, item.id!);
      }
    }
    update(item);
    //item.history = await getUniqueTransactions(item.id!);
    
    return item;
  }

  memberConflict(Item item, Item driveItem) async {
    for(int i=0; i<item.members.length; ++i){
      Member m1 = driveItem.members[i];
      Member m2 = item.members[i];
      if(m1.active != m2.active){
        bool upToDate = m1.timestamp.compareTo(m2.timestamp) <= 0; //
        m2 = Member.fromMember(m2,
            timestamp: upToDate ? m2.timestamp : m1.timestamp,
            active: upToDate ? m2.active : m1.active);
        await updateMember(m2);
      }
    }

    return item;
  }

  add(Item item) async {
    Database db = await instance.database;

    int itemId = await db.insert('splizz_items', item.toMap());

    for (int i=0; i<item.members.length; i++) {
      Member m = item.members[i];
      int memberId = await addMember(m, itemId);
      item.members[i] = Member.fromMember(m, id: memberId);
    }

    for (Transaction transaction in item.history) {
      // if the transaction is imported from a json file the memberId has to be adapted to work
      if (transaction.memberId != null && transaction.memberId != -1) {
        transaction.memberId = item.members[transaction.memberId!].id;
      }

      transaction.itemId = itemId;
      //item.addTransactionFromDatabase(transaction, item.members);

      addTransaction(transaction, db, item, true);
      //pushTransaction(transaction, item.members, db, false);
    }
  }

  // Check if the given sharedId already exists in the database
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

  Future<int> addTransaction(Transaction transaction, [Database? db, Item? item, bool mapMembers=false]) async {
    db = db ?? await instance.database;

    var map = transaction.toMap();
    int transactionId = await db.insert('item_transactions', map);

    for (Operation operation in transaction.operations) {
      operation.transactionId = transactionId;
      if (transaction.itemId != null) operation.itemId = transaction.itemId;
      if (mapMembers) operation.memberId = item!.members[operation.memberId!].id;
      await addOperation(operation, db);
    }

    return transactionId;
  }

  Future<int> addOperation(Operation operation, [Database? db]) async {
    db = db ?? await instance.database;

    var map = operation.toMap();

    return await db.insert('transaction_operations', map);
  }

  Future<int> updateOperation(Operation operation, [Database? db]) async {
    db = db ?? await instance.database;

    return await db.update('transaction_operations', operation.toMap(), where: 'id = ?', whereArgs: [operation.id]);
  }

  remove(int id) async {
    Database db = await instance.database;

    await db.delete('transaction_operations', where: 'itemId = ?', whereArgs: [id]);
    await db.delete('item_transactions', where: 'itemId = ?', whereArgs: [id]);
    await db.delete('item_members', where: 'itemId = ?', whereArgs: [id]);
    await db.delete('splizz_items', where: 'id = ?', whereArgs: [id]);
  }

  update(Item item) async {
    Database db = await instance.database;
    
    int failed = await db.update('splizz_items', item.toMap(), where: 'id = ?', whereArgs: [item.id]);
    if (failed == 0) {
      add(item);
      return;
    }
    for (Member member in item.members) {
      updateMember(member);
    }
    for (Transaction transaction in item.history) {
      if (transaction.id == null) {
        addTransaction(transaction, db);
        continue;
      }
      int failed = await updateTransaction(transaction);
      if (failed == 0) {
        addTransaction(transaction, db);
      }
    }
  }

  updateMember(Member member) async {
    Database db = await instance.database;
    await db.update('item_members', member.toMap(), where: 'id = ?', whereArgs: [member.id]);
  }

  updateTransaction(Transaction transaction) async {
    Database db = await instance.database;
    return await db.update('item_transactions', transaction.toMap(), where: 'id = ?', whereArgs: [transaction.id]);
  }

  // directly import a GoogleDrive item
  import(String path, String sharedId, String imagePath, String imageSharedId) async {
    var response = await GoogleDrive.instance.checkOwner(sharedId);

    Item item = Item.fromJson(await FileHandler.instance.readJsonFile(basename(path)));
    item.sharedId = sharedId;
    item.imageSharedId = imageSharedId;
    item.owner = response;
    item.image = await FileHandler.instance.readImageFile(basename(imagePath));
    add(item);
  }

  Future<List<File>> export(int id, {image=true}) async {
    Item? item = await getItem(id);

    for(Transaction t in item.history){
      t.memberId = item.members.indexWhere((element) => element.id == t.memberId);

      for(Operation o in t.operations){
        o.memberId = item.members.indexWhere((element) => element.id == o.memberId);
      }
    }

    //Todo same for TransactionOperations

    String filename = FileHandler.instance.filename(item);
    File file = await FileHandler.instance.writeJsonFile(filename, item.toJson());


    if(image){
      String imageFilename = FileHandler.instance.imageFilename(item);
      File imageFile = await FileHandler.instance.writeImageFile(imageFilename, item.image!);
      return [file, imageFile];
    }

    return [file];
  }
}