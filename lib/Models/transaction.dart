import 'operation.dart';

class Transaction{
  //Private Variables
  final int? id;
  int? memberId;
  int? itemId;
  late String description;
  late DateTime timestamp;
  late DateTime date;
  late double value;
  bool deleted = false;
  late List<Operation> operations;

  //Constructor
  Transaction(this.description, this.value, this.date, {this.id, this.memberId, this.itemId, timestamp, deleted, operations}){
    if (timestamp == null){
      this.timestamp = DateTime.now();
    }
    else {
      this.timestamp = timestamp;
    }
    if (deleted == null) {
      this.deleted = false;
    } else {
      this.deleted = deleted;
    }
    if (operations == null){
      this.operations = [];
    } else {
      this.operations = operations;
    }
  }

  factory Transaction.payoff({date, id, timestamp, operations}){
    return Transaction(
      'payoff',
      0.0,
      date ?? timestamp,
      id: id,
      memberId: -1,
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

  Map<String, dynamic> toJson() => {
    'memberId': memberId,
    'itemId': itemId,
    'description': description,
    'timestamp': timestamp.toString(),
    'value': value,
    'date': date.toString(),
    'deleted': deleted,
    'operations': operations.map((operation) => operation.toJson()).toList(),
  };

  factory Transaction.fromJson(Map<String, dynamic> data) {
    final operationsData = data['operations'] as List<dynamic>;
    return Transaction(
        data['description'],
        data['value'],
        DateTime.parse(data['date']),
        memberId: data['memberId'],
        itemId: data['itemId'],
        timestamp: DateTime.parse(data['timestamp']),
        deleted: data['deleted'],
        operations: operationsData.map((d) => Operation.fromJson(d)).toList(),
    );
  }
}