// GENERATED CODE EDIT WITH CAUTION
// THIS FILE **WILL NOT** BE REGENERATED
// This file should be version controlled and can be manually edited.
part of 'schema.g.dart';

// While migrations are intelligently created, the difference between some commands, such as
// DropTable vs. RenameTable, cannot be determined. For this reason, please review migrations after
// they are created to ensure the correct inference was made.

// The migration version must **always** mirror the file name

const List<MigrationCommand> _migration_20241121142847_up = [
  InsertTable('Member'),
  InsertColumn('id', Column.varchar, onTable: 'Member', unique: true),
  InsertColumn('item_id', Column.varchar, onTable: 'Member'),
  InsertColumn('name', Column.varchar, onTable: 'Member'),
  InsertColumn('color', Column.integer, onTable: 'Member'),
  InsertColumn('active', Column.boolean, onTable: 'Member'),
  InsertColumn('timestamp', Column.datetime, onTable: 'Member'),
  CreateIndex(columns: ['id'], onTable: 'Member', unique: true)
];

const List<MigrationCommand> _migration_20241121142847_down = [
  DropTable('Member'),
  DropColumn('id', onTable: 'Member'),
  DropColumn('item_id', onTable: 'Member'),
  DropColumn('name', onTable: 'Member'),
  DropColumn('color', onTable: 'Member'),
  DropColumn('active', onTable: 'Member'),
  DropColumn('timestamp', onTable: 'Member'),
  DropIndex('index_Member_on_id')
];

//
// DO NOT EDIT BELOW THIS LINE
//

@Migratable(
  version: '20241121142847',
  up: _migration_20241121142847_up,
  down: _migration_20241121142847_down,
)
class Migration20241121142847 extends Migration {
  const Migration20241121142847()
    : super(
        version: 20241121142847,
        up: _migration_20241121142847_up,
        down: _migration_20241121142847_down,
      );
}
