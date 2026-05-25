import 'package:drift/drift.dart';

class Conversations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get role => text()();
  TextColumn get content => text()();
  TextColumn get emotionTag => text().nullable()();
  IntColumn get tokens => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
