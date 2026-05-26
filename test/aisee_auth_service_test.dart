import 'package:aiseeapp/api/auth_api.dart';
import 'package:aiseeapp/models/aisee_api_models.dart';
import 'package:aiseeapp/services/aisee_auth_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retrofit/dio.dart';

void main() {
  test(
    'resumeSession returns rotated tokens after access token 401 and refresh success',
    () async {
      final _FakeAuthApiClient client = _FakeAuthApiClient(
        meResponses: <HttpResponse<dynamic>>[
          _response(<String, dynamic>{'message': 'unauthorized'}, 401),
          _response(<String, dynamic>{
            'id': 'u1',
            'email': 'a@b.com',
            'display_name': 'Test User',
            'role': 'family',
            'created_at': '2026-03-31T00:00:00Z',
          }, 200),
        ],
        refreshResponses: <HttpResponse<dynamic>>[
          _response(<String, dynamic>{
            'access_token': 'new-access',
            'refresh_token': 'new-refresh',
          }, 200),
        ],
      );
      final AiseeAuthService service = AiseeAuthService(apiClient: client);

      final ({AiseeUserProfile profile, AiseeAuthTokens tokens})? result =
          await service.resumeSession(
            const AiseeAuthTokens(
              accessToken: 'old-access',
              refreshToken: 'old-refresh',
            ),
          );

      expect(result, isNotNull);
      expect(result!.tokens.accessToken, 'new-access');
      expect(result.tokens.refreshToken, 'new-refresh');
      expect(result.profile.id, 'u1');
    },
  );

  test('resumeSession returns null when refresh fails', () async {
    final _FakeAuthApiClient client = _FakeAuthApiClient(
      meResponses: <HttpResponse<dynamic>>[
        _response(<String, dynamic>{'message': 'unauthorized'}, 401),
      ],
      refreshResponses: <HttpResponse<dynamic>>[
        _response(<String, dynamic>{'message': 'refresh expired'}, 401),
      ],
    );
    final AiseeAuthService service = AiseeAuthService(apiClient: client);

    final ({AiseeUserProfile profile, AiseeAuthTokens tokens})? result =
        await service.resumeSession(
          const AiseeAuthTokens(
            accessToken: 'old-access',
            refreshToken: 'bad-refresh',
          ),
        );

    expect(result, isNull);
  });
}

HttpResponse<dynamic> _response(Map<String, dynamic> data, int statusCode) {
  final RequestOptions requestOptions = RequestOptions(path: '/');
  final Response<dynamic> response = Response<dynamic>(
    requestOptions: requestOptions,
    data: data,
    statusCode: statusCode,
  );
  return HttpResponse<dynamic>(data, response);
}

class _FakeAuthApiClient implements AiseeAuthApiClient {
  _FakeAuthApiClient({
    required this.meResponses,
    required this.refreshResponses,
  });

  final List<HttpResponse<dynamic>> meResponses;
  final List<HttpResponse<dynamic>> refreshResponses;
  int _meIndex = 0;
  int _refreshIndex = 0;

  @override
  Future<HttpResponse<dynamic>> fetchCurrentUser(String authorization) async {
    return meResponses[_meIndex++];
  }

  @override
  Future<HttpResponse<dynamic>> refreshTokens(Map<String, dynamic> body) async {
    return refreshResponses[_refreshIndex++];
  }

  @override
  Future<HttpResponse<dynamic>> signInWithGoogle(Map<String, dynamic> body) {
    throw UnimplementedError();
  }
}
