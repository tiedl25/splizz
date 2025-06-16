// GENERATED CODE EDIT WITH CAUTION
// THIS FILE **WILL NOT** BE REGENERATED
// This file should be version controlled and can be manually edited.
part of 'schema.g.dart';

// While migrations are intelligently created, the difference between some commands, such as
// DropTable vs. RenameTable, cannot be determined. For this reason, please review migrations after
// they are created to ensure the correct inference was made.

// The migration version must **always** mirror the file name

const List<MigrationCommand> _migration_20250616101336_up = [
  InsertColumn('deleted', Column.boolean, onTable: 'Member')
];

const List<MigrationCommand> _migration_20250616101336_down = [
  DropColumn('deleted', onTable: 'Member')
];

//
// DO NOT EDIT BELOW THIS LINE
//

@Migratable(
  version: '20250616101336',
  up: _migration_20250616101336_up,
  down: _migration_20250616101336_down,
)
class Migration20250616101336 extends Migration {
  const Migration20250616101336()
    : super(
        version: 20250616101336,
        up: _migration_20250616101336_up,
        down: _migration_20250616101336_down,
      );
}
