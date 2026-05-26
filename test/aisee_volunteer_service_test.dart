import 'package:aiseeapp/api/volunteer_api.dart';
import 'package:aiseeapp/models/aisee_volunteer_status.dart';
import 'package:aiseeapp/services/aisee_volunteer_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retrofit/dio.dart';

void main() {
  test('fetchStatus parses registration and availability', () async {
    final _FakeVolunteerApiClient client = _FakeVolunteerApiClient(
      statusResponse: _response(<String, Object?>{
        'is_registered': true,
        'volunteer': <String, Object?>{'available': true},
      }, 200),
    );
    final AiseeVolunteerService service = AiseeVolunteerService(
      apiClient: client,
    );

    final AiseeVolunteerStatus status = await service.fetchStatus('token');

    expect(status.isRegistered, isTrue);
    expect(status.available, isTrue);
    service.close();
  });

  test('register treats 409 as success', () async {
    final _FakeVolunteerApiClient client = _FakeVolunteerApiClient(
      registerResponse: _response(<String, Object?>{
        'error': <String, Object?>{'message': 'exists'},
      }, 409),
    );
    final AiseeVolunteerService service = AiseeVolunteerService(
      apiClient: client,
    );

    await service.register('token', languages: <String>['vi']);

    expect(client.lastRegisterBody?['languages'], <String>['vi']);
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

class _FakeVolunteerApiClient extends AiseeVolunteerApiClient {
  _FakeVolunteerApiClient({this.statusResponse, this.registerResponse})
    : super(Dio());

  final HttpResponse<dynamic>? statusResponse;
  final HttpResponse<dynamic>? registerResponse;
  Map<String, dynamic>? lastRegisterBody;

  @override
  Future<HttpResponse<dynamic>> fetchStatus(String authorization) async {
    return statusResponse!;
  }

  @override
  Future<HttpResponse<dynamic>> register(
    String authorization,
    Map<String, dynamic> body,
  ) async {
    lastRegisterBody = body;
    return registerResponse!;
  }

  @override
  Future<HttpResponse<dynamic>> setAvailability(
    String authorization,
    Map<String, dynamic> body,
  ) {
    throw UnimplementedError();
  }
}
