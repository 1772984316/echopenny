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
          _SectionHeader(title: 'AI 配置'),
          ListTile(
            leading: const Icon(Icons.key),
            title: const Text('DeepSeek API Key'),
            subtitle: Text(apiKey.isEmpty ? '未配置' : '${apiKey.substring(0, 8)}...'),
            onTap: () => _showApiKeyDialog(context, ref),
          ),
          const Divider(),
          _SectionHeader(title: '账户管理'),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet),
            title: const Text('管理账户'),
            subtitle: const Text('添加/编辑账户和余额'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountManagePage())),
          ),
          const Divider(),
          _SectionHeader(title: '人设'),
          ListTile(
            leading: const Icon(Icons.face),
            title: const Text('切换人设'),
            subtitle: const Text('选择 AI 的性格风格'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonaSelectPage())),
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
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'sk-...', border: OutlineInputBorder()), obscureText: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          FilledButton(onPressed: () { ref.read(apiKeyProvider.notifier).state = controller.text.trim(); Navigator.pop(context); }, child: const Text('保存')),
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
