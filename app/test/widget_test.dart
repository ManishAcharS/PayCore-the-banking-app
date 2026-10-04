import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paycore/main.dart';

void main() {
  testWidgets('App loads', (WidgetTester tester) async {
    await tester.pumpWidget(const PayCoreApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
