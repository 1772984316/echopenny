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
      {'role': 'user', 'content': '打车20'},
      {
        'role': 'assistant',
        'content': null,
        'tool_calls': [
          {'id': 'call_4', 'type': 'function', 'function': {'name': 'create_transaction', 'arguments': '{}'}},
        ],
      },
      {
        'role': 'tool',
        'tool_call_id': 'call_4',
        'content': '{"success": true, "id": 4, "amount": 20, "category": "交通", "account": "微信", "balance_after": 445.0}',
      },
    ];

    final compressed = ContextManager.microCompact(messages);

    final firstToolResult = compressed.where((m) => m['role'] == 'tool').first;
    expect(firstToolResult['content'], contains('[已处理: create_transaction]'));

    final lastToolResult = compressed.where((m) => m['role'] == 'tool').last;
    expect(lastToolResult['content'], contains('445.0'));
  });

  test('estimateTokens returns reasonable estimate', () {
    final messages = <Map<String, dynamic>>[
      {'role': 'user', 'content': '吃饭12'},
    ];
    final tokens = ContextManager.estimateTokens(messages);
    expect(tokens, greaterThan(0));
    expect(tokens, lessThan(100));
  });
}
