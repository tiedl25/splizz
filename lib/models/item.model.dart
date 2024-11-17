import 'dart:typed_data';

import 'package:brick_offline_first_with_supabase/brick_offline_first_with_supabase.dart';
import 'package:brick_sqlite/brick_sqlite.dart';
import 'package:brick_supabase/brick_supabase.dart';
import 'package:uuid/uuid.dart';

import 'package:splizz/models/member.model.dart';
import 'package:splizz/models/transaction.model.dart';
import 'package:splizz/models/operation.model.dart';

import 'package:supabase_flutter/supabase_flutter.dart' as Supabase_Flutter;

@ConnectOfflineFirstWithSupabase(
  supabaseConfig: SupabaseSerializable(tableName: 'items'),
)

class Item extends OfflineFirstWithSupabaseModel {
  @Supabase(unique: true)
  @Sqlite(index: true, unique: true)
  final String id;

  final String name;
  @Supabase(fromGenerator: "DateTime.parse(%DATA_PROPERTY% as String)", toGenerator: "%INSTANCE_PROPERTY%.toIso8601String()")
  final DateTime timestamp;

  //@Supabase(fromGenerator: "null", toGenerator: "'test'")
  //@Supabase(fromGenerator: "%DATA_PROPERTY%", toGenerator: "%INSTANCE_PROPERTY%")
  @Supabase(fromGenerator: "await Item.downloadImage(data['id'] as String)", toGenerator: "await Item.uploadImage(%INSTANCE_PROPERTY%!, instance.id)")
  @Sqlite(fromGenerator: "%DATA_PROPERTY%", toGenerator: "%INSTANCE_PROPERTY%", columnType: Column.blob)
  final Uint8List? image;

  @Sqlite(ignore: true)
  @Supabase(ignore: true)
  bool owner;

  @Sqlite(ignore: true)
  @Supabase(ignore: true)
  List<Member> members;

  @Sqlite(ignore: true)
  @Supabase(ignore: true)
  List<Transaction> history;

  //Constructor
  Item({required String this.name, String? id, this.owner=true, members, history, this.image, timestamp}) : 
    this.id = id ?? Uuid().v4(), 
    this.timestamp = timestamp ?? DateTime.now(),
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
        t.addOperation(Operation(value: -involvedMembers[i]['balance'], memberId: involvedMembers[i]['id'], itemId: this.id, transactionId: t.id));
      }

      t.addOperation(Operation(value: t.value, memberId: members[associatedId].id, itemId: this.id, transactionId: t.id));
    }
  }

  void addMember(Member m){
    members.add(m);
  }

  // Mark transaction as deleted, while also updating total and balance of all members
  void deleteTransaction(Transaction t, Map<String, int> memberMap, index){
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


  static Future<String> uploadImage(Uint8List image, String itemId) async {
    final userId = Supabase_Flutter.Supabase.instance.client.auth.currentUser?.id;
    final path = await Supabase_Flutter.Supabase.instance.client.storage
        .from('images') // Replace with your storage bucket name
        .uploadBinary('$userId/$itemId.jpg', image);
    return path;
  }

  static Future<Uint8List> downloadImage(String itemId) async {
    final userId = Supabase_Flutter.Supabase.instance.client.auth.currentUser?.id;
    final image = await Supabase_Flutter.Supabase.instance.client.storage
        .from('images') // Replace with your storage bucket name
        .download('$userId/$itemId.jpg');
    return image;
  }
}