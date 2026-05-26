import 'package:aiseeapp/api/care_api.dart';
import 'package:aiseeapp/models/aisee_care_models.dart';
import 'package:aiseeapp/services/aisee_care_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retrofit/dio.dart';

void main() {
  test('getTimeline parses events', () async {
    final _FakeCareApiClient client = _FakeCareApiClient(
      timelineResponse: _response(<String, Object?>{
        'requested_days': 7,
        'effective_days': 3,
        'limit': 50,
        'window_start': '2026-05-01T00:00:00Z',
        'window_end': '2026-05-08T00:00:00Z',
        'events': <Object?>[
          <String, Object?>{
            'kind': 'med',
            'title': 'Med',
            'detail': 'Taken',
            'occurred_at': '2026-05-02T10:00:00Z',
          },
        ],
      }, 200),
    );
    final AiseeCareService svc = AiseeCareService(apiClient: client);

    final CareTimelineResponse r = await svc.getTimeline('tok', 'user-1');

    expect(client.lastTimelineUserId, 'user-1');
    expect(client.lastTimelineQuery?['days'], 7);
    expect(r.effectiveDays, 3);
    expect(r.events.single.kind, 'med');
    svc.close();
  });

  test('listAlerts parses rows', () async {
    final _FakeCareApiClient client = _FakeCareApiClient(
      alertsResponse: _response(<String, Object?>{
        'alerts': <Object?>[
          <String, Object?>{
            'id': 'a1',
            'user_id': 'u1',
            'rule_code': 'sos_recent',
            'severity': 'critical',
            'title': 'SOS',
            'body': 'Test',
            'status': 'open',
            'created_at': '2026-05-01T00:00:00Z',
            'updated_at': '2026-05-01T00:00:00Z',
          },
        ],
      }, 200),
    );
    final AiseeCareService svc = AiseeCareService(apiClient: client);

    final List<CareAlert> list = await svc.listAlerts('tok', 'u1');

    expect(client.lastAlertsUserId, 'u1');
    expect(client.lastAlertsQuery?['limit'], 50);
    expect(list.single.ruleCode, 'sos_recent');
    svc.close();
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

class _FakeCareApiClient extends AiseeCareApiClient {
  _FakeCareApiClient({this.timelineResponse, this.alertsResponse})
    : super(Dio());

  final HttpResponse<dynamic>? timelineResponse;
  final HttpResponse<dynamic>? alertsResponse;
  String? lastTimelineUserId;
  Map<String, dynamic>? lastTimelineQuery;
  String? lastAlertsUserId;
  Map<String, dynamic>? lastAlertsQuery;

  @override
  Future<HttpResponse<dynamic>> getTimeline(
    String authorization,
    String caredUserId,
    Map<String, dynamic> query,
  ) async {
    lastTimelineUserId = caredUserId;
    lastTimelineQuery = query;
    return timelineResponse!;
  }

  @override
  Future<HttpResponse<dynamic>> listAlerts(
    String authorization,
    String caredUserId,
    Map<String, dynamic> query,
  ) async {
    lastAlertsUserId = caredUserId;
    lastAlertsQuery = query;
    return alertsResponse!;
  }

  @override
  Future<HttpResponse<dynamic>> ackAlert(String authorization, String alertId) {
    throw UnimplementedError();
  }

  @override
  Future<HttpResponse<dynamic>> completeTask(
    String authorization,
    String taskId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<HttpResponse<dynamic>> createTask(
    String authorization,
    String caredUserId,
    Map<String, dynamic> body,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<HttpResponse<dynamic>> dismissAlert(
    String authorization,
    String alertId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<HttpResponse<dynamic>> exportPdf(
    String authorization,
    String caredUserId,
    Map<String, dynamic> body,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<HttpResponse<dynamic>> getDailyBrief(
    String authorization,
    String caredUserId,
    Map<String, dynamic>? query,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<HttpResponse<dynamic>> getIncidentReport(
    String authorization,
    String caredUserId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<HttpResponse<dynamic>> getWeeklyReport(
    String authorization,
    String caredUserId,
    Map<String, dynamic>? query,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<HttpResponse<dynamic>> listTasks(
    String authorization,
    String caredUserId,
    Map<String, dynamic> query,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<HttpResponse<dynamic>> resolveAlert(
    String authorization,
    String alertId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<HttpResponse<dynamic>> updateTask(
    String authorization,
    String taskId,
    Map<String, dynamic> body,
  ) {
    throw UnimplementedError();
  }
}
