// ignore: unused_import, unused_shown_name, unnecessary_import
import 'package:brick_core/query.dart';
// ignore: unused_import, unused_shown_name, unnecessary_import
import 'package:brick_sqlite/db.dart';
// ignore: unused_import, unused_shown_name, unnecessary_import
import 'package:brick_offline_first_with_supabase/brick_offline_first_with_supabase.dart';
// ignore: unused_import, unused_shown_name, unnecessary_import
import 'package:brick_sqlite/brick_sqlite.dart';
// ignore: unused_import, unused_shown_name, unnecessary_import
import 'package:brick_supabase/brick_supabase.dart';
// ignore: unused_import, unused_shown_name, unnecessary_import
import 'package:uuid/uuid.dart';
// ignore: unused_import, unused_shown_name, unnecessary_import
import 'package:splizz/models/operation.model.dart';
// ignore: unused_import, unused_shown_name, unnecessary_import
import 'package:splizz/models/transaction.model.dart';
// ignore: unused_import, unused_shown_name, unnecessary_import
import 'dart:typed_data';
// ignore: unused_import, unused_shown_name, unnecessary_import
import 'package:splizz/models/member.model.dart';
// ignore: unused_import, unused_shown_name, unnecessary_import
import 'package:supabase_flutter/supabase_flutter.dart' as Supabase_Flutter;// GENERATED CODE DO NOT EDIT
// ignore: unused_import
import 'dart:convert';
import 'package:brick_sqlite/brick_sqlite.dart' show SqliteModel, SqliteAdapter, SqliteModelDictionary, RuntimeSqliteColumnDefinition, SqliteProvider;
import 'package:brick_supabase/brick_supabase.dart' show SupabaseProvider, SupabaseModel, SupabaseAdapter, SupabaseModelDictionary;
// ignore: unused_import, unused_shown_name
import 'package:brick_offline_first/brick_offline_first.dart' show RuntimeOfflineFirstDefinition;
// ignore: unused_import, unused_shown_name
import 'package:sqflite_common/sqlite_api.dart' show DatabaseExecutor;

import '../models/user.model.dart';
import '../models/transaction.model.dart';
import '../models/member.model.dart';
import '../models/operation.model.dart';
import '../models/item.model.dart';

part 'adapters/user_adapter.g.dart';
part 'adapters/transaction_adapter.g.dart';
part 'adapters/member_adapter.g.dart';
part 'adapters/operation_adapter.g.dart';
part 'adapters/item_adapter.g.dart';

/// Supabase mappings should only be used when initializing a [SupabaseProvider]
final Map<Type, SupabaseAdapter<SupabaseModel>> supabaseMappings = {
  User: UserAdapter(),
  Transaction: TransactionAdapter(),
  Member: MemberAdapter(),
  Operation: OperationAdapter(),
  Item: ItemAdapter()
};
final supabaseModelDictionary = SupabaseModelDictionary(supabaseMappings);

/// Sqlite mappings should only be used when initializing a [SqliteProvider]
final Map<Type, SqliteAdapter<SqliteModel>> sqliteMappings = {
  User: UserAdapter(),
  Transaction: TransactionAdapter(),
  Member: MemberAdapter(),
  Operation: OperationAdapter(),
  Item: ItemAdapter()
};
final sqliteModelDictionary = SqliteModelDictionary(sqliteMappings);
