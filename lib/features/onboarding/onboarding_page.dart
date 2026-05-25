import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'onboarding_controller.dart';
import '../../shared/providers/app_providers.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _pageController = PageController();
  int _currentPage = 0;
  final _nameController = TextEditingController();
  final _salaryController = TextEditingController();

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < 2) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _complete();
    }
  }

  Future<void> _complete() async {
    final controller = ref.read(onboardingControllerProvider);
    await controller.completeSetup(name: _nameController.text.trim(), salary: _salaryController.text.trim());
    ref.read(isFirstLaunchProvider.notifier).state = false;
    Navigator.pushReplacementNamed(context, '/chat');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _WelcomePage(onNext: _next),
                  _NamePage(controller: _nameController, onNext: _next),
                  _OptionalInfoPage(salaryController: _salaryController, onComplete: _complete),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  final VoidCallback onNext;
  const _WelcomePage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('👧', style: TextStyle(fontSize: 80)),
          const SizedBox(height: 24),
          Text('你好呀！', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          const Text('我是 Echo，你的 AI 陪伴伙伴\n我可以陪你聊天，也可以帮你记账哦～', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, height: 1.6)),
          const SizedBox(height: 48),
          FilledButton(onPressed: onNext, child: const Text('开始吧')),
        ],
      ),
    );
  }
}

class _NamePage extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onNext;
  const _NamePage({required this.controller, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('😊', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 24),
          Text('你叫什么名字呀？', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 24),
          TextField(
            controller: controller,
            decoration: InputDecoration(hintText: '输入你的名字', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onNext(),
          ),
          const SizedBox(height: 32),
          FilledButton(onPressed: onNext, child: const Text('下一步')),
        ],
      ),
    );
  }
}

class _OptionalInfoPage extends StatelessWidget {
  final TextEditingController salaryController;
  final VoidCallback onComplete;
  const _OptionalInfoPage({required this.salaryController, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📝', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 24),
          Text('还想告诉我点什么吗？', style: Theme.of(context).textTheme.headlineSmall),
          const Text('（选填，可以之后再说）', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          TextField(
            controller: salaryController,
            decoration: InputDecoration(hintText: '月薪多少呀？（选填）', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 32),
          FilledButton(onPressed: onComplete, child: const Text('完成')),
        ],
      ),
    );
  }
}
