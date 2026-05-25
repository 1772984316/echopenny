import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/conversations.dart';

part 'conversation_dao.g.dart';

@DriftAccessor(tables: [Conversations])
class ConversationDao extends DatabaseAccessor<AppDatabase> with _$ConversationDaoMixin {
  ConversationDao(super.db);

  Future<int> saveMessage(ConversationsCompanion entry) {
    return into(conversations).insert(entry);
  }

  Future<List<Conversation>> getRecentMessages({int limit = 50}) {
    return (select(conversations)
      ..orderBy([(c) => OrderingTerm.desc(c.createdAt)])
      ..limit(limit))
      .get();
  }

  Future<int> getMessageCount() {
    return (select(conversations).get()).then((list) => list.length);
  }
}
