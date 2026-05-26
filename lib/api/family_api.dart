import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'family_api.g.dart';

@RestApi()
abstract class AiseeFamilyApiClient {
  factory AiseeFamilyApiClient(Dio dio, {String? baseUrl}) =
      _AiseeFamilyApiClient;

  @GET('/api/v1/users/me/family')
  Future<HttpResponse<dynamic>> fetchFamily(
    @Header('Authorization') String authorization,
  );

  @POST('/api/v1/users/family-link')
  Future<HttpResponse<dynamic>> createInvite(
    @Header('Authorization') String authorization,
    @Body() Map<String, dynamic> body,
  );

  @GET('/api/v1/users/me/group')
  Future<HttpResponse<dynamic>> fetchCurrentGroup(
    @Header('Authorization') String authorization,
  );

  @POST('/api/v1/users/join-family')
  Future<HttpResponse<dynamic>> joinFamily(
    @Header('Authorization') String authorization,
    @Body() Map<String, dynamic> body,
  );

  @DELETE('/api/v1/users/family-invite/{inviteCode}')
  Future<HttpResponse<dynamic>> revokeInvite(
    @Header('Authorization') String authorization,
    @Path('inviteCode') String inviteCode,
  );

  @POST('/api/v1/users/leave-group')
  Future<HttpResponse<dynamic>> leaveGroup(
    @Header('Authorization') String authorization,
    @Body() Map<String, dynamic> body,
  );

  @POST('/api/v1/users/transfer-group-ownership')
  Future<HttpResponse<dynamic>> transferGroupOwnership(
    @Header('Authorization') String authorization,
    @Body() Map<String, dynamic> body,
  );

  @DELETE('/api/v1/users/family-link/{linkId}')
  Future<HttpResponse<dynamic>> deleteLink(
    @Header('Authorization') String authorization,
    @Path('linkId') String linkId,
  );

  @PUT('/api/v1/users/me')
  Future<HttpResponse<dynamic>> updateProfile(
    @Header('Authorization') String authorization,
    @Body() Map<String, dynamic> body,
  );
}
