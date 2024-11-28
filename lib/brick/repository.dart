// Saved in my_app/lib/src/brick/repository.dart

import 'package:brick_offline_first_with_supabase/brick_offline_first_with_supabase.dart';
import 'package:brick_sqlite/brick_sqlite.dart';
import 'package:brick_sqlite/memory_cache_provider.dart';
// This hide is for Brick's @Supabase annotation; in most cases,
// supabase_flutter **will not** be imported in application code.
import 'package:brick_supabase/brick_supabase.dart' hide Supabase;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:splizz/brick/db/schema.g.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'brick.g.dart';

class Repository extends OfflineFirstWithSupabaseRepository {
  static late Repository? _instance;

  static Repository get instance => _instance!;

  Repository._({
    required super.supabaseProvider,
    required super.sqliteProvider,
    required super.migrations,
    required super.offlineRequestQueue,
    super.memoryCacheProvider,
  });

  factory Repository() => _instance!;

  static Future<void> configure(DatabaseFactory databaseFactory) async {
    final cq = OfflineFirstWithSupabaseRepository.clientQueue(
      databaseFactory: databaseFactory,
    );

    final client = cq.$1;
    final queue = cq.$2;

    await dotenv.load(fileName: 'keys.env');

    await Supabase.initialize(
      url: dotenv.get('SUPABASE_URL'),
      anonKey: dotenv.get('SUPABASE_ANON_KEY'),
      httpClient: client,
    );

    final provider = SupabaseProvider(
      Supabase.instance.client,
      modelDictionary: supabaseModelDictionary,
    );

    _instance = Repository._(
      supabaseProvider: provider,
      sqliteProvider: SqliteProvider(
        'my_repository.sqlite',
        databaseFactory: databaseFactory,
        modelDictionary: sqliteModelDictionary,
      ),
      migrations: migrations,
      offlineRequestQueue: queue,
      // Specify class types that should be cached in memory
      memoryCacheProvider: MemoryCacheProvider(),
    );
  }
}
