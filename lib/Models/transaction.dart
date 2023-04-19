class Transaction{
  int _id = 0;
  late final int _memberId;
  late String _description;
  late DateTime _timestamp;
  late double _value;

  int get id => _id;
  String get description => _description;
  DateTime get timestamp => _timestamp;
  double get value => _value;
  int get memberId => _memberId;

  Transaction(this._memberId, this._description, this._value, this._id, [timestamp]){
    if (timestamp == null){
      _timestamp = DateTime.now();
    }
    else {
      _timestamp = timestamp;
    }
  }

  String date(){
    return '${_timestamp.day}.${_timestamp.month}.${_timestamp.year}';
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'description': description,
    'memberId': memberId,
    'timestamp': timestamp.toString(),
    'value': value,
  };

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      map['memberId'],
      map['description'],
      map['value'],
      map['id'],
      DateTime.parse(map['timestamp']),
    );
  }

  Transaction.fromJson(Map<String, dynamic> data) {
    _id = data['id'];
    _memberId = data['associated'];
    _description = data['description'];
    _timestamp = DateTime.parse(data['_timestamp']);
    _value = data['value'];
  }

  Map<String, dynamic> toJson() => {
    'id': _id,
    'associated': memberId,
    'description': description,
    '_timestamp': '$_timestamp',
    'value': value
  };


}