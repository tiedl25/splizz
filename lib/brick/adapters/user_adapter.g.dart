// GENERATED CODE DO NOT EDIT
part of '../brick.g.dart';

Future<User> _$UserFromSupabase(Map<String, dynamic> data,
    {required SupabaseProvider provider,
    OfflineFirstWithSupabaseRepository? repository}) async {
  return User(
      id: data['id'] as String?,
      itemId: data['item_id'] == null ? null : data['item_id'] as String?,
      userId: data['user_id'] == null ? null : data['user_id'] as String?,
      fullAccess: data['full_access'] as bool,
      userEmail:
          data['user_email'] == null ? null : data['user_email'] as String?,
      expirationDate: data['expiration_date'] == null
          ? null
          : data['expiration_date'] == null
              ? null
              : DateTime.tryParse(data['expiration_date'] as String));
}

Future<Map<String, dynamic>> _$UserToSupabase(User instance,
    {required SupabaseProvider provider,
    OfflineFirstWithSupabaseRepository? repository}) async {
  return {
    'id': instance.id,
    'item_id': instance.itemId,
    'user_id': instance.userId,
    'full_access': instance.fullAccess,
    'user_email': instance.userEmail,
    'expiration_date': instance.expirationDate?.toIso8601String()
  };
}

Future<User> _$UserFromSqlite(Map<String, dynamic> data,
    {required SqliteProvider provider,
    OfflineFirstWithSupabaseRepository? repository}) async {
  return User(
      id: data['id'] as String,
      itemId: data['item_id'] == null ? null : data['item_id'] as String?,
      userId: data['user_id'] == null ? null : data['user_id'] as String?,
      fullAccess: data['full_access'] == 1,
      userEmail:
          data['user_email'] == null ? null : data['user_email'] as String?,
      expirationDate: data['expiration_date'] == null
          ? null
          : data['expiration_date'] == null
              ? null
              : DateTime.tryParse(data['expiration_date'] as String))
    ..primaryKey = data['_brick_id'] as int;
}

Future<Map<String, dynamic>> _$UserToSqlite(User instance,
    {required SqliteProvider provider,
    OfflineFirstWithSupabaseRepository? repository}) async {
  return {
    'id': instance.id,
    'item_id': instance.itemId,
    'user_id': instance.userId,
    'full_access': instance.fullAccess ? 1 : 0,
    'user_email': instance.userEmail,
    'expiration_date': instance.expirationDate?.toIso8601String()
  };
}

/// Construct a [User]
class UserAdapter extends OfflineFirstWithSupabaseAdapter<User> {
  UserAdapter();

  @override
  final supabaseTableName = 'shared';
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
    'userId': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'user_id',
    ),
    'fullAccess': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'full_access',
    ),
    'userEmail': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'user_email',
    ),
    'expirationDate': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'expiration_date',
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
    'userId': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'user_id',
      iterable: false,
      type: String,
    ),
    'fullAccess': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'full_access',
      iterable: false,
      type: bool,
    ),
    'userEmail': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'user_email',
      iterable: false,
      type: String,
    ),
    'expirationDate': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'expiration_date',
      iterable: false,
      type: DateTime,
    )
  };
  @override
  Future<int?> primaryKeyByUniqueColumns(
      User instance, DatabaseExecutor executor) async {
    final results = await executor.rawQuery('''
        SELECT * FROM `User` WHERE id = ? LIMIT 1''', [instance.id]);

    // SQFlite returns [{}] when no results are found
    if (results.isEmpty || (results.length == 1 && results.first.isEmpty)) {
      return null;
    }

    return results.first['_brick_id'] as int;
  }

  @override
  final String tableName = 'User';

  @override
  Future<User> fromSupabase(Map<String, dynamic> input,
          {required provider,
          covariant OfflineFirstWithSupabaseRepository? repository}) async =>
      await _$UserFromSupabase(input,
          provider: provider, repository: repository);
  @override
  Future<Map<String, dynamic>> toSupabase(User input,
          {required provider,
          covariant OfflineFirstWithSupabaseRepository? repository}) async =>
      await _$UserToSupabase(input, provider: provider, repository: repository);
  @override
  Future<User> fromSqlite(Map<String, dynamic> input,
          {required provider,
          covariant OfflineFirstWithSupabaseRepository? repository}) async =>
      await _$UserFromSqlite(input, provider: provider, repository: repository);
  @override
  Future<Map<String, dynamic>> toSqlite(User input,
          {required provider,
          covariant OfflineFirstWithSupabaseRepository? repository}) async =>
      await _$UserToSqlite(input, provider: provider, repository: repository);
}
