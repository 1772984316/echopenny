import 'package:drift/drift.dart';

class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get type => text()();
  RealColumn get balance => real().withDefault(const Constant(0.0))();
  TextColumn get icon => text().withDefault(const Constant(''))();
  TextColumn get currency => text().withDefault(const Constant('CNY'))();
  BoolColumn get isCredit => boolean().withDefault(const Constant(false))();
  RealColumn get creditLimit => real().withDefault(const Constant(0.0))();
  IntColumn get billingDay => integer().nullable()();
  IntColumn get repaymentDay => integer().nullable()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer()();
  BoolColumn get isHidden => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
