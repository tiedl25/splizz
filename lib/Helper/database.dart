import 'dart:async';
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

import 'package:brick_core/query.dart';

class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Repository? _database;
  Future<Repository> get database async => _database ??= await _initDatabase();

  static var lock = Lock(reentrant: true);

  Future<Repository> _initDatabase() async {
    return Repository.instance;
  }

  Future<List<Item>> getItems({Repository? db}) async {
    db = db ?? await instance.database;

    final items = await db.get<Item>();
    return items;
  }

  Future<List<Member>> getMembers(String id, {Repository? db}) async {
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

  Future<List<Transaction>> getTransactions(String id, {Repository? db}) async {
    db = db ?? await instance.database;

    final transactionQuery = Query(where: [Where('itemId').isExactly(id)]);
    final transactions = await db.get<Transaction>(query: transactionQuery);

    transactions.sortBy((element) => element.timestamp);

    for(Transaction t in transactions){
      t.operations = await getTransactionOperations(t.id, db: db);
    }

    return transactions;
  }

  Future<List<Transaction>> getMemberTransactions(String id, {Repository? db}) async {
    db = db ?? await instance.database;

    final transactionQuery = Query(where: [Where('memberId').isExactly(id)]);
    final transactions = await db.get<Transaction>(query: transactionQuery);

    return transactions;
  }

  Future<List<Operation>> getTransactionOperations(String id, {Repository? db}) async {
    db = db ?? await instance.database;

    final operationQuery = Query(where: [Where('transactionId').isExactly(id)]);
    final operations = await db.get<Operation>(query: operationQuery); 

    return operations;  
  }

  Future<void> upsertItem(Item item, {Repository? db}) async {
    db = db ?? await instance.database;
  
    db.upsert<Item>(item);

    upsertUser(item.id, db: db, fullAccess: true);

    for(Member member in item.members){
      upsertMember(member, db: db);
    }
  }

  Future<void> upsertTransaction(Transaction transaction, {Repository? db}) async {
    db = db ?? await instance.database;
  
    db.upsert<Transaction>(transaction);

    for(Operation operation in transaction.operations){
      db.upsert<Operation>(operation);
    }
  }

  Future<void> upsertMember(Member member, {Repository? db}) async {
    db = db ?? await instance.database;
  
    db.upsert<Member>(member);
  }

  Future<Result> upsertUser(String itemId, {bool fullAccess = false, String? userEmail, Repository? db}) async {
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

  Future<void> deleteItem(Item item, {Repository? db}) async {
    db = db ?? await instance.database;
  
    db.delete<Item>(item);
  }

  Future<void> deleteTransaction(Transaction transaction, {Repository? db}) async {
    db = db ?? await instance.database;
  
    db.delete<Transaction>(transaction);
  }

  Future<void> deleteMember(Member member, {Repository? db}) async {
    db = db ?? await instance.database;
  
    db.delete<Member>(member);
  }

  Future<void> deleteOperation(Operation operation, {Repository? db}) async {
    db = db ?? await instance.database;
  
    db.delete<Operation>(operation);
  }
  
  Future<void> deleteUser(String id, {Repository? db}) async {
    db = db ?? await instance.database;

    final userQuery = Query(where: [Where('itemId').isExactly(id), Where('userId').isExactly(id)]);
    final user = await db.get<User>(query: userQuery);
  
    db.delete<User>(user[0]);
  }

  Future<void> deleteImage(String id, {Repository? db}) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    await Supabase.instance.client.storage.from('images').remove(["$userId/$id.jpg"]);
  }

  Future<double> getBalance(String id, {Repository? db}) async {
    db = db ?? await instance.database;

    //select sum(value) from Operation where transaction_id in (select id from "Transaction" where deleted==0) and member_id=="5c5aa3b7-b8c0-4020-8a0c-e52e76cb75e2"
    var query = Query.where('deleted', false);
    final transactions = await db.get<Transaction>(query: query);
    List transactionsNotDeleted = transactions.map((t) => t.id).toList();

    query = Query(where: [Where('memberId').isExactly(id)]);
    final operations = await db.get<Operation>(query: query);

    final balance = operations.where((o) => transactionsNotDeleted.contains(o.transactionId)).map((e) => e.value).sum;
    
    return balance;
  }

  Future<double> getTotal(String id, {Repository? db}) async {
    db = db ?? await instance.database;

    //select sum(value) from Operation where transaction_id in (select id from "Transaction" where deleted==0) and member_id=="5c5aa3b7-b8c0-4020-8a0c-e52e76cb75e2"
    var query = Query(where: [Where('deleted').isExactly(false), Where('memberId').isExactly(id)]);
    final transactions = await db.get<Transaction>(query: query);
    final total = transactions.map((t) => t.value).sum;

    return total;
  }

  Future<void> shareItem(Item item, String email) async {
    //final userId = Supabase.instance.client.auth.currentUser?.send;
  }
}