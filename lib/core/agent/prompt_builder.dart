class PromptBuilder {
  static String buildSystemPrompt({
    required String personaPrompt,
    String? summary,
    Map<String, String>? userProfile,
    List<String>? recentEvents,
  }) {
    final now = DateTime.now();
    final weekday = ['一', '二', '三', '四', '五', '六', '日'][now.weekday - 1];
    final timeStr = '${now.year}年${now.month}月${now.day}日 星期$weekday ${now.hour}:${now.minute.toString().padLeft(2, '0')}';

    final parts = <String>[
      personaPrompt,
      '',
      '当前时间：$timeStr',
    ];

    if (summary != null && summary.isNotEmpty) {
      parts.addAll(['', '--- 对话历史摘要 ---', summary]);
    }

    if (userProfile != null && userProfile.isNotEmpty) {
      parts.addAll(['', '--- 用户画像 ---']);
      userProfile.forEach((key, value) {
        parts.add('$key: $value');
      });
    }

    if (recentEvents != null && recentEvents.isNotEmpty) {
      parts.addAll(['', '--- 近期事件 ---', ...recentEvents]);
    }

    return parts.join('\n');
  }

  static String buildCompactPrompt(String conversationHistory) {
    return '请将以下对话历史压缩成一段简洁的摘要，保留关键信息（用户信息、消费记录、重要事件），不超过500字：\n\n$conversationHistory';
  }
}
