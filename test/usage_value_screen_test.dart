import 'package:aiseeapp/generated/l10n/app_localizations.dart';
import 'package:aiseeapp/models/aisee_api_models.dart';
import 'package:aiseeapp/models/aisee_billing_models.dart';
import 'package:aiseeapp/screens/usage_value_screen.dart';
import 'package:aiseeapp/services/aisee_billing_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  Widget buildApp(Widget child) {
    return MaterialApp(
      locale: const Locale('vi'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );
  }

  testWidgets(
    'usage value shows session-expired error instead of spinning forever',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        buildApp(
          UsageValueScreen(
            billingService: _FakeBillingService(),
            readTokens: () async => null,
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Phiên đăng nhập hết hạn'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );

  testWidgets('usage value renders quota cards as progress summaries', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      buildApp(
        UsageValueScreen(
          billingService: _FakeBillingService(
            overview: _overview(),
            usage: _usage(),
          ),
          readTokens: () async => const AiseeAuthTokens(
            accessToken: 'token',
            refreshToken: 'refresh',
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(find.text('Hạn mức sử dụng'), findsAtLeastNWidgets(2));
    expect(find.text('Care Pro'), findsAtLeastNWidgets(1));
    expect(find.text('Đã sử dụng 25%'), findsOneWidget);
    expect(find.text('Cuộc gọi'), findsOneWidget);
    expect(find.text('Gọi video'), findsNothing);
    expect(find.text('Không giới hạn'), findsOneWidget);
    expect(find.text('Tính năng chăm sóc theo gói'), findsOneWidget);
    expect(find.textContaining('Đã dùng 0 /'), findsNothing);
    expect(find.textContaining('Đặt lại'), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNWidgets(2));
    expect(
      tester.widget<Text>(find.text('Không giới hạn')).textAlign,
      TextAlign.right,
    );
    expect(
      (tester.getCenter(find.text('Cuộc gọi')).dy -
              tester.getCenter(find.text('Không giới hạn')).dy)
          .abs(),
      lessThan(4),
    );

    await tester.tap(find.text('Tính năng chăm sóc theo gói'));
    await tester.pumpAndSettle();
    expect(find.text('Báo cáo tuần'), findsOneWidget);
    expect(find.text('Đọc tin nhắn'), findsOneWidget);
    expect(find.text('Cảnh báo thông minh'), findsOneWidget);
    expect(find.text('Gọi khẩn cấp SOS'), findsOneWidget);
    expect(find.text('Cuộc gọi video mỗi ngày'), findsOneWidget);
    expect(find.text('Ưu tiên tình nguyện viên'), findsOneWidget);
    expect(find.text('Quyền theo gói AiSee.'), findsNothing);
    expect(find.text('Read messages enabled'), findsNothing);
    expect(find.text('Smart alert enabled'), findsNothing);
    expect(find.text('Sos enabled'), findsNothing);
    expect(find.text('Video calls per day'), findsNothing);
    expect(find.text('Volunteer priority level'), findsNothing);
  });
}

class _FakeBillingService extends AiseeBillingService {
  _FakeBillingService({this.overview, this.usage})
    : super(httpClient: _NoopClient());

  final AiseeBillingOverview? overview;
  final AiseeMeUsageResponse? usage;

  @override
  Future<AiseeBillingOverview> fetchBillingOverview(
    String accessToken, {
    String? careGroupId,
    String? caredUserId,
  }) async {
    return overview ?? _overview();
  }

  @override
  Future<AiseeMeUsageResponse> fetchUsage(
    String accessToken, {
    String? careGroupId,
    String? caredUserId,
  }) async {
    return usage ?? _usage();
  }
}

class _NoopClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    throw UnimplementedError();
  }
}

AiseeBillingOverview _overview() {
  return AiseeBillingOverview(
    careGroup: const AiseeCareGroupSummary(
      id: 'group-1',
      name: 'Gia dinh',
      currentUserRole: 'billing_admin',
      canManageBilling: true,
      caredUserCount: 1,
      memberCount: 2,
    ),
    effectivePlan: const AiseeBillingPlan(
      code: 'care_pro',
      name: 'Care Pro',
      priceVnd: 399000,
      billingPeriod: 'month',
      status: 'active',
    ),
    entitlements: const <String, AiseeEntitlementValue>{
      'weekly_report_enabled': AiseeEntitlementValue(limitValue: true),
      'read_messages_enabled': AiseeEntitlementValue(limitValue: true),
      'smart_alert_enabled': AiseeEntitlementValue(limitValue: true),
      'sos_enabled': AiseeEntitlementValue(limitValue: true),
      'video_calls_per_day': AiseeEntitlementValue(limitValue: true),
      'volunteer_priority_level': AiseeEntitlementValue(limitValue: 1),
    },
    usage: AiseeUsageSummary(quotas: _quotaMap()),
    events: const <AiseeSubscriptionEvent>[],
    storeManagement: const AiseeStoreManagementInfo(instructions: 'Open store'),
  );
}

AiseeMeUsageResponse _usage() {
  return AiseeMeUsageResponse(
    plan: const AiseeBillingPlan(
      code: 'care_pro',
      name: 'Care Pro',
      priceVnd: 399000,
      billingPeriod: 'month',
      status: 'active',
    ),
    quotas: _quotaMap(),
    topUsage: const <AiseeUsageTopEntry>[],
    periodStart: DateTime.utc(2026, 5, 1),
    periodEnd: DateTime.utc(2026, 6, 1),
    asOf: DateTime.utc(2026, 5, 22, 9, 34),
  );
}

Map<String, AiseeUsageQuota> _quotaMap() {
  return <String, AiseeUsageQuota>{
    'ai_minutes': const AiseeUsageQuota(
      usageType: 'ai_minutes',
      limit: 100,
      used: 25,
      granted: 0,
      remaining: 75,
      unlimited: false,
      upgradeSuggested: false,
      unit: 'phút',
      resetPeriod: 'day',
    ),
    'video_calls': const AiseeUsageQuota(
      usageType: 'video_calls',
      limit: 40,
      used: 10,
      granted: 0,
      remaining: 30,
      unlimited: true,
      upgradeSuggested: false,
      unit: 'phút',
    ),
  };
}
