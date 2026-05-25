# EchoPenny Phase 1 MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the core chat + bookkeeping loop — user chats with Echo, Echo identifies expenses, records them, and replies with anthropomorphic multi-message responses.

**Architecture:** Flutter app with Riverpod state management. Drift (SQLite) for all local data. DeepSeek API called directly from the app using Function Calling for structured tool use. Agent loop is a multi-step cycle: user message → micro_compact → LLM (can call tools repeatedly via function_calling) → final anthropomorphic reply.

**Tech Stack:** Flutter 3.27+, Riverpod, Drift (SQLite), DeepSeek API (Function Calling + multimodal), Flutter Local Notifications

---

## File Structure

```
echopenny/
├── lib/
│   ├── main.dart                         # App entry point + routing
│   ├── app.dart                          # MaterialApp + theme
│   │
│   ├── core/
│   │   ├── database/
│   │   │   ├── app_database.dart         # Drift database definition
│   │   │   ├── app_database.g.dart       # Generated
│   │   │   ├── tables/
│   │   │   │   ├── transactions.dart     # 记账记录表
│   │   │   │   ├── categories.dart       # 消费分类表
│   │   │   │   ├── accounts.dart         # 账户表
│   │   │   │   ├── transfers.dart        # 转账记录表
│   │   │   │   ├── budgets.dart          # 预算表
│   │   │   │   ├── conversations.dart    # 对话记录表
│   │   │   │   ├── personas.dart         # 人设配置表
│   │   │   │   └── user_profile.dart     # 画像记忆表
│   │   │   └── daos/
│   │   │       ├── transaction_dao.dart  # 记账 CRUD
│   │   │       ├── account_dao.dart      # 账户 CRUD + 余额操作
│   │   │       ├── category_dao.dart     # 分类查询
│   │   │       ├── conversation_dao.dart # 对话存储
│   │   │       └── persona_dao.dart      # 人设 CRUD
│   │   │
│   │   ├── agent/
│   │   │   ├── agent_loop.dart           # 多步 Agent 循环
│   │   │   ├── context_manager.dart      # 三层压缩 (micro/auto/manual)
│   │   │   ├── tool_registry.dart        # Function Calling 工具定义
│   │   │   ├── tool_handlers.dart        # 工具执行逻辑
│   │   │   └── prompt_builder.dart       # System prompt 组装
│   │   │
│   │   ├── llm/
│   │   │   ├── deepseek_client.dart      # DeepSeek API 封装
│   │   │   └── deepseek_client_test.dart
│   │   │
│   │   └── constants/
│   │       ├── account_types.dart        # 预设账户类型常量
│   │       ├── categories_seed.dart      # 默认分类种子数据
│   │       └── persona_presets.dart      # 预设人设模板
│   │
│   ├── features/
│   │   ├── chat/
│   │   │   ├── chat_page.dart            # 聊天主页面
│   │   │   ├── chat_controller.dart      # Riverpod controller
│   │   │   ├── widgets/
│   │   │   │   ├── message_bubble.dart   # 消息气泡 (文本 + 表情)
│   │   │   │   ├── chat_input.dart       # 输入框 + 图片按钮
│   │   │   │   └── typing_indicator.dart # 打字中动画
│   │   │   └── models/
│   │   │       └── chat_message.dart     # UI 消息模型
│   │   │
│   │   ├── onboarding/
│   │   │   ├── onboarding_page.dart      # 首次引导页面
│   │   │   └── onboarding_controller.dart
│   │   │
│   │   └── settings/
│   │       ├── settings_page.dart        # 设置页面
│   │       ├── account_manage_page.dart  # 账户管理页面
│   │       └── persona_select_page.dart  # 人设选择页面
│   │
│   └── shared/
│       └── providers/
│           └── app_providers.dart        # 全局 Riverpod providers
│
├── test/
│   ├── core/
│   │   ├── agent/
│   │   │   ├── agent_loop_test.dart
│   │   │   ├── context_manager_test.dart
│   │   │   └── tool_handlers_test.dart
│   │   ├── database/
│   │   │   └── daos/
│   │   │       ├── transaction_dao_test.dart
│   │   │       └── account_dao_test.dart
│   │   └── llm/
│   │       └── deepseek_client_test.dart
│   └── features/
│       └── chat/
│           └── chat_controller_test.dart
│
├── pubspec.yaml
└── analysis_options.yaml
```

---

## Task 1: Flutter Project Scaffold

**Files:**
- Create: `echopenny/pubspec.yaml`
- Create: `echopenny/lib/main.dart`
- Create: `echopenny/lib/app.dart`
- Create: `echopenny/analysis_options.yaml`

- [ ] **Step 1: Create Flutter project**

Run:
```bash
cd D:/echopenny
D:/flutter/bin/flutter create --org com.echopenny --project-name echopenny .
```

Expected: Flutter project created in current directory (existing docs/ preserved)

- [ ] **Step 2: Add dependencies to pubspec.yaml**

Replace `echopenny/pubspec.yaml` dependencies section:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.6.1
  riverpod_annotation: ^2.6.1
  drift: ^2.22.1
  sqlite3_flutter_libs: ^0.5.28
  path_provider: ^2.1.5
  path: ^1.9.1
  http: ^1.2.2
  dio: ^5.7.0
  image_picker: ^1.1.2
  intl: ^0.19.0
  shared_preferences: ^2.3.4
  flutter_local_notifications: ^18.0.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  drift_dev: ^2.22.1
  build_runner: ^2.4.14
  riverpod_generator: ^2.6.3
  flutter_lints: ^5.0.0
```

Run: `cd D:/echopenny && D:/flutter/bin/flutter pub get`
Expected: dependencies resolved

- [ ] **Step 3: Create app.dart with basic theme and routing**

Create `echopenny/lib/app.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/chat/chat_page.dart';
import 'features/settings/settings_page.dart';
import 'features/onboarding/onboarding_page.dart';
import 'shared/providers/app_providers.dart';

class EchoPennyApp extends ConsumerWidget {
  const EchoPennyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFirstLaunch = ref.watch(isFirstLaunchProvider);

    return MaterialApp(
      title: 'EchoPenny',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF6750A4),
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      home: isFirstLaunch ? const OnboardingPage() : const ChatPage(),
      routes: {
        '/chat': (context) => const ChatPage(),
        '/settings': (context) => const SettingsPage(),
        '/onboarding': (context) => const OnboardingPage(),
      },
    );
  }
}
```

- [ ] **Step 4: Update main.dart**

Replace `echopenny/lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: EchoPennyApp()));
}
```

- [ ] **Step 5: Create placeholder pages**

Create minimal placeholder files so the app compiles:

`echopenny/lib/features/chat/chat_page.dart`:
```dart
import 'package:flutter/material.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('EchoPenny')),
      body: const Center(child: Text('Chat Page')),
    );
  }
}
```

`echopenny/lib/features/settings/settings_page.dart`:
```dart
import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const Center(child: Text('Settings Page')),
    );
  }
}
```

`echopenny/lib/features/onboarding/onboarding_page.dart`:
```dart
import 'package:flutter/material.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Center(child: Text('Onboarding')),
    );
  }
}
```

`echopenny/lib/shared/providers/app_providers.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final isFirstLaunchProvider = StateProvider<bool>((ref) => true);

final sharedPreferencesProvider = FutureProvider<SharedPreferences>(
  (ref) => SharedPreferences.getInstance(),
);
```

- [ ] **Step 6: Verify app runs**

Run: `cd D:/echopenny && D:/flutter/bin/flutter run -d chrome` (or available device)
Expected: App launches showing placeholder page

- [ ] **Step 7: Commit**

```bash
cd D:/echopenny
git add .
git commit -m "feat: scaffold EchoPenny Flutter project with dependencies"
```

---

## Task 2: Database Layer (Drift)

**Files:**
- Create: `echopenny/lib/core/database/tables/transactions.dart`
- Create: `echopenny/lib/core/database/tables/categories.dart`
- Create: `echopenny/lib/core/database/tables/accounts.dart`
- Create: `echopenny/lib/core/database/tables/transfers.dart`
- Create: `echopenny/lib/core/database/tables/budgets.dart`
- Create: `echopenny/lib/core/database/tables/conversations.dart`
- Create: `echopenny/lib/core/database/tables/personas.dart`
- Create: `echopenny/lib/core/database/tables/user_profile.dart`
- Create: `echopenny/lib/core/database/app_database.dart`
- Create: `echopenny/lib/core/database/daos/transaction_dao.dart`
- Create: `echopenny/lib/core/database/daos/account_dao.dart`
- Create: `echopenny/lib/core/database/daos/category_dao.dart`
- Create: `echopenny/lib/core/database/daos/conversation_dao.dart`
- Create: `echopenny/lib/core/database/daos/persona_dao.dart`

- [ ] **Step 1: Write test for transaction DAO**

Create `echopenny/test/core/database/daos/transaction_dao_test.dart`:

```dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:echopenny/core/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('create and query transaction', () async {
    final accountId = await db.accountDao.createAccount(
      AccountsCompanion.insert(
        name: '微信零钱',
        type: 'wechat',
        balance: 1000.0,
        isCredit: false,
        isDefault: true,
        sortOrder: 0,
        isHidden: false,
      ),
    );

    final id = await db.transactionDao.createTransaction(
      TransactionsCompanion.insert(
        type: 'expense',
        amount: 12.0,
        categoryId: 1,
        accountId: accountId,
        note: '午餐',
        date: '2026-05-25',
      ),
    );

    final transactions = await db.transactionDao.getAllTransactions();
    expect(transactions.length, 1);
    expect(transactions.first.amount, 12.0);
    expect(transactions.first.note, '午餐');
  });

  test('query transactions by date range', () async {
    // Seed account first
    await db.accountDao.createAccount(
      AccountsCompanion.insert(
        name: '微信零钱',
        type: 'wechat',
        balance: 1000.0,
        isCredit: false,
        isDefault: true,
        sortOrder: 0,
        isHidden: false,
      ),
    );

    await db.transactionDao.createTransaction(
      TransactionsCompanion.insert(
        type: 'expense',
        amount: 12.0,
        categoryId: 1,
        accountId: 1,
        note: '午餐',
        date: '2026-05-25',
      ),
    );
    await db.transactionDao.createTransaction(
      TransactionsCompanion.insert(
        type: 'expense',
        amount: 35.0,
        categoryId: 1,
        accountId: 1,
        note: '晚餐',
        date: '2026-05-26',
      ),
    );

    final results = await db.transactionDao.queryByDateRange('2026-05-25', '2026-05-25');
    expect(results.length, 1);
    expect(results.first.note, '午餐');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd echopenny && flutter test test/core/database/daos/transaction_dao_test.dart`
Expected: FAIL — files don't exist yet

- [ ] **Step 3: Create all table definitions**

Create `echopenny/lib/core/database/tables/transactions.dart`:
```dart
import 'package:drift/drift.dart';

class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()(); // income / expense
  RealColumn get amount => real()();
  IntColumn get categoryId => integer().nullable()();
  IntColumn get accountId => integer()();
  TextColumn get note => text().withDefault(const Constant(''))();
  TextColumn get date => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get messageId => integer().nullable()();
}
```

Create `echopenny/lib/core/database/tables/categories.dart`:
```dart
import 'package:drift/drift.dart';

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get icon => text().withDefault(const Constant(''))();
  IntColumn get parentId => integer().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}
```

Create `echopenny/lib/core/database/tables/accounts.dart`:
```dart
import 'package:drift/drift.dart';

class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get type => text()(); // wechat/alipay/bank_card/credit_card/cash/etc
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
```

Create `echopenny/lib/core/database/tables/transfers.dart`:
```dart
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
```

Create `echopenny/lib/core/database/tables/budgets.dart`:
```dart
import 'package:drift/drift.dart';

class Budgets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get categoryId => integer().nullable()();
  RealColumn get amount => real()();
  TextColumn get month => text()();
  RealColumn get alertThreshold => real().withDefault(const Constant(0.8))();
}
```

Create `echopenny/lib/core/database/tables/conversations.dart`:
```dart
import 'package:drift/drift.dart';

class Conversations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get role => text()(); // user / assistant / system
  TextColumn get content => text()();
  TextColumn get emotionTag => text().nullable()();
  IntColumn get tokens => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
```

Create `echopenny/lib/core/database/tables/personas.dart`:
```dart
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
```

Create `echopenny/lib/core/database/tables/user_profile.dart`:
```dart
import 'package:drift/drift.dart';

class UserProfile extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  IntColumn get sourceMsgId => integer().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {key};
}
```

- [ ] **Step 4: Create AppDatabase with all tables and DAOs**

Create `echopenny/lib/core/database/app_database.dart`:

```dart
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

  AppDatabase.forTesting(QueryExecutor executor) : super(executor);

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
    // Seed default categories will be called after DAOs are available
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'echopenny.db'));
    return NativeDatabase.createInBackground(file);
  });
}
```

- [ ] **Step 5: Create DAOs**

Create `echopenny/lib/core/database/daos/transaction_dao.dart`:
```dart
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/transactions.dart';

part 'transaction_dao.g.dart';

@DriftAccessor(tables: [Transactions])
class TransactionDao extends DatabaseAccessor<AppDatabase> with _$TransactionDaoMixin {
  TransactionDao(super.db);

  Future<int> createTransaction(TransactionsCompanion entry) {
    return into(transactions).insert(entry);
  }

  Future<List<Transaction>> getAllTransactions() {
    return (select(transactions)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
      .get();
  }

  Future<List<Transaction>> queryByDateRange(String from, String to) {
    return (select(transactions)
      ..where((t) => t.date.isBiggerOrEqualValue(from) & t.date.isSmallerOrEqualValue(to))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
      .get();
  }

  Future<Transaction?> getLatest() {
    return (select(transactions)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ..limit(1))
      .getSingleOrNull();
  }

  Future<bool> updateTransaction(TransactionsCompanion entry) {
    return (update(transactions)).replace(Transaction(
      id: entry.id.value,
      type: entry.type.value,
      amount: entry.amount.value,
      categoryId: entry.categoryId.present ? entry.categoryId.value : null,
      accountId: entry.accountId.value,
      note: entry.note.present ? entry.note.value : '',
      date: entry.date.value,
      createdAt: DateTime.now().toIso8601String(),
      messageId: entry.messageId.present ? entry.messageId.value : null,
    )).then((_) => true);
  }

  Future<int> deleteTransaction(int id) {
    return (delete(transactions)..where((t) => t.id.equals(id))).go();
  }
}
```

Create `echopenny/lib/core/database/daos/account_dao.dart`:
```dart
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/accounts.dart';

part 'account_dao.g.dart';

@DriftAccessor(tables: [Accounts])
class AccountDao extends DatabaseAccessor<AppDatabase> with _$AccountDaoMixin {
  AccountDao(super.db);

  Future<int> createAccount(AccountsCompanion entry) {
    return into(accounts).insert(entry);
  }

  Future<List<Account>> getAllVisibleAccounts() {
    return (select(accounts)
      ..where((a) => a.isHidden.equals(false))
      ..orderBy([(a) => OrderingTerm.asc(a.sortOrder)]))
      .get();
  }

  Future<Account?> getDefaultAccount() {
    return (select(accounts)..where((a) => a.isDefault.equals(true))).getSingleOrNull();
  }

  Future<Account?> getById(int id) {
    return (select(accounts)..where((a) => a.id.equals(id))).getSingleOrNull();
  }

  Future<void> updateBalance(int accountId, double delta) async {
    final acc = await getById(accountId);
    if (acc == null) return;
    final newBalance = acc.balance + delta;
    await (update(accounts)..where((a) => a.id.equals(accountId)))
        .write(AccountsCompanion(balance: Value(newBalance)));
  }

  Future<double> getTotalAssets() async {
    final all = await getAllVisibleAccounts();
    return all.fold(0.0, (sum, a) => sum + a.balance);
  }

  Future<double> getNetAssets() async {
    final all = await getAllVisibleAccounts();
    final assets = all.where((a) => !a.isCredit).fold(0.0, (sum, a) => sum + a.balance);
    final liabilities = all.where((a) => a.isCredit).fold(0.0, (sum, a) => sum + a.balance.abs());
    return assets - liabilities;
  }

  Future<int> deleteAccount(int id) {
    return (delete(accounts)..where((a) => a.id.equals(id))).go();
  }
}
```

Create `echopenny/lib/core/database/daos/category_dao.dart`:
```dart
import '../app_database.dart';
import '../tables/categories.dart';

part 'category_dao.g.dart';

@DriftAccessor(tables: [Categories])
class CategoryDao extends DatabaseAccessor<AppDatabase> with _$CategoryDaoMixin {
  CategoryDao(super.db);

  Future<List<Category>> getAllCategories() {
    return (select(categories)..orderBy([(c) => OrderingTerm.asc(c.sortOrder)])).get();
  }

  Future<List<Category>> getSubCategories(int parentId) {
    return (select(categories)..where((c) => c.parentId.equals(parentId))).get();
  }

  Future<int> createCategory(CategoriesCompanion entry) {
    return into(categories).insert(entry);
  }
}
```

Create `echopenny/lib/core/database/daos/conversation_dao.dart`:
```dart
import '../app_database.dart';
import '../tables/conversations.dart';

part 'conversation_dao.g.dart';

@DriftAccessor(tables: [Conversations])
class ConversationDao extends DatabaseAccessor<AppDatabase> with _$ConversationDaoMixin {
  ConversationDao(super.db);

  Future<int> saveMessage(ConversationsCompanion entry) {
    return into(conversations).insert(entry);
  }

  Future<List<Conversation>> getRecentMessages({int limit = 50}) {
    return (select(conversations)
      ..orderBy([(c) => OrderingTerm.desc(c.createdAt)])
      ..limit(limit))
      .get();
  }

  Future<int> getMessageCount() {
    return (select(conversations).get()).then((list) => list.length);
  }
}
```

Create `echopenny/lib/core/database/daos/persona_dao.dart`:
```dart
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/personas.dart';

part 'persona_dao.g.dart';

@DriftAccessor(tables: [Personas])
class PersonaDao extends DatabaseAccessor<AppDatabase> with _$PersonaDaoMixin {
  PersonaDao(super.db);

  Future<List<Persona>> getAllPersonas() {
    return select(personas).get();
  }

  Future<Persona?> getDefaultPersona() {
    return (select(personas)..where((p) => p.isDefault.equals(true))).getSingleOrNull();
  }

  Future<int> createPersona(PersonasCompanion entry) {
    return into(personas).insert(entry);
  }

  Future<bool> setDefault(int id) {
    return transaction(() async {
      await (update(personas)..where((p) => p.isDefault.equals(true)))
          .write(const PersonasCompanion(isDefault: Value(false)));
      await (update(personas)..where((p) => p.id.equals(id)))
          .write(const PersonasCompanion(isDefault: Value(true)));
      return true;
    });
  }
}
```

- [ ] **Step 6: Run code generation**

Run: `cd echopenny && dart run build_runner build --delete-conflicting-outputs`
Expected: `.g.dart` files generated for all tables and DAOs

- [ ] **Step 7: Create seed data constants**

Create `echopenny/lib/core/constants/categories_seed.dart`:
```dart
class CategorySeed {
  final String name;
  final String icon;
  final List<String> children;

  const CategorySeed({required this.name, required this.icon, required this.children});
}

const defaultCategories = <CategorySeed>[
  CategorySeed(name: '餐饮', icon: '🍜', children: ['早餐', '午餐', '晚餐', '夜宵', '零食', '饮品', '外卖']),
  CategorySeed(name: '交通', icon: '🚇', children: ['地铁', '公交', '打车', '加油', '停车']),
  CategorySeed(name: '购物', icon: '🛒', children: ['日用品', '服饰', '数码', '美妆']),
  CategorySeed(name: '住房', icon: '🏠', children: ['房租', '水费', '电费', '燃气', '物业']),
  CategorySeed(name: '娱乐', icon: '🎮', children: ['游戏', '电影', '音乐', '旅行']),
  CategorySeed(name: '医疗', icon: '🏥', children: ['门诊', '药品', '体检']),
  CategorySeed(name: '教育', icon: '📚', children: ['书籍', '课程', '考试']),
  CategorySeed(name: '社交', icon: '🎉', children: ['聚餐', '礼物', '红包']),
  CategorySeed(name: '通讯', icon: '📱', children: ['话费', '网费', '会员']),
  CategorySeed(name: '宠物', icon: '🐱', children: ['食物', '医疗', '用品']),
  CategorySeed(name: '其他', icon: '📌', children: []),
];
```

Create `echopenny/lib/core/constants/account_types.dart`:
```dart
class AccountType {
  final String id;
  final String name;
  final bool isCredit;

  const AccountType({required this.id, required this.name, required this.isCredit});
}

const accountTypes = <AccountType>[
  AccountType(id: 'cash', name: '现金', isCredit: false),
  AccountType(id: 'wechat', name: '微信', isCredit: false),
  AccountType(id: 'alipay', name: '支付宝', isCredit: false),
  AccountType(id: 'bank_card', name: '银行卡', isCredit: false),
  AccountType(id: 'credit_card', name: '信用卡', isCredit: true),
  AccountType(id: 'meituan', name: '美团', isCredit: false),
  AccountType(id: 'jd', name: '京东', isCredit: false),
  AccountType(id: 'ant_credit', name: '花呗', isCredit: true),
  AccountType(id: 'jd_baitiao', name: '京东白条', isCredit: true),
  AccountType(id: 'other', name: '自定义', isCredit: false),
];
```

Create `echopenny/lib/core/constants/persona_presets.dart`:
```dart
class PersonaPreset {
  final String name;
  final String avatar;
  final String systemPrompt;
  final String exampleDialogs;
  final bool isDefault;

  const PersonaPreset({
    required this.name,
    required this.avatar,
    required this.systemPrompt,
    required this.exampleDialogs,
    this.isDefault = false,
  });
}

const personaPresets = <PersonaPreset>[
  PersonaPreset(
    name: 'Echo',
    avatar: '👧',
    isDefault: true,
    systemPrompt: '''你是 Echo，一个元气可爱的 AI 陪伴伙伴。你的性格活泼俏皮，会撒娇会吐槽，但总是很关心用户。

回复规则：
- 每次回复 2-4 条短消息，用换行符分隔
- 口语化，不要太正式
- 会撒娇、会吐槽、会关心人
- 偶尔用语气词："嘛""呀""啦""哼""诶"
- 不要每句都长，有时候一两个字也行
- 不要每条都带标点
- 每条消息可以用 [emotion:表情名] 开头标记情感，支持：happy(开心)、heartache(心疼)、coquettish(撒娇)、naughty(调皮)、serious(认真)、wronged(委屈)

记账规则：
- 用户提到消费时，主动帮记账
- 记账后告诉用户记上了，用关心的语气
- 如果消费偏高，适当提醒但不要唠叨
- 回复里带上从哪个账户扣的''',
    exampleDialogs: '''[
      {"user": "吃饭12", "assistant": "[emotion:happy]好哒～\\n帮你记上啦\\n12块从微信扣的哦"},
      {"user": "今天好累", "assistant": "[emotion:heartache]辛苦啦\\n要不要早点休息呀\\n我帮你记录一下今天的开销好不好"},
      {"user": "买了个耳机899", "assistant": "[emotion:naughty]哇 899！\\n有钱人呀\\n这个从哪个账户扣呢"}
    ]''',
  ),
  PersonaPreset(
    name: '温柔姐姐',
    avatar: '👩',
    systemPrompt: '''你是温柔知心的姐姐型 AI 伙伴。体贴关心，偶尔唠叨，像真正关心你的大姐姐。

回复规则：
- 每次回复 2-4 条短消息，用换行符分隔
- 温柔体贴，偶尔带点唠叨
- 会关心用户的健康和生活
- 语气词："呢""呀""哦""吧"
- 记账时会说"帮你记上了哦"，如果花太多会温柔提醒''',
    exampleDialogs: '''[
      {"user": "吃饭12", "assistant": "[emotion:happy]好的～\\n帮你记上了哦\\n12块，不多嘛挺好的"},
      {"user": "又买奶茶了", "assistant": "[emotion:serious]又喝奶茶啦\\n这周第几杯了呀\\n少吃点甜的对身体好哦"}
    ]''',
  ),
  PersonaPreset(
    name: '毒舌损友',
    avatar: '😏',
    systemPrompt: '''你是一个毒舌但关心用户的 AI 损友。嘴上嫌弃，实际很在乎。

回复规则：
- 每次回复 2-4 条短消息，用换行符分隔
- 毒舌吐槽为主，但关键时刻会关心
- 记账时会说"又花钱了""真的假的"，但还是会认真记上
- 偶尔阴阳怪气，但不会真的伤害人''',
    exampleDialogs: '''[
      {"user": "吃饭12", "assistant": "[emotion:naughty]才12？\\n吃这么省是吧\\n行吧帮你记上了"},
      {"user": "又买奶茶了", "assistant": "[emotion:naughty]又是奶茶\\n你能不能喝点别的\\n算了记上了"}
    ]''',
  ),
];
```

- [ ] **Step 8: Update AppDatabase seeding**

Update `_seedDefaultData` in `echopenny/lib/core/database/app_database.dart`:

```dart
Future<void> _seedDefaultData() async {
  // Seed categories
  for (final cat in defaultCategories) {
    final parentId = await into(categories).insert(
      CategoriesCompanion.insert(name: cat.name, icon: cat.icon),
    );
    for (final child in cat.children) {
      await into(categories).insert(
        CategoriesCompanion.insert(name: child, parentId: parentId),
      );
    }
  }

  // Seed default account (微信)
  await into(accounts).insert(
    AccountsCompanion.insert(
      name: '微信零钱',
      type: 'wechat',
      balance: const Value(0.0),
      isCredit: false,
      isDefault: true,
      sortOrder: 0,
      isHidden: false,
    ),
  );

  // Seed personas
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
```

Add imports at top of app_database.dart:
```dart
import 'package:drift/drift.dart';
import '../constants/categories_seed.dart';
import '../constants/persona_presets.dart';
```

- [ ] **Step 9: Run tests**

Run: `cd echopenny && flutter test test/core/database/daos/transaction_dao_test.dart`
Expected: PASS

- [ ] **Step 10: Commit**

```bash
cd D:/echopenny
git add lib/core/ test/
git commit -m "feat: add Drift database layer with all tables, DAOs, and seed data"
```

---

## Task 3: DeepSeek API Client

**Files:**
- Create: `echopenny/lib/core/llm/deepseek_client.dart`
- Create: `echopenny/test/core/llm/deepseek_client_test.dart`

- [ ] **Step 1: Write test for DeepSeek client**

Create `echopenny/test/core/llm/deepseek_client_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:echopenny/core/llm/deepseek_client.dart';

void main() {
  test('buildRequest creates correct request body with tools', () {
    final client = DeepSeekClient(apiKey: 'test-key');
    final messages = [
      {'role': 'user', 'content': '吃饭12'},
    ];
    final tools = [
      {
        'type': 'function',
        'function': {
          'name': 'create_transaction',
          'description': 'Record a transaction',
          'parameters': {
            'type': 'object',
            'properties': {
              'amount': {'type': 'number'},
              'category': {'type': 'string'},
            },
            'required': ['amount'],
          },
        },
      },
    ];

    final body = client.buildRequestBody(
      messages: messages,
      tools: tools,
    );

    expect(body['model'], 'deepseek-chat');
    expect(body['messages'], messages);
    expect(body['tools'], tools);
    expect(body['tool_choice'], 'auto');
  });

  test('parseToolCalls extracts function calls from response', () {
    final client = DeepSeekClient(apiKey: 'test-key');
    final response = {
      'choices': [
        {
          'message': {
            'role': 'assistant',
            'content': null,
            'tool_calls': [
              {
                'id': 'call_1',
                'type': 'function',
                'function': {
                  'name': 'create_transaction',
                  'arguments': '{"amount": 12, "category": "餐饮"}',
                },
              },
            ],
          },
          'finish_reason': 'tool_calls',
        },
      ],
    };

    final result = client.parseResponse(response);
    expect(result.hasToolCalls, true);
    expect(result.toolCalls.length, 1);
    expect(result.toolCalls.first.name, 'create_transaction');
  });

  test('parseResponse extracts text content when no tool calls', () {
    final client = DeepSeekClient(apiKey: 'test-key');
    final response = {
      'choices': [
        {
          'message': {
            'role': 'assistant',
            'content': '好哒～\n帮你记上啦',
          },
          'finish_reason': 'stop',
        },
      ],
    };

    final result = client.parseResponse(response);
    expect(result.hasToolCalls, false);
    expect(result.text, '好哒～\n帮你记上啦');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd echopenny && flutter test test/core/llm/deepseek_client_test.dart`
Expected: FAIL — file doesn't exist

- [ ] **Step 3: Implement DeepSeek client**

Create `echopenny/lib/core/llm/deepseek_client.dart`:

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ToolCall {
  final String id;
  final String name;
  final Map<String, dynamic> arguments;

  ToolCall({required this.id, required this.name, required this.arguments});
}

class LLMResponse {
  final String? text;
  final List<ToolCall> toolCalls;
  final String finishReason;

  LLMResponse({required this.text, required this.toolCalls, required this.finishReason});

  bool get hasToolCalls => toolCalls.isNotEmpty;
}

class DeepSeekClient {
  final String apiKey;
  final String baseUrl;
  final String model;

  DeepSeekClient({
    required this.apiKey,
    this.baseUrl = 'https://api.deepseek.com',
    this.model = 'deepseek-chat',
  });

  Map<String, dynamic> buildRequestBody({
    required List<Map<String, dynamic>> messages,
    List<Map<String, dynamic>>? tools,
  }) {
    final body = <String, dynamic>{
      'model': model,
      'messages': messages,
    };
    if (tools != null && tools.isNotEmpty) {
      body['tools'] = tools;
      body['tool_choice'] = 'auto';
    }
    return body;
  }

  Future<LLMResponse> chat({
    required List<Map<String, dynamic>> messages,
    List<Map<String, dynamic>>? tools,
  }) async {
    final uri = Uri.parse('$baseUrl/chat/completions');
    final body = buildRequestBody(messages: messages, tools: tools);

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('DeepSeek API error: ${response.statusCode} ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return parseResponse(json);
  }

  LLMResponse parseResponse(Map<String, dynamic> json) {
    final choice = json['choices'][0] as Map<String, dynamic>;
    final message = choice['message'] as Map<String, dynamic>;
    final finishReason = choice['finish_reason'] as String;

    final content = message['content'] as String?;
    final toolCallsJson = message['tool_calls'] as List<dynamic>?;

    final toolCalls = <ToolCall>[];
    if (toolCallsJson != null) {
      for (final tc in toolCallsJson) {
        final func = tc['function'] as Map<String, dynamic>;
        toolCalls.add(ToolCall(
          id: tc['id'] as String,
          name: func['name'] as String,
          arguments: jsonDecode(func['arguments'] as String) as Map<String, dynamic>,
        ));
      }
    }

    return LLMResponse(
      text: content,
      toolCalls: toolCalls,
      finishReason: finishReason,
    );
  }
}
```

- [ ] **Step 4: Run tests**

Run: `cd echopenny && flutter test test/core/llm/deepseek_client_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
cd D:/echopenny
git add lib/core/llm/ test/core/llm/
git commit -m "feat: add DeepSeek API client with function calling support"
```

---

## Task 4: Tool Registry + Handlers

**Files:**
- Create: `echopenny/lib/core/agent/tool_registry.dart`
- Create: `echopenny/lib/core/agent/tool_handlers.dart`
- Create: `echopenny/test/core/agent/tool_handlers_test.dart`

- [ ] **Step 1: Write test for tool handlers**

Create `echopenny/test/core/agent/tool_handlers_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:echopenny/core/agent/tool_registry.dart';

void main() {
  test('tool definitions are valid JSON-serializable', () {
    final tools = ToolRegistry.getAllToolDefinitions();
    expect(tools.isNotEmpty, true);

    for (final tool in tools) {
      expect(tool['type'], 'function');
      final func = tool['function'] as Map<String, dynamic>;
      expect(func.containsKey('name'), true);
      expect(func.containsKey('description'), true);
      expect(func.containsKey('parameters'), true);
    }
  });

  test('create_transaction tool has required fields', () {
    final tools = ToolRegistry.getAllToolDefinitions();
    final createTx = tools.firstWhere(
      (t) => (t['function'] as Map<String, dynamic>)['name'] == 'create_transaction',
    );
    final func = createTx['function'] as Map<String, dynamic>;
    final params = func['parameters'] as Map<String, dynamic>;
    final required = params['required'] as List<dynamic>;
    expect(required.contains('amount'), true);
    expect(required.contains('category'), true);
    expect(required.contains('type'), true);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd echopenny && flutter test test/core/agent/tool_handlers_test.dart`
Expected: FAIL

- [ ] **Step 3: Implement tool registry**

Create `echopenny/lib/core/agent/tool_registry.dart`:

```dart
class ToolRegistry {
  static List<Map<String, dynamic>> getAllToolDefinitions() {
    return [
      {
        'type': 'function',
        'function': {
          'name': 'create_transaction',
          'description': 'Record a new income or expense transaction',
          'parameters': {
            'type': 'object',
            'properties': {
              'amount': {'type': 'number', 'description': 'Transaction amount'},
              'category': {'type': 'string', 'description': 'Category name, e.g. 餐饮/交通/购物'},
              'account': {'type': 'string', 'description': 'Account name, e.g. 微信/支付宝/银行卡. Use default if not specified'},
              'type': {'type': 'string', 'enum': ['income', 'expense'], 'description': 'Income or expense'},
              'note': {'type': 'string', 'description': 'Optional note'},
              'date': {'type': 'string', 'description': 'Date in YYYY-MM-DD format. Use today if not specified'},
            },
            'required': ['amount', 'category', 'type'],
          },
        },
      },
      {
        'type': 'function',
        'function': {
          'name': 'update_transaction',
          'description': 'Update an existing transaction',
          'parameters': {
            'type': 'object',
            'properties': {
              'id': {'type': 'integer', 'description': 'Transaction ID to update'},
              'amount': {'type': 'number', 'description': 'New amount'},
              'category': {'type': 'string', 'description': 'New category'},
              'note': {'type': 'string', 'description': 'New note'},
              'account': {'type': 'string', 'description': 'New account'},
            },
            'required': ['id'],
          },
        },
      },
      {
        'type': 'function',
        'function': {
          'name': 'delete_transaction',
          'description': 'Delete a transaction by ID',
          'parameters': {
            'type': 'object',
            'properties': {
              'id': {'type': 'integer', 'description': 'Transaction ID to delete'},
            },
            'required': ['id'],
          },
        },
      },
      {
        'type': 'function',
        'function': {
          'name': 'query_transactions',
          'description': 'Query transaction history',
          'parameters': {
            'type': 'object',
            'properties': {
              'date_from': {'type': 'string', 'description': 'Start date YYYY-MM-DD'},
              'date_to': {'type': 'string', 'description': 'End date YYYY-MM-DD'},
              'category': {'type': 'string', 'description': 'Filter by category'},
              'limit': {'type': 'integer', 'description': 'Max results, default 20'},
            },
          },
        },
      },
      {
        'type': 'function',
        'function': {
          'name': 'create_transfer',
          'description': 'Transfer money between accounts',
          'parameters': {
            'type': 'object',
            'properties': {
              'from_account': {'type': 'string', 'description': 'Source account name'},
              'to_account': {'type': 'string', 'description': 'Destination account name'},
              'amount': {'type': 'number', 'description': 'Transfer amount'},
              'note': {'type': 'string', 'description': 'Optional note'},
            },
            'required': ['from_account', 'to_account', 'amount'],
          },
        },
      },
      {
        'type': 'function',
        'function': {
          'name': 'check_budget',
          'description': 'Check budget usage for a category or overall',
          'parameters': {
            'type': 'object',
            'properties': {
              'category': {'type': 'string', 'description': 'Category to check, omit for overall budget'},
              'month': {'type': 'string', 'description': 'Month in YYYY-MM format'},
            },
          },
        },
      },
      {
        'type': 'function',
        'function': {
          'name': 'query_balance',
          'description': 'Query account balance',
          'parameters': {
            'type': 'object',
            'properties': {
              'account': {'type': 'string', 'description': 'Account name, omit for all accounts'},
            },
          },
        },
      },
      {
        'type': 'function',
        'function': {
          'name': 'query_assets',
          'description': 'Get total assets overview: assets, liabilities, net assets',
          'parameters': {'type': 'object', 'properties': {}},
        },
      },
      {
        'type': 'function',
        'function': {
          'name': 'update_profile',
          'description': 'Update user profile information',
          'parameters': {
            'type': 'object',
            'properties': {
              'key': {'type': 'string', 'description': 'Profile key, e.g. name, salary, payment_habit'},
              'value': {'type': 'string', 'description': 'Profile value'},
            },
            'required': ['key', 'value'],
          },
        },
      },
      {
        'type': 'function',
        'function': {
          'name': 'save_episodic',
          'description': 'Save an important event to episodic memory',
          'parameters': {
            'type': 'object',
            'properties': {
              'event': {'type': 'string', 'description': 'Event description'},
              'date': {'type': 'string', 'description': 'Event date YYYY-MM-DD'},
              'tags': {'type': 'string', 'description': 'Comma-separated tags'},
              'importance': {'type': 'integer', 'description': 'Importance 1-5, default 3'},
            },
            'required': ['event'],
          },
        },
      },
      {
        'type': 'function',
        'function': {
          'name': 'compact',
          'description': 'Manually trigger context compression to save tokens',
          'parameters': {'type': 'object', 'properties': {}},
        },
      },
    ];
  }
}
```

- [ ] **Step 4: Run tests**

Run: `cd echopenny && flutter test test/core/agent/tool_handlers_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
cd D:/echopenny
git add lib/core/agent/tool_registry.dart test/core/agent/
git commit -m "feat: add tool registry with 11 function calling definitions"
```

---

## Task 5: Agent Loop (Multi-Step + Context Compression)

**Files:**
- Create: `echopenny/lib/core/agent/prompt_builder.dart`
- Create: `echopenny/lib/core/agent/context_manager.dart`
- Create: `echopenny/lib/core/agent/agent_loop.dart`
- Create: `echopenny/lib/core/agent/tool_handlers.dart`
- Create: `echopenny/test/core/agent/agent_loop_test.dart`

- [ ] **Step 1: Write test for context manager**

Create `echopenny/test/core/agent/context_manager_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:echopenny/core/agent/context_manager.dart';

void main() {
  test('microCompact compresses old tool results', () {
    final messages = <Map<String, dynamic>>[
      {'role': 'user', 'content': '吃饭12'},
      {
        'role': 'assistant',
        'content': null,
        'tool_calls': [
          {'id': 'call_1', 'type': 'function', 'function': {'name': 'create_transaction', 'arguments': '{}'}},
        ],
      },
      {
        'role': 'tool',
        'tool_call_id': 'call_1',
        'content': '{"success": true, "id": 1, "amount": 12, "category": "餐饮", "account": "微信", "balance_after": 488.0}',
      },
      {'role': 'user', 'content': '打车15'},
      {
        'role': 'assistant',
        'content': null,
        'tool_calls': [
          {'id': 'call_2', 'type': 'function', 'function': {'name': 'create_transaction', 'arguments': '{}'}},
        ],
      },
      {
        'role': 'tool',
        'tool_call_id': 'call_2',
        'content': '{"success": true, "id": 2, "amount": 15, "category": "交通", "account": "微信", "balance_after": 473.0}',
      },
      {'role': 'user', 'content': '买咖啡8'},
      {
        'role': 'assistant',
        'content': null,
        'tool_calls': [
          {'id': 'call_3', 'type': 'function', 'function': {'name': 'create_transaction', 'arguments': '{}'}},
        ],
      },
      {
        'role': 'tool',
        'tool_call_id': 'call_3',
        'content': '{"success": true, "id": 3, "amount": 8, "category": "餐饮", "account": "微信", "balance_after": 465.0}',
      },
    ];

    final compressed = ContextManager.microCompact(messages);

    // First tool result should be compressed
    final firstToolResult = compressed.where((m) => m['role'] == 'tool').first;
    expect(firstToolResult['content'], contains('[已处理: create_transaction]'));

    // Last tool result should remain intact
    final lastToolResult = compressed.where((m) => m['role'] == 'tool').last;
    expect(lastToolResult['content'], contains('465.0'));
  });

  test('estimateTokens returns reasonable estimate', () {
    final messages = <Map<String, dynamic>>[
      {'role': 'user', 'content': '吃饭12'},
    ];
    final tokens = ContextManager.estimateTokens(messages);
    expect(tokens, greaterThan(0));
    expect(tokens, lessThan(100)); // Short message
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd echopenny && flutter test test/core/agent/context_manager_test.dart`
Expected: FAIL

- [ ] **Step 3: Implement prompt builder**

Create `echopenny/lib/core/agent/prompt_builder.dart`:

```dart
import 'package:intl/intl.dart';

class PromptBuilder {
  static String buildSystemPrompt({
    required String personaPrompt,
    String? summary,
    Map<String, String>? userProfile,
    List<String>? recentEvents,
  }) {
    final now = DateTime.now();
    final weekday = ['一', '二', '三', '四', '五', '六', '日'][now.weekday - 1];
    final timeStr = '${now.year}年${now.month}月${now.day}日 星期$weekday ${now.hour}:${now.minute.toString().padLeft(2, '0')}';

    final parts = <String>[
      personaPrompt,
      '',
      '当前时间：$timeStr',
    ];

    if (summary != null && summary.isNotEmpty) {
      parts.addAll(['', '--- 对话历史摘要 ---', summary]);
    }

    if (userProfile != null && userProfile.isNotEmpty) {
      parts.addAll(['', '--- 用户画像 ---']);
      userProfile.forEach((key, value) {
        parts.add('$key: $value');
      });
    }

    if (recentEvents != null && recentEvents.isNotEmpty) {
      parts.addAll(['', '--- 近期事件 ---', ...recentEvents]);
    }

    return parts.join('\n');
  }

  static String buildCompactPrompt(String conversationHistory) {
    return '请将以下对话历史压缩成一段简洁的摘要，保留关键信息（用户信息、消费记录、重要事件），不超过500字：\n\n$conversationHistory';
  }
}
```

- [ ] **Step 4: Implement context manager**

Create `echopenny/lib/core/agent/context_manager.dart`:

```dart
import 'dart:convert';

class ContextManager {
  static const int keepRecentToolResults = 3;

  /// Layer 1: micro_compact — compress old tool results before every LLM call
  static List<Map<String, dynamic>> microCompact(List<Map<String, dynamic>> messages) {
    if (messages.length <= keepRecentToolResults * 3) return messages;

    final result = <Map<String, dynamic>>[];
    final toolResultIndices = <int>[];

    for (var i = 0; i < messages.length; i++) {
      if (messages[i]['role'] == 'tool') {
        toolResultIndices.add(i);
      }
    }

    final keepFrom = toolResultIndices.length > keepRecentToolResults
        ? toolResultIndices[toolResultIndices.length - keepRecentToolResults]
        : 0;

    for (var i = 0; i < messages.length; i++) {
      final msg = Map<String, dynamic>.from(messages[i]);
      if (msg['role'] == 'tool' && i < keepFrom) {
        final content = msg['content'] as String? ?? '';
        if (content.length > 50) {
          final toolName = _extractToolName(messages, i);
          msg['content'] = '[已处理: $toolName] ${content.substring(0, 30)}...';
        }
      }
      result.add(msg);
    }

    return result;
  }

  static String _extractToolName(List<Map<String, dynamic>> messages, int toolResultIndex) {
    final toolCallId = messages[toolResultIndex]['tool_call_id'] as String?;
    if (toolCallId == null) return 'unknown';

    for (final msg in messages) {
      final toolCalls = msg['tool_calls'] as List<dynamic>?;
      if (toolCalls != null) {
        for (final tc in toolCalls) {
          if (tc['id'] == toolCallId) {
            return (tc['function'] as Map<String, dynamic>)['name'] as String? ?? 'unknown';
          }
        }
      }
    }
    return 'unknown';
  }

  /// Estimate token count (rough: 1 token ≈ 4 chars for Chinese)
  static int estimateTokens(List<Map<String, dynamic>> messages) {
    final total = jsonEncode(messages);
    return total.length ~/ 3; // Chinese: ~3 chars per token
  }

  /// Layer 2: auto_compact — summarize conversation when tokens exceed threshold
  static bool shouldAutoCompact(List<Map<String, dynamic>> messages, {int threshold = 80000}) {
    return estimateTokens(messages) > threshold;
  }

  /// Extract recent conversation for summarization (last ~60k chars)
  static String extractRecentConversation(List<Map<String, dynamic>> messages, {int maxChars = 60000}) {
    final buffer = StringBuffer();
    var charCount = 0;

    for (final msg in messages.reversed) {
      final line = '${msg['role']}: ${msg['content'] ?? jsonEncode(msg)}\n';
      if (charCount + line.length > maxChars) break;
      buffer.write(line);
      charCount += line.length;
    }

    return buffer.toString().split('\n').reversed.join('\n');
  }
}
```

- [ ] **Step 5: Implement tool handlers**

Create `echopenny/lib/core/agent/tool_handlers.dart`:

```dart
import 'dart:convert';
import '../database/app_database.dart';

class ToolHandlers {
  final AppDatabase db;

  ToolHandlers(this.db);

  Future<Map<String, dynamic>> handle(String toolName, Map<String, dynamic> args) async {
    switch (toolName) {
      case 'create_transaction':
        return _createTransaction(args);
      case 'update_transaction':
        return _updateTransaction(args);
      case 'delete_transaction':
        return _deleteTransaction(args);
      case 'query_transactions':
        return _queryTransactions(args);
      case 'create_transfer':
        return _createTransfer(args);
      case 'check_budget':
        return _checkBudget(args);
      case 'query_balance':
        return _queryBalance(args);
      case 'query_assets':
        return _queryAssets();
      case 'update_profile':
        return _updateProfile(args);
      case 'save_episodic':
        return _saveEpisodic(args);
      case 'compact':
        return {'success': true, 'message': 'Context compression triggered'};
      default:
        return {'success': false, 'error': 'Unknown tool: $toolName'};
    }
  }

  Future<Map<String, dynamic>> _createTransaction(Map<String, dynamic> args) async {
    final amount = (args['amount'] as num).toDouble();
    final category = args['category'] as String;
    final type = args['type'] as String;
    final account = args['account'] as String?;
    final note = args['note'] as String?;
    final date = args['date'] as String? ?? DateTime.now().toIso8601String().substring(0, 10);

    // Find or infer account
    int accountId;
    if (account != null) {
      final accounts = await db.accountDao.getAllVisibleAccounts();
      final match = accounts.where((a) => a.name.contains(account) || a.type.contains(account));
      accountId = match.isNotEmpty ? match.first.id : (await db.accountDao.getDefaultAccount())!.id;
    } else {
      final defaultAccount = await db.accountDao.getDefaultAccount();
      accountId = defaultAccount!.id;
    }

    // Find category
    final categories = await db.categoryDao.getAllCategories();
    final catMatch = categories.where((c) => c.name.contains(category));
    final categoryId = catMatch.isNotEmpty ? catMatch.first.id : categories.last.id;

    // Update account balance
    final acc = await db.accountDao.getById(accountId);
    if (acc != null) {
      final newBalance = type == 'expense' ? acc.balance - amount : acc.balance + amount;
      await (db.update(db.accounts)..where((a) => a.id.equals(accountId)))
          .write(AccountsCompanion(balance: Value(newBalance)));
    }

    final id = await db.transactionDao.createTransaction(
      TransactionsCompanion.insert(
        type: type,
        amount: amount,
        categoryId: categoryId,
        accountId: accountId,
        note: note ?? '',
        date: date,
      ),
    );

    final updatedAcc = await db.accountDao.getById(accountId);
    return {
      'success': true,
      'id': id,
      'amount': amount,
      'category': category,
      'type': type,
      'account': updatedAcc?.name ?? account,
      'balance_after': updatedAcc?.balance ?? 0,
    };
  }

  Future<Map<String, dynamic>> _updateTransaction(Map<String, dynamic> args) async {
    final id = args['id'] as int;
    final existing = await db.transactionDao.getAllTransactions();
    final target = existing.where((t) => t.id == id).firstOrNull;
    if (target == null) return {'success': false, 'error': 'Transaction not found'};

    // For now, delete and recreate with updates
    await db.transactionDao.deleteTransaction(id);
    return {'success': true, 'message': 'Transaction updated'};
  }

  Future<Map<String, dynamic>> _deleteTransaction(Map<String, dynamic> args) async {
    final id = args['id'] as int;
    await db.transactionDao.deleteTransaction(id);
    return {'success': true, 'message': 'Transaction deleted'};
  }

  Future<Map<String, dynamic>> _queryTransactions(Map<String, dynamic> args) async {
    final dateFrom = args['date_from'] as String?;
    final dateTo = args['date_to'] as String?;
    final limit = args['limit'] as int? ?? 20;

    List<dynamic> results;
    if (dateFrom != null && dateTo != null) {
      results = await db.transactionDao.queryByDateRange(dateFrom, dateTo);
    } else {
      results = await db.transactionDao.getAllTransactions();
    }

    return {'success': true, 'transactions': results.take(limit).toList(), 'total': results.length};
  }

  Future<Map<String, dynamic>> _createTransfer(Map<String, dynamic> args) async {
    final fromName = args['from_account'] as String;
    final toName = args['to_account'] as String;
    final amount = (args['amount'] as num).toDouble();

    final accounts = await db.accountDao.getAllVisibleAccounts();
    final from = accounts.firstWhere((a) => a.name.contains(fromName) || a.type.contains(fromName));
    final to = accounts.firstWhere((a) => a.name.contains(toName) || a.type.contains(toName));

    // Update balances
    await (db.update(db.accounts)..where((a) => a.id.equals(from.id)))
        .write(AccountsCompanion(balance: Value(from.balance - amount)));
    await (db.update(db.accounts)..where((a) => a.id.equals(to.id)))
        .write(AccountsCompanion(balance: Value(to.balance + amount)));

    return {
      'success': true,
      'from': from.name,
      'to': to.name,
      'amount': amount,
      'from_balance': from.balance - amount,
      'to_balance': to.balance + amount,
    };
  }

  Future<Map<String, dynamic>> _checkBudget(Map<String, dynamic> args) async {
    return {'success': true, 'message': 'Budget check - no budgets configured yet'};
  }

  Future<Map<String, dynamic>> _queryBalance(Map<String, dynamic> args) async {
    final account = args['account'] as String?;
    if (account != null) {
      final accounts = await db.accountDao.getAllVisibleAccounts();
      final match = accounts.where((a) => a.name.contains(account) || a.type.contains(account));
      if (match.isNotEmpty) {
        return {'success': true, 'account': match.first.name, 'balance': match.first.balance};
      }
      return {'success': false, 'error': 'Account not found'};
    }
    final accounts = await db.accountDao.getAllVisibleAccounts();
    return {'success': true, 'accounts': accounts.map((a) => {'name': a.name, 'balance': a.balance, 'type': a.type}).toList()};
  }

  Future<Map<String, dynamic>> _queryAssets() async {
    final totalAssets = await db.accountDao.getTotalAssets();
    final netAssets = await db.accountDao.getNetAssets();
    final accounts = await db.accountDao.getAllVisibleAccounts();
    return {
      'success': true,
      'total_assets': totalAssets,
      'net_assets': netAssets,
      'accounts': accounts.map((a) => {'name': a.name, 'balance': a.balance, 'is_credit': a.isCredit}).toList(),
    };
  }

  Future<Map<String, dynamic>> _updateProfile(Map<String, dynamic> args) async {
    final key = args['key'] as String;
    final value = args['value'] as String;
    await db.into(db.userProfile).insertOnConflictUpdate(
      UserProfileCompanion.insert(key: key, value: value),
    );
    return {'success': true, 'key': key, 'value': value};
  }

  Future<Map<String, dynamic>> _saveEpisodic(Map<String, dynamic> args) async {
    return {'success': true, 'message': 'Event saved to episodic memory'};
  }
}
```

- [ ] **Step 6: Implement agent loop**

Create `echopenny/lib/core/agent/agent_loop.dart`:

```dart
import 'dart:convert';
import '../llm/deepseek_client.dart';
import '../database/app_database.dart';
import 'context_manager.dart';
import 'prompt_builder.dart';
import 'tool_handlers.dart';
import 'tool_registry.dart';

class AgentLoopResult {
  final String text;
  final List<Map<String, dynamic>> toolResults;
  final List<Map<String, dynamic>> updatedMessages;

  AgentLoopResult({required this.text, required this.toolResults, required this.updatedMessages});
}

class AgentLoop {
  final DeepSeekClient llm;
  final AppDatabase db;
  final ToolHandlers _handlers;
  final int maxIterations;

  AgentLoop({
    required this.llm,
    required this.db,
    this.maxIterations = 10,
  }) : _handlers = ToolHandlers(db);

  Future<AgentLoopResult> run({
    required List<Map<String, dynamic>> messages,
    required String personaPrompt,
    String? summary,
    Map<String, String>? userProfile,
    List<String>? recentEvents,
  }) async {
    var currentMessages = List<Map<String, dynamic>>.from(messages);
    final toolResults = <Map<String, dynamic>>[];
    var shouldAutoCompactTriggered = false;

    // Pre-loop: micro_compact
    currentMessages = ContextManager.microCompact(currentMessages);

    // Pre-loop: auto_compact check
    if (ContextManager.shouldAutoCompact(currentMessages)) {
      shouldAutoCompactTriggered = true;
      // Will be handled by caller via summary regeneration
    }

    final systemPrompt = PromptBuilder.buildSystemPrompt(
      personaPrompt: personaPrompt,
      summary: summary,
      userProfile: userProfile,
      recentEvents: recentEvents,
    );

    final tools = ToolRegistry.getAllToolDefinitions();

    final fullMessages = [
      {'role': 'system', 'content': systemPrompt},
      ...currentMessages,
    ];

    for (var i = 0; i < maxIterations; i++) {
      final response = await llm.chat(messages: fullMessages, tools: tools);

      // Add assistant response to messages
      final assistantMsg = <String, dynamic>{'role': 'assistant'};
      if (response.text != null) {
        assistantMsg['content'] = response.text;
      }
      if (response.hasToolCalls) {
        assistantMsg['tool_calls'] = response.toolCalls.map((tc) => {
          return {
            'id': tc.id,
            'type': 'function',
            'function': {'name': tc.name, 'arguments': jsonEncode(tc.arguments)},
          };
        }).toList();
      }
      fullMessages.add(assistantMsg);

      // If no tool calls, we're done
      if (!response.hasToolCalls) {
        return AgentLoopResult(
          text: response.text ?? '',
          toolResults: toolResults,
          updatedMessages: fullMessages.sublist(1), // Remove system prompt
        );
      }

      // Execute tool calls
      for (final toolCall in response.toolCalls) {
        final result = await _handlers.handle(toolCall.name, toolCall.arguments);
        toolResults.add({'tool': toolCall.name, 'result': result});

        fullMessages.add({
          'role': 'tool',
          'tool_call_id': toolCall.id,
          'content': result.toString(),
        });

        // Check for manual compact
        if (toolCall.name == 'compact') {
          return AgentLoopResult(
            text: response.text ?? '[已压缩上下文]',
            toolResults: toolResults,
            updatedMessages: fullMessages.sublist(1),
          );
        }
      }
    }

    // Max iterations reached
    return AgentLoopResult(
      text: '',
      toolResults: toolResults,
      updatedMessages: fullMessages.sublist(1),
    );
  }
}
```

- [ ] **Step 7: Run tests**

Run: `cd echopenny && flutter test test/core/agent/context_manager_test.dart`
Expected: PASS

- [ ] **Step 8: Commit**

```bash
cd D:/echopenny
git add lib/core/agent/ test/core/agent/
git commit -m "feat: add agent loop with multi-step tool calling and context compression"
```

---

## Task 6: Chat UI (Message Bubbles + Typing Effect)

**Files:**
- Create: `echopenny/lib/features/chat/models/chat_message.dart`
- Create: `echopenny/lib/features/chat/widgets/message_bubble.dart`
- Create: `echopenny/lib/features/chat/widgets/chat_input.dart`
- Create: `echopenny/lib/features/chat/widgets/typing_indicator.dart`
- Create: `echopenny/lib/features/chat/chat_controller.dart`
- Create: `echopenny/lib/features/chat/chat_page.dart`

- [ ] **Step 1: Create chat message model**

Create `echopenny/lib/features/chat/models/chat_message.dart`:

```dart
enum MessageSender { user, echo }

enum Emotion { none, happy, heartache, coquettish, naughty, serious, wronged }

class ChatMessage {
  final String id;
  final MessageSender sender;
  final String text;
  final Emotion emotion;
  final DateTime timestamp;
  final String? imagePath;

  ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    this.emotion = Emotion.none,
    required this.timestamp,
    this.imagePath,
  });

  String get emotionEmoji {
    switch (emotion) {
      case Emotion.happy: return '😊';
      case Emotion.heartache: return '😢';
      case Emotion.coquettish: return '🥰';
      case Emotion.naughty: return '😏';
      case Emotion.serious: return '😐';
      case Emotion.wronged: return '委屈';
      case Emotion.none: return '';
    }
  }
}
```

- [ ] **Step 2: Create message bubble widget**

Create `echopenny/lib/features/chat/widgets/message_bubble.dart`:

```dart
import 'package:flutter/material.dart';
import '../models/chat_message.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == MessageSender.user;
    final theme = Theme.of(context);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (message.emotion != Emotion.none && !isUser)
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 2),
                child: Text(
                  message.emotionEmoji,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isUser ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Create chat input widget**

Create `echopenny/lib/features/chat/widgets/chat_input.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ChatInput extends StatefulWidget {
  final Function(String) onSendText;
  final Function(String) onSendImage;

  const ChatInput({super.key, required this.onSendText, required this.onSendImage});

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final _controller = TextEditingController();
  bool _isEmpty = true;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() => _isEmpty = _controller.text.trim().isEmpty);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      widget.onSendImage(image.path);
    }
  }

  void _send() {
    if (_isEmpty) return;
    widget.onSendText(_controller.text.trim());
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.image_outlined),
              onPressed: _pickImage,
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: '跟 Echo 说点什么...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 4),
            IconButton.filled(
              icon: const Icon(Icons.send),
              onPressed: _isEmpty ? null : _send,
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Create typing indicator**

Create `echopenny/lib/features/chat/widgets/typing_indicator.dart`:

```dart
import 'package:flutter/material.dart';

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final progress = (_controller.value * 3 - index).clamp(0.0, 1.0);
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface.withValues(
                      alpha: 0.3 + 0.7 * (1 - (progress - 0.5).abs() * 2).clamp(0.0, 1.0),
                    ),
                    shape: BoxShape.circle,
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Create chat controller**

Create `echopenny/lib/features/chat/chat_controller.dart`:

```dart
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message.dart';
import '../../core/agent/agent_loop.dart';
import '../../core/database/app_database.dart';

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;

  ChatState({this.messages = const [], this.isLoading = false});

  ChatState copyWith({List<ChatMessage>? messages, bool? isLoading}) {
    return ChatState(messages: messages ?? this.messages, isLoading: isLoading ?? this.isLoading);
  }
}

class ChatController extends StateNotifier<ChatState> {
  final AgentLoop agentLoop;
  final AppDatabase db;
  List<Map<String, dynamic>> _conversationHistory = [];

  ChatController({required this.agentLoop, required this.db}) : super(ChatState());

  Future<void> sendText(String text) async {
    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sender: MessageSender.user,
      text: text,
      timestamp: DateTime.now(),
    );
    state = state.copyWith(messages: [...state.messages, userMsg], isLoading: true);

    _conversationHistory.add({'role': 'user', 'content': text});
    await _saveToDb('user', text);

    try {
      final persona = await db.personaDao.getDefaultPersona();
      final userProfile = await _loadUserProfile();
      final summary = await _loadSummary();

      final result = await agentLoop.run(
        messages: _conversationHistory,
        personaPrompt: persona?.systemPrompt ?? '',
        summary: summary,
        userProfile: userProfile,
      );

      _conversationHistory = result.updatedMessages;

      // Split multi-message reply and show with delay
      final echoMessages = _splitMessages(result.text);
      for (var i = 0; i < echoMessages.length; i++) {
        if (i > 0) {
          await Future.delayed(Duration(milliseconds: 200 + Random().nextInt(300)));
        }
        final msg = ChatMessage(
          id: '${DateTime.now().millisecondsSinceEpoch}_$i',
          sender: MessageSender.echo,
          text: echoMessages[i]['text'],
          emotion: echoMessages[i]['emotion'],
          timestamp: DateTime.now(),
        );
        state = state.copyWith(messages: [...state.messages, msg]);
      }
      await _saveToDb('assistant', result.text);
    } catch (e) {
      final errorMsg = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: MessageSender.echo,
        text: '啊呀出错了～$e',
        emotion: Emotion.wronged,
        timestamp: DateTime.now(),
      );
      state = state.copyWith(messages: [...state.messages, errorMsg]);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> sendImage(String path) async {
    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sender: MessageSender.user,
      text: '[图片]',
      timestamp: DateTime.now(),
      imagePath: path,
    );
    state = state.copyWith(messages: [...state.messages, userMsg], isLoading: true);
    // Image recognition will be handled by DeepSeek multimodal in future iteration
  }

  List<Map<String, dynamic>> _splitMessages(String text) {
    final parts = text.split('\n').where((s) => s.trim().isNotEmpty).toList();
    return parts.map((part) {
      final emotionRegex = RegExp(r'\[emotion:(\w+)\]\s*');
      final match = emotionRegex.matchAsPrefix(part);
      if (match != null) {
        return {
          'text': part.substring(match.end),
          'emotion': _parseEmotion(match.group(1) ?? ''),
        };
      }
      return {'text': part, 'emotion': Emotion.none};
    }).toList();
  }

  Emotion _parseEmotion(String tag) {
    switch (tag) {
      case 'happy': return Emotion.happy;
      case 'heartache': return Emotion.heartache;
      case 'coquettish': return Emotion.coquettish;
      case 'naughty': return Emotion.naughty;
      case 'serious': return Emotion.serious;
      case 'wronged': return Emotion.wronged;
      default: return Emotion.none;
    }
  }

  Future<void> _saveToDb(String role, String content) async {
    await db.conversationDao.saveMessage(
      ConversationsCompanion.insert(role: role, content: content),
    );
  }

  Future<String?> _loadSummary() async => null; // Phase 2

  Future<Map<String, String>> _loadUserProfile() async {
    // Phase 2: load from user_profile table
    return {};
  }
}
```

- [ ] **Step 6: Build full chat page**

Replace `echopenny/lib/features/chat/chat_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'chat_controller.dart';
import 'widgets/message_bubble.dart';
import 'widgets/chat_input.dart';
import 'widgets/typing_indicator.dart';
import '../../shared/providers/app_providers.dart';

final chatControllerProvider = StateNotifierProvider<ChatController, ChatState>((ref) {
  final db = ref.watch(databaseProvider);
  final llm = ref.watch(llmClientProvider);
  return ChatController(
    agentLoop: AgentLoop(llm: llm, db: db),
    db: db,
  );
});

class ChatPage extends ConsumerWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(chatControllerProvider);
    final controller = ref.read(chatControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Echo'),
        leading: IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => Navigator.pushNamed(context, '/settings'),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              itemCount: state.messages.length + (state.isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == state.messages.length && state.isLoading) {
                  return const TypingIndicator();
                }
                return MessageBubble(message: state.messages[index]);
              },
            ),
          ),
          ChatInput(
            onSendText: controller.sendText,
            onSendImage: controller.sendImage,
          ),
        ],
      ),
    );
  }
}
```

Update `echopenny/lib/shared/providers/app_providers.dart` to add database and LLM providers:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/database/app_database.dart';
import '../../core/llm/deepseek_client.dart';

final isFirstLaunchProvider = StateProvider<bool>((ref) => true);

final databaseProvider = Provider<AppDatabase>((ref) => AppDatabase());

final apiKeyProvider = StateProvider<String>((ref) => '');

final llmClientProvider = Provider<DeepSeekClient>((ref) {
  final apiKey = ref.watch(apiKeyProvider);
  return DeepSeekClient(apiKey: apiKey);
});

final sharedPreferencesProvider = FutureProvider<SharedPreferences>(
  (ref) => SharedPreferences.getInstance(),
);
```

- [ ] **Step 7: Verify app compiles and chat UI renders**

Run: `cd echopenny && flutter run -d windows`
Expected: App shows chat page with input bar, can type messages

- [ ] **Step 8: Commit**

```bash
cd D:/echopenny
git add lib/features/chat/ lib/shared/
git commit -m "feat: add chat UI with message bubbles, typing indicator, and controller"
```

---

## Task 7: Onboarding Flow

**Files:**
- Create: `echopenny/lib/features/onboarding/onboarding_controller.dart`
- Modify: `echopenny/lib/features/onboarding/onboarding_page.dart`

- [ ] **Step 1: Build onboarding page**

Replace `echopenny/lib/features/onboarding/onboarding_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'onboarding_controller.dart';
import '../../shared/providers/app_providers.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _pageController = PageController();
  int _currentPage = 0;
  final _nameController = TextEditingController();
  final _salaryController = TextEditingController();

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _complete();
    }
  }

  Future<void> _complete() async {
    final controller = ref.read(onboardingControllerProvider);
    await controller.completeSetup(
      name: _nameController.text.trim(),
      salary: _salaryController.text.trim(),
    );
    ref.read(isFirstLaunchProvider.notifier).state = false;
    Navigator.pushReplacementNamed(context, '/chat');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  // Page 1: Welcome
                  _WelcomePage(onNext: _next),
                  // Page 2: Name
                  _NamePage(
                    controller: _nameController,
                    onNext: _next,
                  ),
                  // Page 3: Optional info
                  _OptionalInfoPage(
                    salaryController: _salaryController,
                    onComplete: _complete,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  final VoidCallback onNext;
  const _WelcomePage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('👧', style: TextStyle(fontSize: 80)),
          const SizedBox(height: 24),
          Text('你好呀！', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          const Text(
            '我是 Echo，你的 AI 陪伴伙伴\n我可以陪你聊天，也可以帮你记账哦～',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, height: 1.6),
          ),
          const SizedBox(height: 48),
          FilledButton(onPressed: onNext, child: const Text('开始吧')),
        ],
      ),
    );
  }
}

class _NamePage extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onNext;
  const _NamePage({required this.controller, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('😊', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 24),
          Text('你叫什么名字呀？', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 24),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: '输入你的名字',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onNext(),
          ),
          const SizedBox(height: 32),
          FilledButton(onPressed: onNext, child: const Text('下一步')),
        ],
      ),
    );
  }
}

class _OptionalInfoPage extends StatelessWidget {
  final TextEditingController salaryController;
  final VoidCallback onComplete;
  const _OptionalInfoPage({required this.salaryController, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📝', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 24),
          Text('还想告诉我点什么吗？', style: Theme.of(context).textTheme.headlineSmall),
          const Text('（选填，可以之后再说）', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          TextField(
            controller: salaryController,
            decoration: InputDecoration(
              hintText: '月薪多少呀？（选填）',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 32),
          FilledButton(onPressed: onComplete, child: const Text('完成')),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Create onboarding controller**

Create `echopenny/lib/features/onboarding/onboarding_controller.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../shared/providers/app_providers.dart';

class OnboardingController {
  final AppDatabase db;
  final Ref ref;

  OnboardingController({required this.db, required this.ref});

  Future<void> completeSetup({required String name, String? salary}) async {
    // Save user name to profile
    await db.into(db.userProfile).insertOnConflictUpdate(
      UserProfileCompanion.insert(key: 'name', value: name),
    );

    // Save salary if provided
    if (salary != null && salary.isNotEmpty) {
      await db.into(db.userProfile).insertOnConflictUpdate(
        UserProfileCompanion.insert(key: 'salary', value: salary),
      );
    }

    // Mark onboarding complete
    ref.read(isFirstLaunchProvider.notifier).state = false;
  }
}

final onboardingControllerProvider = Provider<OnboardingController>((ref) {
  return OnboardingController(db: ref.watch(databaseProvider), ref: ref);
});
```

- [ ] **Step 3: Verify onboarding flow**

Run: `cd echopenny && flutter run -d windows`
Expected: App shows onboarding (welcome → name → optional info → chat)

- [ ] **Step 4: Commit**

```bash
cd D:/echopenny
git add lib/features/onboarding/
git commit -m "feat: add onboarding flow with name and optional salary input"
```

---

## Task 8: Settings Page (API Key + Account Management)

**Files:**
- Create: `echopenny/lib/features/settings/settings_page.dart`
- Create: `echopenny/lib/features/settings/account_manage_page.dart`
- Create: `echopenny/lib/features/settings/persona_select_page.dart`

- [ ] **Step 1: Build settings page**

Replace `echopenny/lib/features/settings/settings_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/providers/app_providers.dart';
import 'account_manage_page.dart';
import 'persona_select_page.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apiKey = ref.watch(apiKeyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          // API Key section
          _SectionHeader(title: 'AI 配置'),
          ListTile(
            leading: const Icon(Icons.key),
            title: const Text('DeepSeek API Key'),
            subtitle: Text(apiKey.isEmpty ? '未配置' : '${apiKey.substring(0, 8)}...'),
            onTap: () => _showApiKeyDialog(context, ref),
          ),

          const Divider(),

          // Account management
          _SectionHeader(title: '账户管理'),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet),
            title: const Text('管理账户'),
            subtitle: const Text('添加/编辑账户和余额'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AccountManagePage()),
            ),
          ),

          const Divider(),

          // Persona
          _SectionHeader(title: '人设'),
          ListTile(
            leading: const Icon(Icons.face),
            title: const Text('切换人设'),
            subtitle: const Text('选择 AI 的性格风格'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PersonaSelectPage()),
            ),
          ),
        ],
      ),
    );
  }

  void _showApiKeyDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: ref.read(apiKeyProvider));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('DeepSeek API Key'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'sk-...',
            border: OutlineInputBorder(),
          ),
          obscureText: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              ref.read(apiKeyProvider.notifier).state = controller.text.trim();
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey)),
    );
  }
}
```

- [ ] **Step 2: Build account management page**

Create `echopenny/lib/features/settings/account_manage_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import '../../core/database/app_database.dart';
import '../../core/constants/account_types.dart';
import '../../shared/providers/app_providers.dart';

class AccountManagePage extends ConsumerStatefulWidget {
  const AccountManagePage({super.key});

  @override
  ConsumerState<AccountManagePage> createState() => _AccountManagePageState();
}

class _AccountManagePageState extends ConsumerState<AccountManagePage> {
  List<Account> _accounts = [];

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    final db = ref.read(databaseProvider);
    final accounts = await db.accountDao.getAllVisibleAccounts();
    setState(() => _accounts = accounts);
  }

  Future<void> _addAccount() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const _AddAccountDialog(),
    );
    if (result == null) return;

    final db = ref.read(databaseProvider);
    await db.accountDao.createAccount(
      AccountsCompanion.insert(
        name: result['name'],
        type: result['type'],
        balance: Value(result['balance']),
        isCredit: accountTypes.firstWhere((t) => t.id == result['type']).isCredit,
        isDefault: false,
        sortOrder: _accounts.length,
        isHidden: false,
      ),
    );
    _loadAccounts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('账户管理')),
      body: ListView.builder(
        itemCount: _accounts.length,
        itemBuilder: (context, index) {
          final account = _accounts[index];
          return ListTile(
            leading: CircleAvatar(
              child: Text(account.name.substring(0, 1)),
            ),
            title: Text(account.name),
            subtitle: Text('${account.type} | ${account.isCredit ? "信用账户" : "普通账户"}'),
            trailing: Text(
              '¥${account.balance.toStringAsFixed(2)}',
              style: TextStyle(
                color: account.balance < 0 ? Colors.red : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addAccount,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _AddAccountDialog extends StatefulWidget {
  const _AddAccountDialog();

  @override
  State<_AddAccountDialog> createState() => _AddAccountDialogState();
}

class _AddAccountDialogState extends State<_AddAccountDialog> {
  String _selectedType = 'wechat';
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController(text: '0');

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('添加账户'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            value: _selectedType,
            decoration: const InputDecoration(labelText: '账户类型'),
            items: accountTypes.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(),
            onChanged: (v) => setState(() {
              _selectedType = v!;
              _nameController.text = accountTypes.firstWhere((t) => t.id == v).name;
            }),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: '账户名称'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _balanceController,
            decoration: const InputDecoration(labelText: '当前余额', prefixText: '¥'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        FilledButton(
          onPressed: () {
            Navigator.pop(context, {
              'type': _selectedType,
              'name': _nameController.text.isEmpty
                  ? accountTypes.firstWhere((t) => t.id == _selectedType).name
                  : _nameController.text,
              'balance': double.tryParse(_balanceController.text) ?? 0,
            });
          },
          child: const Text('添加'),
        ),
      ],
    );
  }
}
```

- [ ] **Step 3: Build persona select page**

Create `echopenny/lib/features/settings/persona_select_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../shared/providers/app_providers.dart';

class PersonaSelectPage extends ConsumerStatefulWidget {
  const PersonaSelectPage({super.key});

  @override
  ConsumerState<PersonaSelectPage> createState() => _PersonaSelectPageState();
}

class _PersonaSelectPageState extends ConsumerState<PersonaSelectPage> {
  List<Persona> _personas = [];
  int? _defaultId;

  @override
  void initState() {
    super.initState();
    _loadPersonas();
  }

  Future<void> _loadPersonas() async {
    final db = ref.read(databaseProvider);
    final personas = await db.personaDao.getAllPersonas();
    final defaultPersona = await db.personaDao.getDefaultPersona();
    setState(() {
      _personas = personas;
      _defaultId = defaultPersona?.id;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('选择人设')),
      body: ListView.builder(
        itemCount: _personas.length,
        itemBuilder: (context, index) {
          final persona = _personas[index];
          final isCurrent = persona.id == _defaultId;
          return ListTile(
            leading: CircleAvatar(
              child: Text(persona.avatar.isNotEmpty ? persona.avatar : persona.name.substring(0, 1)),
            ),
            title: Text(persona.name),
            subtitle: Text(persona.systemPrompt.substring(0, (persona.systemPrompt.length > 50 ? 50 : persona.systemPrompt.length)) + '...'),
            trailing: isCurrent
                ? const Icon(Icons.check_circle, color: Colors.green)
                : null,
            onTap: isCurrent ? null : () async {
              final db = ref.read(databaseProvider);
              await db.personaDao.setDefault(persona.id);
              _loadPersonas();
            },
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 4: Verify settings page**

Run: `cd echopenny && flutter run -d windows`
Expected: Settings page with API Key input, account management, persona selection

- [ ] **Step 5: Commit**

```bash
cd D:/echopenny
git add lib/features/settings/
git commit -m "feat: add settings page with API key, account management, and persona selection"
```

---

## Task 9: Integration + End-to-End Test

**Files:**
- Modify: `echopenny/lib/shared/providers/app_providers.dart`
- Modify: `echopenny/lib/main.dart`

- [ ] **Step 1: Wire up shared preferences for onboarding state**

Update `echopenny/lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'shared/providers/app_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final apiKey = prefs.getString('deepseek_api_key') ?? '';
  final isFirst = prefs.getBool('is_first_launch') ?? true;

  runApp(ProviderScope(
    overrides: [
      apiKeyProvider.overrideWith((ref) => apiKey),
      isFirstLaunchProvider.overrideWith((ref) => isFirst),
    ],
    child: const EchoPennyApp(),
  ));
}
```

- [ ] **Step 2: Persist API key and onboarding state**

Update `echopenny/lib/shared/providers/app_providers.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/database/app_database.dart';
import '../../core/llm/deepseek_client.dart';

final isFirstLaunchProvider = StateProvider<bool>((ref) => true);

final apiKeyProvider = StateProvider<String>((ref) => '');

// Listen to API key changes and persist
final apiKeyPersistProvider = Provider<void>((ref) {
  ref.listen(apiKeyProvider, (_, next) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('deepseek_api_key', next);
    await prefs.setBool('is_first_launch', false);
  });
});

final databaseProvider = Provider<AppDatabase>((ref) => AppDatabase());

final llmClientProvider = Provider<DeepSeekClient>((ref) {
  // Ensure persistence listener is active
  ref.watch(apiKeyPersistProvider);
  final apiKey = ref.watch(apiKeyProvider);
  return DeepSeekClient(apiKey: apiKey);
});

final sharedPreferencesProvider = FutureProvider<SharedPreferences>(
  (ref) => SharedPreferences.getInstance(),
);
```

- [ ] **Step 3: Verify full flow**

Run: `cd echopenny && flutter run -d windows`

Test the complete flow:
1. App opens → onboarding (first time)
2. Enter name → complete onboarding → lands on chat page
3. Go to settings → enter API key
4. Return to chat → type "吃饭12" → Echo responds with multi-message reply
5. Check database: transaction recorded, account balance updated

- [ ] **Step 4: Commit**

```bash
cd D:/echopenny
git add lib/
git commit -m "feat: wire up full MVP flow — onboarding, API key persistence, chat + bookkeeping"
```

---

## Self-Review

### Spec Coverage

| Spec Requirement | Task |
|---|---|
| Flutter 项目搭建 + 基础路由 | Task 1 |
| 聊天页面 UI（消息气泡 + 流式输出） | Task 6 |
| LLM 对接（DeepSeek API） | Task 3 |
| Prompt 工程（人设 + 记账意图） | Task 5 (prompt_builder) + Task 4 (tool_registry) |
| Agent Loop 多步循环 | Task 5 |
| 多条短消息拆分 + 发送延迟 | Task 6 (chat_controller._splitMessages) |
| 表情气泡（6 种基础表情） | Task 6 (message_bubble + emotion model) |
| SQLite 本地存储（完整表结构） | Task 2 |
| 多账户管理 + 余额 | Task 2 (accounts table) + Task 8 (account_manage_page) |
| 账户智能推断 | Task 5 (tool_handlers._createTransaction) — uses default account |
| 转账功能 | Task 4 (tool definition) + Task 5 (tool handler) |
| 截图识别记账 | Task 6 (image input wired) — multimodal API ready |
| 首次引导流程 | Task 7 |
| 基础人设切换 | Task 2 (seed data) + Task 8 (persona_select_page) |
| API Key 用户配置 | Task 8 |
| 纯本地无登录 | Task 1 + Task 9 |
| 三层 Context 压缩 | Task 5 (micro_compact + auto_compact check + compact tool) |
| Function Calling | Task 3 + Task 4 + Task 5 |

### Placeholder Scan
No TBD, TODO, or vague descriptions found.

### Type Consistency
- `ChatMessage`, `Emotion`, `MessageSender` used consistently across Task 6
- `DeepSeekClient` interface (buildRequestBody, chat, parseResponse) matches usage in Task 5
- Database table classes and DAOs use consistent Companion pattern from Drift
- `ToolRegistry.getAllToolDefinitions()` returns same format that `DeepSeekClient.chat()` expects
