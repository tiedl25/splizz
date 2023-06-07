import 'package:flutter/material.dart';
import 'package:splizz/Models/member.dart';
import 'package:splizz/Models/transaction.dart';

class Item{
  //Private Variables
  final int? _id;
  String _name;
  String _sharedId;
  bool _owner;
  List<Member> _members = [];
  List<Transaction> _history = [];

  //Getter
  int? get id => _id;
  String get name => _name;
  String get sharedId => _sharedId;
  bool get owner => _owner;
  List<Member> get members => _members;
  List<Transaction> get history => _history;

  //Setter
  set members(List<Member> members) {_members = members;}
  set history(List<Transaction> history) {_history = history;}
  set sharedId(String sharedId) {_sharedId = sharedId;}
  set owner(bool owner) {_owner = owner;}

  //Constructor
  Item(this._name, {id, sharedId='', owner=true, members, history}): _id=id, _sharedId=sharedId, _owner=owner {
    if(members!=null){
      _members=members;
    }
    if(history!=null){
      _history=history;
    }
  }

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

  void addTransaction(int associatedId, Transaction t){
    _members[associatedId].add(t);
    history.add(t);
    double val = t.value/_members.length;
    for(int i=0; i<_members.length; i++){
      _members[i].sub(val);
    }
  }

  void addPayoff(int associatedId, Transaction t){
    _members[associatedId].payoff(t);
    history.add(t);
  }

  void payoff(DateTime timestamp){
    for(Member e in _members){
      Transaction t = Transaction.payoff(-e.balance, memberId: e.id, timestamp: timestamp);
      history.add(t);
      e.payoff(t);
    }
  }

  Map<Member, List<Member>> calculatePayoff(){
    List<Member> payer = [];
    for(Member e in _members){
      Member a = Member.fromMember(e);
      a.compensate();
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
  
  void addMember(String name){
    _members.add(Member(name, colormap[id!]));
  }

  @override
  String toString() => 'Item(id: $id, name: $name)';

  Map<String, dynamic> toMap() => {
    'name': name,
    'id': id,
    'sharedId': sharedId,
    'owner': owner,
  };

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      map['name'],
      id: map['id'],
      sharedId: map['sharedId'],
      owner: map['owner'] == 1 ? true : false,
    );
  }

  factory Item.fromJson(Map<String, dynamic> data) {
    final historyData = data['history'] as List<dynamic>;
    final memberData = data['member'] as List<dynamic>;
    return Item(
        data['name'],
        owner: false,
        members: memberData.map((d) => Member.fromJson(d)).toList(),
        history: historyData.map((d) => Transaction.fromJson(d)).toList()
    );
  }

  factory Item.fromOld(Map<String, dynamic> data) {
    final historyData = data['history'] as List<dynamic>;
    final memberData = data['member'] as List<dynamic>;

    return Item(
        data['name'],
        members: memberData.map((d) => Member.fromOld(d)).toList(),
        history: historyData.map((d) => Transaction.fromOld(d)).toList()
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'id': id,
    'member': members.map((m) => m.toJson()).toList(),
    'history': history.map((transaction) => transaction.toJson()).toList()
  };
}