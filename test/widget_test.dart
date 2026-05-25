import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:echopenny/app.dart';

void main() {
  testWidgets('App renders onboarding page', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: EchoPennyApp()));
    expect(find.text('Onboarding'), findsOneWidget);
  });
}
