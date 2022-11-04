import 'package:flutter/material.dart';
import 'package:splizz/member.dart';
import 'package:splizz/transaction.dart';

class Item{
  late String name;
  late final int _id;
  List<Member> _member = [];

  List<Member> get member => _member;
  List<Transaction> history = [];

  int get id => _id;

  static int _counter = 0;

  static List<Color> colormap = [
    Colors.blue.shade300,
    Colors.red.shade300,
    Colors.green.shade300,
    Colors.yellow.shade300,
    Colors.orange.shade300,
    Colors.purple.shade300,
    Colors.pink.shade300,
    Colors.grey.shade300,
    Colors.teal.shade300,
    Colors.amber.shade300,
    Colors.indigo.shade300,
    Colors.lime.shade300,
  ];

  void addTransaction(Member m, Transaction t){
    _member[m.id].add(t);
    history.add(t);
    for(int i=0; i<_member.length; i++){
      _member[i].sub(t.value/_member.length);
    }
  }
  
  void addMember(String name){
    _member.add(Member(name, id, colormap[id]));
  }

  void setCounter(value){
    _counter = value;
  }

  Item(this.name, this._member){
    _id = _counter;
    _counter++;
  }

  Item.fromJson(Map<String, dynamic> data) {
    final historyData = data['history'] as List<dynamic>;
    final memberData = data['member'] as List<dynamic>;

    name = data['name'];
    _member = memberData.map((d) => Member.fromJson(d)).toList();
    _id = data['id'];
    history = historyData.map((d) => Transaction.fromJson(d)).toList();
    _counter = _id >= _counter ? _id+1 : _counter;
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'id': _id,
    'member': _member.map((m) => m.toJson()).toList(),
    'history': history.map((transaction) => transaction.toJson()).toList()
  };
}