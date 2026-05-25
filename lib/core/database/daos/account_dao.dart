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
    return all.fold<double>(0.0, (sum, a) => sum + a.balance);
  }

  Future<double> getNetAssets() async {
    final all = await getAllVisibleAccounts();
    final assets = all.where((a) => !a.isCredit).fold<double>(0.0, (sum, a) => sum + a.balance);
    final liabilities = all.where((a) => a.isCredit).fold<double>(0.0, (sum, a) => sum + a.balance.abs());
    return assets - liabilities;
  }

  Future<int> deleteAccount(int id) {
    return (delete(accounts)..where((a) => a.id.equals(id))).go();
  }
}
