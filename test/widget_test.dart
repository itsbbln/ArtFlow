import 'package:flutter_test/flutter_test.dart';

import 'package:artflow_flutter/app.dart';

void main() {
  testWidgets('Artflow app boots', (WidgetTester tester) async {
    await tester.pumpWidget(const ArtflowApp());
    await tester.pumpAndSettle();

    expect(find.text('ArtFlow'), findsOneWidget);
  });
}
