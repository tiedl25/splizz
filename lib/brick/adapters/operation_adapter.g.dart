// GENERATED CODE DO NOT EDIT
part of '../brick.g.dart';

Future<Operation> _$OperationFromSupabase(Map<String, dynamic> data,
    {required SupabaseProvider provider,
    OfflineFirstWithSupabaseRepository? repository}) async {
  return Operation(
      id: data['id'] as String?,
      itemId: data['item_id'] as String?,
      memberId: data['member_id'] as String?,
      transactionId: data['transaction_id'] as String?,
      value: data['value'].toDouble(),
      timestamp: data['timestamp'] == null
          ? null
          : DateTime.tryParse(data['timestamp'] as String));
}

Future<Map<String, dynamic>> _$OperationToSupabase(Operation instance,
    {required SupabaseProvider provider,
    OfflineFirstWithSupabaseRepository? repository}) async {
  return {
    'id': instance.id,
    'item_id': instance.itemId,
    'member_id': instance.memberId,
    'transaction_id': instance.transactionId,
    'value': instance.value,
    'timestamp': instance.timestamp.toIso8601String()
  };
}

Future<Operation> _$OperationFromSqlite(Map<String, dynamic> data,
    {required SqliteProvider provider,
    OfflineFirstWithSupabaseRepository? repository}) async {
  return Operation(
      id: data['id'] as String,
      itemId: data['item_id'] == null ? null : data['item_id'] as String?,
      memberId: data['member_id'] == null ? null : data['member_id'] as String?,
      transactionId: data['transaction_id'] == null
          ? null
          : data['transaction_id'] as String?,
      value: data['value'] as double,
      timestamp: DateTime.parse(data['timestamp'] as String))
    ..primaryKey = data['_brick_id'] as int;
}

Future<Map<String, dynamic>> _$OperationToSqlite(Operation instance,
    {required SqliteProvider provider,
    OfflineFirstWithSupabaseRepository? repository}) async {
  return {
    'id': instance.id,
    'item_id': instance.itemId,
    'member_id': instance.memberId,
    'transaction_id': instance.transactionId,
    'value': instance.value,
    'timestamp': instance.timestamp.toIso8601String()
  };
}

/// Construct a [Operation]
class OperationAdapter extends OfflineFirstWithSupabaseAdapter<Operation> {
  OperationAdapter();

  @override
  final supabaseTableName = 'operations';
  @override
  final defaultToNull = true;
  @override
  final fieldsToSupabaseColumns = {
    'id': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'id',
    ),
    'itemId': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'item_id',
    ),
    'memberId': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'member_id',
    ),
    'transactionId': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'transaction_id',
    ),
    'value': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'value',
    ),
    'timestamp': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'timestamp',
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
    'itemId': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'item_id',
      iterable: false,
      type: String,
    ),
    'memberId': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'member_id',
      iterable: false,
      type: String,
    ),
    'transactionId': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'transaction_id',
      iterable: false,
      type: String,
    ),
    'value': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'value',
      iterable: false,
      type: double,
    ),
    'timestamp': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'timestamp',
      iterable: false,
      type: DateTime,
    )
  };
  @override
  Future<int?> primaryKeyByUniqueColumns(
      Operation instance, DatabaseExecutor executor) async {
    final results = await executor.rawQuery('''
        SELECT * FROM `Operation` WHERE id = ? LIMIT 1''', [instance.id]);

    // SQFlite returns [{}] when no results are found
    if (results.isEmpty || (results.length == 1 && results.first.isEmpty)) {
      return null;
    }

    return results.first['_brick_id'] as int;
  }

  @override
  final String tableName = 'Operation';

  @override
  Future<Operation> fromSupabase(Map<String, dynamic> input,
          {required provider,
          covariant OfflineFirstWithSupabaseRepository? repository}) async =>
      await _$OperationFromSupabase(input,
          provider: provider, repository: repository);
  @override
  Future<Map<String, dynamic>> toSupabase(Operation input,
          {required provider,
          covariant OfflineFirstWithSupabaseRepository? repository}) async =>
      await _$OperationToSupabase(input,
          provider: provider, repository: repository);
  @override
  Future<Operation> fromSqlite(Map<String, dynamic> input,
          {required provider,
          covariant OfflineFirstWithSupabaseRepository? repository}) async =>
      await _$OperationFromSqlite(input,
          provider: provider, repository: repository);
  @override
  Future<Map<String, dynamic>> toSqlite(Operation input,
          {required provider,
          covariant OfflineFirstWithSupabaseRepository? repository}) async =>
      await _$OperationToSqlite(input,
          provider: provider, repository: repository);
}
