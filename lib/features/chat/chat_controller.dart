import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/chat_message.dart';
import '../../core/agent/agent_loop.dart';
import '../../core/database/app_database.dart';

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;

  ChatState({this.messages = const [], this.isLoading = false});

  ChatState copyWith({List<ChatMessage>? messages, bool? isLoading}) {
    return ChatState(messages: messages ?? this.messages, isLoading: isLoading ?? this.isLoading);
  }
}

class ChatController extends StateNotifier<ChatState> {
  final AgentLoop agentLoop;
  final AppDatabase db;
  List<Map<String, dynamic>> _conversationHistory = [];

  ChatController({required this.agentLoop, required this.db}) : super(ChatState());

  Future<void> sendText(String text) async {
    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sender: MessageSender.user,
      text: text,
      timestamp: DateTime.now(),
    );
    state = state.copyWith(messages: [...state.messages, userMsg], isLoading: true);

    _conversationHistory.add({'role': 'user', 'content': text});
    await _saveToDb('user', text);

    try {
      final persona = await db.personaDao.getDefaultPersona();
      final userProfile = await _loadUserProfile();
      final summary = await _loadSummary();

      final result = await agentLoop.run(
        messages: _conversationHistory,
        personaPrompt: persona?.systemPrompt ?? '',
        summary: summary,
        userProfile: userProfile,
      );

      _conversationHistory = result.updatedMessages;

      final echoMessages = _splitMessages(result.text);
      for (var i = 0; i < echoMessages.length; i++) {
        if (i > 0) {
          await Future.delayed(Duration(milliseconds: 200 + Random().nextInt(300)));
        }
        final msg = ChatMessage(
          id: '${DateTime.now().millisecondsSinceEpoch}_$i',
          sender: MessageSender.echo,
          text: echoMessages[i]['text'],
          emotion: echoMessages[i]['emotion'],
          timestamp: DateTime.now(),
        );
        state = state.copyWith(messages: [...state.messages, msg]);
      }
      await _saveToDb('assistant', result.text);
    } catch (e) {
      final errorMsg = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: MessageSender.echo,
        text: '啊呀出错了～$e',
        emotion: Emotion.wronged,
        timestamp: DateTime.now(),
      );
      state = state.copyWith(messages: [...state.messages, errorMsg]);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> sendImage(String path) async {
    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sender: MessageSender.user,
      text: '[图片]',
      timestamp: DateTime.now(),
      imagePath: path,
    );
    state = state.copyWith(messages: [...state.messages, userMsg], isLoading: true);
  }

  List<Map<String, dynamic>> _splitMessages(String text) {
    final parts = text.split('\n').where((s) => s.trim().isNotEmpty).toList();
    return parts.map((part) {
      final emotionRegex = RegExp(r'\[emotion:(\w+)\]\s*');
      final match = emotionRegex.matchAsPrefix(part);
      if (match != null) {
        return {
          'text': part.substring(match.end),
          'emotion': _parseEmotion(match.group(1) ?? ''),
        };
      }
      return {'text': part, 'emotion': Emotion.none};
    }).toList();
  }

  Emotion _parseEmotion(String tag) {
    switch (tag) {
      case 'happy': return Emotion.happy;
      case 'heartache': return Emotion.heartache;
      case 'coquettish': return Emotion.coquettish;
      case 'naughty': return Emotion.naughty;
      case 'serious': return Emotion.serious;
      case 'wronged': return Emotion.wronged;
      default: return Emotion.none;
    }
  }

  Future<void> _saveToDb(String role, String content) async {
    await db.conversationDao.saveMessage(
      ConversationsCompanion.insert(role: role, content: content),
    );
  }

  Future<String?> _loadSummary() async => null;
  Future<Map<String, String>> _loadUserProfile() async => {};
}
