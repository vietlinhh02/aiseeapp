import 'package:aiseeapp/generated/l10n/app_localizations.dart';
import 'package:aiseeapp/models/aisee_dashboard_models.dart';
import 'package:aiseeapp/screens/family_dashboard_health_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildHealthTab() {
    final health = DashboardHealth(
      medications: [
        MedWithAdherence(
          medication: DashboardMedication(
            id: 'med-1',
            name: 'Vitamin D',
            dosage: '1 viên',
            times: ['08:00'],
            frequency: 'daily',
          ),
          takenToday: true,
        ),
      ],
      recentSymptoms: [
        HealthSymptom(
          id: 'symptom-1',
          symptom: 'Đau đầu',
          severity: 'Nhẹ',
          loggedAt: DateTime(2026, 4, 24, 9, 30),
        ),
      ],
      recentMetrics: [
        HealthMetric(
          id: 'metric-1',
          metricType: 'Huyết áp',
          value: '120/80',
          unit: 'mmHg',
          loggedAt: DateTime(2026, 4, 24, 10),
        ),
      ],
    );

    return MaterialApp(
      locale: const Locale('vi'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: FamilyDashboardHealthTab(
          loading: false,
          health: health,
          onRefresh: () async {},
          overviewChartBuilder: (chartConfig) {
            return Text(
              'chartjs-${chartConfig['type']}',
              key: const Key('health-overview-chart'),
            );
          },
        ),
      ),
    );
  }

  testWidgets('hiển thị overview bằng Chart.js và chi tiết dạng card', (
    tester,
  ) async {
    await tester.pumpWidget(buildHealthTab());
    await tester.pump();

    expect(find.text('Tổng quan'), findsOneWidget);
    expect(find.byKey(const Key('health-overview-chart')), findsOneWidget);
    expect(find.text('chartjs-bar'), findsOneWidget);
    expect(find.textContaining('Đã uống hôm nay'), findsOneWidget);
    expect(find.textContaining('Triệu chứng'), findsWidgets);
    expect(find.textContaining('Chỉ số'), findsWidgets);

    expect(find.text('Vitamin D'), findsOneWidget);
    expect(find.text('1 viên'), findsOneWidget);
    expect(find.text('Đã uống'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pump();

    expect(find.text('Đau đầu'), findsOneWidget);
    expect(find.text('Nhẹ'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pump();

    expect(find.text('Huyết áp'), findsOneWidget);
    expect(find.text('120/80 mmHg'), findsOneWidget);
  });
}
