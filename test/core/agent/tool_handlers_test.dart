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
