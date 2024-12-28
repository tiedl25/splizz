// GENERATED CODE EDIT WITH CAUTION
// THIS FILE **WILL NOT** BE REGENERATED
// This file should be version controlled and can be manually edited.
part of 'schema.g.dart';

// While migrations are intelligently created, the difference between some commands, such as
// DropTable vs. RenameTable, cannot be determined. For this reason, please review migrations after
// they are created to ensure the correct inference was made.

// The migration version must **always** mirror the file name

const List<MigrationCommand> _migration_20241228115507_up = [
  InsertColumn('user_email', Column.varchar, onTable: 'User'),
  InsertColumn('expiration_date', Column.datetime, onTable: 'User')
];

const List<MigrationCommand> _migration_20241228115507_down = [
  DropColumn('user_email', onTable: 'User'),
  DropColumn('expiration_date', onTable: 'User')
];

//
// DO NOT EDIT BELOW THIS LINE
//

@Migratable(
  version: '20241228115507',
  up: _migration_20241228115507_up,
  down: _migration_20241228115507_down,
)
class Migration20241228115507 extends Migration {
  const Migration20241228115507()
    : super(
        version: 20241228115507,
        up: _migration_20241228115507_up,
        down: _migration_20241228115507_down,
      );
}
