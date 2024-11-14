// GENERATED CODE EDIT WITH CAUTION
// THIS FILE **WILL NOT** BE REGENERATED
// This file should be version controlled and can be manually edited.
part of 'schema.g.dart';

// While migrations are intelligently created, the difference between some commands, such as
// DropTable vs. RenameTable, cannot be determined. For this reason, please review migrations after
// they are created to ensure the correct inference was made.

// The migration version must **always** mirror the file name

const List<MigrationCommand> _migration_20241114143859_up = [
  DropTable('_brick_Member_history'),
  DropTable('_brick_Item_members'),
  DropTable('_brick_Item_history'),
  DropColumn('total', onTable: 'Member'),
  DropColumn('balance', onTable: 'Member'),
  DropColumn('owner', onTable: 'Item'),
  CreateIndex(columns: ['l_Member_brick_id', 'f_Transaction_brick_id'], onTable: '_brick_Member_history', unique: true),
  CreateIndex(columns: ['l_Item_brick_id', 'f_Member_brick_id'], onTable: '_brick_Item_members', unique: true),
  CreateIndex(columns: ['l_Item_brick_id', 'f_Transaction_brick_id'], onTable: '_brick_Item_history', unique: true)
];

const List<MigrationCommand> _migration_20241114143859_down = [
  InsertTable('_brick_Member_history'),
  InsertTable('_brick_Item_members'),
  InsertTable('_brick_Item_history'),
  DropIndex('index__brick_Member_history_on_l_Member_brick_id_f_Transaction_brick_id'),
  DropIndex('index__brick_Item_members_on_l_Item_brick_id_f_Member_brick_id'),
  DropIndex('index__brick_Item_history_on_l_Item_brick_id_f_Transaction_brick_id')
];

//
// DO NOT EDIT BELOW THIS LINE
//

@Migratable(
  version: '20241114143859',
  up: _migration_20241114143859_up,
  down: _migration_20241114143859_down,
)
class Migration20241114143859 extends Migration {
  const Migration20241114143859()
    : super(
        version: 20241114143859,
        up: _migration_20241114143859_up,
        down: _migration_20241114143859_down,
      );
}
