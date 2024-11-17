import 'package:brick_offline_first_with_supabase/brick_offline_first_with_supabase.dart';
import 'package:brick_sqlite/brick_sqlite.dart';
import 'package:brick_supabase/brick_supabase.dart';
import 'package:uuid/uuid.dart';


@ConnectOfflineFirstWithSupabase(
  supabaseConfig: SupabaseSerializable(tableName: 'operations'),
)

class Operation extends OfflineFirstWithSupabaseModel{
  @Supabase(unique: true)
  @Sqlite(index: true, unique: true)
  final String id;

  String? itemId;
  String? memberId;
  String? transactionId;

  @Supabase(fromGenerator: "%DATA_PROPERTY%.toDouble()")
  final double value;
  
  final DateTime timestamp;

  //Constructor
  Operation({required this.value, String? id, this.itemId, this.memberId, this.transactionId, DateTime? timestamp}) : 
    this.id = id ?? const Uuid().v4(),
    this.timestamp = timestamp ?? DateTime.now();
}