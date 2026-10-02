import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/main.dart';

void main() {
  testWidgets(
    'CRM Business app starts',
    (WidgetTester tester) async {
      await tester.pumpWidget(const CrmApp());

      expect(find.text('CRM Business'), findsOneWidget);
    },
  );
}
