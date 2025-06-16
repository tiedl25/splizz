import 'dart:async';
import 'dart:typed_data';
import 'package:brick_offline_first/brick_offline_first.dart';
import 'package:collection/collection.dart';
import 'package:splizz/data/result.dart';

import 'package:splizz/brick/repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:synchronized/synchronized.dart';

import 'package:splizz/models/item.model.dart';
import 'package:splizz/models/member.model.dart';
import 'package:splizz/models/operation.model.dart';
import 'package:splizz/models/transaction.model.dart';
import 'package:splizz/models/user.model.dart';

import 'package:connectivity_plus/connectivity_plus.dart';

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

  Future<bool> checkQueue() async {
    if (!isSignedIn) return true;

    // ignore: invalid_use_of_protected_member
    final queue = Repository.instance.offlineRequestQueue;
    final unprocessedRequests = await queue.requestManager.unprocessedRequests();

    for (final sqliteRequest in unprocessedRequests) {
      

      final request = queue.requestManager.sqliteToRequest(sqliteRequest);
      if (sqliteRequest["attempts"] < 3) {
        await queue.transmitRequest(request);
      } else {
        try {
          await queue.transmitRequest(request);
        } catch (e) {
          if (e.toString().contains("Unauthorized")) {
            await queue.requestManager.deleteUnprocessedRequest(sqliteRequest["id"]);
          }
        }
      }
    }

    return (await queue.requestManager.unprocessedRequests()).length > 0;
  }

  Future<void> destructiveSync() async {
    final db = await Repository.instance;

    if (await checkQueue()) return;

    db.destructiveLocalSyncFromRemote<Item>();
    db.destructiveLocalSyncFromRemote<User>();
    db.destructiveLocalSyncFromRemote<Member>();
    db.destructiveLocalSyncFromRemote<Operation>();
    db.destructiveLocalSyncFromRemote<Transaction>();
  }

  Future<List<Item>> getItems({dynamic db, bool sync = false}) async {
    db = db ?? await instance.database;

    checkQueue();

    final connection = (await Connectivity().checkConnectivity())[0] != ConnectivityResult.none;

    sync = sync && isSignedIn && connection;

    final items = sync ? await db.destructiveLocalSyncFromRemote<Item>() : await db.get<Item>();
   
    return items;
  }

  Future<Item> getItem(String id, {dynamic db, bool sync = false}) async {
    db = db ?? await instance.database;

    final connection = (await Connectivity().checkConnectivity())[0] != ConnectivityResult.none;

    sync = sync && isSignedIn && connection;

    final itemQuery = Query(where: [Where('id').isExactly(id)]);

    final item = !isSignedIn ? (await db.get<Item>(query: itemQuery))[0] : (await db.get<Item>(query: itemQuery, policy: sync ? OfflineFirstGetPolicy.alwaysHydrate : OfflineFirstGetPolicy.awaitRemoteWhenNoneExist))[0];

    item.members = await getMembers(id, db: db, sync: sync);
    item.history = await getTransactions(id, db: db, sync: sync);

    return item;
  }

  Future<List<Member>> getMembers(String id, {dynamic db, bool sync = false}) async {
    db = db ?? await instance.database;
    sync = sync && isSignedIn;

    final memberQuery = Query(where: [Where('itemId').isExactly(id)]);
    final members = !isSignedIn ? await db.get<Member>(query: memberQuery) : await db.get<Member>(query: memberQuery, policy: sync ? OfflineFirstGetPolicy.alwaysHydrate : OfflineFirstGetPolicy.awaitRemoteWhenNoneExist);

    for(Member m in members){
      m.balance = await getBalance(m.id, db: db);
      m.total = await getTotal(m.id, db: db);
      m.history = await getMemberTransactions(m.id, db: db);
    }

    members.sort((Member a, Member b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return members;
  }

  Future<List<Transaction>> getTransactions(String id, {dynamic db, bool sync = false}) async {
    db = db ?? await instance.database;
    sync = sync && isSignedIn;

    final transactionQuery = Query(where: [Where('itemId').isExactly(id)], providerArgs: {'orderBy': 'timestamp ASC'});
    final transactions = !isSignedIn ? await db.get<Transaction>(query: transactionQuery) : await db.get<Transaction>(query: transactionQuery, policy: sync ? OfflineFirstGetPolicy.alwaysHydrate : OfflineFirstGetPolicy.awaitRemoteWhenNoneExist);

    if (transactions.isEmpty) return [];

    for(Transaction t in transactions){
      t.operations = await getTransactionOperations(t.id, db: db, sync: sync);
    }

    return transactions;
  }

  Future<List<Transaction>> getMemberTransactions(String id, {dynamic db}) async {
    db = db ?? await instance.database;

    final transactionQuery = Query(where: [Where('memberId').isExactly(id)]);
    final transactions = await db.get<Transaction>(query: transactionQuery);

    return transactions;
  }

  Future<List<Operation>> getTransactionOperations(String id, {dynamic db, bool sync = false}) async {
    db = db ?? await instance.database;
    sync = sync && isSignedIn;

    final operationQuery = Query(where: [Where('transactionId').isExactly(id)]);
    List<Operation> operations = !isSignedIn ? await db.get<Operation>(query: operationQuery) : await db.get<Operation>(query: operationQuery, policy: sync ? OfflineFirstGetPolicy.alwaysHydrate : OfflineFirstGetPolicy.awaitRemoteWhenNoneExist);

    operations.sort((Operation a, Operation b) => b.value.compareTo(a.value), );

    return operations;  
  }

  Future<User> getPermission(String itemId, String userId, {dynamic db}) async {
    db = db ?? await instance.database;

    final userQuery = Query(where: [Where('itemId').isExactly(itemId), Where('userId').isExactly(userId)]);
    return (await db.get<User>(query: userQuery))[0];
  }

  Future<void> upsertItem(Item item, {dynamic db}) async {
    db ??= await instance.database;
  
    await db.upsert<Item>(item);

    final currentUser = Supabase.instance.client.auth.currentUser;

    if (currentUser != null) await db.upsert<User>(User(itemId: item.id, userId: currentUser.id, userEmail: currentUser.email, fullAccess: true));

    for(Member member in item.members){
      await upsertMember(member, db: db);
    }
    for(Transaction transaction in item.history){
      await upsertTransaction(transaction, db: db);
    }
  }

  Future<void> upsertTransaction(Transaction transaction, {dynamic db}) async {
    db = db ?? await instance.database;
  
    await db.upsert<Transaction>(transaction);

    for(Operation operation in transaction.operations){
      upsertOperation(operation, db: db);
    }
  }

  Future<void> upsertMember(Member member, {dynamic db}) async {
    db = db ?? await instance.database;
  
    await db.upsert<Member>(member);
  }

  Future<Result> addPermission(User permission, {dynamic db}) async {
    db = db ?? await instance.database;

    final existingPermission = await db.get<User>(query: Query(where: [Where("itemId").isExactly(permission.itemId), Where("userEmail").isExactly(permission.userEmail)]));

    if (existingPermission.isNotEmpty){
      if (existingPermission[0].expirationDate == null) return Result.failure("User is already granted access!");

      existingPermission[0].fullAccess = permission.fullAccess;
      existingPermission[0].expirationDate = permission.expirationDate;

      permission = existingPermission[0];
    }

    await db.upsert<User>(permission);

    return Result.success(permission);
  }

  Future<Result> confirmPermission(String permissionId, {dynamic db}) async {
    db = db ?? await instance.database;

    final currentUser = Supabase.instance.client.auth.currentUser!;

    final permissions = await db.get<User>(query: Query(where: [Where('id').isExactly(permissionId)]));

    if (permissions.isEmpty) return Result.failure("You are not authorized for this action!");
    
    User permission = permissions[0];

    if(permission.userEmail != null){
      if (permission.userEmail != currentUser.email) return Result.failure("You are not authorized for this action!");

      permission.userId = currentUser.id;
      permission.expirationDate = null;
    } else {
      permission = User(
        itemId: permission.itemId,
        userId: permission.userId,
        fullAccess: permission.fullAccess,
        userEmail: currentUser.email,
      );
    }

    Query query = Query(where: [Where("itemId").isExactly(permission.itemId), Where("userId").isExactly(permission.userId)]);
    final existingPermissions = await db.get<User>(query: query);

    if (existingPermissions.isNotEmpty) return Result.failure("The item has already been added");    

    await db.upsert<User>(permission);

    Item item = await getItem(permission.itemId!, db: db);
    await db.upsert<Item>(item);

    return Result.success(null);
  }

  Future<void> upsertOperation(Operation operation, {dynamic db}) async {
    db = db ?? await instance.database;
  
    await db.upsert<Operation>(operation);
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

    if (db != Repository.instance.sqliteProvider) await deleteImage(item.id, db: db);

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

    var query = Query(where: [Where('deleted').isExactly(false), Where('memberId').isExactly(id)]);
    final transactions = await db.get<Transaction>(query: query);

    if (transactions.isEmpty) return 0;

    final total = List<double>.from(transactions.map((t) => t.value)).sum;

    return total;
  }

  Future<Uint8List?> getLocalImage(String id) async {
    final db = await Repository.instance.sqliteProvider;

    final Query query = Query(where: [Where('id').isExactly(id)]);
    final items = await db.get<Item>(query: query);

    if (items.isEmpty) return null;

    return items[0].image;
  }

  Future <void> deleteDatabase() async {
    await Repository.instance.reset();
    await Repository().initialize();
  }
}