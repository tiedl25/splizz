import 'package:uuid/uuid.dart';
import 'package:splizz/models/operation.model.dart';

class Transaction{
  final String id;

  String? memberId;
  String? itemId;
  String description;
  DateTime date;
  String? payoffId;
  double value;
  bool deleted = false;
  final DateTime timestamp;
  late List<Operation> operations;

  //Constructor
  Transaction({required this.description, required this.value, required this.date, String? id, this.memberId, this.itemId, this.payoffId, DateTime? timestamp, deleted, operations}) : 
    this.id = id ?? Uuid().v4(),
    this.timestamp = timestamp ?? DateTime.now(),
    this.deleted = deleted ?? false,
    this.operations = operations ?? [];

  Transaction.copy(Transaction transaction) : this(
    description: transaction.description,
    value: transaction.value,
    date: transaction.date,
    id: transaction.id,
    timestamp: transaction.timestamp,
    deleted: transaction.deleted,
    operations: transaction.operations.toList(
      growable: true,
    ),
    memberId: transaction.memberId,
    itemId: transaction.itemId,
    payoffId: transaction.payoffId,
  );

  factory Transaction.payoff({date, id, timestamp, operations}){
    return Transaction(
      description: 'payoff',
      value: 0.0,
      date: date ?? timestamp,
      id: id,
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

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      description: map['description'],
      value: map['value'],
      date: DateTime.parse(map['date']),
      memberId: map['member_id'],
      itemId: map['item_id'],
      payoffId: map['payoff_id'],
      deleted: map['deleted'] == 1,
      id: map['id'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'value': value,
      'date': date.toString(),
      'member_id': memberId,
      'item_id': itemId,
      'payoff_id': payoffId,
      'deleted': deleted ? 1 : 0,
      'timestamp': timestamp.toString(),
      'id': id,
    };
  }
}