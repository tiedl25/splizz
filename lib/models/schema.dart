import 'package:powersync/powersync.dart';

const schema = Schema([
  Table('items', [
    Column.text('timestamp'),
    Column.text('name'),
    Column.integer('image'), //TODO: change to blob
  ], viewName: 'items'),
  Table('members', [
    Column.text('timestamp'),
    Column.text('name'),
    Column.text('item_id'),
    Column.integer('color'),
    Column.integer('active'),
    Column.integer('deleted'),
    Column.text('email'),
  ], viewName: 'members'),
  Table('transactions', [
    Column.text('timestamp'),
    Column.text('description'),
    Column.text('item_id'),
    Column.text('member_id'),
    Column.integer('payoff_id'),
    Column.integer('value'),
    Column.text('date'),
    Column.integer('deleted'),
  ], viewName: 'transactions'),
  Table('operations', [
    Column.text('timestamp'),
    Column.text('item_id'),
    Column.text('member_id'),
    Column.text('transaction_id'),
    Column.integer('value'),
  ], viewName: 'operations'),
  Table('users', [
    Column.text('timestamp'),
    Column.text('user_email'),
    Column.text('item_id'),
    Column.text('user_id'),
    Column.integer('full_access'),
    Column.text('expiration_date'),
  ]),
  Table.localOnly('local_items', [
    Column.text('timestamp'),
    Column.text('name'),
    Column.integer('image'), //TODO: change to blob
  ], viewName: 'inactive_local_items'),
  Table.localOnly('local_members', [
    Column.text('timestamp'),
    Column.text('name'),
    Column.text('item_id'),
    Column.integer('color'),
    Column.integer('active'),
    Column.integer('deleted'),
    Column.text('email'),
  ], viewName: 'inactive_local_members'),
  Table.localOnly('local_transactions', [
    Column.text('timestamp'),
    Column.text('description'),
    Column.text('item_id'),
    Column.text('member_id'),
    Column.integer('payoff_id'),
    Column.integer('value'),
    Column.text('date'),
    Column.integer('deleted'),
  ], viewName: 'inactive_local_transactions'),
  Table.localOnly('local_operations', [
    Column.text('timestamp'),
    Column.text('item_id'),
    Column.text('member_id'),
    Column.text('transaction_id'),
    Column.integer('value'),
  ], viewName: 'inactive_local_operations')
]);

const localSchema = Schema([
  Table('items', [
    Column.text('timestamp'),
    Column.text('name'),
    Column.integer('image'), //TODO: change to blob
  ], viewName: 'inactive_synced_items'),
  Table('members', [
    Column.text('timestamp'),
    Column.text('name'),
    Column.text('item_id'),
    Column.integer('color'),
    Column.integer('active'),
    Column.integer('deleted'),
    Column.text('email'),
  ], viewName: 'inactive_synced_members'),
  Table('transactions', [
    Column.text('timestamp'),
    Column.text('description'),
    Column.text('item_id'),
    Column.text('member_id'),
    Column.integer('payoff_id'),
    Column.integer('value'),
    Column.text('date'),
    Column.integer('deleted'),
  ], viewName: 'inactive_synced_transactions'),
  Table('operations', [
    Column.text('timestamp'),
    Column.text('item_id'),
    Column.text('member_id'),
    Column.text('transaction_id'),
    Column.integer('value'),
  ], viewName: 'inactive_synced_operations'),
  Table.localOnly('local_items', [
    Column.text('timestamp'),
    Column.text('name'),
    Column.integer('image'), //TODO: change to blob
  ], viewName: 'items'),
  Table.localOnly('local_members', [
    Column.text('timestamp'),
    Column.text('name'),
    Column.text('item_id'),
    Column.integer('color'),
    Column.integer('active'),
    Column.integer('deleted'),
    Column.text('email'),
  ], viewName: 'members'),
  Table.localOnly('local_transactions', [
    Column.text('timestamp'),
    Column.text('description'),
    Column.text('item_id'),
    Column.text('member_id'),
    Column.integer('payoff_id'),
    Column.integer('value'),
    Column.text('date'),
    Column.integer('deleted'),
  ], viewName: 'transactions'),
  Table.localOnly('local_operations', [
    Column.text('timestamp'),
    Column.text('item_id'),
    Column.text('member_id'),
    Column.text('transaction_id'),
    Column.integer('value'),
  ], viewName: 'operations')
]);