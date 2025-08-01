// GENERATED CODE DO NOT EDIT
part of '../brick.g.dart';

Future<Transaction> _$TransactionFromSupabase(Map<String, dynamic> data,
    {required SupabaseProvider provider,
    OfflineFirstWithSupabaseRepository? repository}) async {
  return Transaction(
      id: data['id'] as String?,
      memberId: data['member_id'] == null ? null : data['member_id'] as String?,
      itemId: data['item_id'] == null ? null : data['item_id'] as String?,
      description: data['description'] as String,
      date: DateTime.parse(data['date'] as String),
      payoffId: data['payoff_id'] == null ? null : data['payoff_id'] as String?,
      value: data['value'].toDouble(),
      deleted: data['deleted'],
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
    'payoff_id': instance.payoffId,
    'value': instance.value,
    'deleted': instance.deleted,
    'timestamp': instance.timestamp.toIso8601String()
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
      payoffId: data['payoff_id'] == null ? null : data['payoff_id'] as String?,
      value: data['value'] as double,
      deleted: data['deleted'] == 1,
      timestamp: DateTime.parse(data['timestamp'] as String))
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
    'payoff_id': instance.payoffId,
    'value': instance.value,
    'deleted': instance.deleted ? 1 : 0,
    'timestamp': instance.timestamp.toIso8601String()
  };
}

/// Construct a [Transaction]
class TransactionAdapter extends OfflineFirstWithSupabaseAdapter<Transaction> {
  TransactionAdapter();

  @override
  final supabaseTableName = 'transactions';
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
    'payoffId': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'payoff_id',
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
    'payoffId': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'payoff_id',
      iterable: false,
      type: String,
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
