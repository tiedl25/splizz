import 'dart:typed_data';

import 'package:brick_offline_first_with_supabase/brick_offline_first_with_supabase.dart';
import 'package:brick_sqlite/brick_sqlite.dart';
import 'package:brick_supabase/brick_supabase.dart';
import 'package:uuid/uuid.dart';

@ConnectOfflineFirstWithSupabase(
  supabaseConfig: SupabaseSerializable(tableName: 'items'),
)

class Item extends OfflineFirstWithSupabaseModel {
  @Supabase(unique: true)
  @Sqlite(index: true, unique: true)
  final String id;

  final String name;
  Uint8List? image;
  final DateTime timestamp;

  //Constructor
  Item({required String? name, String? id, this.image, timestamp}) : 
    this.id = id ?? Uuid().v4(), 
    this.timestamp = timestamp ?? DateTime.now(),
    this.name = name ?? '';
}