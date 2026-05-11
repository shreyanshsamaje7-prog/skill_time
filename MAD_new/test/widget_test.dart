import 'package:flutter_test/flutter_test.dart';

import 'package:skill_time/main.dart';

void main() {
  testWidgets('SkillTime app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SkillTimeApp());

    expect(find.text('SkillTime'), findsOneWidget);
  });
}
