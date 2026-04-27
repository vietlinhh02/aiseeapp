import 'package:aiseeapp/models/aisee_api_models.dart';
import 'package:aiseeapp/services/aisee_revenuecat_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/models/customer_info_wrapper.dart';
import 'package:purchases_flutter/models/entitlement_info_wrapper.dart';
import 'package:purchases_flutter/models/entitlement_infos_wrapper.dart';
import 'package:purchases_flutter/models/package_wrapper.dart';
import 'package:purchases_flutter/models/store.dart';

void main() {
  group('AiseeRevenueCatService', () {
    test('uses the configured API key and AiSee Pro entitlement', () {
      final service = AiseeRevenueCatService(
        client: _FakeRevenueCatClient(),
        apiKey: 'test_revenuecat_key',
      );
      expect(service.apiKey, 'test_revenuecat_key');
      expect(AiseeRevenueCatService.proEntitlementId, 'AiSee Pro');
    });

    test('identifies backend user and syncs care group attributes', () async {
      final _FakeRevenueCatClient client = _FakeRevenueCatClient();
      final AiseeRevenueCatService service = AiseeRevenueCatService(
        client: client,
        apiKey: 'test_revenuecat_key',
      );

      await service.identify(
        const AiseeUserProfile(
          id: 'user-123',
          email: 'family@example.com',
          displayName: 'Family Admin',
        ),
        careGroupId: 'care-group-456',
      );

      expect(client.configuredApiKey, 'test_revenuecat_key');
      expect(client.configuredAppUserId, 'user-123');
      expect(client.loginAppUserId, isNull);
      expect(client.email, 'family@example.com');
      expect(client.displayName, 'Family Admin');
      expect(client.attributes, <String, String>{
        'aisee_user_id': 'user-123',
        'care_group_id': 'care-group-456',
      });
    });

    test(
      'logs into existing RevenueCat configuration when already configured',
      () async {
        final _FakeRevenueCatClient client = _FakeRevenueCatClient(
          initiallyConfigured: true,
        );
        final AiseeRevenueCatService service = AiseeRevenueCatService(
          client: client,
          apiKey: 'test_revenuecat_key',
        );

        await service.identify(
          const AiseeUserProfile(id: 'user-789', email: 'user@example.com'),
        );

        expect(client.configuredApiKey, isNull);
        expect(client.loginAppUserId, 'user-789');
      },
    );

    test('requires RevenueCat API key before configuring SDK', () async {
      final _FakeRevenueCatClient client = _FakeRevenueCatClient();
      final AiseeRevenueCatService service = AiseeRevenueCatService(
        client: client,
        apiKey: '',
      );

      expect(
        service.identify(
          const AiseeUserProfile(id: 'user-123', email: 'user@example.com'),
        ),
        throwsA(isA<AiseeRevenueCatException>()),
      );
      expect(client.configuredApiKey, isNull);
    });

    test('rejects RevenueCat secret API keys in mobile SDK config', () async {
      final _FakeRevenueCatClient client = _FakeRevenueCatClient();
      final AiseeRevenueCatService service = AiseeRevenueCatService(
        client: client,
        apiKey: 'sk_DlsTOXwMgZSJkOnZwqbQCjmXVHeMO',
      );

      await expectLater(
        service.identify(
          const AiseeUserProfile(id: 'user-123', email: 'user@example.com'),
        ),
        throwsA(
          isA<AiseeRevenueCatException>().having(
            (e) => e.message,
            'message',
            contains('Secret API key'),
          ),
        ),
      );
      expect(client.configuredApiKey, isNull);
    });

    test('handles non-numeric RevenueCat platform error codes', () async {
      final AiseeRevenueCatService service = AiseeRevenueCatService(
        client: _FakeRevenueCatClient(
          customerInfoError: PlatformException(
            code: 'PAYWALLS_MISSING_WRONG_ACTIVITY',
            message: 'Paywalls require FlutterFragmentActivity',
          ),
        ),
        apiKey: 'test_revenuecat_key',
      );

      await expectLater(
        service.customerInfo(),
        throwsA(
          isA<AiseeRevenueCatException>().having(
            (e) => e.message,
            'message',
            'Paywalls require FlutterFragmentActivity',
          ),
        ),
      );
    });

    test('checks active AiSee Pro entitlement from customer info', () {
      expect(
        AiseeRevenueCatService.hasAiSeePro(_customerInfo(activePro: true)),
        isTrue,
      );
      expect(
        AiseeRevenueCatService.hasAiSeePro(_customerInfo(activePro: false)),
        isFalse,
      );
    });

    test('refreshes purchases without restore on Android', () async {
      final _FakeRevenueCatClient client = _FakeRevenueCatClient();
      final AiseeRevenueCatService service = AiseeRevenueCatService(
        client: client,
        apiKey: 'test_revenuecat_key',
      );

      await service.refreshPurchasesForCurrentPlatform(
        platform: TargetPlatform.android,
      );

      expect(client.customerInfoCalls, 1);
      expect(client.restoreCalls, 0);
    });

    test('uses restore purchases outside Android', () async {
      final _FakeRevenueCatClient client = _FakeRevenueCatClient();
      final AiseeRevenueCatService service = AiseeRevenueCatService(
        client: client,
        apiKey: 'test_revenuecat_key',
      );

      await service.refreshPurchasesForCurrentPlatform(
        platform: TargetPlatform.iOS,
      );

      expect(client.restoreCalls, 1);
    });

    test('maps supported RevenueCat packages to AiSee products', () {
      expect(
        AiseeRevenueCatService.productForPackage(
          identifier: 'aisee_basic_149k_monthly',
          packageType: PackageType.monthly,
        ),
        AiseeRevenueCatProduct.basic149k,
      );
      expect(
        AiseeRevenueCatService.productForPackage(
          identifier: 'aisee_plus_399k_monthly',
          packageType: PackageType.monthly,
        ),
        AiseeRevenueCatProduct.plus399k,
      );
      expect(
        AiseeRevenueCatService.productForPackage(
          identifier: 'aisee_premium_599k_monthly',
          packageType: PackageType.monthly,
        ),
        AiseeRevenueCatProduct.premium599k,
      );
      expect(
        AiseeRevenueCatService.productForPackage(
          identifier: 'unknown',
          packageType: PackageType.custom,
        ),
        isNull,
      );
    });
  });
}

CustomerInfo _customerInfo({required bool activePro}) {
  final EntitlementInfo pro = EntitlementInfo(
    AiseeRevenueCatService.proEntitlementId,
    activePro,
    true,
    '2026-04-26T00:00:00Z',
    '2026-04-26T00:00:00Z',
    'monthly',
    true,
    store: Store.playStore,
  );
  return CustomerInfo(
    EntitlementInfos(
      <String, EntitlementInfo>{AiseeRevenueCatService.proEntitlementId: pro},
      activePro
          ? <String, EntitlementInfo>{
              AiseeRevenueCatService.proEntitlementId: pro,
            }
          : <String, EntitlementInfo>{},
    ),
    <String, String?>{},
    activePro ? <String>['monthly'] : <String>[],
    activePro ? <String>['monthly'] : <String>[],
    const [],
    '2026-04-26T00:00:00Z',
    'user-123',
    <String, String?>{},
    '2026-04-26T00:00:00Z',
  );
}

class _FakeRevenueCatClient implements AiseeRevenueCatClient {
  _FakeRevenueCatClient({
    this.initiallyConfigured = false,
    this.customerInfoError,
  });

  final bool initiallyConfigured;
  final PlatformException? customerInfoError;
  String? configuredApiKey;
  String? configuredAppUserId;
  String? loginAppUserId;
  String? email;
  String? displayName;
  int customerInfoCalls = 0;
  int restoreCalls = 0;
  Map<String, String> attributes = <String, String>{};

  @override
  Future<bool> get isConfigured async => initiallyConfigured;

  @override
  Future<void> configure({required String apiKey, String? appUserId}) async {
    configuredApiKey = apiKey;
    configuredAppUserId = appUserId;
  }

  @override
  Future<CustomerInfo> logIn(String appUserId) async {
    loginAppUserId = appUserId;
    return _customerInfo(activePro: false);
  }

  @override
  Future<CustomerInfo> getCustomerInfo() async {
    customerInfoCalls++;
    final PlatformException? error = customerInfoError;
    if (error != null) {
      throw error;
    }
    return _customerInfo(activePro: false);
  }

  @override
  Future<CustomerInfo> restorePurchases() async {
    restoreCalls++;
    return _customerInfo(activePro: false);
  }

  @override
  Future<void> syncPurchases() async {}

  @override
  Future<void> setAttributes(Map<String, String> nextAttributes) async {
    attributes = nextAttributes;
  }

  @override
  Future<void> setDisplayName(String nextDisplayName) async {
    displayName = nextDisplayName;
  }

  @override
  Future<void> setEmail(String nextEmail) async {
    email = nextEmail;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
