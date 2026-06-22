import 'package:aiseeapp/config/app_env.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('appDownloadUri uses the public APK download page', () {
    expect(AppEnv.appDownloadUri().toString(), 'https://aaisee.me/tai-apk');
  });

  test('appDownloadUri preserves supporter ref as an encoded query param', () {
    final Uri uri = AppEnv.appDownloadUri(ref: ' supporter 01 ');

    expect(uri.toString(), 'https://aaisee.me/tai-apk?ref=supporter+01');
  });
}
