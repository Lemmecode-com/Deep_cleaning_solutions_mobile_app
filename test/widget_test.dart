// test/widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:srg_app/main.dart';


void main() {
  testWidgets('SRG App launches successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const SRGApp());
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}