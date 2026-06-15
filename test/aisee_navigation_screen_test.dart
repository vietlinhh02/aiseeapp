import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aiseeapp/screens/aisee_navigation_screen.dart';

void main() {
  testWidgets('renders destination name + step + stop button',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: AiseeNavigationScreen(
        data: const NavigationScreenData(
          destinationName: 'Bệnh viện Chợ Rẫy',
          destinationQuery: 'Bệnh viện Chợ Rẫy',
          totalDistanceM: 1500,
          totalDurationS: 1200,
          totalSteps: 5,
          currentStepIndex: 2,
          currentStepName: 'Nguyễn Trãi',
          currentStepVoiceVi: 'Đi thẳng 200 mét rồi rẽ phải',
          remainingDistanceM: 800,
          progressPct: 0.4,
          isDeviated: false,
          isCompleted: false,
          outcome: 'in_progress',
        ),
        onStop: () async {},
      ),
    ));

    expect(find.text('Bệnh viện Chợ Rẫy'), findsOneWidget);
    expect(find.text('Đi thẳng 200 mét rồi rẽ phải'), findsOneWidget);
    expect(find.text('DỪNG CHỈ ĐƯỜNG'), findsOneWidget);
    expect(find.text('800 m'), findsOneWidget); // Còn lại
    expect(find.text('1.50 km'), findsOneWidget); // Tổng
  });

  testWidgets('renders red deviation warning when isDeviated=true',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: AiseeNavigationScreen(
        data: const NavigationScreenData(
          destinationName: 'X',
          destinationQuery: 'X',
          totalDistanceM: 1000,
          totalDurationS: 600,
          totalSteps: 3,
          currentStepIndex: 2,
          currentStepName: 'Lê Lợi',
          currentStepVoiceVi: 'Quay lại hướng Lê Lợi',
          remainingDistanceM: 500,
          progressPct: 0.5,
          isDeviated: true,
          isCompleted: false,
          outcome: 'in_progress',
        ),
        onStop: () async {},
      ),
    ));

    expect(find.text('Có vẻ bạn đang đi lệch'), findsOneWidget);
    expect(find.text('Quay lại hướng Lê Lợi'), findsOneWidget);
  });

  testWidgets('tapping stop button invokes onStop',
      (WidgetTester tester) async {
    bool stopCalled = false;

    await tester.pumpWidget(MaterialApp(
      home: AiseeNavigationScreen(
        data: const NavigationScreenData(
          destinationName: 'X',
          destinationQuery: 'X',
          totalDistanceM: 100,
          totalDurationS: 60,
          totalSteps: 1,
          currentStepIndex: 1,
          currentStepName: 'A',
          currentStepVoiceVi: 'Bước 1',
          remainingDistanceM: 100,
          progressPct: 0.0,
          isDeviated: false,
          isCompleted: false,
          outcome: 'in_progress',
        ),
        onStop: () async {
          stopCalled = true;
        },
      ),
    ));

    await tester.tap(find.text('DỪNG CHỈ ĐƯỜNG'));
    await tester.pump();
    expect(stopCalled, isTrue);
  });
}
