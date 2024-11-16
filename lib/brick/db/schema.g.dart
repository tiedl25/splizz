// GENERATED CODE DO NOT EDIT
// This file should be version controlled
import 'package:brick_sqlite/db.dart';
part '20241114184827.migration.dart';
part '20241114185427.migration.dart';

/// All intelligently-generated migrations from all `@Migratable` classes on disk
final migrations = <Migration>{
  const Migration20241114184827(),
  const Migration20241114185427()
};

/// A consumable database structure including the latest generated migration.
final schema =
    Schema(20241114185427, generatorVersion: 1, tables: <SchemaTable>{
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
  SchemaTable('Member', columns: <SchemaColumn>{
    SchemaColumn('_brick_id', Column.integer,
        autoincrement: true, nullable: false, isPrimaryKey: true),
    SchemaColumn('id', Column.varchar, unique: true),
    SchemaColumn('item_id', Column.varchar),
    SchemaColumn('name', Column.varchar),
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
  SchemaTable('Item', columns: <SchemaColumn>{
    SchemaColumn('_brick_id', Column.integer,
        autoincrement: true, nullable: false, isPrimaryKey: true),
    SchemaColumn('id', Column.varchar, unique: true),
    SchemaColumn('name', Column.varchar),
    SchemaColumn('timestamp', Column.datetime),
    SchemaColumn('image', Column.blob)
  }, indices: <SchemaIndex>{
    SchemaIndex(columns: ['id'], unique: true)
  })
});
