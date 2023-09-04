import 'dart:ui';
import 'package:splizz/Models/transaction.dart';

class Member{
  //Private Variables
  final int? id;
  late final String _name;
  late double _total = 0;
  late double _balance = 0;
  late Color _color;
  bool _active = true;
  late DateTime _timestamp;
  late List<Transaction> history = [];

//Getter
  String get name => _name;
  double get total => _total;
  double get balance => _balance;
  Color get color => _color;
  bool get active => _active;
  DateTime get timestamp => _timestamp;

  //Setter
  set balance(double value) {
    _balance = value;
  }

  set active(bool value) {
    _active = value;
  }

  //Constructor
  Member(this._name, this._color, {this.id, total, balance, history, active, timestamp}){
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
    if (active==null) {
      _active=true;
    } else {
      _active=active;
    }
    if (history==null){
      this.history = [];
    } else {
      this.history = history;
    }
    if (timestamp == null){
      _timestamp = DateTime.now();
    }
    else {
      _timestamp = timestamp;
    }
  }

  factory Member.fromMember(Member m, {name, color, id, total, balance, history, active, timestamp}){
    return Member(
        name ?? m.name,
        color ?? m.color,
        id: id ?? m.id,
        total: total ?? m.total,
        balance: balance ?? m.balance,
        history: history ?? m.history,
        active: active ?? m.active,
        timestamp: timestamp ?? m.timestamp
    );
  }

  @override
  bool operator ==(dynamic other) =>
      other.name == name &&
      other.timestamp == timestamp &&
      other.active == active &&
      other.color == color;

  //Methods
  void addTransaction(Transaction t){
    history.add(t);
    _total += t.value;
    _balance += t.value;
  }

  void pushTransaction(Transaction t){
    history.add(t);
  }

  void deleteTransaction(Transaction t){
    _total -= t.value;
    _balance -= t.value;
  }

  void add(double d){
    _balance += d;
  }

  void sub(double d){
    _balance -= d;
  }

  void payoff(Transaction t){
    history.add(t);
    _balance += t.value;
  }

  void compensate(){
    _total = _balance;
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'color': color.value,
    'total': total,
    'balance': balance,
    'active': active,
    'timestamp': timestamp.toString()
  };

  factory Member.fromMap(Map<String, dynamic> map) {
    return Member(
      map['name'],
      Color(map['color']),
      id: map['id'],
      total: map['total'],
      balance: map['balance'],
      active: map['active'] == 1 ? true : false,
      timestamp: DateTime.parse(map['timestamp'])
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'total': total,
    'balance': balance,
    'color': color.value,
    'active': active,
    'timestamp': timestamp.toString()
  };

  factory Member.fromJson(Map<String, dynamic> data){
    return Member(
        data['name'],
        Color(data['color']),
        total: data['total'],
        balance: data['balance'],
        active: data['active'],
        timestamp: DateTime.parse(data['timestamp'])
    );
  }
}