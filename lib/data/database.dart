import 'dart:async';
import 'dart:io';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:powersync/powersync.dart';
import 'package:logging/logging.dart';
import 'package:powersync/attachments/attachments.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import 'package:splizz/data/result.dart';
import 'package:splizz/data/storage_adapter.dart';
import 'package:splizz/data/supabase.dart';
import 'package:splizz/data/backend_connector.dart';
import 'package:splizz/resources/strings.dart';

import 'package:splizz/models/schema.dart';
import 'package:splizz/models/item.model.dart';
import 'package:splizz/models/member.model.dart';
import 'package:splizz/models/operation.model.dart';
import 'package:splizz/models/transaction.model.dart';
import 'package:splizz/models/user.model.dart';

class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static final String _databaseName = "powersync.db";
  static final int _databaseVersion = 1;

  static PowerSyncDatabase? _database;
  Future<PowerSyncDatabase> get database async =>
      _database ??= await _initDatabase();

  bool _logoutInProgress = false;
  bool get logoutInProgress => _logoutInProgress;

  final logger = Logger('AttachmentQueue');
  late AttachmentQueue attachmentQueue;
  
  Future<String> getDatabasePath() async {
    if (kIsWeb) {
      return _databaseName;
    }
    final dir = await getApplicationSupportDirectory();
    return path.join(dir.path, _databaseName);
  }

  Future<void> connectToDatabase(PowerSyncDatabase db) async {
    final connector = BackendConnector();
    await db.connect(connector: connector);
    return;
  }

  Future<PowerSyncDatabase> _initDatabase() async {
    final path = await getDatabasePath();

    final db =
        PowerSyncDatabase(schema: loggedIn ? schema : localSchema, path: path);
    await db.initialize();
    await initializeAttachmentQueue(db);

    if (loggedIn) {
      await connectToDatabase(db);
      await attachmentQueue.startSync();
    }

    return db;
  }

  Future<void> login() async {
    PowerSyncDatabase db = await instance.database;

    List<Item> items = await getItems();
    List<Member> members = await getMembers(sort: false);
    members
        .where((member) => member.email == "thisIsMe")
        .forEach((member) => member.email = currentUser?.email);
    List<Transaction> transactions = await getTransactions();
    List<Operation> operations = await getOperations(sort: false);
    await db.disconnectAndClear();
    await db.updateSchema(schema);

    // Connect to PowerSync when the user is signed in
    final connector = BackendConnector();
    await db.connect(connector: connector);
    await db.waitForFirstSync();
      
    await attachmentQueue.startSync();
    await waitForAttachmentSync(db).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        logger.warning('Timed out while waiting for attachment sync during login.');
      },
    );

    await uploadAllData(
        items: items,
        members: members,
        transactions: transactions,
        operations: operations);
  }

  Future<void> waitForAttachmentSync(
    PowerSyncDatabase db, {
    Duration pollInterval = const Duration(milliseconds: 250),
  }) async {

    while (true) {
      final rows = await db.getAll(
        'SELECT id, image FROM items WHERE image IS NOT NULL',
      );

      var allAttachmentsAvailable = true;

      for (final row in rows) {
        final imageName = row['image'] as String?;
        if (imageName == null) {
          continue;
        }

        final file = File(await _getAttachmentFilePath(imageName));
        if (!await file.exists()) {
          allAttachmentsAvailable = false;
          break;
        }
      }

      if (allAttachmentsAvailable) {
        return;
      }

      await Future.delayed(pollInterval);
    }
  }

  Future<void> uploadAllData(
      {List<Item> items = const [],
      List<Member> members = const [],
      List<Transaction> transactions = const [],
      List<Operation> operations = const []}) async {
    PowerSyncDatabase db = await instance.database;

    List<User> permissions = [];
    for (var item in items) {
      permissions.add(User(
        itemId: item.id,
        userId: userId,
        userEmail: currentUser!.email,
        expirationDate: null,
      ));
    }

    await Future.wait(items.map((item) async {
      if (item.image != null)
        await DatabaseHelper.instance.uploadItemImage(item.image!, item.id);
    }));

    final sql = [
      'INSERT INTO items (name, image, timestamp, id) VALUES (?, ?, ?, ?)',
      'INSERT INTO shared (item_id, user_id, full_access, user_email, expiration_date, id) VALUES (?, ?, ?, ?, ?, ?)',
      'INSERT INTO members (name, color, item_id, active, deleted, email, timestamp, id) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      'INSERT INTO transactions (description, value, date, member_id, item_id, payoff_id, deleted, timestamp, id) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
      'INSERT INTO operations (value, item_id, member_id, transaction_id, timestamp, id) VALUES (?, ?, ?, ?, ?, ?)',
    ];

    final parameterSets = [
      items.map((item) => item.toMap().values.toList()).toList(),
      permissions
          .map((permission) => permission.toMap().values.toList())
          .toList(),
      members.map((member) => member.toMap().values.toList()).toList(),
      transactions
          .map((transaction) => transaction.toMap().values.toList())
          .toList(),
      operations.map((operation) => operation.toMap().values.toList()).toList(),
    ];

    await db.executeBatch(sql[0], parameterSets[0]);
    await db.executeBatch(sql[1], parameterSets[1]);
    await db.executeBatch(sql[2], parameterSets[2]);
    await db.executeBatch(sql[3], parameterSets[3]);
    await db.executeBatch(sql[4], parameterSets[4]);
  }

  Future<void> logout() async {
    PowerSyncDatabase db = await instance.database;
    _logoutInProgress = true;

    // 1. Stop syncing attachments first
    try {
      await attachmentQueue.stopSyncing();
    } catch (error) {
      logger.warning('Failed to stop attachment syncing during logout.', error);
    }

    // 2. Disconnect and clear the SQLite database
    try {
      await db.disconnectAndClear().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          logger.warning('Timed out while clearing PowerSync during logout.');
        },
      );
    } catch (error) {
      logger.warning('Failed to disconnect and clear PowerSync during logout.', error);
    }

    // 3. Delete locally stored images/attachments
    try {
      await _clearLocalImages();
    } catch (error) {
      logger.warning('Failed to delete local images during logout.', error);
    } finally {
      _logoutInProgress = false;
      // 4. Finally, sign out of Supabase Auth
      await Supabase.instance.client.auth.signOut();
    }


    final docDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${docDir.path}/attachments');
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    await db.close();

    _database = await _initDatabase();
  }

  /// Helper method to delete the local images directory
  Future<void> _clearLocalImages() async {
    // Get the directory where your attachments are stored.
    // Replace this with the exact path logic your app uses to save images.
    final docDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${docDir.path}/attachments'); // e.g., 'attachments' folder

    if (await imagesDir.exists()) {
      // recursive: true deletes the folder and everything inside it
      await imagesDir.delete(recursive: true);
      logger.info('Successfully deleted local images directory.');
    }
  }

  Future<void> deleteLocalDatabase() async {
    Directory documentsDirectory = await getApplicationSupportDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
    _database = null;
  }

  Future<void> delete() async {
    Directory documentsDirectory = await getApplicationSupportDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
    _database = null;

    await Future.wait((await getItems()).map((item) => deleteItemImage(item.id)));
  }

  Future<List<Item>> getItems({dynamic db}) async {
    db = db ?? await instance.database;

    final List<Map<String, dynamic>> rows = await db.getAll('SELECT * FROM items');
    final List<Item> items = rows.isNotEmpty ? rows.map(Item.fromMap).toList() : <Item>[];

    final futures = items.map<Future<void>>((item) async {
      item.balance = await getUserBalance(itemId: item.id, db: db);
      final imagePath = await getItemImagePath(db, item.id);
      if (imagePath != null) {
        item.image = Uint8List.fromList(File(imagePath).readAsBytesSync());
      }
    });

    await Future.wait(futures);

    return items;
  }

  Future<Item> getItem(String id, {dynamic db}) async {
    db = db ?? await instance.database;

    final row = await db.get('SELECT * FROM items WHERE id = ?', [id]);
    Item item = Item.fromMap(row);
    final imagePath = await getItemImagePath(db, item.id);
    if (imagePath != null) {
      item.image = Uint8List.fromList(File(imagePath).readAsBytesSync());
    }

    List<Operation> operations = await getOperations(id: id, db: db);

    item.members = await getMembers(id: id, db: db);
    item.history = await getTransactions(id: id, db: db);

    item.members.forEach((m) {
      m.history = item.history.where((t) => t.memberId == m.id).toList();
      List<Transaction> balanceTransactions = item.history
          .where((t) =>
              t.payoffId == null &&
              t.description != "payoff" &&
              t.deleted == false)
          .toList();
      m.balance = List<double>.from(operations
          .where((o) =>
              o.memberId == m.id &&
              balanceTransactions.any((t) => t.id == o.transactionId))
          .map((e) => e.value)).sum;
      m.total = List<double>.from(
          m.history.where((t) => t.deleted == false).map((e) => e.value)).sum;
      m.payoff = List<double>.from(operations
          .where((o) =>
              o.memberId == m.id &&
              m.history.any(
                  (t) => t.payoffId == o.transactionId && t.deleted == false))
          .map((e) => e.value)).sum;
    });

    item.history.forEach((t) {
      t.operations = operations.where((o) => o.transactionId == t.id).toList();
      t.operations
          .sort((Operation a, Operation b) => b.value.compareTo(a.value));
    });

    return item;
  }

  Future<List<Member>> getMembers({String? id, sort = true, dynamic db}) async {
    db = db ?? await instance.database;

    final List<Map<String, dynamic>> rows = id == null
        ? await db.getAll('SELECT * FROM members')
        : await db.getAll('SELECT * FROM members WHERE item_id = ?', [id]);

    List<Member> members = rows.isNotEmpty
        ? rows.map((e) => Member.fromMap(e)).toList()
        : <Member>[];

    if (sort)
      members.sort((Member a, Member b) =>
          a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return members;
  }

  Future<List<Transaction>> getTransactions({String? id, dynamic db}) async {
    db = db ?? await instance.database;

    final List<Map<String, dynamic>> rows = id == null
        ? await db.getAll(
            'SELECT * FROM transactions ORDER BY date ASC, timestamp ASC')
        : await db.getAll(
            'SELECT * FROM transactions WHERE item_id = ? ORDER BY date ASC, timestamp ASC',
            [id]);

    List<Transaction> transactions = rows.isNotEmpty
        ? rows.map((e) => Transaction.fromMap(e)).toList()
        : <Transaction>[];

    return transactions;
  }

  Future<List<Operation>> getTransactionOperations(String id,
      {dynamic db}) async {
    db = db ?? await instance.database;

    final List<Map<String, dynamic>> rows = await db
        .getAll('SELECT * FROM operations WHERE transaction_id = ?', [id]);
    List<Operation> operations = rows.isNotEmpty
        ? rows.map((e) => Operation.fromMap(e)).toList()
        : <Operation>[];

    operations.sort(
      (Operation a, Operation b) => b.value.compareTo(a.value),
    );

    return operations;
  }

  Future<List<Operation>> getOperations(
      {String? id, sort = true, dynamic db}) async {
    db = db ?? await instance.database;

    final List<Map<String, dynamic>> rows = id == null
        ? await db.getAll('SELECT * FROM operations')
        : await db.getAll('SELECT * FROM operations WHERE item_id = ?', [id]);
    List<Operation> operations = rows.isNotEmpty
        ? rows.map((e) => Operation.fromMap(e)).toList()
        : <Operation>[];

    if (sort)
      operations.sort(
        (Operation a, Operation b) => b.value.compareTo(a.value),
      );

    return operations;
  }

  Future<User> getPermission(String itemId, String userId, {dynamic db}) async {
    db = db ?? await instance.database;

    final List<Map<String, dynamic>> rows = await db.getAll(
        'SELECT * FROM shared WHERE item_id = ? AND user_id = ?',
        [itemId, userId]);
    if (rows.isEmpty) throw Exception("Permission not found");
    User user = User.fromMap(rows[0]);

    return user;
  }

  Future<void> insertItem(Item item, {dynamic db}) async {
    db ??= await instance.database;

    Attachment attachment = await uploadItemImage(item.image!, item.id);
    item.imagePath = attachment.filename;

    await db.execute(
        'INSERT INTO items (name, image, timestamp, id) VALUES (?, ?, ?, ?)',
        item.toMap().values.toList());

    if (currentUser != null)
      await db.execute(
          'INSERT INTO shared (item_id, user_id, full_access, user_email, expiration_date, id) VALUES (?, ?, ?, ?, ?, ?)',
          User(
                  itemId: item.id,
                  userId: currentUser?.id,
                  userEmail: currentUser?.email,
                  fullAccess: true)
              .toMap()
              .values
              .toList());

    await Future.wait(
        item.members.map((member) => insertMember(member, db: db)));
    await Future.wait(item.history
        .map((transaction) => insertTransaction(transaction, db: db)));
  }

  Future<void> updateItem(Item item,
      {bool updateImage = false, dynamic db}) async {
    db ??= await instance.database;

    await db.execute(
        'UPDATE items SET name = ?, image = ?, timestamp = ? WHERE id = ?',
        item.toMap().values.toList());

    await Future.wait(
        item.members.map((member) => updateMember(member, db: db)));
    await Future.wait(item.history
        .map((transaction) => updateTransaction(transaction, db: db)));

    if (updateImage && item.image != null) {
      await uploadItemImage(item.image!, item.id);
    }
  }

  Future<double> getUserBalance({String? itemId, dynamic db}) async {
    db = db ?? await instance.database;

    final List<Map<String, dynamic>> rows;
    if (itemId == null)
      rows = await db.getAll('SELECT * FROM members WHERE email = ?',
          [currentUser != null ? currentUser?.email : "thisIsMe"]);
    else
      rows = await db.getAll(
          'SELECT * FROM members WHERE item_id = ? AND email = ?',
          [itemId, currentUser != null ? currentUser?.email : "thisIsMe"]);

    List<Member> members = rows.isNotEmpty
        ? rows.map((e) => Member.fromMap(e)).toList()
        : <Member>[];

    await Future.wait(members.map((m) async {
      final balanceFuture = getBalance(m.id, m.itemId!, db: db);
      m.balance = await balanceFuture;
    }));

    return members.length > 0
        ? members.fold<double>(
            0.0, (previousValue, element) => previousValue + (element.balance))
        : 0;
  }

  Future<void> insertTransaction(Transaction transaction,
      {dynamic db, List<Transaction> payoffTransactions = const []}) async {
    db = db ?? await instance.database;

    final operations = List<Operation>.from(transaction.operations);

    await db.execute(
        'INSERT INTO transactions (description, value, date, member_id, item_id, payoff_id, deleted, timestamp, id) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
        transaction.toMap().values.toList());

    if (payoffTransactions.isNotEmpty) {
      await Future.wait(payoffTransactions
          .map((t) => updateTransaction(t..payoffId = transaction.id, db: db)));
    }

    await Future.wait(
        operations.map((operation) => insertOperation(operation, db: db)));
  }

  Future<void> updateTransaction(Transaction transaction, {dynamic db}) async {
    db = db ?? await instance.database;

    final operations = List<Operation>.from(transaction.operations);

    await db.execute(
        'UPDATE transactions SET description = ?, value = ?, date = ?, member_id = ?, item_id = ?, payoff_id = ?, deleted = ?, timestamp = ? WHERE id = ?',
        transaction.toMap().values.toList());

    await Future.wait(
        operations.map((operation) => updateOperation(operation, db: db)));
  }

  Future<void> insertMember(Member member, {dynamic db}) async {
    db = db ?? await instance.database;

    await db.execute(
        'INSERT INTO members (name, color, item_id, active, deleted, email, timestamp, id) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        member.toMap().values.toList());
  }

  Future<void> updateMember(Member member, {dynamic db}) async {
    db = db ?? await instance.database;

    await db.execute(
        'UPDATE members SET name = ?, color = ?, item_id = ?, active = ?, deleted = ?, email = ?, timestamp = ? WHERE id = ?',
        member.toMap().values.toList());
  }

  Future<void> insertOperation(Operation operation, {dynamic db}) async {
    db = db ?? await instance.database;

    await db.execute(
        'INSERT INTO operations (value, item_id, member_id, transaction_id, timestamp, id) VALUES (?, ?, ?, ?, ?, ?)',
        operation.toMap().values.toList());
  }

  Future<void> updateOperation(Operation operation, {dynamic db}) async {
    db = db ?? await instance.database;

    await db.execute(
        'UPDATE operations SET value = ?, item_id = ?, member_id = ?, transaction_id = ?, timestamp = ? WHERE id = ?',
        operation.toMap().values.toList());
  }

  Future<Result> addPermission(User permission, {dynamic db}) async {
    db = db ?? await instance.database;

    if (currentUser == null) {
      return Result.failure(notAuthorized);
    }

    if (permission.userEmail == currentUser!.email) {
      return Result.failure(cannotShareWithYourself);
    }

    final row = await db.getAll(
        'SELECT * FROM shared WHERE item_id = ? and user_email = ?',
        [permission.itemId, permission.userEmail]);

    if (row.isNotEmpty) {
      final existingPermission = User.fromMap(row[0]);
      if (existingPermission.expirationDate == null)
        return Result.failure(alreadyGrantedAccess);

      existingPermission.fullAccess = permission.fullAccess;
      existingPermission.expirationDate = permission.expirationDate;

      permission = existingPermission;

      await db.execute(
          'UPDATE shared SET full_access = ?, expiration_date = ? WHERE item_id = ? and user_email = ?',
          [
            permission.fullAccess ? 1 : 0,
            permission.expirationDate?.toString(),
            permission.itemId,
            permission.userEmail
          ]);
    } else {
      await db.execute(
          'INSERT INTO shared (item_id, user_id, full_access, user_email, expiration_date, id) VALUES (?, ?, ?, ?, ?, ?)',
          permission.toMap().values.toList());
    }

    return Result.success(permission);
  }

  Future<Result> confirmPermission(String permissionId, {dynamic db}) async {
    db = db ?? await instance.database;

    if (!loggedIn) {
      return Result.failure(logInForSharing);
    }

    final row =
        await db.get('SELECT * FROM shared WHERE id = ?', [permissionId]);
    if (row.isEmpty) return Result.failure(notAuthorized);
    User permission = User.fromMap(row);

    if (permission.userEmail != null) {
      if (permission.userEmail != currentUser?.email)
        return Result.failure(notAuthorized);

      permission.userId = currentUser?.id;
      permission.expirationDate = null;

      final row2 = await db.getAll(
          'SELECT * FROM shared WHERE item_id = ? AND user_id = ?',
          [permission.itemId, permission.userId]);
      if (row2.isNotEmpty) return Result.failure(itemAlreadyAdded);

      await db.execute(
          'UPDATE shared SET item_id = ?, user_id = ?, full_access = ?, user_email = ?, expiration_date = ? WHERE id = ?',
          permission.toMap().values.toList());
    } else {
      permission = User(
        itemId: permission.itemId,
        userId: permission.userId,
        fullAccess: permission.fullAccess,
        userEmail: currentUser?.email,
      );

      final row2 = await db.getAll(
          'SELECT * FROM shared WHERE item_id = ? AND user_id = ?',
          [permission.itemId, permission.userId]);
      if (row2.isNotEmpty) return Result.failure(itemAlreadyAdded);

      await db.execute(
          'INSERT INTO shared (item_id, user_id, full_access, user_email, expiration_date, id) VALUES (?, ?, ?, ?, ?, ?)',
          permission.toMap().values.toList());
    }

    return Result.success(null);
  }

  Future<void> deleteItem(Item item, {dynamic db}) async {
    db = db ?? await instance.database;

    item.members = await getMembers(id: item.id, db: db);
    item.history = await getTransactions(id: item.id, db: db);

    await Future.wait(item.history
        .map((transaction) => deleteTransaction(transaction, db: db)));
    await Future.wait(
        item.members.map((member) => deleteMember(member, db: db)));

    await deleteItemImage(item.id);

    await db.execute('DELETE FROM items WHERE id = ?', [item.id]);

    if (currentUser != null) await deleteUser(item.id, db: db);
  }

  Future<void> deleteTransaction(Transaction transaction, {dynamic db}) async {
    db = db ?? await instance.database;

    transaction.operations =
        await getTransactionOperations(transaction.id, db: db);

    await Future.wait(transaction.operations
        .map((operation) => deleteOperation(operation, db: db)));

    await db.execute('DELETE FROM transactions WHERE id = ?', [transaction.id]);
  }

  Future<void> deleteMember(Member member, {dynamic db}) async {
    db = db ?? await instance.database;

    await db.execute('DELETE FROM members WHERE id = ?', [member.id]);
  }

  Future<void> markMemberDeleted(Member member, {dynamic db}) async {
    db = db ?? await instance.database;

    member.deleted = true;

    await db.execute('UPDATE members SET deleted = ? WHERE id = ?',
        [member.deleted, member.id]);
  }

  Future<void> deleteOperation(Operation operation, {dynamic db}) async {
    db = db ?? await instance.database;

    await db.execute('DELETE FROM operations WHERE id = ?', [operation.id]);
  }

  Future<void> deleteUser(String id, {dynamic db}) async {
    db = db ?? await instance.database;

    final List<Map<String, dynamic>> rows =
        await db.getAll('SELECT * FROM shared WHERE item_id = ?', [id]);
    List<User> users =
        rows.isNotEmpty ? rows.map((e) => User.fromMap(e)).toList() : [];

    await Future.wait<dynamic>(users.map((u) => db.delete<User>(u)));
  }

  Future<double> getBalance(String memberId, String itemId,
      {dynamic db}) async {
    db = db ?? await instance.database;

    final List<Map<String, dynamic>> rows = await db.getAll(
        'SELECT * FROM transactions WHERE item_id = ? AND deleted = ? AND description != ? AND payoff_id IS NULL',
        [itemId, false, "payoff"]);
    List<Transaction> transactions =
        rows.isNotEmpty ? rows.map((e) => Transaction.fromMap(e)).toList() : [];

    if (transactions.isEmpty) return 0;

    List transactionsNotDeleted = transactions.map((t) => t.id).toList();

    final List<Map<String, dynamic>> rows2 = await db
        .getAll('SELECT * FROM operations WHERE member_id = ?', [memberId]);
    List<Operation> operations =
        rows2.isNotEmpty ? rows2.map((e) => Operation.fromMap(e)).toList() : [];

    if (operations.isEmpty) return 0;

    double balance = List<double>.from(operations
        .where((o) => transactionsNotDeleted.contains(o.transactionId))
        .map((e) => e.value)).sum;

    return balance;
  }

  Future<void> initializeAttachmentQueue(PowerSyncDatabase db) async {
    attachmentQueue = AttachmentQueue(
      db: db,
      remoteStorage: SupabaseStorageAdapter(),
      localStorage: await getLocalStorage(),

      // Define which attachments exist in your data model
      watchAttachments: () => db.watch('''
        SELECT id, image 
        FROM items 
        WHERE image IS NOT NULL
      ''').map(
        (results) => [
          for (final row in results)
            WatchedAttachmentItem(
              id: row['id'] as String,
              filename: row['image'] as String,
            )
        ],
      ),

      // Optional configuration
      syncInterval: const Duration(seconds: 30), // Sync every 30 seconds
      downloadAttachments: true, // Auto-download referenced files
      archivedCacheLimit: 100, // Keep 100 archived files before cleanup
      logger: logger,
    );
  }

  Future<Attachment> uploadItemImage(
    Uint8List image,
    String id,
  ) async {
    final imageBytes = await image;

    final attachment = await attachmentQueue.saveFile(
      id: id,
      data: Stream.value(imageBytes),
      mediaType: 'image/jpeg',
      fileExtension: 'jpg',

      // updateHook runs in same transaction, ensuring atomicity
      updateHook: (context, attachment) async {
        await context.execute(
          'UPDATE items SET image = ? WHERE id = ?',
          [attachment.filename, id],
        );
      },
    );

    return attachment;
  }

  Future<String?> getItemImagePath(
    PowerSyncDatabase db,
    String id,
  ) async {
    final item = await db.get(
      'SELECT id, image FROM items WHERE id = ?',
      [id],
    );

    if (item == null || item['image'] == null) {
      return null;
    }

    final imageName = item['image'] as String;
    final attachmentPath = await _getAttachmentFilePath(imageName);
    if (await File(attachmentPath).exists()) {
      return attachmentPath;
    }

    return null;
  }

  Future<String> _getAttachmentFilePath(String filename) async {
    final appDocDir = await getApplicationDocumentsDirectory();
    return '${appDocDir.path}/attachments/$filename';
  }

  Future<void> deleteItemImage(
    String id,
  ) async {
    await attachmentQueue.deleteFile(
      attachmentId: id,

      // updateHook ensures atomic deletion
      updateHook: (context, attachment) async {
        await context.execute(
          'UPDATE items SET image = NULL WHERE id = ?',
          [id],
        );
      },
    );

    print('Photo queued for deletion');
    // The queue will:
    // 1. Delete from remote storage
    // 2. Delete local file
    // 3. Remove attachment record
  }

  // Alternative: Remove reference and let queue archive it automatically
  Future<void> removeItemImageReference(
    PowerSyncDatabase db,
    String id,
  ) async {
    await db.execute(
      'UPDATE items SET image = NULL WHERE id = ?',
      [id],
    );

    // The watchAttachments callback will detect this change
    // The queue will automatically archive the unreferenced attachment
    // After reaching archivedCacheLimit, it will be deleted
  }
}











//TODO: Rename User class to Permission to avoid confusion with Supabase User. Update all references accordingly.
//TODO: Remove Overhead brick files
//TODO: Use Debug Supabase instance with separate powersync connector
//TODO: Delete Images when logout and delete local database (currently they remain in local storage until overwritten, but won't be accessible)