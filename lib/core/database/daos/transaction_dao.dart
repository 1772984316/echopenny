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

  Future<int> deleteTransaction(int id) {
    return (delete(transactions)..where((t) => t.id.equals(id))).go();
  }
}
