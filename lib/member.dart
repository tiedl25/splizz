import 'package:splizz/transaction.dart';

class ShortMember{
  late final int _id;
  String name = '';
  static int _counter = 0;

  int get id => _id;

  ShortMember(this.name){
    _id = _counter;
    _counter++;
  }

  ShortMember.fromJson(Map<String, dynamic> data) {
    _id = data['id'];
    name = data['name'];

    _counter = _id >= _counter ? _id+1 : _counter;
  }

  ShortMember.fromMember(Member m){
    name = m.name;
    _id = m.id;
  }

  Map<String, dynamic> toJson() => {
    'id': _id,
    'name': name,
  };
}

class Member extends ShortMember{
  double total = 0;
  double balance = 0;
  late List<Transaction> history = [];

  void add(Transaction t){
    history.add(t);

    total += t.value;
    balance += t.value;
  }

  void sub(double d){
    balance -= d;
  }

  Member(String name) : super(name);

  Member.fromJson(Map<String, dynamic> data) : super.fromJson(data){
    final historyData = data['history'] as List<dynamic>;

    total = data['total'];
    balance = data['balance'];
    history = historyData.map((d) => Transaction.fromJson(d)).toList();
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> su = super.toJson();
    su.addAll({
      'total': total,
      'balance': balance,
      'history': history.map((transaction) => transaction.toJson()).toList()});
    return su;
  }
}