// GENERATED CODE DO NOT EDIT
part of '../brick.g.dart';

Future<Item> _$ItemFromSupabase(Map<String, dynamic> data,
    {required SupabaseProvider provider,
    OfflineFirstWithSupabaseRepository? repository}) async {
  return Item(
      id: data['id'] as String?,
      name: data['name'] as String?,
      owner: data['owner'] as bool);
}

Future<Map<String, dynamic>> _$ItemToSupabase(Item instance,
    {required SupabaseProvider provider,
    OfflineFirstWithSupabaseRepository? repository}) async {
  return {
    'id': instance.id,
    'name': instance.name,
    'owner': instance.owner,
    'timestamp': instance.timestamp.toIso8601String(),
    'members': await Future.wait<Map<String, dynamic>>(instance.members
        .map((s) => MemberAdapter()
            .toSupabase(s, provider: provider, repository: repository))
        .toList()),
    'history': await Future.wait<Map<String, dynamic>>(instance.history
        .map((s) => TransactionAdapter()
            .toSupabase(s, provider: provider, repository: repository))
        .toList())
  };
}

Future<Item> _$ItemFromSqlite(Map<String, dynamic> data,
    {required SqliteProvider provider,
    OfflineFirstWithSupabaseRepository? repository}) async {
  return Item(
      id: data['id'] as String,
      name: data['name'] as String,
      owner: data['owner'] == 1,
      timestamp: DateTime.parse(data['timestamp'] as String),
      members: (await provider.rawQuery(
              'SELECT DISTINCT `f_Member_brick_id` FROM `_brick_Item_members` WHERE l_Item_brick_id = ?',
              [
            data['_brick_id'] as int
          ]).then((results) {
        final ids = results.map((r) => r['f_Member_brick_id']);
        return Future.wait<Member>(ids.map((primaryKey) => repository!
            .getAssociation<Member>(
              Query.where('primaryKey', primaryKey, limit1: true),
            )
            .then((r) => r!.first)));
      }))
          .toList()
          .cast<Member>(),
      history: (await provider.rawQuery(
              'SELECT DISTINCT `f_Transaction_brick_id` FROM `_brick_Item_history` WHERE l_Item_brick_id = ?',
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

Future<Map<String, dynamic>> _$ItemToSqlite(Item instance,
    {required SqliteProvider provider,
    OfflineFirstWithSupabaseRepository? repository}) async {
  return {
    'id': instance.id,
    'name': instance.name,
    'owner': instance.owner ? 1 : 0,
    'timestamp': instance.timestamp.toIso8601String()
  };
}

/// Construct a [Item]
class ItemAdapter extends OfflineFirstWithSupabaseAdapter<Item> {
  ItemAdapter();

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
    'owner': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'owner',
    ),
    'timestamp': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'timestamp',
    ),
    'members': const RuntimeSupabaseColumnDefinition(
      association: true,
      columnName: 'members',
      associationType: Member,
      associationIsNullable: false,
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
    'owner': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'owner',
      iterable: false,
      type: bool,
    ),
    'timestamp': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'timestamp',
      iterable: false,
      type: DateTime,
    ),
    'members': const RuntimeSqliteColumnDefinition(
      association: true,
      columnName: 'members',
      iterable: true,
      type: Member,
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
      Item instance, DatabaseExecutor executor) async {
    final results = await executor.rawQuery('''
        SELECT * FROM `Item` WHERE id = ? LIMIT 1''', [instance.id]);

    // SQFlite returns [{}] when no results are found
    if (results.isEmpty || (results.length == 1 && results.first.isEmpty)) {
      return null;
    }

    return results.first['_brick_id'] as int;
  }

  @override
  final String tableName = 'Item';
  @override
  Future<void> afterSave(instance, {required provider, repository}) async {
    if (instance.primaryKey != null) {
      final membersOldColumns = await provider.rawQuery(
          'SELECT `f_Member_brick_id` FROM `_brick_Item_members` WHERE `l_Item_brick_id` = ?',
          [instance.primaryKey]);
      final membersOldIds =
          membersOldColumns.map((a) => a['f_Member_brick_id']);
      final membersNewIds =
          instance.members.map((s) => s.primaryKey).whereType<int>();
      final membersIdsToDelete =
          membersOldIds.where((id) => !membersNewIds.contains(id));

      await Future.wait<void>(membersIdsToDelete.map((id) async {
        return await provider.rawExecute(
            'DELETE FROM `_brick_Item_members` WHERE `l_Item_brick_id` = ? AND `f_Member_brick_id` = ?',
            [instance.primaryKey, id]).catchError((e) => null);
      }));

      await Future.wait<int?>(instance.members.map((s) async {
        final id = s.primaryKey ??
            await provider.upsert<Member>(s, repository: repository);
        return await provider.rawInsert(
            'INSERT OR IGNORE INTO `_brick_Item_members` (`l_Item_brick_id`, `f_Member_brick_id`) VALUES (?, ?)',
            [instance.primaryKey, id]);
      }));
    }

    if (instance.primaryKey != null) {
      final historyOldColumns = await provider.rawQuery(
          'SELECT `f_Transaction_brick_id` FROM `_brick_Item_history` WHERE `l_Item_brick_id` = ?',
          [instance.primaryKey]);
      final historyOldIds =
          historyOldColumns.map((a) => a['f_Transaction_brick_id']);
      final historyNewIds =
          instance.history.map((s) => s.primaryKey).whereType<int>();
      final historyIdsToDelete =
          historyOldIds.where((id) => !historyNewIds.contains(id));

      await Future.wait<void>(historyIdsToDelete.map((id) async {
        return await provider.rawExecute(
            'DELETE FROM `_brick_Item_history` WHERE `l_Item_brick_id` = ? AND `f_Transaction_brick_id` = ?',
            [instance.primaryKey, id]).catchError((e) => null);
      }));

      await Future.wait<int?>(instance.history.map((s) async {
        final id = s.primaryKey ??
            await provider.upsert<Transaction>(s, repository: repository);
        return await provider.rawInsert(
            'INSERT OR IGNORE INTO `_brick_Item_history` (`l_Item_brick_id`, `f_Transaction_brick_id`) VALUES (?, ?)',
            [instance.primaryKey, id]);
      }));
    }
  }

  @override
  Future<Item> fromSupabase(Map<String, dynamic> input,
          {required provider,
          covariant OfflineFirstWithSupabaseRepository? repository}) async =>
      await _$ItemFromSupabase(input,
          provider: provider, repository: repository);
  @override
  Future<Map<String, dynamic>> toSupabase(Item input,
          {required provider,
          covariant OfflineFirstWithSupabaseRepository? repository}) async =>
      await _$ItemToSupabase(input, provider: provider, repository: repository);
  @override
  Future<Item> fromSqlite(Map<String, dynamic> input,
          {required provider,
          covariant OfflineFirstWithSupabaseRepository? repository}) async =>
      await _$ItemFromSqlite(input, provider: provider, repository: repository);
  @override
  Future<Map<String, dynamic>> toSqlite(Item input,
          {required provider,
          covariant OfflineFirstWithSupabaseRepository? repository}) async =>
      await _$ItemToSqlite(input, provider: provider, repository: repository);
}
