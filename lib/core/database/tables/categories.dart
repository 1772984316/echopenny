import 'package:drift/drift.dart';

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get icon => text().withDefault(const Constant(''))();
  IntColumn get parentId => integer().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}
