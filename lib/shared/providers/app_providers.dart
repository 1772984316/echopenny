import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/database/app_database.dart';
import '../../core/llm/deepseek_client.dart';

final isFirstLaunchProvider = StateProvider<bool>((ref) => true);

final apiKeyProvider = StateProvider<String>((ref) => '');

final apiKeyPersistProvider = Provider<void>((ref) {
  ref.listen(apiKeyProvider, (_, next) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('deepseek_api_key', next);
    await prefs.setBool('is_first_launch', false);
  });
});

final databaseProvider = Provider<AppDatabase>((ref) => AppDatabase());

final llmClientProvider = Provider<DeepSeekClient>((ref) {
  ref.watch(apiKeyPersistProvider);
  final apiKey = ref.watch(apiKeyProvider);
  return DeepSeekClient(apiKey: apiKey);
});

final sharedPreferencesProvider = FutureProvider<SharedPreferences>(
  (ref) => SharedPreferences.getInstance(),
);
