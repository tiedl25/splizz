// GENERATED CODE DO NOT EDIT
// This file should be version controlled
import 'package:brick_sqlite/db.dart';
part '20241114120555.migration.dart';

/// All intelligently-generated migrations from all `@Migratable` classes on disk
final migrations = <Migration>{const Migration20241114120555()};

/// A consumable database structure including the latest generated migration.
final schema =
    Schema(20241114120555, generatorVersion: 1, tables: <SchemaTable>{
  SchemaTable('_brick_Transaction_operations', columns: <SchemaColumn>{
    SchemaColumn('_brick_id', Column.integer,
        autoincrement: true, nullable: false, isPrimaryKey: true),
    SchemaColumn('l_Transaction_brick_id', Column.integer,
        isForeignKey: true,
        foreignTableName: 'Transaction',
        onDeleteCascade: true,
        onDeleteSetDefault: false),
    SchemaColumn('f_Operation_brick_id', Column.integer,
        isForeignKey: true,
        foreignTableName: 'Operation',
        onDeleteCascade: true,
        onDeleteSetDefault: false)
  }, indices: <SchemaIndex>{
    SchemaIndex(
        columns: ['l_Transaction_brick_id', 'f_Operation_brick_id'],
        unique: true)
  }),
  SchemaTable('Transaction', columns: <SchemaColumn>{
    SchemaColumn('_brick_id', Column.integer,
        autoincrement: true, nullable: false, isPrimaryKey: true),
    SchemaColumn('id', Column.varchar, unique: true),
    SchemaColumn('member_id', Column.varchar),
    SchemaColumn('item_id', Column.varchar),
    SchemaColumn('description', Column.varchar),
    SchemaColumn('date', Column.datetime),
    SchemaColumn('value', Column.Double),
    SchemaColumn('deleted', Column.boolean),
    SchemaColumn('timestamp', Column.datetime)
  }, indices: <SchemaIndex>{
    SchemaIndex(columns: ['id'], unique: true)
  }),
  SchemaTable('_brick_Member_history', columns: <SchemaColumn>{
    SchemaColumn('_brick_id', Column.integer,
        autoincrement: true, nullable: false, isPrimaryKey: true),
    SchemaColumn('l_Member_brick_id', Column.integer,
        isForeignKey: true,
        foreignTableName: 'Member',
        onDeleteCascade: true,
        onDeleteSetDefault: false),
    SchemaColumn('f_Transaction_brick_id', Column.integer,
        isForeignKey: true,
        foreignTableName: 'Transaction',
        onDeleteCascade: true,
        onDeleteSetDefault: false)
  }, indices: <SchemaIndex>{
    SchemaIndex(
        columns: ['l_Member_brick_id', 'f_Transaction_brick_id'], unique: true)
  }),
  SchemaTable('Member', columns: <SchemaColumn>{
    SchemaColumn('_brick_id', Column.integer,
        autoincrement: true, nullable: false, isPrimaryKey: true),
    SchemaColumn('id', Column.varchar, unique: true),
    SchemaColumn('name', Column.varchar),
    SchemaColumn('total', Column.Double),
    SchemaColumn('balance', Column.Double),
    SchemaColumn('color', Column.integer),
    SchemaColumn('active', Column.boolean),
    SchemaColumn('timestamp', Column.datetime)
  }, indices: <SchemaIndex>{
    SchemaIndex(columns: ['id'], unique: true)
  }),
  SchemaTable('Operation', columns: <SchemaColumn>{
    SchemaColumn('_brick_id', Column.integer,
        autoincrement: true, nullable: false, isPrimaryKey: true),
    SchemaColumn('id', Column.varchar, unique: true),
    SchemaColumn('item_id', Column.varchar),
    SchemaColumn('member_id', Column.varchar),
    SchemaColumn('transaction_id', Column.varchar),
    SchemaColumn('value', Column.Double),
    SchemaColumn('timestamp', Column.datetime)
  }, indices: <SchemaIndex>{
    SchemaIndex(columns: ['id'], unique: true)
  }),
  SchemaTable('_brick_Item_members', columns: <SchemaColumn>{
    SchemaColumn('_brick_id', Column.integer,
        autoincrement: true, nullable: false, isPrimaryKey: true),
    SchemaColumn('l_Item_brick_id', Column.integer,
        isForeignKey: true,
        foreignTableName: 'Item',
        onDeleteCascade: true,
        onDeleteSetDefault: false),
    SchemaColumn('f_Member_brick_id', Column.integer,
        isForeignKey: true,
        foreignTableName: 'Member',
        onDeleteCascade: true,
        onDeleteSetDefault: false)
  }, indices: <SchemaIndex>{
    SchemaIndex(columns: ['l_Item_brick_id', 'f_Member_brick_id'], unique: true)
  }),
  SchemaTable('_brick_Item_history', columns: <SchemaColumn>{
    SchemaColumn('_brick_id', Column.integer,
        autoincrement: true, nullable: false, isPrimaryKey: true),
    SchemaColumn('l_Item_brick_id', Column.integer,
        isForeignKey: true,
        foreignTableName: 'Item',
        onDeleteCascade: true,
        onDeleteSetDefault: false),
    SchemaColumn('f_Transaction_brick_id', Column.integer,
        isForeignKey: true,
        foreignTableName: 'Transaction',
        onDeleteCascade: true,
        onDeleteSetDefault: false)
  }, indices: <SchemaIndex>{
    SchemaIndex(
        columns: ['l_Item_brick_id', 'f_Transaction_brick_id'], unique: true)
  }),
  SchemaTable('Item', columns: <SchemaColumn>{
    SchemaColumn('_brick_id', Column.integer,
        autoincrement: true, nullable: false, isPrimaryKey: true),
    SchemaColumn('id', Column.varchar, unique: true),
    SchemaColumn('name', Column.varchar),
    SchemaColumn('owner', Column.boolean),
    SchemaColumn('timestamp', Column.datetime)
  }, indices: <SchemaIndex>{
    SchemaIndex(columns: ['id'], unique: true)
  })
});
