import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aiseeapp/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues(<String, Object>{});

  testWidgets('App khởi tạo MaterialApp', (WidgetTester tester) async {
    await tester.pumpWidget(const AiseeApp());
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
