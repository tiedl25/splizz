// GENERATED CODE DO NOT EDIT
part of '../brick.g.dart';

Future<Transaction> _$TransactionFromSupabase(Map<String, dynamic> data,
    {required SupabaseProvider provider,
    OfflineFirstWithSupabaseRepository? repository}) async {
  return Transaction(
      id: data['id'] as String?,
      memberId: data['member_id'] as String?,
      itemId: data['item_id'] as String?,
      description: data['description'] as String,
      date: DateTime.parse(data['date'] as String),
      value: data['value'] as double,
      timestamp: data['timestamp'] == null
          ? null
          : DateTime.tryParse(data['timestamp'] as String));
}

Future<Map<String, dynamic>> _$TransactionToSupabase(Transaction instance,
    {required SupabaseProvider provider,
    OfflineFirstWithSupabaseRepository? repository}) async {
  return {
    'id': instance.id,
    'member_id': instance.memberId,
    'item_id': instance.itemId,
    'description': instance.description,
    'date': instance.date.toIso8601String(),
    'value': instance.value,
    'deleted': instance.deleted,
    'timestamp': instance.timestamp.toIso8601String(),
    'operations': await Future.wait<Map<String, dynamic>>(instance.operations
        .map((s) => OperationAdapter()
            .toSupabase(s, provider: provider, repository: repository))
        .toList())
  };
}

Future<Transaction> _$TransactionFromSqlite(Map<String, dynamic> data,
    {required SqliteProvider provider,
    OfflineFirstWithSupabaseRepository? repository}) async {
  return Transaction(
      id: data['id'] as String,
      memberId: data['member_id'] == null ? null : data['member_id'] as String?,
      itemId: data['item_id'] == null ? null : data['item_id'] as String?,
      description: data['description'] as String,
      date: DateTime.parse(data['date'] as String),
      value: data['value'] as double,
      deleted: data['deleted'] == 1,
      timestamp: DateTime.parse(data['timestamp'] as String),
      operations: (await provider.rawQuery(
              'SELECT DISTINCT `f_Operation_brick_id` FROM `_brick_Transaction_operations` WHERE l_Transaction_brick_id = ?',
              [data['_brick_id'] as int]).then((results) {
        final ids = results.map((r) => r['f_Operation_brick_id']);
        return Future.wait<Operation>(ids.map((primaryKey) => repository!
            .getAssociation<Operation>(
              Query.where('primaryKey', primaryKey, limit1: true),
            )
            .then((r) => r!.first)));
      }))
          .toList()
          .cast<Operation>())
    ..primaryKey = data['_brick_id'] as int;
}

Future<Map<String, dynamic>> _$TransactionToSqlite(Transaction instance,
    {required SqliteProvider provider,
    OfflineFirstWithSupabaseRepository? repository}) async {
  return {
    'id': instance.id,
    'member_id': instance.memberId,
    'item_id': instance.itemId,
    'description': instance.description,
    'date': instance.date.toIso8601String(),
    'value': instance.value,
    'deleted': instance.deleted ? 1 : 0,
    'timestamp': instance.timestamp.toIso8601String()
  };
}

/// Construct a [Transaction]
class TransactionAdapter extends OfflineFirstWithSupabaseAdapter<Transaction> {
  TransactionAdapter();

  @override
  final supabaseTableName = 'items';
  @override
  final defaultToNull = true;
  @override
  final fieldsToSupabaseColumns = {
    'id': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'id',
    ),
    'memberId': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'member_id',
    ),
    'itemId': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'item_id',
    ),
    'description': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'description',
    ),
    'date': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'date',
    ),
    'value': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'value',
    ),
    'deleted': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'deleted',
    ),
    'timestamp': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'timestamp',
    ),
    'operations': const RuntimeSupabaseColumnDefinition(
      association: true,
      columnName: 'operations',
      associationType: Operation,
      associationIsNullable: false,
    )
  };
  @override
  final ignoreDuplicates = false;
  @override
  final uniqueFields = {'id'};
  @override
  final Map<String, RuntimeSqliteColumnDefinition> fieldsToSqliteColumns = {
    'primaryKey': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: '_brick_id',
      iterable: false,
      type: int,
    ),
    'id': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'id',
      iterable: false,
      type: String,
    ),
    'memberId': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'member_id',
      iterable: false,
      type: String,
    ),
    'itemId': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'item_id',
      iterable: false,
      type: String,
    ),
    'description': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'description',
      iterable: false,
      type: String,
    ),
    'date': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'date',
      iterable: false,
      type: DateTime,
    ),
    'value': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'value',
      iterable: false,
      type: double,
    ),
    'deleted': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'deleted',
      iterable: false,
      type: bool,
    ),
    'timestamp': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'timestamp',
      iterable: false,
      type: DateTime,
    ),
    'operations': const RuntimeSqliteColumnDefinition(
      association: true,
      columnName: 'operations',
      iterable: true,
      type: Operation,
    )
  };
  @override
  Future<int?> primaryKeyByUniqueColumns(
      Transaction instance, DatabaseExecutor executor) async {
    final results = await executor.rawQuery('''
        SELECT * FROM `Transaction` WHERE id = ? LIMIT 1''', [instance.id]);

    // SQFlite returns [{}] when no results are found
    if (results.isEmpty || (results.length == 1 && results.first.isEmpty)) {
      return null;
    }

    return results.first['_brick_id'] as int;
  }

  @override
  final String tableName = 'Transaction';
  @override
  Future<void> afterSave(instance, {required provider, repository}) async {
    if (instance.primaryKey != null) {
      final operationsOldColumns = await provider.rawQuery(
          'SELECT `f_Operation_brick_id` FROM `_brick_Transaction_operations` WHERE `l_Transaction_brick_id` = ?',
          [instance.primaryKey]);
      final operationsOldIds =
          operationsOldColumns.map((a) => a['f_Operation_brick_id']);
      final operationsNewIds =
          instance.operations.map((s) => s.primaryKey).whereType<int>();
      final operationsIdsToDelete =
          operationsOldIds.where((id) => !operationsNewIds.contains(id));

      await Future.wait<void>(operationsIdsToDelete.map((id) async {
        return await provider.rawExecute(
            'DELETE FROM `_brick_Transaction_operations` WHERE `l_Transaction_brick_id` = ? AND `f_Operation_brick_id` = ?',
            [instance.primaryKey, id]).catchError((e) => null);
      }));

      await Future.wait<int?>(instance.operations.map((s) async {
        final id = s.primaryKey ??
            await provider.upsert<Operation>(s, repository: repository);
        return await provider.rawInsert(
            'INSERT OR IGNORE INTO `_brick_Transaction_operations` (`l_Transaction_brick_id`, `f_Operation_brick_id`) VALUES (?, ?)',
            [instance.primaryKey, id]);
      }));
    }
  }

  @override
  Future<Transaction> fromSupabase(Map<String, dynamic> input,
          {required provider,
          covariant OfflineFirstWithSupabaseRepository? repository}) async =>
      await _$TransactionFromSupabase(input,
          provider: provider, repository: repository);
  @override
  Future<Map<String, dynamic>> toSupabase(Transaction input,
          {required provider,
          covariant OfflineFirstWithSupabaseRepository? repository}) async =>
      await _$TransactionToSupabase(input,
          provider: provider, repository: repository);
  @override
  Future<Transaction> fromSqlite(Map<String, dynamic> input,
          {required provider,
          covariant OfflineFirstWithSupabaseRepository? repository}) async =>
      await _$TransactionFromSqlite(input,
          provider: provider, repository: repository);
  @override
  Future<Map<String, dynamic>> toSqlite(Transaction input,
          {required provider,
          covariant OfflineFirstWithSupabaseRepository? repository}) async =>
      await _$TransactionToSqlite(input,
          provider: provider, repository: repository);
}
