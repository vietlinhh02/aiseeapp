import 'dart:convert';

import 'package:aiseeapp/models/aisee_care_models.dart';
import 'package:aiseeapp/services/aisee_care_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  test('getTimeline parses events', () async {
    late String path;
    final http.Client client = _FakeHttpClient((http.BaseRequest request) {
      path = request.url.path;
      return http.Response(
        jsonEncode(<String, Object?>{
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
        }),
        200,
      );
    });
    final AiseeCareService svc = AiseeCareService(httpClient: client);
    final CareTimelineResponse r = await svc.getTimeline('tok', 'user-1');
    expect(path, '/api/v1/dashboard/user-1/care/timeline');
    expect(r.effectiveDays, 3);
    expect(r.events.single.kind, 'med');
    svc.close();
  });

  test('listAlerts parses rows', () async {
    late String path;
    final http.Client client = _FakeHttpClient((http.BaseRequest request) {
      path = request.url.path;
      return http.Response(
        jsonEncode(<String, Object?>{
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
        }),
        200,
      );
    });
    final AiseeCareService svc = AiseeCareService(httpClient: client);
    final List<CareAlert> list = await svc.listAlerts('tok', 'u1');
    expect(path, '/api/v1/care/users/u1/alerts');
    expect(list.single.ruleCode, 'sos_recent');
    svc.close();
  });
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
