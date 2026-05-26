import 'package:aiseeapp/api/dashboard_api.dart';
import 'package:aiseeapp/models/aisee_dashboard_models.dart';
import 'package:aiseeapp/services/aisee_dashboard_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retrofit/dio.dart';

void main() {
  test('getHealth parses health payload', () async {
    final _FakeDashboardApiClient client = _FakeDashboardApiClient(
      healthResponse: _response(<String, Object?>{
        'medications': <Object?>[
          <String, Object?>{
            'medication': <String, Object?>{
              'id': 'm1',
              'name': 'Med',
              'dosage': '1 pill',
              'times': <Object?>['08:00'],
              'frequency': 'daily',
            },
            'taken_today': true,
          },
        ],
        'recent_symptoms': <Object?>[],
        'recent_metrics': <Object?>[],
      }, 200),
    );
    final AiseeDashboardService service = AiseeDashboardService(
      apiClient: client,
    );

    final DashboardHealth health = await service.getHealth('token', 'user-1');

    expect(client.lastHealthUserId, 'user-1');
    expect(health.medications.single.medication.id, 'm1');
    expect(health.medications.single.takenToday, isTrue);
    service.close();
  });

  test('getAuditLog passes page query and parses logs', () async {
    final _FakeDashboardApiClient client = _FakeDashboardApiClient(
      auditLogResponse: _response(<String, Object?>{
        'logs': <Object?>[
          <String, Object?>{
            'id': '1',
            'tool_name': 'send_chat_message',
            'params': <String, Object?>{'message': 'hello'},
            'created_at': '2026-05-24T00:00:00Z',
          },
        ],
      }, 200),
    );
    final AiseeDashboardService service = AiseeDashboardService(
      apiClient: client,
    );

    final List<AuditLogEntry> logs = await service.getAuditLog(
      'token',
      'user-1',
      page: 2,
      limit: 10,
    );

    expect(client.lastAuditQuery?['page'], 2);
    expect(client.lastAuditQuery?['limit'], 10);
    expect(logs.single.toolName, 'send_chat_message');
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

class _FakeDashboardApiClient extends AiseeDashboardApiClient {
  _FakeDashboardApiClient({this.healthResponse, this.auditLogResponse})
    : super(Dio());

  final HttpResponse<dynamic>? healthResponse;
  final HttpResponse<dynamic>? auditLogResponse;
  String? lastHealthUserId;
  Map<String, dynamic>? lastAuditQuery;

  @override
  Future<HttpResponse<dynamic>> getHealth(
    String authorization,
    String userId,
  ) async {
    lastHealthUserId = userId;
    return healthResponse!;
  }

  @override
  Future<HttpResponse<dynamic>> getAuditLog(
    String authorization,
    String userId,
    Map<String, dynamic> query,
  ) async {
    lastAuditQuery = query;
    return auditLogResponse!;
  }

  @override
  Future<HttpResponse<dynamic>> createMedication(
    String authorization,
    String userId,
    Map<String, dynamic> body,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<HttpResponse<dynamic>> deleteMedication(
    String authorization,
    String userId,
    String medId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<HttpResponse<dynamic>> getLocation(
    String authorization,
    String userId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<HttpResponse<dynamic>> getMedications(
    String authorization,
    String userId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<HttpResponse<dynamic>> updateMedication(
    String authorization,
    String userId,
    String medId,
    Map<String, dynamic> body,
  ) {
    throw UnimplementedError();
  }
}
