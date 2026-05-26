import 'package:aiseeapp/api/billing_api.dart';
import 'package:aiseeapp/models/aisee_billing_models.dart';
import 'package:aiseeapp/services/aisee_billing_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retrofit/dio.dart';

void main() {
  test(
    'fetchBillingOverview parses care group plan quota and store status',
    () async {
      final _FakeBillingApiClient client = _FakeBillingApiClient(
        billingOverviewResponses: <HttpResponse<dynamic>>[
          _response(<String, Object?>{
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
          }, 200),
        ],
      );
      final AiseeBillingService service = AiseeBillingService(
        apiClient: client,
      );

      final AiseeBillingOverview overview = await service.fetchBillingOverview(
        'access-token',
        caredUserId: 'user-a',
      );

      expect(client.lastAuthorization, 'Bearer access-token');
      expect(client.lastBillingOverviewQuery?['cared_user_id'], 'user-a');
      expect(overview.careGroup.canManageBilling, isTrue);
      expect(overview.effectivePlan.code, 'plus_399k');
      expect(overview.aiQuota?.remaining, 120);
      expect(overview.events.single.eventType, 'subscription_renewed');
      expect(overview.storeManagement.provider, 'google_play');
    },
  );

  test('fetchUsage parses plan and quotas', () async {
    final _FakeBillingApiClient client = _FakeBillingApiClient(
      usageResponses: <HttpResponse<dynamic>>[
        _response(<String, Object?>{
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
        }, 200),
      ],
    );
    final AiseeBillingService service = AiseeBillingService(apiClient: client);
    final AiseeMeUsageResponse u = await service.fetchUsage(
      'access-token',
      caredUserId: 'user-a',
    );
    expect(client.lastAuthorization, 'Bearer access-token');
    expect(client.lastUsageQuery?['cared_user_id'], 'user-a');
    expect(u.plan.code, 'basic_149k');
    expect(u.quotas['ai_minutes']?.remaining, 90);
    service.close();
  });

  test(
    'fetchBillingOverview retries without cared user when billing context is stale',
    () async {
      final _FakeBillingApiClient client = _FakeBillingApiClient(
        billingOverviewResponses: <HttpResponse<dynamic>>[
          _response(<String, Object?>{
            'error': <String, Object?>{
              'code': 'no_billing_care_group',
              'message':
                  'Hãy tham gia hoặc chọn một nhóm chăm sóc trước khi quản lý gói',
            },
          }, 409),
          _response(<String, Object?>{
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
          }, 200),
        ],
      );
      final AiseeBillingService service = AiseeBillingService(
        apiClient: client,
      );

      final AiseeBillingOverview overview = await service.fetchBillingOverview(
        'access-token',
        caredUserId: 'user-a',
      );

      expect(client.billingOverviewQueries, hasLength(2));
      expect(client.billingOverviewQueries.first['cared_user_id'], 'user-a');
      expect(
        client.billingOverviewQueries.last.containsKey('cared_user_id'),
        isFalse,
      );
      expect(overview.careGroup.id, 'group-1');
      service.close();
    },
  );

  test(
    'fetchUsage retries without cared user when billing context is stale',
    () async {
      final _FakeBillingApiClient client = _FakeBillingApiClient(
        usageResponses: <HttpResponse<dynamic>>[
          _response(<String, Object?>{
            'error': <String, Object?>{
              'code': 'no_billing_care_group',
              'message':
                  'Hãy tham gia hoặc chọn một nhóm chăm sóc trước khi quản lý gói',
            },
          }, 409),
          _response(<String, Object?>{
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
          }, 200),
        ],
      );
      final AiseeBillingService service = AiseeBillingService(
        apiClient: client,
      );

      final AiseeMeUsageResponse usage = await service.fetchUsage(
        'access-token',
        caredUserId: 'user-a',
      );

      expect(client.usageQueries, hasLength(2));
      expect(client.usageQueries.first['cared_user_id'], 'user-a');
      expect(client.usageQueries.last.containsKey('cared_user_id'), isFalse);
      expect(usage.plan.code, 'basic_149k');
      service.close();
    },
  );
}

HttpResponse<dynamic> _response(Map<String, Object?> data, int statusCode) {
  final Response<dynamic> response = Response<dynamic>(
    requestOptions: RequestOptions(path: '/'),
    data: data,
    statusCode: statusCode,
  );
  return HttpResponse<dynamic>(data, response);
}

class _FakeBillingApiClient implements AiseeBillingApiClient {
  _FakeBillingApiClient({
    List<HttpResponse<dynamic>>? billingOverviewResponses,
    List<HttpResponse<dynamic>>? usageResponses,
  }) : billingOverviewResponses =
           billingOverviewResponses ?? <HttpResponse<dynamic>>[],
       usageResponses = usageResponses ?? <HttpResponse<dynamic>>[];

  final List<HttpResponse<dynamic>> billingOverviewResponses;
  final List<HttpResponse<dynamic>> usageResponses;

  final List<Map<String, dynamic>> billingOverviewQueries =
      <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> usageQueries = <Map<String, dynamic>>[];
  String? lastAuthorization;
  Map<String, dynamic>? lastBillingOverviewQuery;
  Map<String, dynamic>? lastUsageQuery;
  int _billingOverviewIndex = 0;
  int _usageIndex = 0;

  @override
  Future<HttpResponse<dynamic>> fetchBillingOverview(
    String authorization,
    Map<String, dynamic> query,
  ) async {
    lastAuthorization = authorization;
    lastBillingOverviewQuery = Map<String, dynamic>.from(query);
    billingOverviewQueries.add(lastBillingOverviewQuery!);
    return billingOverviewResponses[_billingOverviewIndex++];
  }

  @override
  Future<HttpResponse<dynamic>> fetchUsage(
    String authorization,
    Map<String, dynamic> query,
  ) async {
    lastAuthorization = authorization;
    lastUsageQuery = Map<String, dynamic>.from(query);
    usageQueries.add(lastUsageQuery!);
    return usageResponses[_usageIndex++];
  }
}
