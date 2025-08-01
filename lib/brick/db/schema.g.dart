// GENERATED CODE DO NOT EDIT
// This file should be version controlled
import 'package:brick_sqlite/db.dart';
part '20241203223811.migration.dart';
part '20250616101336.migration.dart';
part '20241228115507.migration.dart';
part '20250731211627.migration.dart';

/// All intelligently-generated migrations from all `@Migratable` classes on disk
final migrations = <Migration>{
  const Migration20241203223811(),
  const Migration20250616101336(),
  const Migration20241228115507(),
  const Migration20250731211627()
};

/// A consumable database structure including the latest generated migration.
final schema =
    Schema(20250731211627, generatorVersion: 1, tables: <SchemaTable>{
  SchemaTable('User', columns: <SchemaColumn>{
    SchemaColumn('_brick_id', Column.integer,
        autoincrement: true, nullable: false, isPrimaryKey: true),
    SchemaColumn('id', Column.varchar, unique: true),
    SchemaColumn('item_id', Column.varchar),
    SchemaColumn('user_id', Column.varchar),
    SchemaColumn('full_access', Column.boolean),
    SchemaColumn('user_email', Column.varchar),
    SchemaColumn('expiration_date', Column.datetime)
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
    SchemaColumn('payoff_id', Column.varchar),
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
    SchemaColumn('deleted', Column.boolean),
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
