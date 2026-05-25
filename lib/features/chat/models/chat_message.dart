enum MessageSender { user, echo }

enum Emotion { none, happy, heartache, coquettish, naughty, serious, wronged }

class ChatMessage {
  final String id;
  final MessageSender sender;
  final String text;
  final Emotion emotion;
  final DateTime timestamp;
  final String? imagePath;

  ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    this.emotion = Emotion.none,
    required this.timestamp,
    this.imagePath,
  });

  String get emotionEmoji {
    switch (emotion) {
      case Emotion.happy: return '😊';
      case Emotion.heartache: return '😢';
      case Emotion.coquettish: return '🥰';
      case Emotion.naughty: return '😏';
      case Emotion.serious: return '😐';
      case Emotion.wronged: return '😢';
      case Emotion.none: return '';
    }
  }
}
