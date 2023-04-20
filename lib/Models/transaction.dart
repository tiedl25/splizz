class Transaction{
  //Private Variables
  int? id;
  int? memberId;
  late String _description;
  late DateTime _timestamp;
  late double _value;

  //Getter
  String get description => _description;
  DateTime get timestamp => _timestamp;
  double get value => _value;

  Transaction(this._description, this._value, {this.id, this.memberId, timestamp}){
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
      map['description'],
      map['value'],
      id: map['id'],
      memberId: map['memberId'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }

  Transaction.fromJson(Map<String, dynamic> data) {
    id = data['id'];
    memberId = data['associated'];
    _description = data['description'];
    _timestamp = DateTime.parse(data['_timestamp']);
    _value = data['value'];
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'associated': memberId,
    'description': description,
    '_timestamp': '$_timestamp',
    'value': value
  };


}