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

    final body = client.buildRequestBody(messages: messages, tools: tools);

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
