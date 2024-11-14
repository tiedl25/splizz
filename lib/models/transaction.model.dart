import 'package:brick_offline_first_with_supabase/brick_offline_first_with_supabase.dart';
import 'package:brick_sqlite/brick_sqlite.dart';
import 'package:brick_supabase/brick_supabase.dart';
import 'package:uuid/uuid.dart';

import 'package:splizz/models/operation.model.dart';

@ConnectOfflineFirstWithSupabase(
  supabaseConfig: SupabaseSerializable(tableName: 'items'),
)

class Transaction extends OfflineFirstWithSupabaseModel {
  @Supabase(unique: true)
  @Sqlite(index: true, unique: true)
  final String id;

  String? memberId;
  String? itemId;
  late String description;
  late DateTime date;
  late double value;
  bool deleted = false;
  final DateTime timestamp;
  
  late List<Operation> operations;

  //Constructor
  Transaction(this.description, this.value, this.date, {String? id, this.memberId, this.itemId, DateTime? timestamp, deleted, operations}) : 
    this.id = id ?? Uuid().v4(),
    this.timestamp = timestamp ?? DateTime.now(),
    this.deleted = deleted ?? false,
    this.operations = operations ?? [];

  factory Transaction.payoff({date, id, timestamp, operations}){
    return Transaction(
      'payoff',
      0.0,
      date ?? timestamp,
      id: id,
      memberId: "",
      timestamp: timestamp,
      operations: operations,
    );
  }

  //Operator
  @override
  bool operator ==(dynamic other) =>
      other.description == description &&
      other.timestamp == timestamp &&
      other.value == value &&
      other.deleted == deleted;

  bool isSimilar(dynamic other) =>
      other.description == description &&
      other.timestamp == timestamp &&
      other.value == value &&
      other.deleted != deleted;

  //Methods
  String formatDate(){
    return '${date.day}.${date.month}.${date.year}';
  }

  void delete(){
    deleted = true;
  }

  void restore(){
    deleted = false;
  }

  void addOperation(Operation operation){
    operations.add(operation);
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'description': description,
    'memberId': memberId,
    'itemId': itemId,
    'timestamp': timestamp.toString(),
    'value': value,
    'deleted': deleted ? 1 : 0,
    'date': date.toString()
  };

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      map['description'],
      map['value'],
      DateTime.parse(map['date']),
      id: map['id'],
      memberId: map['memberId'],
      itemId: map['itemId'],
      timestamp: DateTime.parse(map['timestamp']),
      deleted: map['deleted'] == 1 ? true : false
    );
  }
}