import 'dart:async';
import 'package:brick_offline_first/brick_offline_first.dart';
import 'package:collection/collection.dart';
import 'package:splizz/Helper/result.dart';

import 'package:splizz/brick/repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:synchronized/synchronized.dart';

import 'package:splizz/models/item.model.dart';
import 'package:splizz/models/member.model.dart';
import 'package:splizz/models/operation.model.dart';
import 'package:splizz/models/transaction.model.dart';
import 'package:splizz/models/user.model.dart';

bool isSignedIn = Supabase.instance.client.auth.currentSession != null;

bool switchRepository() {
  if (isSignedIn != (Supabase.instance.client.auth.currentSession != null))
  {
    isSignedIn = Supabase.instance.client.auth.currentSession != null;
    return true;
  }
  return false;
}

class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static dynamic _database;
  Future<dynamic> get database async => _database = _database == null || switchRepository() ? await _initDatabase() : _database;//_database ??= await _initDatabase();

  static var lock = Lock(reentrant: true);

  Future<dynamic> _initDatabase() async {
    return isSignedIn ? Repository.instance : Repository.instance.sqliteProvider;
  }

  Future<List<Item>> getItems({dynamic db, bool sync = false}) async {
    db = db ?? await instance.database;

    if (sync) await downloadData();

    final items = await db.get<Item>();
    return items;
  }

  Future<Item> getItem(String id, {dynamic db}) async {
    db = db ?? await instance.database;

    final itemQuery = Query(where: [Where('id').isExactly(id)]);
    final item = (await db.get<Item>(query: itemQuery))[0];

    item.members = await getMembers(id, db: db);
    item.history = await getTransactions(id, db: db);

    return item;
  }

  Future<List<Member>> getMembers(String id, {dynamic db}) async {
    db = db ?? await instance.database;

    final memberQuery = Query(where: [Where('itemId').isExactly(id)]);
    final members = await db.get<Member>(query: memberQuery);

    for(Member m in members){
      m.balance = await getBalance(m.id, db: db);
      m.total = await getTotal(m.id, db: db);
      m.history = await getMemberTransactions(m.id, db: db);
    }

    return members;
  }

  Future<List<Transaction>> getTransactions(String id, {dynamic db}) async {
    db = db ?? await instance.database;

    final transactionQuery = Query(where: [Where('itemId').isExactly(id)], providerArgs: {'orderBy': 'timestamp ASC'});
    final transactions = await db.get<Transaction>(query: transactionQuery);

    if (transactions.isEmpty) return [];

    //transactions.sortBy((element) => element.timestamp);

    for(Transaction t in transactions){
      t.operations = await getTransactionOperations(t.id, db: db);
    }

    return transactions;
  }

  Future<List<Transaction>> getMemberTransactions(String id, {dynamic db}) async {
    db = db ?? await instance.database;

    final transactionQuery = Query(where: [Where('memberId').isExactly(id)]);
    final transactions = await db.get<Transaction>(query: transactionQuery);

    return transactions;
  }

  Future<List<Operation>> getTransactionOperations(String id, {dynamic db}) async {
    db = db ?? await instance.database;

    final operationQuery = Query(where: [Where('transactionId').isExactly(id)]);
    final operations = await db.get<Operation>(query: operationQuery); 

    return operations;  
  }

  Future<void> upsertItem(Item item, {dynamic db}) async {
    db ??= await instance.database;
  
    db.upsert<Item>(item);

    upsertUser(item.id, db: db, fullAccess: true);

    for(Member member in item.members){
      upsertMember(member, db: db);
    }
    for(Transaction transaction in item.history){
      upsertTransaction(transaction, db: db);
    }
  }

  Future<void> upsertTransaction(Transaction transaction, {dynamic db}) async {
    db = db ?? await instance.database;
  
    db.upsert<Transaction>(transaction);

    for(Operation operation in transaction.operations){
      upsertOperation(operation, db: db);
    }
  }

  Future<void> upsertMember(Member member, {dynamic db}) async {
    db = db ?? await instance.database;
  
    db.upsert<Member>(member);
  }

  Future<Result> upsertUser(String itemId, {bool fullAccess = false, String? userEmail, dynamic db}) async {
    db = db ?? await instance.database;

    if(userEmail != null){
      if (userEmail != Supabase.instance.client.auth.currentUser?.email) return Result.failure("You are not authorized for this action!");
    }

    final userId = Supabase.instance.client.auth.currentUser?.id;

    Query query = Query(where: [Where("itemId").isExactly(itemId), Where("userId").isExactly(userId)]);
    final u = await db.get<User>(query: query);

    if (u.isNotEmpty) return Result.failure("The item has already been added");

    User user = User(itemId: itemId, userId: userId, fullAccess: fullAccess);

    db.upsert<User>(user);

    return Result.success(null);
  }

  Future<void> upsertOperation(Operation operation, {dynamic db}) async {
    db = db ?? await instance.database;
  
    db.upsert<Operation>(operation);
  }

  Future<void> syncData() async {
    dynamic db = await Repository.instance.sqliteProvider;
    
    final items = await getItems(db: db);

    for(Item item in items){
      item.members = await getMembers(item.id, db: db);
      item.history = await getTransactions(item.id, db: db);
    }
    db = await Repository.instance.remoteProvider;

    final items2 = await getItems(db: db);

    for(Item item in items2){
      item.members = await getMembers(item.id, db: db);
      item.history = await getTransactions(item.id, db: db);
    }

    db = await Repository.instance;

    for(Item item in items){
      upsertItem(item, db: db);
    }

    for(Item item in items2){
      upsertItem(item, db: db);
    }
  }

  Future<void> downloadData() async {
    dynamic db = await Repository.instance.remoteProvider;

    final items = await getItems(db: db);

    for(Item item in items){
      item.members = await getMembers(item.id, db: db);
      item.history = await getTransactions(item.id, db: db);
    }

    db = await Repository.instance.sqliteProvider;

    for(Item item in items){
      upsertItem(item, db: db);
    }
  }

  Future<void> deleteItem(Item item, {dynamic db}) async {
    db = db ?? await instance.database;

    item.upload = false;

    item.members = await getMembers(item.id, db: db);
    item.history = await getTransactions(item.id, db: db);

    for(Transaction transaction in item.history){
      await deleteTransaction(transaction, db: db);
    }
    for(Member member in item.members){
      await deleteMember(member, db: db);
    }

    await deleteImage(item.id, db: db);

    await db.delete<Item>(item);

    await deleteUser(item.id, db: db);
  }

  Future<void> deleteTransaction(Transaction transaction, {dynamic db}) async {
    db = db ?? await instance.database;

    transaction.operations = await getTransactionOperations(transaction.id, db: db);

    for(Operation operation in transaction.operations){
      await deleteOperation(operation, db: db);
    }
  
    await db.delete<Transaction>(transaction);
  }

  Future<void> deleteMember(Member member, {dynamic db}) async {
    db = db ?? await instance.database;
  
    await db.delete<Member>(member);
  }

  Future<void> deleteOperation(Operation operation, {dynamic db}) async {
    db = db ?? await instance.database;
  
    await db.delete<Operation>(operation);
  }
  
  Future<void> deleteUser(String id, {dynamic db}) async {
    db = db ?? await instance.database;

    final userQuery = Query(where: [Where('itemId').isExactly(id)]);
    final user = await db.get<User>(query: userQuery);

    for (User u in user){
      await db.delete<User>(u);
    }
  }

  Future<void> deleteImage(String id, {dynamic db}) async {
    await Repository.instance.remoteProvider.client.storage.from('images').remove(['$id.jpg']);
  }

  Future<double> getBalance(String id, {dynamic db}) async {
    db = db ?? await instance.database;

    //select sum(value) from Operation where transaction_id in (select id from "Transaction" where deleted==0) and member_id=="5c5aa3b7-b8c0-4020-8a0c-e52e76cb75e2"
    var query = Query.where('deleted', false);
    final transactions = await db.get<Transaction>(query: query);

    if (transactions.isEmpty) return 0;

    List transactionsNotDeleted = transactions.map((t) => t.id).toList();

    query = Query(where: [Where('memberId').isExactly(id)]);
    final operations = await db.get<Operation>(query: query);

    if (operations.isEmpty) return 0;

    double balance = List<double>.from(operations.where((o) => transactionsNotDeleted.contains(o.transactionId)).map((e) => e.value)).sum;
    
    return balance;
  }

  Future<double> getTotal(String id, {dynamic db}) async {
    db = db ?? await instance.database;

    //select sum(value) from Operation where transaction_id in (select id from "Transaction" where deleted==0) and member_id=="5c5aa3b7-b8c0-4020-8a0c-e52e76cb75e2"
    var query = Query(where: [Where('deleted').isExactly(false), Where('memberId').isExactly(id)]);
    final transactions = await db.get<Transaction>(query: query);

    if (transactions.isEmpty) return 0;

    final total = List<double>.from(transactions.map((t) => t.value)).sum;

    return total;
  }

  Future <void> deleteDatabase() async {
    await Repository.instance.reset();
    await Repository().initialize();
  }
}