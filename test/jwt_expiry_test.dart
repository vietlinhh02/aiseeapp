import 'dart:convert';

import 'package:aiseeapp/utils/jwt_expiry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('isJwtExpiringSoon returns true for expired token', () {
    expect(
      isJwtExpiringSoon(
        _jwt(exp: 10),
        now: DateTime.fromMillisecondsSinceEpoch(20 * 1000, isUtc: true),
      ),
      isTrue,
    );
  });

  test('isJwtExpiringSoon returns true inside skew window', () {
    expect(
      isJwtExpiringSoon(
        _jwt(exp: 70),
        now: DateTime.fromMillisecondsSinceEpoch(20 * 1000, isUtc: true),
        skew: const Duration(seconds: 60),
      ),
      isTrue,
    );
  });

  test('isJwtExpiringSoon returns false for valid future token', () {
    expect(
      isJwtExpiringSoon(
        _jwt(exp: 1000),
        now: DateTime.fromMillisecondsSinceEpoch(20 * 1000, isUtc: true),
      ),
      isFalse,
    );
  });

  test('isJwtExpiringSoon returns false for malformed token', () {
    expect(isJwtExpiringSoon('not-a-jwt'), isFalse);
  });
}

String _jwt({required int exp}) {
  String enc(Map<String, Object?> value) {
    return base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  }

  return '${enc(<String, Object?>{'alg': 'HS256', 'typ': 'JWT'})}.'
      '${enc(<String, Object?>{'exp': exp})}.sig';
}
