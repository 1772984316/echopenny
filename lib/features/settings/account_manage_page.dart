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
    final result = await showDialog<Map<String, dynamic>>(context: context, builder: (context) => const _AddAccountDialog());
    if (result == null) return;

    final db = ref.read(databaseProvider);
    await db.accountDao.createAccount(
      AccountsCompanion.insert(
        name: result['name'] as String,
        type: result['type'] as String,
        balance: Value(result['balance'] as double),
        isCredit: Value(accountTypes.firstWhere((t) => t.id == result['type']).isCredit),
        isDefault: const Value(false),
        sortOrder: _accounts.length,
        isHidden: const Value(false),
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
            leading: CircleAvatar(child: Text(account.name.substring(0, 1))),
            title: Text(account.name),
            subtitle: Text('${account.type} | ${account.isCredit ? "信用账户" : "普通账户"}'),
            trailing: Text('¥${account.balance.toStringAsFixed(2)}', style: TextStyle(color: account.balance < 0 ? Colors.red : Colors.green, fontWeight: FontWeight.bold)),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(onPressed: _addAccount, child: const Icon(Icons.add)),
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
            onChanged: (v) => setState(() { _selectedType = v!; _nameController.text = accountTypes.firstWhere((t) => t.id == v).name; }),
          ),
          const SizedBox(height: 12),
          TextField(controller: _nameController, decoration: const InputDecoration(labelText: '账户名称')),
          const SizedBox(height: 12),
          TextField(controller: _balanceController, decoration: const InputDecoration(labelText: '当前余额', prefixText: '¥'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        FilledButton(
          onPressed: () {
            Navigator.pop(context, {
              'type': _selectedType,
              'name': _nameController.text.isEmpty ? accountTypes.firstWhere((t) => t.id == _selectedType).name : _nameController.text,
              'balance': double.tryParse(_balanceController.text) ?? 0,
            });
          },
          child: const Text('添加'),
        ),
      ],
    );
  }
}
