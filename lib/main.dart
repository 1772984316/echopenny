import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'shared/providers/app_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final apiKey = prefs.getString('deepseek_api_key') ?? '';
  final isFirst = prefs.getBool('is_first_launch') ?? true;

  runApp(ProviderScope(
    overrides: [
      apiKeyProvider.overrideWith((ref) => apiKey),
      isFirstLaunchProvider.overrideWith((ref) => isFirst),
    ],
    child: const EchoPennyApp(),
  ));
}
