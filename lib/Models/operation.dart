class Operation{
  //Private Variables
  final int? _id;
  int? itemId;
  int? memberId;
  int? transactionId;
  late double _value;

  //Getter
  int? get id => _id;
  double get value => _value;

  //Constructor
  Operation(this._value, {id, this.itemId, this.memberId, this.transactionId}): _id=id;

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

  Map<String, dynamic> toJson() => {
    'value': value,
    'memberId': memberId,
  };

  factory Operation.fromJson(Map<String, dynamic> data) {
    return Operation(
      data['value'],
      memberId: data['memberId'],
    );
  }
}