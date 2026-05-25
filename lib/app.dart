import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/chat/chat_page.dart';
import 'features/settings/settings_page.dart';
import 'features/onboarding/onboarding_page.dart';
import 'shared/providers/app_providers.dart';

class EchoPennyApp extends ConsumerWidget {
  const EchoPennyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFirstLaunch = ref.watch(isFirstLaunchProvider);

    return MaterialApp(
      title: 'EchoPenny',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF6750A4),
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      home: isFirstLaunch ? const OnboardingPage() : const ChatPage(),
      routes: {
        '/chat': (context) => const ChatPage(),
        '/settings': (context) => const SettingsPage(),
        '/onboarding': (context) => const OnboardingPage(),
      },
    );
  }
}
