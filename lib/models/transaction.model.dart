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
  String description;
  DateTime date;
  double value;
  bool deleted = false;
  final DateTime timestamp;

  late List<Operation> operations;

  //Constructor
  Transaction({required this.description, required this.value, required this.date, String? id, this.memberId, this.itemId, DateTime? timestamp, deleted, operations}) : 
    this.id = id ?? Uuid().v4(),
    this.timestamp = timestamp ?? DateTime.now(),
    this.deleted = deleted ?? false,
    this.operations = operations ?? [];

  factory Transaction.payoff({date, id, timestamp, operations}){
    return Transaction(
      description: 'payoff',
      value: 0.0,
      date: date ?? timestamp,
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
}