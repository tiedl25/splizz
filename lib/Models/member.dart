import 'dart:ui';
import 'package:splizz/Models/transaction.dart';

class Member{
  //Private Variables
  int? id;
  late final String _name;
  late double _total = 0;
  late double _balance = 0;
  late Color _color;
  late List<Transaction> _history = [];

//Getter
  String get name => _name;
  double get total => _total;
  double get balance => _balance;
  Color get color => _color;
  List<Transaction> get history => _history;

  //Setter
  set balance(double value) {
    _balance = value;
  }
  set history(List<Transaction> value) {
    _history = value;
  }

  //Constructor
  Member(this._name, this._color, {this.id, total, balance}){
    if (total==null) {
      _total=0;
    } else {
      _total=total.toDouble();
    }
    if (balance==null) {
      _balance=0;
    } else {
      _balance=balance.toDouble();
    }
  }
  Member.fromMember(Member m){
    _name = m.name;
    id = m.id;
    _total = m.total;
    _balance = m.balance;
    _color = m.color;
    _history = m.history;
  }

  //Methods

  void add(Transaction t){
    history.add(t);
    _total += t.value;
    _balance += t.value;
  }

  void sub(double d){
    _balance -= d;
  }

  void payoff(){
    _total = _balance;
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'color': color.value,
    'total': total,
    'balance': balance,
  };

  factory Member.fromMap(Map<String, dynamic> map) {
    return Member(
      map['name'],
      Color(map['color']),
      id: map['id'],
      total: map['total'],
      balance: map['balance'],
    );
  }

  Member.fromJson(Map<String, dynamic> data){
    final historyData = data['history'] as List<dynamic>;
    id = data['id'];
    _name = data['name'];
    _total = data['total'];
    _balance = data['balance'];
    _history = historyData.map((d) => Transaction.fromJson(d)).toList();
    _color = Color(data['color']);

  }

  Map<String, dynamic> toJson() => {
      'id': id,
      'name': name,
      'total': total,
      'balance': balance,
      'history': history.map((transaction) => transaction.toJson()).toList(),
      'color': color.value};
}