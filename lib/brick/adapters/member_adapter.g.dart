// GENERATED CODE DO NOT EDIT
part of '../brick.g.dart';

Future<Member> _$MemberFromSupabase(Map<String, dynamic> data,
    {required SupabaseProvider provider,
    OfflineFirstWithSupabaseRepository? repository}) async {
  return Member(
      id: data['id'] as String?,
      name: data['name'] as String,
      total: data['total'] as double?,
      balance: data['balance'] as double?,
      color: data['color'] as int);
}

Future<Map<String, dynamic>> _$MemberToSupabase(Member instance,
    {required SupabaseProvider provider,
    OfflineFirstWithSupabaseRepository? repository}) async {
  return {
    'id': instance.id,
    'name': instance.name,
    'total': instance.total,
    'balance': instance.balance,
    'color': instance.color,
    'active': instance.active,
    'timestamp': instance.timestamp.toIso8601String(),
    'history': await Future.wait<Map<String, dynamic>>(instance.history
        .map((s) => TransactionAdapter()
            .toSupabase(s, provider: provider, repository: repository))
        .toList())
  };
}

Future<Member> _$MemberFromSqlite(Map<String, dynamic> data,
    {required SqliteProvider provider,
    OfflineFirstWithSupabaseRepository? repository}) async {
  return Member(
      id: data['id'] as String,
      name: data['name'] as String,
      total: data['total'] as double,
      balance: data['balance'] as double,
      color: data['color'] as int,
      active: data['active'] == 1,
      timestamp: DateTime.parse(data['timestamp'] as String),
      history: (await provider.rawQuery(
              'SELECT DISTINCT `f_Transaction_brick_id` FROM `_brick_Member_history` WHERE l_Member_brick_id = ?',
              [data['_brick_id'] as int]).then((results) {
        final ids = results.map((r) => r['f_Transaction_brick_id']);
        return Future.wait<Transaction>(ids.map((primaryKey) => repository!
            .getAssociation<Transaction>(
              Query.where('primaryKey', primaryKey, limit1: true),
            )
            .then((r) => r!.first)));
      }))
          .toList()
          .cast<Transaction>())
    ..primaryKey = data['_brick_id'] as int;
}

Future<Map<String, dynamic>> _$MemberToSqlite(Member instance,
    {required SqliteProvider provider,
    OfflineFirstWithSupabaseRepository? repository}) async {
  return {
    'id': instance.id,
    'name': instance.name,
    'total': instance.total,
    'balance': instance.balance,
    'color': instance.color,
    'active': instance.active ? 1 : 0,
    'timestamp': instance.timestamp.toIso8601String()
  };
}

/// Construct a [Member]
class MemberAdapter extends OfflineFirstWithSupabaseAdapter<Member> {
  MemberAdapter();

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
    'name': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'name',
    ),
    'total': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'total',
    ),
    'balance': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'balance',
    ),
    'color': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'color',
    ),
    'active': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'active',
    ),
    'timestamp': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'timestamp',
    ),
    'history': const RuntimeSupabaseColumnDefinition(
      association: true,
      columnName: 'history',
      associationType: Transaction,
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
    'name': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'name',
      iterable: false,
      type: String,
    ),
    'total': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'total',
      iterable: false,
      type: double,
    ),
    'balance': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'balance',
      iterable: false,
      type: double,
    ),
    'color': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'color',
      iterable: false,
      type: int,
    ),
    'active': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'active',
      iterable: false,
      type: bool,
    ),
    'timestamp': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'timestamp',
      iterable: false,
      type: DateTime,
    ),
    'history': const RuntimeSqliteColumnDefinition(
      association: true,
      columnName: 'history',
      iterable: true,
      type: Transaction,
    )
  };
  @override
  Future<int?> primaryKeyByUniqueColumns(
      Member instance, DatabaseExecutor executor) async {
    final results = await executor.rawQuery('''
        SELECT * FROM `Member` WHERE id = ? LIMIT 1''', [instance.id]);

    // SQFlite returns [{}] when no results are found
    if (results.isEmpty || (results.length == 1 && results.first.isEmpty)) {
      return null;
    }

    return results.first['_brick_id'] as int;
  }

  @override
  final String tableName = 'Member';
  @override
  Future<void> afterSave(instance, {required provider, repository}) async {
    if (instance.primaryKey != null) {
      final historyOldColumns = await provider.rawQuery(
          'SELECT `f_Transaction_brick_id` FROM `_brick_Member_history` WHERE `l_Member_brick_id` = ?',
          [instance.primaryKey]);
      final historyOldIds =
          historyOldColumns.map((a) => a['f_Transaction_brick_id']);
      final historyNewIds =
          instance.history.map((s) => s.primaryKey).whereType<int>();
      final historyIdsToDelete =
          historyOldIds.where((id) => !historyNewIds.contains(id));

      await Future.wait<void>(historyIdsToDelete.map((id) async {
        return await provider.rawExecute(
            'DELETE FROM `_brick_Member_history` WHERE `l_Member_brick_id` = ? AND `f_Transaction_brick_id` = ?',
            [instance.primaryKey, id]).catchError((e) => null);
      }));

      await Future.wait<int?>(instance.history.map((s) async {
        final id = s.primaryKey ??
            await provider.upsert<Transaction>(s, repository: repository);
        return await provider.rawInsert(
            'INSERT OR IGNORE INTO `_brick_Member_history` (`l_Member_brick_id`, `f_Transaction_brick_id`) VALUES (?, ?)',
            [instance.primaryKey, id]);
      }));
    }
  }

  @override
  Future<Member> fromSupabase(Map<String, dynamic> input,
          {required provider,
          covariant OfflineFirstWithSupabaseRepository? repository}) async =>
      await _$MemberFromSupabase(input,
          provider: provider, repository: repository);
  @override
  Future<Map<String, dynamic>> toSupabase(Member input,
          {required provider,
          covariant OfflineFirstWithSupabaseRepository? repository}) async =>
      await _$MemberToSupabase(input,
          provider: provider, repository: repository);
  @override
  Future<Member> fromSqlite(Map<String, dynamic> input,
          {required provider,
          covariant OfflineFirstWithSupabaseRepository? repository}) async =>
      await _$MemberFromSqlite(input,
          provider: provider, repository: repository);
  @override
  Future<Map<String, dynamic>> toSqlite(Member input,
          {required provider,
          covariant OfflineFirstWithSupabaseRepository? repository}) async =>
      await _$MemberToSqlite(input, provider: provider, repository: repository);
}
