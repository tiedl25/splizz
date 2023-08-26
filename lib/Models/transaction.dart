import 'operation.dart';

class Transaction{
  //Private Variables
  final int? _id;
  int? memberId;
  late String _description;
  late DateTime _timestamp;
  late double _value;
  bool _deleted = false;
  late List<Operation> operations;

  //Getter
  int? get id => _id;
  String get description => _description;
  DateTime get timestamp => _timestamp;
  double get value => _value;
  bool get deleted => _deleted;

  //Constructor
  Transaction(this._description, this._value, {id, this.memberId, timestamp, deleted, operations}): _id=id{
    if (timestamp == null){
      _timestamp = DateTime.now();
    }
    else {
      _timestamp = timestamp;
    }
    if (deleted == null) {
      _deleted = false;
    } else {
      _deleted = deleted;
    }
    if (operations == null){
      this.operations = [];
    } else {
      this.operations = operations;
    }
  }

  factory Transaction.payoff(value, {id, memberId, timestamp, operations}){
    return Transaction(
      'payoff',
      value,
      id: id,
      memberId: memberId,
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
  String date(){
    return '${_timestamp.day}.${_timestamp.month}.${_timestamp.year}';
  }

  void delete(){
    _deleted = true;
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'description': description,
    'memberId': memberId,
    'timestamp': timestamp.toString(),
    'value': value,
    'deleted': deleted
  };

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      map['description'],
      map['value'],
      id: map['id'],
      memberId: map['memberId'],
      timestamp: DateTime.parse(map['timestamp']),
      deleted: map['deleted'] == 1 ? true : false
    );
  }

  Map<String, dynamic> toJson() => {
    'memberId': memberId,
    'description': description,
    'timestamp': '$timestamp',
    'value': value,
    'deleted': deleted,
    'operations': operations.map((operation) => operation.toJson()).toList(),
  };

  factory Transaction.fromJson(Map<String, dynamic> data) {
    final operationsData = data['operations'] as List<dynamic>;
    return Transaction(
        data['description'],
        data['value'],
        memberId: data['memberId'],
        timestamp: DateTime.parse(data['timestamp']),
        deleted: data['deleted'],
        operations: operationsData.map((d) => Operation.fromJson(d)).toList(),
    );
  }
}