import 'dart:typed_data';
import 'package:uuid/uuid.dart';

import 'package:splizz/models/member.model.dart';
import 'package:splizz/models/transaction.model.dart';
import 'package:splizz/models/operation.model.dart';

class Item{
  final String id;
  final String name;
  final DateTime timestamp;
  Uint8List? image;
  String? imagePath;
  bool owner;
  List<Member> members;
  List<Transaction> history;

  double? balance;

  //Constructor
  Item({required String this.name, String? id, this.owner=true, members, history, this.image, this.imagePath, timestamp}) : 
    this.id = id ?? Uuid().v4(), 
    this.timestamp = timestamp ?? DateTime.now(),
    this.members = members ?? [],
    this.history = history ?? [];

  Item.copyWith({required Item item, String? name, String? id, bool? owner, List<Member>? members, List<Transaction>? history, Uint8List? image, String? imagePath, DateTime? timestamp})
    : this(
        name: name ?? item.name,
        id: id ?? item.id,
        owner: owner ?? item.owner,
        members: members ?? List<Member>.from(item.members.map((m) => Member.fromMember(m))),
        history: history ?? List<Transaction>.from(item.history.map((h) => Transaction.copy(h))),
        image: image ?? item.image,
        imagePath: imagePath ?? item.imagePath,
        timestamp: timestamp ?? item.timestamp
  );

  // Add new transaction to history and member history, while also updating total and balance of all members
  void addTransaction(int associatedId, Transaction t, List<Map<String, dynamic>> involvedMembers){
    final newMembers = members.where((m) => !m.deleted).toList();

    newMembers[associatedId].addTransaction(t);
    history.add(t);

    if(!t.deleted)
    {
      for(int i=0; i<involvedMembers.length; i++) {
        newMembers[involvedMembers[i]['listId']].sub(involvedMembers[i]['balance']);
        t.addOperation(Operation(value: -involvedMembers[i]['balance'], memberId: involvedMembers[i]['id'], itemId: this.id, transactionId: t.id));
      }

      t.addOperation(Operation(value: t.value, memberId: newMembers[associatedId].id, itemId: this.id, transactionId: t.id));
    }
    t.operations.sort((a,b) => b.value.compareTo(a.value));

    //members = newMembers;
  }

  void addMember(Member m){
    members.add(m);
  }

  // Mark transaction as deleted, while also updating total and balance of all members
  void deleteTransaction(Transaction t){
    members.firstWhere((element) => element.id == t.memberId).deleteTransaction(t, balance: false);
    //members[memberMap[t.memberId]!].deleteTransaction(t, balance: false);
    history.firstWhere((e) => e.id == t.id).delete();

    for(Operation o in t.operations){
      //int mId = memberMap[o.memberId]!;
      int mId = members.indexWhere((element) => element.id == o.memberId);
      //members[mId].sub(o.value);
      o.itemId = this.id;
      this.members[mId].sub(o.value);
      o.memberId = this.members[mId].id;
    }
  }

  void payoff(){
    Transaction t = Transaction.payoff(timestamp: DateTime.now());
    t.itemId = this.id;
    history.add(t);

    for(Member m in members){
      Operation o = Operation(value: -m.balance, itemId: this.id, memberId: m.id, transactionId: t.id);
      t.addOperation(o);
      m.add(o.value);
    }
  }

  Map<Member, List<Member>> calculatePayoff(){
    List<Member> payer = [];
    for(Member e in members){
      Member a = Member.fromMember(e);
      a.balance = double.parse(a.balance.toStringAsFixed(2));
      a.compensate();
      payer.add(a);
    }

    List<Member> positive = List.from(payer.where((element) => element.balance > 0.005));
    positive.sort((a,b) => a.balance.compareTo(b.balance));
    positive.reversed;
    List<Member> negative = List.from(payer.where((element) => element.balance < -0.005));
    negative.sort((a,b) => a.balance.compareTo(b.balance));
    negative.reversed;
    
    Map<Member, List<Member>> payMap = { for (var item in negative) item : [] };

    for(int a=0; a<positive.length; a++){
      for(int b=0; b<negative.length; b++){
        if(positive[a].balance > 0.005){
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

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'],
      name: map['name'],
      imagePath: map['image'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'image': imagePath,
      'timestamp': timestamp.toString(),
      'id': id,
    };
  }
}