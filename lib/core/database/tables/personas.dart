import 'package:drift/drift.dart';

class Personas extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  TextColumn get systemPrompt => text()();
  TextColumn get exampleDialogs => text().withDefault(const Constant('[]'))();
  TextColumn get avatar => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
