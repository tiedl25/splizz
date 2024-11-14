// GENERATED CODE EDIT WITH CAUTION
// THIS FILE **WILL NOT** BE REGENERATED
// This file should be version controlled and can be manually edited.
part of 'schema.g.dart';

// While migrations are intelligently created, the difference between some commands, such as
// DropTable vs. RenameTable, cannot be determined. For this reason, please review migrations after
// they are created to ensure the correct inference was made.

// The migration version must **always** mirror the file name

const List<MigrationCommand> _migration_20241114120555_up = [
  InsertTable('_brick_Transaction_operations'),
  InsertTable('Transaction'),
  InsertTable('_brick_Member_history'),
  InsertTable('Member'),
  InsertTable('Operation'),
  InsertTable('_brick_Item_members'),
  InsertTable('_brick_Item_history'),
  InsertTable('Item'),
  InsertForeignKey('_brick_Transaction_operations', 'Transaction', foreignKeyColumn: 'l_Transaction_brick_id', onDeleteCascade: true, onDeleteSetDefault: false),
  InsertForeignKey('_brick_Transaction_operations', 'Operation', foreignKeyColumn: 'f_Operation_brick_id', onDeleteCascade: true, onDeleteSetDefault: false),
  InsertColumn('id', Column.varchar, onTable: 'Transaction', unique: true),
  InsertColumn('member_id', Column.varchar, onTable: 'Transaction'),
  InsertColumn('item_id', Column.varchar, onTable: 'Transaction'),
  InsertColumn('description', Column.varchar, onTable: 'Transaction'),
  InsertColumn('date', Column.datetime, onTable: 'Transaction'),
  InsertColumn('value', Column.Double, onTable: 'Transaction'),
  InsertColumn('deleted', Column.boolean, onTable: 'Transaction'),
  InsertColumn('timestamp', Column.datetime, onTable: 'Transaction'),
  InsertForeignKey('_brick_Member_history', 'Member', foreignKeyColumn: 'l_Member_brick_id', onDeleteCascade: true, onDeleteSetDefault: false),
  InsertForeignKey('_brick_Member_history', 'Transaction', foreignKeyColumn: 'f_Transaction_brick_id', onDeleteCascade: true, onDeleteSetDefault: false),
  InsertColumn('id', Column.varchar, onTable: 'Member', unique: true),
  InsertColumn('name', Column.varchar, onTable: 'Member'),
  InsertColumn('total', Column.Double, onTable: 'Member'),
  InsertColumn('balance', Column.Double, onTable: 'Member'),
  InsertColumn('color', Column.integer, onTable: 'Member'),
  InsertColumn('active', Column.boolean, onTable: 'Member'),
  InsertColumn('timestamp', Column.datetime, onTable: 'Member'),
  InsertColumn('id', Column.varchar, onTable: 'Operation', unique: true),
  InsertColumn('item_id', Column.varchar, onTable: 'Operation'),
  InsertColumn('member_id', Column.varchar, onTable: 'Operation'),
  InsertColumn('transaction_id', Column.varchar, onTable: 'Operation'),
  InsertColumn('value', Column.Double, onTable: 'Operation'),
  InsertColumn('timestamp', Column.datetime, onTable: 'Operation'),
  InsertForeignKey('_brick_Item_members', 'Item', foreignKeyColumn: 'l_Item_brick_id', onDeleteCascade: true, onDeleteSetDefault: false),
  InsertForeignKey('_brick_Item_members', 'Member', foreignKeyColumn: 'f_Member_brick_id', onDeleteCascade: true, onDeleteSetDefault: false),
  InsertForeignKey('_brick_Item_history', 'Item', foreignKeyColumn: 'l_Item_brick_id', onDeleteCascade: true, onDeleteSetDefault: false),
  InsertForeignKey('_brick_Item_history', 'Transaction', foreignKeyColumn: 'f_Transaction_brick_id', onDeleteCascade: true, onDeleteSetDefault: false),
  InsertColumn('id', Column.varchar, onTable: 'Item', unique: true),
  InsertColumn('name', Column.varchar, onTable: 'Item'),
  InsertColumn('owner', Column.boolean, onTable: 'Item'),
  InsertColumn('timestamp', Column.datetime, onTable: 'Item'),
  CreateIndex(columns: ['l_Transaction_brick_id', 'f_Operation_brick_id'], onTable: '_brick_Transaction_operations', unique: true),
  CreateIndex(columns: ['id'], onTable: 'Transaction', unique: true),
  CreateIndex(columns: ['l_Member_brick_id', 'f_Transaction_brick_id'], onTable: '_brick_Member_history', unique: true),
  CreateIndex(columns: ['id'], onTable: 'Member', unique: true),
  CreateIndex(columns: ['id'], onTable: 'Operation', unique: true),
  CreateIndex(columns: ['l_Item_brick_id', 'f_Member_brick_id'], onTable: '_brick_Item_members', unique: true),
  CreateIndex(columns: ['l_Item_brick_id', 'f_Transaction_brick_id'], onTable: '_brick_Item_history', unique: true),
  CreateIndex(columns: ['id'], onTable: 'Item', unique: true)
];

const List<MigrationCommand> _migration_20241114120555_down = [
  DropTable('_brick_Transaction_operations'),
  DropTable('Transaction'),
  DropTable('_brick_Member_history'),
  DropTable('Member'),
  DropTable('Operation'),
  DropTable('_brick_Item_members'),
  DropTable('_brick_Item_history'),
  DropTable('Item'),
  DropColumn('l_Transaction_brick_id', onTable: '_brick_Transaction_operations'),
  DropColumn('f_Operation_brick_id', onTable: '_brick_Transaction_operations'),
  DropColumn('id', onTable: 'Transaction'),
  DropColumn('member_id', onTable: 'Transaction'),
  DropColumn('item_id', onTable: 'Transaction'),
  DropColumn('description', onTable: 'Transaction'),
  DropColumn('date', onTable: 'Transaction'),
  DropColumn('value', onTable: 'Transaction'),
  DropColumn('deleted', onTable: 'Transaction'),
  DropColumn('timestamp', onTable: 'Transaction'),
  DropColumn('l_Member_brick_id', onTable: '_brick_Member_history'),
  DropColumn('f_Transaction_brick_id', onTable: '_brick_Member_history'),
  DropColumn('id', onTable: 'Member'),
  DropColumn('name', onTable: 'Member'),
  DropColumn('total', onTable: 'Member'),
  DropColumn('balance', onTable: 'Member'),
  DropColumn('color', onTable: 'Member'),
  DropColumn('active', onTable: 'Member'),
  DropColumn('timestamp', onTable: 'Member'),
  DropColumn('id', onTable: 'Operation'),
  DropColumn('item_id', onTable: 'Operation'),
  DropColumn('member_id', onTable: 'Operation'),
  DropColumn('transaction_id', onTable: 'Operation'),
  DropColumn('value', onTable: 'Operation'),
  DropColumn('timestamp', onTable: 'Operation'),
  DropColumn('l_Item_brick_id', onTable: '_brick_Item_members'),
  DropColumn('f_Member_brick_id', onTable: '_brick_Item_members'),
  DropColumn('l_Item_brick_id', onTable: '_brick_Item_history'),
  DropColumn('f_Transaction_brick_id', onTable: '_brick_Item_history'),
  DropColumn('id', onTable: 'Item'),
  DropColumn('name', onTable: 'Item'),
  DropColumn('owner', onTable: 'Item'),
  DropColumn('timestamp', onTable: 'Item'),
  DropIndex('index__brick_Transaction_operations_on_l_Transaction_brick_id_f_Operation_brick_id'),
  DropIndex('index_Transaction_on_id'),
  DropIndex('index__brick_Member_history_on_l_Member_brick_id_f_Transaction_brick_id'),
  DropIndex('index_Member_on_id'),
  DropIndex('index_Operation_on_id'),
  DropIndex('index__brick_Item_members_on_l_Item_brick_id_f_Member_brick_id'),
  DropIndex('index__brick_Item_history_on_l_Item_brick_id_f_Transaction_brick_id'),
  DropIndex('index_Item_on_id')
];

//
// DO NOT EDIT BELOW THIS LINE
//

@Migratable(
  version: '20241114120555',
  up: _migration_20241114120555_up,
  down: _migration_20241114120555_down,
)
class Migration20241114120555 extends Migration {
  const Migration20241114120555()
    : super(
        version: 20241114120555,
        up: _migration_20241114120555_up,
        down: _migration_20241114120555_down,
      );
}
