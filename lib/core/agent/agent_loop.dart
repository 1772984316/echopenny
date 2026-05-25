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

    currentMessages = ContextManager.microCompact(currentMessages);

    final systemPrompt = PromptBuilder.buildSystemPrompt(
      personaPrompt: personaPrompt,
      summary: summary,
      userProfile: userProfile,
      recentEvents: recentEvents,
    );

    final tools = ToolRegistry.getAllToolDefinitions();

    final fullMessages = <Map<String, dynamic>>[
      {'role': 'system', 'content': systemPrompt},
      ...currentMessages,
    ];

    for (var i = 0; i < maxIterations; i++) {
      final response = await llm.chat(messages: fullMessages, tools: tools);

      final assistantMsg = <String, dynamic>{'role': 'assistant'};
      if (response.text != null) {
        assistantMsg['content'] = response.text;
      }
      if (response.hasToolCalls) {
        assistantMsg['tool_calls'] = response.toolCalls.map((tc) {
          return {
            'id': tc.id,
            'type': 'function',
            'function': {'name': tc.name, 'arguments': jsonEncode(tc.arguments)},
          };
        }).toList();
      }
      fullMessages.add(assistantMsg);

      if (!response.hasToolCalls) {
        return AgentLoopResult(
          text: response.text ?? '',
          toolResults: toolResults,
          updatedMessages: fullMessages.sublist(1),
        );
      }

      for (final toolCall in response.toolCalls) {
        final result = await _handlers.handle(toolCall.name, toolCall.arguments);
        toolResults.add({'tool': toolCall.name, 'result': result});

        fullMessages.add({
          'role': 'tool',
          'tool_call_id': toolCall.id,
          'content': jsonEncode(result),
        });

        if (toolCall.name == 'compact') {
          return AgentLoopResult(
            text: response.text ?? '[已压缩上下文]',
            toolResults: toolResults,
            updatedMessages: fullMessages.sublist(1),
          );
        }
      }
    }

    return AgentLoopResult(
      text: '',
      toolResults: toolResults,
      updatedMessages: fullMessages.sublist(1),
    );
  }
}
