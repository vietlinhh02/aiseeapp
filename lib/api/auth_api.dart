import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'auth_api.g.dart';

@RestApi()
abstract class AiseeAuthApiClient {
  factory AiseeAuthApiClient(Dio dio, {String? baseUrl}) = _AiseeAuthApiClient;

  @POST('/api/v1/auth/google')
  Future<HttpResponse<dynamic>> signInWithGoogle(
    @Body() Map<String, dynamic> body,
  );

  @POST('/api/v1/auth/refresh')
  Future<HttpResponse<dynamic>> refreshTokens(
    @Body() Map<String, dynamic> body,
  );

  @GET('/api/v1/users/me')
  Future<HttpResponse<dynamic>> fetchCurrentUser(
    @Header('Authorization') String authorization,
  );
}
