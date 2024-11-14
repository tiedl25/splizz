import 'package:brick_offline_first_with_supabase/brick_offline_first_with_supabase.dart';
import 'package:brick_sqlite/brick_sqlite.dart';
import 'package:brick_supabase/brick_supabase.dart';
import 'package:uuid/uuid.dart';

@ConnectOfflineFirstWithSupabase(
  supabaseConfig: SupabaseSerializable(tableName: 'items'),
)

class Operation extends OfflineFirstWithSupabaseModel{
  @Supabase(unique: true)
  @Sqlite(index: true, unique: true)
  final String id;

  String? itemId;
  String? memberId;
  String? transactionId;
  late double value;
  final DateTime timestamp;

  //Constructor
  Operation(this.value, {String? id, this.itemId, this.memberId, this.transactionId, DateTime? timestamp}) : 
  this.id = id ?? const Uuid().v4(),
  this.timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id,
    'itemId': itemId,
    'memberId': memberId,
    'transactionId': transactionId,
    'value': value,
  };

  factory Operation.fromMap(Map<String, dynamic> map) {
    return Operation(
      map['value'],
      id: map['id'],
      itemId: map['itemId'],
      memberId: map['memberId'],
      transactionId: map['transactionId'],
    );
  }
}