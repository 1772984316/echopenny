import 'package:drift/drift.dart';

class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()();
  RealColumn get amount => real()();
  IntColumn get categoryId => integer().nullable()();
  IntColumn get accountId => integer()();
  TextColumn get note => text().withDefault(const Constant(''))();
  TextColumn get date => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get messageId => integer().nullable()();
}
