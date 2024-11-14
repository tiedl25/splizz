import 'dart:typed_data';

import 'package:brick_offline_first_with_supabase/brick_offline_first_with_supabase.dart';
import 'package:brick_sqlite/brick_sqlite.dart';
import 'package:brick_supabase/brick_supabase.dart';
import 'package:uuid/uuid.dart';

import 'package:splizz/models/member.model.dart';
import 'package:splizz/models/transaction.model.dart';
import 'package:splizz/models/operation.model.dart';

@ConnectOfflineFirstWithSupabase(
  supabaseConfig: SupabaseSerializable(tableName: 'items'),
)

class Item extends OfflineFirstWithSupabaseModel {
  @Supabase(unique: true)
  @Sqlite(index: true, unique: true)
  final String id;

  final String name;
  bool owner;
  Uint8List? image;
  final DateTime timestamp;

  List<Member> members;
  List<Transaction> history;

  //Constructor
  Item({required String? name, String? id, this.owner=true, members, history, this.image, timestamp}) : 
    this.id = id ?? Uuid().v4(), 
    this.timestamp = timestamp ?? DateTime.now(),
    this.name = name ?? '',
    this.members = members ?? [],
    this.history = history ?? [];

  Item.copy(Item item) : this(name: item.name, id: item.id, owner: item.owner, members: item.members, history: item.history, image: item.image, timestamp: item.timestamp);

  // Add new transaction to history and member history, while also updating total and balance of all members
  void addTransaction(int associatedId, Transaction t, List<Map<String, dynamic>> involvedMembers){
    members[associatedId].addTransaction(t);
    history.add(t);

    if(!t.deleted)
    {
      for(int i=0; i<involvedMembers.length; i++) {
        members[involvedMembers[i]['listId']].sub(involvedMembers[i]['balance']);
        t.addOperation(Operation(value: -involvedMembers[i]['balance'], memberId: involvedMembers[i]['id'], itemId: this.id));
      }

      t.addOperation(Operation(value: t.value, memberId: members[associatedId].id, itemId: this.id));
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
      Operation o = Operation(value: -m.balance, itemId: this.id, memberId: m.id);
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
    'owner': owner ? 1 : 0,
    'image': image,
    'timestamp': timestamp.toString(),
  };

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      name: map['name'],
      id: map['id'],
      owner: map['owner'] == 1 ? true : false,
      image: map['image'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}