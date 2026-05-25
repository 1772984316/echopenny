import 'dart:convert';

class ContextManager {
  static const int keepRecentToolResults = 3;

  static List<Map<String, dynamic>> microCompact(List<Map<String, dynamic>> messages) {
    if (messages.length <= keepRecentToolResults * 3) return messages;

    final result = <Map<String, dynamic>>[];
    final toolResultIndices = <int>[];

    for (var i = 0; i < messages.length; i++) {
      if (messages[i]['role'] == 'tool') {
        toolResultIndices.add(i);
      }
    }

    final keepFrom = toolResultIndices.length > keepRecentToolResults
        ? toolResultIndices[toolResultIndices.length - keepRecentToolResults]
        : 0;

    for (var i = 0; i < messages.length; i++) {
      final msg = Map<String, dynamic>.from(messages[i]);
      if (msg['role'] == 'tool' && i < keepFrom) {
        final content = msg['content'] as String? ?? '';
        if (content.length > 50) {
          final toolName = _extractToolName(messages, i);
          msg['content'] = '[已处理: $toolName] ${content.substring(0, 30)}...';
        }
      }
      result.add(msg);
    }

    return result;
  }

  static String _extractToolName(List<Map<String, dynamic>> messages, int toolResultIndex) {
    final toolCallId = messages[toolResultIndex]['tool_call_id'] as String?;
    if (toolCallId == null) return 'unknown';

    for (final msg in messages) {
      final toolCalls = msg['tool_calls'] as List<dynamic>?;
      if (toolCalls != null) {
        for (final tc in toolCalls) {
          if (tc['id'] == toolCallId) {
            return (tc['function'] as Map<String, dynamic>)['name'] as String? ?? 'unknown';
          }
        }
      }
    }
    return 'unknown';
  }

  static int estimateTokens(List<Map<String, dynamic>> messages) {
    final total = jsonEncode(messages);
    return total.length ~/ 3;
  }

  static bool shouldAutoCompact(List<Map<String, dynamic>> messages, {int threshold = 80000}) {
    return estimateTokens(messages) > threshold;
  }

  static String extractRecentConversation(List<Map<String, dynamic>> messages, {int maxChars = 60000}) {
    final buffer = StringBuffer();
    var charCount = 0;

    for (final msg in messages.reversed) {
      final line = '${msg['role']}: ${msg['content'] ?? jsonEncode(msg)}\n';
      if (charCount + line.length > maxChars) break;
      buffer.write(line);
      charCount += line.length;
    }

    return buffer.toString().split('\n').reversed.join('\n');
  }
}
