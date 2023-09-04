import 'dart:typed_data';

import 'package:splizz/Models/member.dart';
import 'package:splizz/Models/transaction.dart';

import 'operation.dart';

class Item{
  //Private Variables
  final int? _id;
  String _name;
  String sharedId;
  String imageSharedId;
  bool owner;
  List<Member> members = [];
  List<Transaction> history = [];
  late DateTime _timestamp;
  Uint8List? image;

   //Getter
  int? get id => _id;
  String get name => _name;
  DateTime get timestamp => _timestamp;

  //Constructor
  Item(this._name, {id, this.sharedId='', this.owner=true, this.imageSharedId='', members, history, this.image, timestamp}): _id=id, _timestamp = timestamp ?? DateTime.now() {
    if(members!=null){
      this.members=members;
    }
    if(history!=null){
      this.history=history;
    }
  }

  // Add new transaction to history and member history, while also updating total and balance of all members
  void addTransaction(int associatedId, Transaction t, List<int> involvedMembers){
    members[associatedId].addTransaction(t);
    history.add(t);

    if(!t.deleted)
    {
      double val = t.value/involvedMembers.length;

      for(int i in involvedMembers){
        members[i].sub(val);
      }
    }
  }

  // Mark transaction as deleted, while also updating total and balance of all members
  void deleteTransaction(int associatedId, Transaction t){
    members[associatedId].deleteTransaction(t);

    for(Operation o in t.operations){
      // Todo
      //this.members[i].add(val);
    }
    t.delete();
  }

  void payoff(DateTime timestamp){
    Transaction t = Transaction.payoff(0.0, memberId: -1, timestamp: timestamp);
    history.add(t);
    for(Member e in members){
      e.payoff(t);
    }
  }

  Map<Member, List<Member>> calculatePayoff(){
    List<Member> payer = [];
    for(Member e in members){
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

  @override
  String toString() => 'Item(id: $id, name: $name)';

  Map<String, dynamic> toMap() => {
    'name': name,
    'id': id,
    'sharedId': sharedId,
    'imageSharedId': imageSharedId,
    'owner': owner,
    'image': image,
    'timestamp': timestamp.toString(),
  };

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      map['name'],
      id: map['id'],
      sharedId: map['sharedId'],
      imageSharedId: map['imageSharedId'],
      owner: map['owner'] == 1 ? true : false,
      image: map['image'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'member': members.map((m) => m.toJson()).toList(),
    'history': history.map((transaction) => transaction.toJson()).toList(),
    'timestamp': timestamp.toString(),
  };

  factory Item.fromJson(Map<String, dynamic> data) {
    final historyData = data['history'] as List<dynamic>;
    final memberData = data['member'] as List<dynamic>;
    return Item(
        data['name'],
        owner: false,
        members: memberData.map((d) => Member.fromJson(d)).toList(),
        history: historyData.map((d) => Transaction.fromJson(d)).toList(),
        timestamp: DateTime.parse(data['timestamp']),
    );
  }
}