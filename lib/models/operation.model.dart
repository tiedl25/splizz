import 'package:uuid/uuid.dart';

class Operation{
  final String id;

  String? itemId;
  String? memberId;
  String? transactionId;

  double value;
  
  final DateTime timestamp;

  //Constructor
  Operation({required this.value, String? id, this.itemId, this.memberId, this.transactionId, DateTime? timestamp}) : 
    this.id = id ?? const Uuid().v4(),
    this.timestamp = timestamp ?? DateTime.now();

  Operation.copy(Operation operation) : this(
    value: operation.value,
    id: operation.id,
    itemId: operation.itemId,
    memberId: operation.memberId,
    transactionId: operation.transactionId,
    timestamp: operation.timestamp,
  );

  factory Operation.fromMap(Map<String, dynamic> map) {
    return Operation(
      id: map['id'],
      value: map['value'],
      itemId: map['item_id'],
      memberId: map['member_id'],
      transactionId: map['transaction_id'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'value': value,
      'item_id': itemId,
      'member_id': memberId,
      'transaction_id': transactionId,
      'timestamp': timestamp.toString(),
      'id': id,
    };
  }
}