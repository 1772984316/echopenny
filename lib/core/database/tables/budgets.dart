import 'package:drift/drift.dart';

class Budgets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get categoryId => integer().nullable()();
  RealColumn get amount => real()();
  TextColumn get month => text()();
  RealColumn get alertThreshold => real().withDefault(const Constant(0.8))();
}
