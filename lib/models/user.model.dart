import 'package:uuid/uuid.dart';

class User{
  final String id;

  String? itemId;
  String? userId;

  bool fullAccess;

  String? userEmail;
  DateTime? expirationDate;

  //Constructor
  User({String? id, this.itemId, this.userId, this.fullAccess = false, this.userEmail, this.expirationDate}) : 
    this.id = id ?? const Uuid().v4();

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      itemId: map['item_id'],
      userId: map['user_id'],
      fullAccess: map['full_access'] == 1,
      userEmail: map['user_email'],
      expirationDate: map['expiration_date'] != null ? DateTime.parse(map['expiration_date']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'item_id': itemId,
      'user_id': userId,
      'full_access': fullAccess ? 1 : 0,
      'user_email': userEmail,
      'expiration_date': expirationDate?.toString(),
      'id': id,
    };
  }
}