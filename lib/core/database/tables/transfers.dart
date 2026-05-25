import 'package:drift/drift.dart';

class Transfers extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get fromAccountId => integer()();
  IntColumn get toAccountId => integer()();
  RealColumn get amount => real()();
  TextColumn get note => text().withDefault(const Constant(''))();
  TextColumn get date => text()();
  IntColumn get messageId => integer().nullable()();
}
