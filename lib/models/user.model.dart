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
}