import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/main.dart';

void main() {
  testWidgets('welcome screen shows the verification entry point', (
    tester,
  ) async {
    await tester.pumpWidget(const KycFlowApp());

    expect(find.text('Start verification'), findsOneWidget);
    expect(find.text('KYCFlow'), findsOneWidget);
    expect(find.textContaining('Branch staff'), findsOneWidget);
  });
}
