// GENERATED CODE DO NOT EDIT
// This file should be version controlled
import 'package:brick_sqlite/db.dart';
part '20241121142828.migration.dart';
part '20241121143315.migration.dart';
part '20241121145354.migration.dart';
part '20241121143232.migration.dart';
part '20241121143342.migration.dart';
part '20241121144744.migration.dart';
part '20241121142847.migration.dart';
part '20241121145727.migration.dart';

/// All intelligently-generated migrations from all `@Migratable` classes on disk
final migrations = <Migration>{
  const Migration20241121142828(),
  const Migration20241121143315(),
  const Migration20241121145354(),
  const Migration20241121143232(),
  const Migration20241121143342(),
  const Migration20241121144744(),
  const Migration20241121142847(),
  const Migration20241121145727()
};

/// A consumable database structure including the latest generated migration.
final schema =
    Schema(20241121145727, generatorVersion: 1, tables: <SchemaTable>{
  SchemaTable('User', columns: <SchemaColumn>{
    SchemaColumn('_brick_id', Column.integer,
        autoincrement: true, nullable: false, isPrimaryKey: true),
    SchemaColumn('id', Column.varchar, unique: true),
    SchemaColumn('item_id', Column.varchar),
    SchemaColumn('user_id', Column.varchar),
    SchemaColumn('full_access', Column.boolean)
  }, indices: <SchemaIndex>{
    SchemaIndex(columns: ['id'], unique: true)
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
