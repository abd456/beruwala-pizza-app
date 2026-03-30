import 'package:flutter_test/flutter_test.dart';
import 'package:beruwala_pizza/main.dart';

void main() {
  testWidgets('App should build', (WidgetTester tester) async {
    await tester.pumpWidget(const BeruwalaPizzaApp());
    expect(find.text('Beruwala Pizza'), findsOneWidget);
  });
}
