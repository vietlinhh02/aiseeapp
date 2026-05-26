import 'package:aiseeapp/api/health_api.dart';
import 'package:aiseeapp/services/aisee_health_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retrofit/dio.dart';

void main() {
  test('fetchMedications flattens medication payload', () async {
    final _FakeHealthApiClient client = _FakeHealthApiClient(
      getJsonResponses: <HttpResponse<dynamic>>[
        _response(<String, Object?>{
          'medications': <Object?>[
            <String, Object?>{
              'medication': <String, Object?>{'id': 'm1', 'name': 'Med A'},
              'taken': true,
              'skipped': false,
            },
          ],
        }, 200),
      ],
      postJsonResponses: <HttpResponse<dynamic>>[],
    );
    final AiseeHealthService service = AiseeHealthService(apiClient: client);

    final List<Map<String, dynamic>> meds = await service.fetchMedications(
      'tk',
    );

    expect(meds.single['id'], 'm1');
    expect(meds.single['taken'], isTrue);
    expect(meds.single['skipped'], isFalse);
    service.close();
  });

  test('sendEmergencyAlert returns empty map for non-map payload', () async {
    final _FakeHealthApiClient client = _FakeHealthApiClient(
      getJsonResponses: <HttpResponse<dynamic>>[],
      postJsonResponses: <HttpResponse<dynamic>>[_responseString('ok', 200)],
    );
    final AiseeHealthService service = AiseeHealthService(apiClient: client);

    final Map<String, dynamic> result = await service.sendEmergencyAlert(
      'tk',
      <String, dynamic>{'kind': 'sos'},
    );

    expect(result, isEmpty);
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

HttpResponse<dynamic> _responseString(String data, int statusCode) {
  final RequestOptions requestOptions = RequestOptions(path: '/');
  final Response<dynamic> response = Response<dynamic>(
    requestOptions: requestOptions,
    data: data,
    statusCode: statusCode,
  );
  return HttpResponse<dynamic>(data, response);
}

class _FakeHealthApiClient extends AiseeHealthApiClient {
  _FakeHealthApiClient({
    required this.getJsonResponses,
    required this.postJsonResponses,
  }) : super(Dio());

  final List<HttpResponse<dynamic>> getJsonResponses;
  final List<HttpResponse<dynamic>> postJsonResponses;
  int _getIndex = 0;
  int _postIndex = 0;

  @override
  Future<HttpResponse<dynamic>> getJson(
    String authorization,
    String path,
  ) async {
    return getJsonResponses[_getIndex++];
  }

  @override
  Future<HttpResponse<dynamic>> postJson(
    String authorization,
    String path,
    Map<String, dynamic> body,
  ) async {
    return postJsonResponses[_postIndex++];
  }
}
