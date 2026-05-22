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
        return http.Response.bytes(
          utf8.encode(
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
          ),
          200,
        );
      });
      final AiseeBillingService service = AiseeBillingService(
        httpClient: client,
      );

      final AiseeBillingOverview overview = await service.fetchBillingOverview(
        'access-token',
        caredUserId: 'user-a',
      );

      expect(capturedRequest.url.path, '/api/v1/me/billing-overview');
      expect(capturedRequest.url.queryParameters['cared_user_id'], 'user-a');
      expect(capturedRequest.headers['Authorization'], 'Bearer access-token');
      expect(overview.careGroup.canManageBilling, isTrue);
      expect(overview.effectivePlan.code, 'plus_399k');
      expect(overview.aiQuota?.remaining, 120);
      expect(overview.events.single.eventType, 'subscription_renewed');
      expect(overview.storeManagement.provider, 'google_play');
    },
  );

  test('fetchUsage parses plan and quotas', () async {
    late String path;
    final _FakeHttpClient client = _FakeHttpClient((http.BaseRequest request) {
      path = request.url.path;
      return http.Response(
        jsonEncode(<String, Object?>{
          'plan': <String, Object?>{
            'code': 'basic_149k',
            'name': 'Basic',
            'price_vnd': 149000,
            'billing_period': 'month',
            'status': 'active',
          },
          'quotas': <String, Object?>{
            'ai_minutes': <String, Object?>{
              'usage_type': 'ai_minutes',
              'limit': 100,
              'used': 10,
              'granted': 0,
              'remaining': 90,
              'unlimited': false,
              'upgrade_suggested': false,
            },
          },
          'top_usage': <Object?>[],
          'period_start': '2026-05-01T00:00:00Z',
          'period_end': '2026-06-01T00:00:00Z',
          'as_of': '2026-05-10T00:00:00Z',
        }),
        200,
      );
    });
    final AiseeBillingService service = AiseeBillingService(httpClient: client);
    final AiseeMeUsageResponse u = await service.fetchUsage(
      'access-token',
      caredUserId: 'user-a',
    );
    expect(path, '/api/v1/me/usage');
    expect(client.lastRequest?.url.queryParameters['cared_user_id'], 'user-a');
    expect(u.plan.code, 'basic_149k');
    expect(u.quotas['ai_minutes']?.remaining, 90);
    service.close();
  });

  test(
    'fetchBillingOverview retries without cared user when billing context is stale',
    () async {
      final List<http.BaseRequest> requests = <http.BaseRequest>[];
      final _FakeHttpClient client = _FakeHttpClient((
        http.BaseRequest request,
      ) {
        requests.add(request);
        if (requests.length == 1) {
          return http.Response.bytes(
            utf8.encode(
              jsonEncode(<String, Object?>{
                'error': <String, Object?>{
                  'code': 'no_billing_care_group',
                  'message':
                      'Hãy tham gia hoặc chọn một nhóm chăm sóc trước khi quản lý gói',
                },
              }),
            ),
            409,
          );
        }
        return http.Response.bytes(
          utf8.encode(
            jsonEncode(<String, Object?>{
              'care_group': <String, Object?>{
                'id': 'group-1',
                'name': 'Gia dinh me',
                'current_user_role': 'billing_admin',
                'can_manage_billing': true,
                'cared_user_count': 1,
                'member_count': 2,
              },
              'subscription': null,
              'effective_plan': <String, Object?>{
                'code': 'free',
                'name': 'Miễn phí',
                'price_vnd': 0,
                'billing_period': 'month',
                'status': 'active',
              },
              'entitlements': <String, Object?>{},
              'usage': <String, Object?>{
                'plan': <String, Object?>{'code': 'free', 'name': 'Miễn phí'},
                'quotas': <String, Object?>{},
                'top_usage': <Object?>[],
                'period_start': '2026-05-01T00:00:00Z',
                'period_end': '2026-06-01T00:00:00Z',
                'as_of': '2026-05-10T00:00:00Z',
              },
              'events': <Object?>[],
              'store_management': <String, Object?>{
                'provider': 'google_play',
                'instructions': 'Quan ly trong cua hang',
              },
              'as_of': '2026-05-10T00:00:00Z',
            }),
          ),
          200,
        );
      });
      final AiseeBillingService service = AiseeBillingService(
        httpClient: client,
      );

      final AiseeBillingOverview overview = await service.fetchBillingOverview(
        'access-token',
        caredUserId: 'user-a',
      );

      expect(requests, hasLength(2));
      expect(requests.first.url.queryParameters['cared_user_id'], 'user-a');
      expect(
        requests.last.url.queryParameters.containsKey('cared_user_id'),
        isFalse,
      );
      expect(overview.careGroup.id, 'group-1');
      service.close();
    },
  );

  test(
    'fetchUsage retries without cared user when billing context is stale',
    () async {
      final List<http.BaseRequest> requests = <http.BaseRequest>[];
      final _FakeHttpClient client = _FakeHttpClient((
        http.BaseRequest request,
      ) {
        requests.add(request);
        if (requests.length == 1) {
          return http.Response.bytes(
            utf8.encode(
              jsonEncode(<String, Object?>{
                'error': <String, Object?>{
                  'code': 'no_billing_care_group',
                  'message':
                      'Hãy tham gia hoặc chọn một nhóm chăm sóc trước khi quản lý gói',
                },
              }),
            ),
            409,
          );
        }
        return http.Response(
          jsonEncode(<String, Object?>{
            'plan': <String, Object?>{
              'code': 'basic_149k',
              'name': 'Basic',
              'price_vnd': 149000,
              'billing_period': 'month',
              'status': 'active',
            },
            'quotas': <String, Object?>{
              'ai_minutes': <String, Object?>{
                'usage_type': 'ai_minutes',
                'limit': 100,
                'used': 10,
                'granted': 0,
                'remaining': 90,
                'unlimited': false,
                'upgrade_suggested': false,
              },
            },
            'top_usage': <Object?>[],
            'period_start': '2026-05-01T00:00:00Z',
            'period_end': '2026-06-01T00:00:00Z',
            'as_of': '2026-05-10T00:00:00Z',
          }),
          200,
        );
      });
      final AiseeBillingService service = AiseeBillingService(
        httpClient: client,
      );

      final AiseeMeUsageResponse usage = await service.fetchUsage(
        'access-token',
        caredUserId: 'user-a',
      );

      expect(requests, hasLength(2));
      expect(requests.first.url.queryParameters['cared_user_id'], 'user-a');
      expect(
        requests.last.url.queryParameters.containsKey('cared_user_id'),
        isFalse,
      );
      expect(usage.plan.code, 'basic_149k');
      service.close();
    },
  );
}

class _FakeHttpClient extends http.BaseClient {
  _FakeHttpClient(this._handler);

  final http.Response Function(http.BaseRequest request) _handler;
  http.BaseRequest? lastRequest;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    lastRequest = request;
    final http.Response response = _handler(request);
    return http.StreamedResponse(
      Stream<List<int>>.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
    );
  }
}
