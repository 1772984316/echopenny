import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'tables/transactions.dart';
import 'tables/categories.dart';
import 'tables/accounts.dart';
import 'tables/transfers.dart';
import 'tables/budgets.dart';
import 'tables/conversations.dart';
import 'tables/personas.dart';
import 'tables/user_profile.dart';
import 'daos/transaction_dao.dart';
import 'daos/account_dao.dart';
import 'daos/category_dao.dart';
import 'daos/conversation_dao.dart';
import 'daos/persona_dao.dart';
import '../constants/categories_seed.dart';
import '../constants/persona_presets.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  Transactions,
  Categories,
  Accounts,
  Transfers,
  Budgets,
  Conversations,
  Personas,
  UserProfile,
], daos: [
  TransactionDao,
  AccountDao,
  CategoryDao,
  ConversationDao,
  PersonaDao,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await _seedDefaultData();
    },
  );

  Future<void> _seedDefaultData() async {
    for (final cat in defaultCategories) {
      final parentId = await into(categories).insert(
        CategoriesCompanion.insert(name: cat.name, icon: Value(cat.icon)),
      );
      for (final child in cat.children) {
        await into(categories).insert(
          CategoriesCompanion.insert(name: child, parentId: Value(parentId)),
        );
      }
    }

    await into(accounts).insert(
      AccountsCompanion.insert(
        name: '微信零钱',
        type: 'wechat',
        balance: const Value(0.0),
        isCredit: const Value(false),
        isDefault: const Value(true),
        sortOrder: 0,
        isHidden: const Value(false),
      ),
    );

    for (final preset in personaPresets) {
      await into(personas).insert(
        PersonasCompanion.insert(
          name: preset.name,
          systemPrompt: preset.systemPrompt,
          isDefault: Value(preset.isDefault),
          avatar: Value(preset.avatar),
          exampleDialogs: Value(preset.exampleDialogs),
        ),
      );
    }
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'echopenny.db'));
    return NativeDatabase.createInBackground(file);
  });
}
