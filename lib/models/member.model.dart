import 'package:uuid/uuid.dart';
import 'package:splizz/models/transaction.model.dart';

class Member {
  final String id;
  
  String? itemId;
  String name;
  int color;
  bool active;
  bool deleted;
  final DateTime timestamp;
  String? email;
  double total = 0;
  double balance = 0;
  double payoff = 0;
  List<Transaction> history;

  //Constructor
  Member({required this.name, required this.color, String? id, String? itemId, double? total, double? balance, double? payoff,List<Transaction>? history, bool? active, bool? deleted, DateTime? timestamp, String? email}) : 
    this.id = id ?? const Uuid().v4(),
    this.itemId = itemId,
    this.total = total ?? 0,
    this.balance = balance ?? 0,
    this.payoff = payoff ?? 0,
    this.history = history ?? [],
    this.active = active ?? true,
    this.deleted = deleted ?? false,
    this.timestamp = timestamp ?? DateTime.now(),
    this.email = email;

  factory Member.fromMember(Member m, {name, color, id, itemId, total, balance, payoff, history, active, timestamp, String? email}){
    return Member(
        name: name ?? m.name,
        color: color ?? m.color,
        id: id ?? m.id,
        itemId: itemId ?? m.itemId,
        total: total ?? m.total,
        balance: balance ?? m.balance,
        payoff: payoff ?? m.payoff,
        history: history ?? m.history,
        active: active ?? m.active,
        timestamp: timestamp ?? m.timestamp,
        email: email
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

  factory Member.fromMap(Map<String, dynamic> map) {
    return Member(
      name: map['name'],
      color: map['color'],
      id: map['id'],
      itemId: map['item_id'],
      active: map['active'] == 1,
      deleted: map['deleted'] == 1,
      timestamp: DateTime.parse(map['timestamp']),
      email: map['email']
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'color': color,
      'item_id': itemId,
      'active': active ? 1 : 0,
      'deleted': deleted ? 1 : 0,
      'email': email,
      'timestamp': timestamp.toString(),
      'id': id,
    };
  }
}