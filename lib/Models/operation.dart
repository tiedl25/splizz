class Operation{
  //Private Variables
  final int? id;
  int? itemId;
  int? memberId;
  int? transactionId;
  late double value;

  //Constructor
  Operation(this.value, {id, this.itemId, this.memberId, this.transactionId}): id=id;

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