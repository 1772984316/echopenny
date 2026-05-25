import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/database/app_database.dart';
import '../../core/llm/deepseek_client.dart';

final isFirstLaunchProvider = StateProvider<bool>((ref) => true);

final databaseProvider = Provider<AppDatabase>((ref) => AppDatabase());

final apiKeyProvider = StateProvider<String>((ref) => '');

final llmClientProvider = Provider<DeepSeekClient>((ref) {
  final apiKey = ref.watch(apiKeyProvider);
  return DeepSeekClient(apiKey: apiKey);
});

final sharedPreferencesProvider = FutureProvider<SharedPreferences>(
  (ref) => SharedPreferences.getInstance(),
);
