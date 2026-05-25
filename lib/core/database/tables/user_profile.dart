import 'package:drift/drift.dart';

class UserProfile extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  IntColumn get sourceMsgId => integer().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {key};
}
