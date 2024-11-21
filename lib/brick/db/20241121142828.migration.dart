// GENERATED CODE EDIT WITH CAUTION
// THIS FILE **WILL NOT** BE REGENERATED
// This file should be version controlled and can be manually edited.
part of 'schema.g.dart';

// While migrations are intelligently created, the difference between some commands, such as
// DropTable vs. RenameTable, cannot be determined. For this reason, please review migrations after
// they are created to ensure the correct inference was made.

// The migration version must **always** mirror the file name

const List<MigrationCommand> _migration_20241121142828_up = [
  InsertTable('User'),
  InsertTable('Transaction'),
  InsertTable('Operation'),
  InsertTable('Item'),
  InsertColumn('id', Column.varchar, onTable: 'User', unique: true),
  InsertColumn('item_id', Column.varchar, onTable: 'User'),
  InsertColumn('user_id', Column.varchar, onTable: 'User'),
  InsertColumn('full_access', Column.boolean, onTable: 'User'),
  InsertColumn('id', Column.varchar, onTable: 'Transaction', unique: true),
  InsertColumn('member_id', Column.varchar, onTable: 'Transaction'),
  InsertColumn('item_id', Column.varchar, onTable: 'Transaction'),
  InsertColumn('description', Column.varchar, onTable: 'Transaction'),
  InsertColumn('date', Column.datetime, onTable: 'Transaction'),
  InsertColumn('value', Column.Double, onTable: 'Transaction'),
  InsertColumn('deleted', Column.boolean, onTable: 'Transaction'),
  InsertColumn('timestamp', Column.datetime, onTable: 'Transaction'),
  InsertColumn('id', Column.varchar, onTable: 'Operation', unique: true),
  InsertColumn('item_id', Column.varchar, onTable: 'Operation'),
  InsertColumn('member_id', Column.varchar, onTable: 'Operation'),
  InsertColumn('transaction_id', Column.varchar, onTable: 'Operation'),
  InsertColumn('value', Column.Double, onTable: 'Operation'),
  InsertColumn('timestamp', Column.datetime, onTable: 'Operation'),
  InsertColumn('id', Column.varchar, onTable: 'Item', unique: true),
  InsertColumn('name', Column.varchar, onTable: 'Item'),
  InsertColumn('timestamp', Column.datetime, onTable: 'Item'),
  InsertColumn('image', Column.blob, onTable: 'Item'),
  CreateIndex(columns: ['id'], onTable: 'User', unique: true),
  CreateIndex(columns: ['id'], onTable: 'Transaction', unique: true),
  CreateIndex(columns: ['id'], onTable: 'Operation', unique: true),
  CreateIndex(columns: ['id'], onTable: 'Item', unique: true)
];

const List<MigrationCommand> _migration_20241121142828_down = [
  DropTable('User'),
  DropTable('Transaction'),
  DropTable('Operation'),
  DropTable('Item'),
  DropColumn('id', onTable: 'User'),
  DropColumn('item_id', onTable: 'User'),
  DropColumn('user_id', onTable: 'User'),
  DropColumn('full_access', onTable: 'User'),
  DropColumn('id', onTable: 'Transaction'),
  DropColumn('member_id', onTable: 'Transaction'),
  DropColumn('item_id', onTable: 'Transaction'),
  DropColumn('description', onTable: 'Transaction'),
  DropColumn('date', onTable: 'Transaction'),
  DropColumn('value', onTable: 'Transaction'),
  DropColumn('deleted', onTable: 'Transaction'),
  DropColumn('timestamp', onTable: 'Transaction'),
  DropColumn('id', onTable: 'Operation'),
  DropColumn('item_id', onTable: 'Operation'),
  DropColumn('member_id', onTable: 'Operation'),
  DropColumn('transaction_id', onTable: 'Operation'),
  DropColumn('value', onTable: 'Operation'),
  DropColumn('timestamp', onTable: 'Operation'),
  DropColumn('id', onTable: 'Item'),
  DropColumn('name', onTable: 'Item'),
  DropColumn('timestamp', onTable: 'Item'),
  DropColumn('image', onTable: 'Item'),
  DropIndex('index_User_on_id'),
  DropIndex('index_Transaction_on_id'),
  DropIndex('index_Operation_on_id'),
  DropIndex('index_Item_on_id')
];

//
// DO NOT EDIT BELOW THIS LINE
//

@Migratable(
  version: '20241121142828',
  up: _migration_20241121142828_up,
  down: _migration_20241121142828_down,
)
class Migration20241121142828 extends Migration {
  const Migration20241121142828()
    : super(
        version: 20241121142828,
        up: _migration_20241121142828_up,
        down: _migration_20241121142828_down,
      );
}