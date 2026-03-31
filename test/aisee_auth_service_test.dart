import 'dart:convert';

import 'package:aiseeapp/models/aisee_api_models.dart';
import 'package:aiseeapp/services/aisee_auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  test(
    'resumeSession returns rotated tokens after access token 401 and refresh success',
    () async {
      final _FakeHttpClient client = _FakeHttpClient(<http.Response>[
        http.Response('{"message":"unauthorized"}', 401),
        http.Response(
          jsonEncode(<String, String>{
            'access_token': 'new-access',
            'refresh_token': 'new-refresh',
          }),
          200,
        ),
        http.Response(
          jsonEncode(<String, Object?>{
            'id': 'u1',
            'email': 'a@b.com',
            'display_name': 'Test User',
            'role': 'family',
            'created_at': '2026-03-31T00:00:00Z',
          }),
          200,
        ),
      ]);
      final AiseeAuthService service = AiseeAuthService(httpClient: client);

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
    final _FakeHttpClient client = _FakeHttpClient(<http.Response>[
      http.Response('{"message":"unauthorized"}', 401),
      http.Response('{"message":"refresh expired"}', 401),
    ]);
    final AiseeAuthService service = AiseeAuthService(httpClient: client);

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

class _FakeHttpClient extends http.BaseClient {
  _FakeHttpClient(this._responses);

  final List<http.Response> _responses;
  int _index = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final http.Response response = _responses[_index++];
    return http.StreamedResponse(
      Stream<List<int>>.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
    );
  }
}
