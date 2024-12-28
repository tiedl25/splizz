import 'package:brick_offline_first_with_supabase/brick_offline_first_with_supabase.dart';
import 'package:brick_sqlite/brick_sqlite.dart';
import 'package:brick_supabase/brick_supabase.dart';
import 'package:uuid/uuid.dart';


@ConnectOfflineFirstWithSupabase(
  supabaseConfig: SupabaseSerializable(tableName: 'shared'),
)

@Sqlite(ignore: true)
class User extends OfflineFirstWithSupabaseModel{
  @Supabase(unique: true)
  @Sqlite(index: true, unique: true)
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