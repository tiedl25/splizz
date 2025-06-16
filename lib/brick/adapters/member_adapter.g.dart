// GENERATED CODE DO NOT EDIT
part of '../brick.g.dart';

Future<Member> _$MemberFromSupabase(Map<String, dynamic> data,
    {required SupabaseProvider provider,
    OfflineFirstWithSupabaseRepository? repository}) async {
  return Member(
      id: data['id'] as String?,
      itemId: data['item_id'] == null ? null : data['item_id'] as String?,
      name: data['name'] as String,
      color: data['color'] as int,
      active: data['active'] as bool?,
      deleted: data['deleted'] as bool?,
      timestamp: data['timestamp'] == null
          ? null
          : DateTime.tryParse(data['timestamp'] as String));
}

Future<Map<String, dynamic>> _$MemberToSupabase(Member instance,
    {required SupabaseProvider provider,
    OfflineFirstWithSupabaseRepository? repository}) async {
  return {
    'id': instance.id,
    'item_id': instance.itemId,
    'name': instance.name,
    'color': instance.color,
    'active': instance.active,
    'deleted': instance.deleted,
    'timestamp': instance.timestamp.toIso8601String()
  };
}

Future<Member> _$MemberFromSqlite(Map<String, dynamic> data,
    {required SqliteProvider provider,
    OfflineFirstWithSupabaseRepository? repository}) async {
  return Member(
      id: data['id'] as String,
      itemId: data['item_id'] == null ? null : data['item_id'] as String?,
      name: data['name'] as String,
      color: data['color'] as int,
      active: data['active'] == 1,
      deleted: data['deleted'] == 1,
      timestamp: DateTime.parse(data['timestamp'] as String))
    ..primaryKey = data['_brick_id'] as int;
}

Future<Map<String, dynamic>> _$MemberToSqlite(Member instance,
    {required SqliteProvider provider,
    OfflineFirstWithSupabaseRepository? repository}) async {
  return {
    'id': instance.id,
    'item_id': instance.itemId,
    'name': instance.name,
    'color': instance.color,
    'active': instance.active ? 1 : 0,
    'deleted': instance.deleted ? 1 : 0,
    'timestamp': instance.timestamp.toIso8601String()
  };
}

/// Construct a [Member]
class MemberAdapter extends OfflineFirstWithSupabaseAdapter<Member> {
  MemberAdapter();

  @override
  final supabaseTableName = 'members';
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
    'name': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'name',
    ),
    'color': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'color',
    ),
    'active': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'active',
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
    'itemId': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'item_id',
      iterable: false,
      type: String,
    ),
    'name': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'name',
      iterable: false,
      type: String,
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
