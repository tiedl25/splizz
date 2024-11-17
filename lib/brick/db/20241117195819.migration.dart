// GENERATED CODE EDIT WITH CAUTION
// THIS FILE **WILL NOT** BE REGENERATED
// This file should be version controlled and can be manually edited.
part of 'schema.g.dart';

// While migrations are intelligently created, the difference between some commands, such as
// DropTable vs. RenameTable, cannot be determined. For this reason, please review migrations after
// they are created to ensure the correct inference was made.

// The migration version must **always** mirror the file name

const List<MigrationCommand> _migration_20241117195819_up = [
  InsertTable('User'),
  InsertColumn('id', Column.varchar, onTable: 'User', unique: true),
  InsertColumn('item_id', Column.varchar, onTable: 'User'),
  InsertColumn('user_id', Column.varchar, onTable: 'User'),
  InsertColumn('full_access', Column.boolean, onTable: 'User'),
  CreateIndex(columns: ['id'], onTable: 'User', unique: true)
];

const List<MigrationCommand> _migration_20241117195819_down = [
  DropTable('User'),
  DropColumn('id', onTable: 'User'),
  DropColumn('item_id', onTable: 'User'),
  DropColumn('user_id', onTable: 'User'),
  DropColumn('full_access', onTable: 'User'),
  DropIndex('index_User_on_id')
];

//
// DO NOT EDIT BELOW THIS LINE
//

@Migratable(
  version: '20241117195819',
  up: _migration_20241117195819_up,
  down: _migration_20241117195819_down,
)
class Migration20241117195819 extends Migration {
  const Migration20241117195819()
    : super(
        version: 20241117195819,
        up: _migration_20241117195819_up,
        down: _migration_20241117195819_down,
      );
}
