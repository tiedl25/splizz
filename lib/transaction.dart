import 'member.dart';

class Transaction{
  late final int _id;
  late final ShortMember associated;
  late String description;
  late DateTime _timestamp;
  late double value;

  int get id => _id;

  static int _counter = 0;

  Transaction(this.associated, this.description, this.value){
    _id = _counter;
    _counter++;
    _timestamp = DateTime.now();
  }

  String date(){
    return '${_timestamp.day}.${_timestamp.month}.${_timestamp.year}';
  }

  Transaction.fromJson(Map<String, dynamic> data) {
    _id = data['id'];
    associated = ShortMember.fromJson(data['associated']);
    description = data['description'];
    _timestamp = DateTime.parse(data['_timestamp']);
    value = data['value'];
    _counter = _id >= _counter ? _id+1 : _counter;
  }

  Map<String, dynamic> toJson() => {
    'id': _id,
    'associated': associated.toJson(),
    'description': description,
    '_timestamp': '$_timestamp',
    'value': value
  };
}