import 'dart:ui';
import 'package:splizz/Models/transaction.dart';

class Member{
  //Private Variables
  final int? _id;
  late final String _name;
  late double _total = 0;
  late double _balance = 0;
  late Color _color;
  late List<Transaction> _history = [];

//Getter
  int? get id => _id;
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
  Member(this._name, this._color, {id, total, balance, history}): _id=id{
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

  factory Member.fromMember(Member m){
    return Member(
        m.name,
        m.color,
        id: m.id,
        total: m.total,
        balance: m.balance,
        history: m.history
    );
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

  factory Member.fromJson(Map<String, dynamic> data){
    final historyData = data['history'] as List<dynamic>;
    return Member(
        data['name'],
        Color(data['color']),
        id: data['id'],
        total: data['total'],
        balance: data['balance'],
        history: historyData.map((d) => Transaction.fromJson(d)).toList()
    );
  }

  Map<String, dynamic> toJson() => {
      'id': id,
      'name': name,
      'total': total,
      'balance': balance,
      'history': history.map((transaction) => transaction.toJson()).toList(),
      'color': color.value};
}