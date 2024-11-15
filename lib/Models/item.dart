import 'dart:typed_data';

import 'package:splizz/Models/member.dart';
import 'package:splizz/Models/transaction.dart';
import 'package:splizz/Models/operation.dart';

class Item{
  //Private Variables
  final int? id;
  String name;
  String sharedId;
  String imageSharedId;
  bool owner;
  List<Member> members = [];
  List<Transaction> history = [];
  late DateTime timestamp;
  Uint8List? image;

  //Constructor
  Item(this.name, {id, this.sharedId='', this.owner=true, this.imageSharedId='', members, history, this.image, timestamp}): id=id, timestamp = timestamp ?? DateTime.now() {
    if(members!=null){
      this.members=members;
    }
    if(history!=null){
      this.history=history;
    }
  }

  Item.copy(Item item) : this(item.name, id: item.id, sharedId: item.sharedId, owner: item.owner, members: item.members, history: item.history, image: item.image, timestamp: item.timestamp);

  // Add new transaction to history and member history, while also updating total and balance of all members
  void addTransaction(int associatedId, Transaction t, List<Map<String, dynamic>> involvedMembers){
    members[associatedId].addTransaction(t);
    history.add(t);

    if(!t.deleted)
    {
      for(int i=0; i<involvedMembers.length; i++) {
        members[involvedMembers[i]['listId']].sub(involvedMembers[i]['balance']);
        t.addOperation(Operation(-involvedMembers[i]['balance'], memberId: involvedMembers[i]['id'], itemId: this.id));
      }

      t.addOperation(Operation(t.value, memberId: members[associatedId].id, itemId: this.id));
    }
  }

  void addTransactionFromDatabase(Transaction t, List<Member> transactionMembers){
    if (t.memberId != -1){
      if (!t.deleted){
        members.firstWhere((element) => element.id == t.memberId).addTransaction(t, balance: false);
      } else {
        members.firstWhere((element) => element.id == t.memberId).pushTransaction(t);
      }
    }
    
    //members[t.memberId!].addTransaction(t);
    history.add(t);

    for (Operation o in t.operations){
      o.itemId = this.id;
      if (!t.deleted){
        this.members[o.memberId!].add(o.value);
      }
      o.memberId = transactionMembers[o.memberId!].id;
    }
    
  }

  void deleteTransactionFromDatabase(Transaction t){
    members.firstWhere((element) => element.id == t.memberId).deleteTransaction(t, balance: false);
    history.firstWhere((e) => e.id == t.id).delete();

    for (Operation o in t.operations){
      o.itemId = this.id;
      this.members.firstWhere((element) => element.id == o.memberId).sub(o.value);
      //o.memberId = this.members[o.memberId!-1].id;
    }
  }

  void addMember(Member m){
    members.add(m);
  }

  // Mark transaction as deleted, while also updating total and balance of all members
  bool deleteTransaction(Transaction t, Map<int, int> memberMap, index){
    if(t.id == null){
      return false;
    }
    members.firstWhere((element) => element.id == t.memberId).deleteTransaction(t, balance: false);
    //members[memberMap[t.memberId]!].deleteTransaction(t, balance: false);
    history.firstWhere((e) => e.id == t.id).delete();

    for(Operation o in t.operations){
      int mId = memberMap[o.memberId]!;
      //members[mId].sub(o.value);
      o.itemId = this.id;
      this.members[mId].sub(o.value);
      o.memberId = this.members[mId].id;
    }
    return true;
  }

  bool payoff(){
    if (history.any((element) => element.id == null)){
      return false;
    }
    Transaction t = Transaction.payoff(timestamp: DateTime.now());
    t.itemId = this.id;
    history.add(t);

    for(Member m in members){
      Operation o = Operation(-m.balance, itemId: this.id, memberId: m.id);
      t.addOperation(o);
      m.add(o.value);
    }

    return true;
  }

  Map<Member, List<Member>> calculatePayoff(){
    List<Member> payer = [];
    for(Member e in members){
      Member a = Member.fromMember(e);
      a.compensate();
      payer.add(a);
    }

    List<Member> positive = List.from(payer.where((element) => element.balance > 1e-6));
    positive.sort((a,b) => a.balance.compareTo(b.balance));
    positive.reversed;
    List<Member> negative = List.from(payer.where((element) => element.balance < -1e-6));
    negative.sort((a,b) => a.balance.compareTo(b.balance));
    negative.reversed;
    
    Map<Member, List<Member>> payMap = { for (var item in negative) item : [] };

    for(int a=0; a<positive.length; a++){
      for(int b=0; b<negative.length; b++){
        if(positive[a].balance > 1e-6){
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
    'owner': owner ? 1 : 0,
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