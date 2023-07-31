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
import '../Models/operation.dart';
import '../Models/transaction.dart';

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
        owner INTEGER,
        image INTEGER,
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
    List<Operation> operationList = operations.isNotEmpty ? operations.map((e) => Operation.fromMap(e)).toList() : [];
    return operationList;
  }

  Future<List<Operation>> getOperations(int id, [Database? db]) async {
    db = db ?? await instance.database;
    var operations = await db.query('transaction_operations', orderBy: 'id', where: 'itemId = ?', whereArgs: [id]);
    List<Operation> operationList = operations.isNotEmpty ? operations.map((e) => Operation.fromMap(e)).toList() : [];
    return operationList;
  }

  Future<List<Transaction>> getMemberTransactions(int itemId, int memberId, [Database? db]) async {
    db = db ?? await instance.database;
    var transactions = await db.query('item_transactions', orderBy: 'id', where: 'itemId = ? and memberId = ?', whereArgs: [itemId, memberId]);
    List<Transaction> transactionList = transactions.isNotEmpty ? transactions.map((e) => Transaction.fromMap(e)).toList() : [];
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
    Item item = await lock.synchronized(() async {
      var response = await db.query('splizz_items', orderBy: 'id', where: 'id = ?', whereArgs: [id]);
      Item item = (response.isNotEmpty ? (response.map((e) => Item.fromMap(e)).toList()) : [])[0];

      item.members = await getMembers(id, db);
      item.history = await getUniqueTransactions(id, db);
      return item;
    });
    return item;
  }

  // Synchronize a given item with it's corresponding json-file in GoogleDrive
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
          //update(item);

          // item history contains all transactions/deletions that appeared in the conflict management --> upload it also to GoogleDrive
          File file2 = await export(item.id!);
          GoogleDrive.instance.updateFile(file2, item.sharedId).then((value) => FileHandler.instance.deleteFile(file2.path));
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
          tNew = Transaction(t.description, t.value, memberId: memberId, timestamp: t.timestamp, deleted: t.deleted, operations: t.operations);
          //Todo item.addTransaction(t.memberId!, tNew);
          addTransaction(tNew, item.members, item.id!, memberId);
        } else {
          tNew = Transaction.payoff(t.value, timestamp: t.timestamp, operations: t.operations);
          addTransaction(tNew, item.members, item.id!, t.memberId!);
          //Todo item.addPayoff(t.memberId!, tNew);
          //addPayoff(tNew, item.id!, memberId);
        }
      }
      // Update Transaction as deleted if so in driveTransactions
      else if (similarTransactions.isNotEmpty && t.deleted){
        Transaction tNew = similarTransactions[0];
        tNew.delete();
        // Todo item.deleteTransaction(t.memberId!, tNew);
        deleteTransaction(tNew, item.id!);
      }
    }
    item.history = await getUniqueTransactions(item.id!);

    return item;
  }

  add(Item item) async {
    Database db = await instance.database;

    await lock.synchronized(() async {
      int itemId = await db.insert('splizz_items', item.toMap());

      for (int i=0; i<item.members.length; i++) {
        Member m = item.members[i];
        int memberId = await addMember(m, itemId);
        item.members[i] = Member.fromMember(m, memberId);
      }

      for (Transaction transaction in item.history) {
        // if the transaction is imported from a json file the memberId has to be adapted to work
        if (transaction.memberId != null && transaction.memberId != -1) {
          transaction.memberId = item.members[transaction.memberId!].id;
        }

        addTransaction(transaction, item.members, itemId, transaction.memberId!, db, false);
      }
    });
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

  //Add new Transaction to Database ignoring the operations
  Future<int> pushTransaction(Transaction transaction, int itemId, int memberId, [Database? db]) async {
    db = db ?? await instance.database;

    var map = transaction.toMap();
    map.addAll({'itemId' : itemId, 'memberId' : memberId});
    return await db.insert('item_transactions', map);
  }

  Future<int> addPayoff(Transaction transaction, int itemId, int memberId, [Database? db]) async {
    db = db ?? await instance.database;

    var map = transaction.toMap();
    map.addAll({'itemId' : itemId, 'memberId' : memberId});
    await db.rawUpdate('UPDATE item_members SET balance = balance + ${transaction.value} WHERE id = $memberId');
    return await db.insert('item_transactions', map);
  }

  // Add Transaction to Database
  // Used to add a Transaction from a Json file either by importing or through conflict management
  Future<int> addTransaction(Transaction transaction, List<Member> members, int itemId, int memberId, [Database? db, bool calculate=true]) async {
    db = db ?? await instance.database;

    //double value = transaction.value/transaction.operations.length;

    await lock.synchronized(() async {
      int tId = await pushTransaction(transaction, itemId, memberId, db);

      // Update total only if item is not deleted, it should be calculated and the memberId is not -1 (-1 means it is a payoff transaction)
      if(!transaction.deleted && memberId != -1 && calculate) await db?.rawUpdate('UPDATE item_members SET total = total + ${transaction.value} WHERE id = $memberId');

      for(Operation operation in transaction.operations){
        operation.itemId = itemId;
        operation.transactionId = tId;

        // if the operation is imported from a json file the memberId has to be adapted to work
        if (operation.memberId != null) {
          operation.memberId = members[operation.memberId!].id;
        }

        addOperation(operation);

        // Update balance only if item is not deleted and it should be calculated
        if(!transaction.deleted && calculate) await db?.rawUpdate('UPDATE item_members SET balance = balance + ${operation.value} WHERE id = ${operation.memberId}');
      }

      //if(!transaction.deleted){
      //  await db?.rawUpdate('UPDATE item_members SET total = total + ${transaction.value} WHERE id = $memberId');
      //  await db?.rawUpdate('UPDATE item_members SET balance = balance + ${transaction.value} WHERE id = $memberId');
      //  await db?.rawUpdate('UPDATE item_members SET balance = balance - $value WHERE transactionId in $involvedMembers');
      //}
    });
    return 1;
  }

  // Mark transaction deleted and calculate new balance and total value
  Future<int> deleteTransaction(Transaction transaction, int itemId) async {
    Database db = await instance.database;
    int memberId = transaction.memberId!;

    //double value = transaction.value/transaction.operations.length;

    await lock.synchronized(() async {
      await db.rawUpdate('UPDATE item_members SET total = total - ${transaction.value} WHERE id = $memberId');

      for(Operation o in transaction.operations){
        await db.rawUpdate('UPDATE item_members SET balance = balance - ${o.value} WHERE id = ${o.memberId}');
      }

      //await db.rawUpdate('UPDATE item_members SET balance = balance - ${transaction.value} WHERE id = $memberId');
      //await db.rawUpdate('UPDATE item_members SET balance = balance + $value WHERE itemId = $itemId');
      updateTransaction(transaction);
    });

    return 1;
  }

  // Calculate and add new transaction to Database and calculate new balance and total value
  // Only used when adding a Transaction from the ui
  Future<int> addTransactionCalculate(Transaction transaction, int itemId, int memberId, List<int> involvedMembers) async {
    Database db = await instance.database;

    double value = transaction.value/involvedMembers.length;

    await lock.synchronized(() async {
      int tId = await pushTransaction(transaction, itemId, memberId, db);
      Operation operation = Operation(transaction.value, itemId: itemId, memberId: memberId, transactionId: tId);
      int opId = await addOperation(operation, db);

      for(int involvedMember in involvedMembers){
        if(involvedMember == memberId){
          Operation o = Operation(transaction.value-value, id: opId, itemId: itemId, memberId: involvedMember, transactionId: tId);
          updateOperation(o, db);
        } else {
          Operation o = Operation(-value, itemId: itemId, memberId: involvedMember, transactionId: tId);
          addOperation(o, db);
        }
        if(!transaction.deleted) await db.rawUpdate('UPDATE item_members SET balance = balance - $value WHERE id = $involvedMember');
      }

      if(!transaction.deleted){
        await db.rawUpdate('UPDATE item_members SET total = total + ${transaction.value} WHERE id = $memberId');
        await db.rawUpdate('UPDATE item_members SET balance = balance + ${transaction.value} WHERE id = $memberId');
        //await db.rawUpdate('UPDATE item_members SET balance = balance - $value WHERE transactionId in $involvedMembers');
      }
    });
    return 1;
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

  // Apply payoff to all members of an item in the database
  Future<int> payoff(Item item, DateTime timestamp) async {
    Database db = await instance.database;

    await lock.synchronized(() async {
      Transaction t = Transaction.payoff(0.0, timestamp: timestamp);
      int tId = await pushTransaction(t, item.id!, -1);

      for(Member e in item.members){
        Operation o = Operation(-e.balance, itemId: item.id, memberId: e.id, transactionId: tId);
        await addOperation(o, db);
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
      await db.delete('transaction_operations', where: 'itemId = ?', whereArgs: [id]);
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

  // directly import a GoogleDrive item
  import(String path, String sharedId) async {
    Item item = Item.fromJson(await FileHandler.instance.readJsonFile(basename(path)));
    item.sharedId = sharedId;
    item.owner = await GoogleDrive.instance.checkOwner(sharedId);
    add(item);
  }

  Future<File> export(int id) async {
    Database db = await instance.database;

    //var response = await db.query('splizz_items', orderBy: 'id', where: 'id = ?', whereArgs: [id]);
    //Item? item = Item.fromMap(response[0]);
    //item.members = await getMembers(item.id!);
    //item.history = await getTransactions(item.id!);

    Item? item = await getItem(id);

    for(Transaction t in item.history){
      t.memberId = item.members.indexWhere((element) => element.id == t.memberId);

      for(Operation o in t.operations){
        o.memberId = item.members.indexWhere((element) => element.id == o.memberId);
      }
    }

    //Map the memberId to a value between 0 and the count of the members so that in another database each transaction can be correctly mapped
    //The memberId is database specific
    //Map<int, int> map = {};
    //for (int i = 0; i < item.members.length; i++) {
    //  map.addAll({item.members[i].id!: i});
    //}
    //for (int i = 0; i < item.history.length; i++) {
    //  item.history[i].memberId = map[item.history[i].memberId];
    //}

    //Todo same for TransactionOperations

    String filename = FileHandler.instance.filename(item);

    File file = await FileHandler.instance.writeJsonFile(filename, item.toJson());
    return file;
  }
}