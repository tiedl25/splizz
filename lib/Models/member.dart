import 'dart:ui';
import 'package:splizz/Models/transaction.dart';

class Member{
  //Private Variables
  final int? id;
  late final String name;
  late double total = 0;
  late double balance = 0;
  late Color color;
  bool active = true;
  late DateTime timestamp;
  late List<Transaction> history = [];

  //Constructor
  Member(this.name, this.color, {this.id, total, balance, history, active, timestamp}){
    if (total==null) {
      this.total=0;
    } else {
      this.total=total.toDouble();
    }
    if (balance==null) {
      this.balance=0;
    } else {
      this.balance=balance.toDouble();
    }
    if (active==null) {
      this.active=true;
    } else {
      this.active=active;
    }
    if (history==null){
      this.history = [];
    } else {
      this.history = history;
    }
    if (timestamp == null){
      this.timestamp = DateTime.now();
    }
    else {
      this.timestamp = timestamp;
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
  void addTransaction(Transaction t, {balance=true}){
    history.add(t);
    total += t.value;
    if (balance) this.balance += t.value;
  }

  void pushTransaction(Transaction t){
    history.add(t);
  }

  void deleteTransaction(Transaction t, {balance=true}){
    total -= t.value;
    if (balance) this.balance -= t.value;
    history.firstWhere((e) => e.id == t.id).delete();
  }

  void add(double d){
    balance += d;
  }

  void sub(double d){
    balance -= d;
  }

  void compensate(){
    total = balance;
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'color': color.value,
    'total': total,
    'balance': balance,
    'active': active ? 1 : 0,
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