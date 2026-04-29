import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ArtFlow/app.dart';

void main() {
  testWidgets('Artflow app boots', (WidgetTester tester) async {
    await tester.pumpWidget(const ArtflowApp());
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
