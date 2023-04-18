import 'package:flutter/material.dart';
import 'package:splizz/Models/member.dart';
import 'package:splizz/Models/transaction.dart';

class Item{
  late String name;
  late final int _id;
  List<Member> _members = [];

  List<Member> get member => _members;
  List<Transaction> history = [];

  int get id => _id;

  static int _counter = 0;

  static List<Color> colormap = [
    Colors.blue.shade400,
    Colors.red.shade400,
    Colors.green.shade400,
    Colors.yellow.shade400,
    Colors.orange.shade400,
    Colors.purple.shade400,
    Colors.pink.shade400,
    Colors.grey.shade400,
    Colors.teal.shade400,
    Colors.amber.shade400,
    Colors.indigo.shade400,
    Colors.lime.shade400,
  ];

  void addTransaction(Member m, Transaction t){
    _members[m.id].add(t);
    history.add(t);
    double val = t.value/_members.length;
    for(int i=0; i<_members.length; i++){
      _members[i].sub(val);
    }
  }

  Map<Member, List<Member>> calculatePayoff(){
    List<Member> payer = [];
    for(Member e in _members){
      Member a = Member.fromMember(e);
      a.total = a.balance;
      payer.add(a);
    }

    List<Member> positive = List.from(payer.where((element) => element.balance > 0));
    positive.sort((a,b) => a.balance.compareTo(b.balance));
    positive.reversed;
    List<Member> negative = List.from(payer.where((element) => element.balance < 0));
    negative.sort((a,b) => a.balance.compareTo(b.balance));
    negative.reversed;
    
    Map<Member, List<Member>> payMap = { for (var item in negative) item : [] };

    for(int a=0; a<positive.length; a++){
      for(int b=0; b<negative.length; b++){
        if(positive[a].balance > 0){
          double tmp = positive[a].balance;
          Member receiver = Member.fromMember(positive[a]);
          
          if(negative[b].balance.abs() >= positive[a].balance){
            positive[a].balance = 0;
            negative[b].balance += tmp;
          }else{
            receiver.balance = negative[b].balance;
            positive[a].balance += negative[b].balance;
            negative[b].balance = 0;
          }
          
          payMap[negative[b]]?.add(receiver);
        }

      }
      negative.sort((a,b) => a.balance.compareTo((b.balance)));
      negative.reversed;
    }
    return payMap;
  }
  
  void payoff(){
    for(Member e in _members){
      e.balance = 0;
    }
  }
  
  void addMember(String name){
    _members.add(Member(name, id, colormap[id]));
  }

  void setCounter(value){
    _counter = value;
  }

  Item(this.name, this._members){
    _id = _counter;
    _counter++;
  }

  Item.tmp(this.name, this._members);

  Item.fromJson(Map<String, dynamic> data) {
    final historyData = data['history'] as List<dynamic>;
    final memberData = data['member'] as List<dynamic>;

    name = data['name'];
    _members = memberData.map((d) => Member.fromJson(d)).toList();
    _id = data['id'];
    history = historyData.map((d) => Transaction.fromJson(d)).toList();
    _counter = _id >= _counter ? _id+1 : _counter;
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'id': _id,
    'member': _members.map((m) => m.toJson()).toList(),
    'history': history.map((transaction) => transaction.toJson()).toList()
  };
}