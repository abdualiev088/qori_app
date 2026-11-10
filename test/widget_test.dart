import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qori_app/main.dart';

void main() {
  testWidgets('app starts on an empty screen', (WidgetTester tester) async {
    await tester.pumpWidget(const QoriApp());

    expect(find.byType(Scaffold), findsOneWidget);
  });
}
