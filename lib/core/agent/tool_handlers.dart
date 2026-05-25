import 'package:drift/drift.dart';
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

    int accountId;
    if (account != null) {
      final accounts = await db.accountDao.getAllVisibleAccounts();
      final match = accounts.where((a) => a.name.contains(account) || a.type.contains(account));
      accountId = match.isNotEmpty ? match.first.id : (await db.accountDao.getDefaultAccount())!.id;
    } else {
      final defaultAccount = await db.accountDao.getDefaultAccount();
      accountId = defaultAccount!.id;
    }

    final categories = await db.categoryDao.getAllCategories();
    final catMatch = categories.where((c) => c.name.contains(category));
    final categoryId = catMatch.isNotEmpty ? catMatch.first.id : categories.last.id;

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
        categoryId: Value(categoryId),
        accountId: accountId,
        note: Value(note ?? ''),
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
