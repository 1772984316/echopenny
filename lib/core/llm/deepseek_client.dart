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
