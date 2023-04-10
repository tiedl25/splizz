import 'dart:ui';

import 'package:splizz/Models/transaction.dart';

import 'item.dart';

class ShortMember{
  int _id = 0;
  String name = '';

  int get id => _id;

  ShortMember(this.name, this._id);

  ShortMember.fromJson(Map<String, dynamic> data) {
    _id = data['id'];
    name = data['name'];
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
  late Color color;
  late List<Transaction> history = [];

  void add(Transaction t){
    history.add(t);

    total += t.value;
    balance += t.value;
  }

  void sub(double d){
    balance -= d;
  }

  Member(String name, int id, this.color) : super(name, id);

  Member.fromMember(Member m) : super.fromMember(m){
    total = m.total;
    balance = m.balance;
    color = m.color;
    history = m.history;
  }

  Member.fromJson(Map<String, dynamic> data) : super.fromJson(data){
    final historyData = data['history'] as List<dynamic>;

    total = data['total'];
    balance = data['balance'];
    history = historyData.map((d) => Transaction.fromJson(d)).toList();
    color = Color(data['color']);

  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> su = super.toJson();
    su.addAll({
      'total': total,
      'balance': balance,
      'history': history.map((transaction) => transaction.toJson()).toList(),
      'color': color.value});
    return su;
  }
}