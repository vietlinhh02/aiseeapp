import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aiseeapp/widgets/permission_bootstrap_gate.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('gate waits for bootstrap and then shows child', (
    WidgetTester tester,
  ) async {
    final Completer<void> completer = Completer<void>();

    await tester.pumpWidget(
      MaterialApp(
        home: PermissionBootstrapGate(
          ensurePermissions: () => completer.future,
          child: const Text('home ready'),
        ),
      ),
    );

    expect(find.text('home ready'), findsNothing);

    completer.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));

    expect(find.text('home ready'), findsOneWidget);
  });
}
