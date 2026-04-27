import 'dart:convert';

import 'package:aiseeapp/models/aisee_billing_models.dart';
import 'package:aiseeapp/services/aisee_billing_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  test(
    'fetchBillingOverview parses care group plan quota and store status',
    () async {
      late http.BaseRequest capturedRequest;
      final _FakeHttpClient client = _FakeHttpClient((request) {
        capturedRequest = request;
        return http.Response(
          jsonEncode(<String, Object?>{
            'care_group': <String, Object?>{
              'id': 'group-1',
              'name': 'Gia dinh me',
              'current_user_role': 'billing_admin',
              'can_manage_billing': true,
              'cared_user_count': 2,
              'member_count': 3,
            },
            'subscription': <String, Object?>{
              'id': 'sub-1',
              'care_group_id': 'group-1',
              'plan_code': 'plus_399k',
              'status': 'active',
              'provider': 'google_play',
              'cancel_at_period_end': false,
            },
            'effective_plan': <String, Object?>{
              'code': 'plus_399k',
              'name': 'Care Plus',
              'price_vnd': 399000,
              'billing_period': 'month',
              'status': 'active',
            },
            'entitlements': <String, Object?>{
              'weekly_report_enabled': <String, Object?>{'limit_value': true},
            },
            'usage': <String, Object?>{
              'plan': <String, Object?>{
                'code': 'plus_399k',
                'name': 'Care Plus',
              },
              'quotas': <String, Object?>{
                'ai_minutes': <String, Object?>{
                  'usage_type': 'ai_minutes',
                  'feature_key': 'ai_minutes_per_month',
                  'limit': 600,
                  'used': 480,
                  'remaining': 120,
                  'unit': 'minutes',
                  'reset_period': 'month',
                  'upgrade_suggested': true,
                },
              },
              'top_usage': <Object?>[],
              'period_start': '2026-04-01T00:00:00Z',
              'period_end': '2026-05-01T00:00:00Z',
              'as_of': '2026-04-26T00:00:00Z',
            },
            'events': <Object?>[
              <String, Object?>{
                'id': 'event-1',
                'event_type': 'subscription_renewed',
                'provider': 'google_play',
                'created_at': '2026-04-26T00:00:00Z',
                'occurred_at': '2026-04-26T00:00:00Z',
              },
            ],
            'store_management': <String, Object?>{
              'provider': 'google_play',
              'manage_url':
                  'https://play.google.com/store/account/subscriptions',
              'instructions': 'Quan ly hoac huy goi trong Google Play.',
            },
            'as_of': '2026-04-26T00:00:00Z',
          }),
          200,
        );
      });
      final AiseeBillingService service = AiseeBillingService(
        httpClient: client,
      );

      final AiseeBillingOverview overview = await service.fetchBillingOverview(
        'access-token',
      );

      expect(capturedRequest.url.path, '/api/v1/me/billing-overview');
      expect(capturedRequest.headers['Authorization'], 'Bearer access-token');
      expect(overview.careGroup.canManageBilling, isTrue);
      expect(overview.effectivePlan.code, 'plus_399k');
      expect(overview.aiQuota?.remaining, 120);
      expect(overview.events.single.eventType, 'subscription_renewed');
      expect(overview.storeManagement.provider, 'google_play');
    },
  );
}

class _FakeHttpClient extends http.BaseClient {
  _FakeHttpClient(this._handler);

  final http.Response Function(http.BaseRequest request) _handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final http.Response response = _handler(request);
    return http.StreamedResponse(
      Stream<List<int>>.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
    );
  }
}
