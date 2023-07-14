class Transaction{
  //Private Variables
  final int? _id;
  int? _memberId;
  late String _description;
  late DateTime _timestamp;
  late double _value;
  bool _deleted = false;

  //Getter
  int? get id => _id;
  int? get memberId => _memberId;
  String get description => _description;
  DateTime get timestamp => _timestamp;
  double get value => _value;
  bool get deleted => _deleted;

  //Setter
  set memberId(int? memberId) {_memberId=memberId;}

  //Constructor
  Transaction(this._description, this._value, {id, memberId, timestamp, deleted}): _id=id, _memberId=memberId{
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
  }

  factory Transaction.payoff(value, {id, memberId, timestamp}){
    return Transaction(
      'payoff',
      value,
      id: id,
      memberId: memberId,
      timestamp: timestamp,
    );
  }

  void delete(){
    _deleted = true;
  }

  //Operator
  @override
  bool operator ==(dynamic other) =>
      other.description == description &&
          other.timestamp == timestamp &&
          other.value == value;

  String date(){
    return '${_timestamp.day}.${_timestamp.month}.${_timestamp.year}';
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

  factory Transaction.fromJson(Map<String, dynamic> data) {
    return Transaction(
        data['description'],
        data['value'],
        memberId: data['associated'],
        timestamp: DateTime.parse(data['timestamp']),
        deleted: data['deleted'] == 1 ? true : false
    );
  }

  factory Transaction.fromOld(Map<String, dynamic> data) {
    return Transaction(
      data['description'],
      data['value'],
      memberId: data['associated']['id'],
      timestamp: DateTime.parse(data['_timestamp']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'associated': memberId,
    'description': description,
    'timestamp': '$timestamp',
    'value': value,
    'deleted': deleted
  };
}