import 'dart:convert';

bool isJwtExpiringSoon(
  String token, {
  DateTime? now,
  Duration skew = const Duration(seconds: 60),
}) {
  final List<String> parts = token.split('.');
  if (parts.length != 3) {
    return false;
  }
  try {
    final String normalized = base64Url.normalize(parts[1]);
    final Object? decoded = jsonDecode(
      utf8.decode(base64Url.decode(normalized)),
    );
    if (decoded is! Map<String, dynamic>) {
      return false;
    }
    final Object? expValue = decoded['exp'];
    final int? expSeconds = switch (expValue) {
      int value => value,
      num value => value.toInt(),
      _ => null,
    };
    if (expSeconds == null) {
      return false;
    }
    final DateTime expiry = DateTime.fromMillisecondsSinceEpoch(
      expSeconds * 1000,
      isUtc: true,
    );
    final DateTime threshold = (now ?? DateTime.now().toUtc()).add(skew);
    return !expiry.isAfter(threshold);
  } catch (_) {
    return false;
  }
}
