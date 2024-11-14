import 'package:brick_offline_first_with_supabase/brick_offline_first_with_supabase.dart';
import 'package:brick_sqlite/brick_sqlite.dart';
import 'package:brick_supabase/brick_supabase.dart';
import 'package:uuid/uuid.dart';

@ConnectOfflineFirstWithSupabase(
  supabaseConfig: SupabaseSerializable(tableName: 'items'),
)

class Member extends OfflineFirstWithSupabaseModel {
  @Supabase(unique: true)
  @Sqlite(index: true, unique: true)
  final String id;

  late final String name;
  late int color;
  bool active = true;
  final DateTime timestamp;

  //Constructor
  Member({required this.name, required this.color, String? id, active, timestamp}) : this.id = id ?? const Uuid().v4(),
    this.active = active ?? true,
    this.timestamp = timestamp ?? DateTime.now();
}