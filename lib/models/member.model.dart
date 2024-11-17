import 'package:brick_offline_first_with_supabase/brick_offline_first_with_supabase.dart';
import 'package:brick_sqlite/brick_sqlite.dart';
import 'package:brick_supabase/brick_supabase.dart';
import 'package:uuid/uuid.dart';

import 'package:splizz/models/transaction.model.dart';

@ConnectOfflineFirstWithSupabase(
  supabaseConfig: SupabaseSerializable(tableName: 'members'),
)

class Member extends OfflineFirstWithSupabaseModel {
  @Supabase(unique: true)
  @Sqlite(index: true, unique: true)
  final String id;
  
  String? itemId;
  final String name;
  final int color;
  bool active = true;
  final DateTime timestamp;

  @Sqlite(ignore: true)
  @Supabase(ignore: true)
  double total = 0;

  @Sqlite(ignore: true)
  @Supabase(ignore: true)
  double balance = 0;

  @Sqlite(ignore: true)
  @Supabase(ignore: true)
  List<Transaction> history;

  //Constructor
  Member({required this.name, required this.color, String? id, String? itemId, double? total, double? balance, history, active, timestamp}) : 
    this.id = id ?? const Uuid().v4(),
    this.itemId = itemId,
    this.total = total ?? 0,
    this.balance = balance ?? 0,
    this.history = history ?? [],
    this.active = active ?? true,
    this.timestamp = timestamp ?? DateTime.now();

  factory Member.fromMember(Member m, {name, color, id, itemId, total, balance, history, active, timestamp, String? user_id}){
    return Member(
        name: name ?? m.name,
        color: color ?? m.color,
        id: id ?? m.id,
        itemId: itemId ?? m.itemId,
        total: total ?? m.total,
        balance: balance ?? m.balance,
        history: history ?? m.history,
        active: active ?? m.active,
        timestamp: timestamp ?? m.timestamp,
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
}