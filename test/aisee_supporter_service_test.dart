import 'package:aiseeapp/api/supporter_api.dart';
import 'package:aiseeapp/models/aisee_supporter_models.dart';
import 'package:aiseeapp/services/aisee_supporter_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retrofit/dio.dart';

void main() {
  test('overview parses community supporter avatars', () async {
    final _FakeSupporterApiClient client = _FakeSupporterApiClient(
      overviewResponse: _response(<String, Object?>{
        'personal': <String, Object?>{
          'supported_people_count': 1,
          'total_ai_turns_gifted': 300,
          'ads_watched_today': 0,
          'coin_balance': 700,
          'total_earned': 1000,
          'total_redeemed': 300,
        },
        'community': <String, Object?>{
          'total_cared_users': 2,
          'total_ai_turns_gifted': 300,
          'active_supporters': 2,
          'supporters': <Object?>[
            <String, Object?>{
              'anon_seed': 'abc123def456',
            },
          ],
          'activities': <Object?>[
            <String, Object?>{
              'anon_seed': 'abc123def456',
              'type': 'redeem',
              'amount': 300,
              'occurred_at': '2026-05-27T00:00:00Z',
            },
          ],
        },
      }, 200),
    );
    final AiseeSupporterService service = AiseeSupporterService(
      apiClient: client,
    );

    final SupporterOverviewResponse response = await service.getOverview(
      'token',
    );

    expect(response.community.supporters, hasLength(1));
    expect(response.community.supporters.first.anonSeed, 'abc123def456');
    final List<CommunitySupporterActivity> activities =
        response.community.activities ?? const <CommunitySupporterActivity>[];
    expect(activities, hasLength(1));
    expect(activities.first.type, 'redeem');
    expect(activities.first.amount, 300);
    service.close();
  });

  test('redeem parses response body', () async {
    final _FakeSupporterApiClient client = _FakeSupporterApiClient(
      redeemResponse: _response(<String, Object?>{
        'coins_redeemed': 10,
        'new_balance': 90,
        'ai_turns_granted': 10,
      }, 200),
    );
    final AiseeSupporterService service = AiseeSupporterService(
      apiClient: client,
    );

    final RedeemResponse response = await service.redeem('token', 10, null);

    expect(client.lastRedeemBody?['amount'], 10);
    expect(response.newBalance, 90);
    service.close();
  });
}

HttpResponse<dynamic> _response(Map<String, Object?> data, int statusCode) {
  final RequestOptions requestOptions = RequestOptions(path: '/');
  final Response<dynamic> response = Response<dynamic>(
    requestOptions: requestOptions,
    data: data,
    statusCode: statusCode,
  );
  return HttpResponse<dynamic>(data, response);
}

class _FakeSupporterApiClient extends AiseeSupporterApiClient {
  _FakeSupporterApiClient({this.overviewResponse, this.redeemResponse})
    : super(Dio());

  final HttpResponse<dynamic>? overviewResponse;
  final HttpResponse<dynamic>? redeemResponse;
  Map<String, dynamic>? lastRedeemBody;

  @override
  Future<HttpResponse<dynamic>> redeem(
    String authorization,
    Map<String, dynamic> body,
  ) async {
    lastRedeemBody = body;
    return redeemResponse!;
  }

  @override
  Future<HttpResponse<dynamic>> getOverview(String authorization) async {
    return overviewResponse!;
  }

  @override
  Future<HttpResponse<dynamic>> watchAd(String authorization) {
    throw UnimplementedError();
  }
}
