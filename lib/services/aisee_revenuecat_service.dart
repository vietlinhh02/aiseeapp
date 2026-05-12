import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import '../config/app_env.dart';
import '../models/aisee_api_models.dart';

enum AiseeRevenueCatProduct { basic149k, plus399k, premium599k }

class AiseeRevenueCatPackageOption {
  const AiseeRevenueCatPackageOption({
    required this.product,
    required this.package,
  });

  final AiseeRevenueCatProduct product;
  final Package package;

  String get packageIdentifier => package.identifier;
  String get storeProductIdentifier => package.storeProduct.identifier;
  String get storeTitle => package.storeProduct.title;
  String get storeDescription => package.storeProduct.description;
  String get priceString => package.storeProduct.priceString;
  String get currencyCode => package.storeProduct.currencyCode;
}

class AiseeRevenueCatException implements Exception {
  AiseeRevenueCatException(this.message, {this.cancelled = false});

  final String message;
  final bool cancelled;

  @override
  String toString() => message;
}

abstract class AiseeRevenueCatClient {
  Future<bool> get isConfigured;

  Future<void> configure({required String apiKey, String? appUserId});

  Future<CustomerInfo> logIn(String appUserId);

  Future<CustomerInfo> logOut();

  Future<void> setAttributes(Map<String, String> attributes);

  Future<void> setEmail(String email);

  Future<void> setDisplayName(String displayName);

  Future<CustomerInfo> getCustomerInfo();

  Future<Offerings> getOfferings();

  Future<Offerings> syncAttributesAndOfferingsIfNeeded();

  Future<PurchaseResult> purchasePackage(Package package);

  Future<CustomerInfo> restorePurchases();

  Future<void> syncPurchases();

  Future<PaywallResult> presentPaywallIfNeeded(
    String requiredEntitlementIdentifier, {
    Offering? offering,
  });

  Future<void> presentCustomerCenter();
}

class RevenueCatSdkClient implements AiseeRevenueCatClient {
  const RevenueCatSdkClient();

  @override
  Future<bool> get isConfigured => Purchases.isConfigured;

  @override
  Future<void> configure({required String apiKey, String? appUserId}) {
    final PurchasesConfiguration configuration = PurchasesConfiguration(apiKey)
      ..appUserID = appUserId
      ..storeKitVersion = StoreKitVersion.defaultVersion;
    return Purchases.configure(configuration);
  }

  @override
  Future<CustomerInfo> logIn(String appUserId) async {
    final LogInResult result = await Purchases.logIn(appUserId);
    return result.customerInfo;
  }

  @override
  Future<CustomerInfo> logOut() => Purchases.logOut();

  @override
  Future<void> setAttributes(Map<String, String> attributes) {
    return Purchases.setAttributes(attributes);
  }

  @override
  Future<void> setEmail(String email) => Purchases.setEmail(email);

  @override
  Future<void> setDisplayName(String displayName) {
    return Purchases.setDisplayName(displayName);
  }

  @override
  Future<CustomerInfo> getCustomerInfo() => Purchases.getCustomerInfo();

  @override
  Future<Offerings> getOfferings() => Purchases.getOfferings();

  @override
  Future<Offerings> syncAttributesAndOfferingsIfNeeded() {
    return Purchases.syncAttributesAndOfferingsIfNeeded();
  }

  @override
  Future<PurchaseResult> purchasePackage(Package package) {
    return Purchases.purchase(PurchaseParams.package(package));
  }

  @override
  Future<CustomerInfo> restorePurchases() => Purchases.restorePurchases();

  @override
  Future<void> syncPurchases() => Purchases.syncPurchases();

  @override
  Future<PaywallResult> presentPaywallIfNeeded(
    String requiredEntitlementIdentifier, {
    Offering? offering,
  }) {
    return RevenueCatUI.presentPaywallIfNeeded(
      requiredEntitlementIdentifier,
      offering: offering,
      displayCloseButton: true,
    );
  }

  @override
  Future<void> presentCustomerCenter() => RevenueCatUI.presentCustomerCenter();
}

class AiseeRevenueCatService {
  AiseeRevenueCatService({AiseeRevenueCatClient? client, String? apiKey})
    : _client = client ?? const RevenueCatSdkClient(),
      _apiKeyOverride = apiKey;

  static final AiseeRevenueCatService instance = AiseeRevenueCatService();

  static const String proEntitlementId = 'AiSee Pro';

  final AiseeRevenueCatClient _client;
  final String? _apiKeyOverride;
  String? _identifiedUserId;

  String get apiKey => (_apiKeyOverride ?? AppEnv.revenueCatApiKey).trim();

  Future<void> identify(AiseeUserProfile profile, {String? careGroupId}) async {
    final String userId = profile.id.trim();
    if (userId.isEmpty) {
      throw AiseeRevenueCatException('Không xác định được tài khoản AiSee.');
    }
    final String configuredApiKey = apiKey;
    if (configuredApiKey.isEmpty) {
      throw AiseeRevenueCatException(
        'Thiếu REVENUECAT_API_KEY. Chạy app với '
        '--dart-define=REVENUECAT_API_KEY=... hoặc cấu hình app_config.env.',
      );
    }
    if (configuredApiKey.startsWith('sk_')) {
      throw AiseeRevenueCatException(
        'REVENUECAT_API_KEY đang là Secret API key. App mobile phải dùng '
        'public SDK key của RevenueCat, ví dụ test_..., goog_... hoặc appl_...',
      );
    }
    if (defaultTargetPlatform == TargetPlatform.android &&
        configuredApiKey.startsWith('appl_')) {
      throw AiseeRevenueCatException(
        'Trên Android cần public SDK key Google Play (goog_...) từ RevenueCat. '
        'Key hiện tại có tiền tố appl_ (App Store). Điền goog_... vào '
        'REVENUECAT_API_KEY_ANDROID hoặc REVENUECAT_API_KEY trong app_config.env.',
      );
    }
    if (defaultTargetPlatform == TargetPlatform.iOS &&
        configuredApiKey.startsWith('goog_')) {
      throw AiseeRevenueCatException(
        'Trên iOS cần public SDK key App Store (appl_...) từ RevenueCat. '
        'Key hiện tại có tiền tố goog_ (Google Play). Điền appl_... vào '
        'REVENUECAT_API_KEY_IOS hoặc REVENUECAT_API_KEY trong app_config.env.',
      );
    }

    await _runRevenueCatCall(() async {
      if (await _client.isConfigured) {
        if (_identifiedUserId != userId) {
          await _client.logIn(userId);
        }
      } else {
        await _client.configure(apiKey: configuredApiKey, appUserId: userId);
      }
      _identifiedUserId = userId;

      final String email = profile.email.trim();
      if (email.isNotEmpty) {
        await _client.setEmail(email);
      }
      final String displayName = profile.displayName?.trim() ?? '';
      if (displayName.isNotEmpty) {
        await _client.setDisplayName(displayName);
      }
      await _client.setAttributes(<String, String>{
        'aisee_user_id': userId,
        if (careGroupId != null && careGroupId.trim().isNotEmpty)
          'care_group_id': careGroupId.trim(),
      });
    });
  }

  Future<void> logOut() async {
    if (!await _client.isConfigured) {
      _identifiedUserId = null;
      return;
    }
    await _runRevenueCatCall(() => _client.logOut());
    _identifiedUserId = null;
  }

  Future<CustomerInfo> customerInfo() {
    return _runRevenueCatCall(_client.getCustomerInfo);
  }

  Future<Offerings> offerings({bool syncAttributes = false}) {
    return _runRevenueCatCall(
      syncAttributes
          ? _client.syncAttributesAndOfferingsIfNeeded
          : _client.getOfferings,
    );
  }

  Future<CustomerInfo> restorePurchases() {
    return _runRevenueCatCall(_client.restorePurchases);
  }

  Future<CustomerInfo> refreshPurchasesForCurrentPlatform({
    TargetPlatform? platform,
  }) async {
    final TargetPlatform resolvedPlatform = platform ?? defaultTargetPlatform;
    if (resolvedPlatform == TargetPlatform.android) {
      return customerInfo();
    }
    return restorePurchases();
  }

  Future<CustomerInfo> purchase(AiseeRevenueCatProduct product) async {
    final Offering offering = await _currentOffering();
    final Package package = _packageForProduct(offering, product);
    return _purchasePackage(package);
  }

  Future<CustomerInfo> purchaseOption(AiseeRevenueCatPackageOption option) {
    return _purchasePackage(option.package);
  }

  Future<List<AiseeRevenueCatPackageOption>> availablePackageOptions() async {
    final Offering offering = await _currentOffering();
    final List<AiseeRevenueCatPackageOption> options =
        <AiseeRevenueCatPackageOption>[];
    for (final Package package in offering.availablePackages) {
      final AiseeRevenueCatProduct? product = productForPackage(
        identifier: package.identifier,
        packageType: package.packageType,
      );
      if (product == null) {
        continue;
      }
      options.add(
        AiseeRevenueCatPackageOption(product: product, package: package),
      );
    }
    options.sort((a, b) => a.product.index.compareTo(b.product.index));
    if (options.isEmpty) {
      throw AiseeRevenueCatException(
        'RevenueCat offering chưa có 3 gói AiSee.',
      );
    }
    return options;
  }

  Future<PaywallResult> presentProPaywall() async {
    final Offering? offering = (await offerings(syncAttributes: true)).current;
    return _runRevenueCatCall(
      () =>
          _client.presentPaywallIfNeeded(proEntitlementId, offering: offering),
    );
  }

  Future<void> presentCustomerCenter() {
    return _runRevenueCatCall(_client.presentCustomerCenter);
  }

  static bool hasAiSeePro(CustomerInfo customerInfo) {
    return customerInfo.entitlements.active.containsKey(proEntitlementId);
  }

  static AiseeRevenueCatProduct? productForPackage({
    required String identifier,
    required PackageType packageType,
  }) {
    final String normalized = identifier.trim().toLowerCase();
    if (normalized == 'aisee_basic_149k_monthly' ||
        normalized == 'basic_149k_monthly' ||
        normalized == 'basic_149k' ||
        normalized == 'care_basic') {
      return AiseeRevenueCatProduct.basic149k;
    }
    if (normalized == 'aisee_plus_399k_monthly' ||
        normalized == 'plus_399k_monthly' ||
        normalized == 'plus_399k' ||
        normalized == 'care_plus') {
      return AiseeRevenueCatProduct.plus399k;
    }
    if (normalized == 'aisee_premium_599k_monthly' ||
        normalized == 'premium_599k_monthly' ||
        normalized == 'premium_599k' ||
        normalized == 'care_premium') {
      return AiseeRevenueCatProduct.premium599k;
    }
    return null;
  }

  Future<Offering> _currentOffering() async {
    final Offering? current = (await offerings(syncAttributes: true)).current;
    if (current == null) {
      throw AiseeRevenueCatException(
        'RevenueCat chưa có offering hiện hành cho AiSee.',
      );
    }
    return current;
  }

  Package _packageForProduct(
    Offering offering,
    AiseeRevenueCatProduct product,
  ) {
    for (final Package package in offering.availablePackages) {
      final AiseeRevenueCatProduct? candidate = productForPackage(
        identifier: package.identifier,
        packageType: package.packageType,
      );
      if (candidate == product) {
        return package;
      }
    }
    throw AiseeRevenueCatException(
      'RevenueCat offering thiếu gói ${product.name}.',
    );
  }

  Future<CustomerInfo> _purchasePackage(Package package) async {
    final PurchaseResult result = await _runRevenueCatCall(
      () => _client.purchasePackage(package),
    );
    return result.customerInfo;
  }

  Future<T> _runRevenueCatCall<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on PlatformException catch (e, stack) {
      final PurchasesErrorCode code = _revenueCatErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        throw AiseeRevenueCatException(
          'Bạn đã hủy thanh toán.',
          cancelled: true,
        );
      }
      if (code == PurchasesErrorCode.invalidCredentialsError) {
        debugPrint('[AiSee:RevenueCat] $code ${e.message}\n$stack');
        throw AiseeRevenueCatException(
          'RevenueCat báo API key không hợp lệ. Trong Dashboard → Project '
          'settings → API keys: Android dùng key goog_..., iOS dùng appl_.... '
          'Có thể đặt REVENUECAT_API_KEY_ANDROID / REVENUECAT_API_KEY_IOS (hoặc '
          '--dart-define tương ứng) trong assets/app_config.env.',
        );
      }
      debugPrint('[AiSee:RevenueCat] $code ${e.message}\n$stack');
      throw AiseeRevenueCatException(
        e.message ?? 'Không xử lý được thanh toán qua cửa hàng ứng dụng.',
      );
    } catch (e, stack) {
      if (e is AiseeRevenueCatException) {
        rethrow;
      }
      debugPrint('[AiSee:RevenueCat] $e\n$stack');
      throw AiseeRevenueCatException(
        'Không xử lý được thanh toán qua cửa hàng ứng dụng.',
      );
    }
  }

  PurchasesErrorCode _revenueCatErrorCode(PlatformException e) {
    try {
      return PurchasesErrorHelper.getErrorCode(e);
    } on FormatException {
      return PurchasesErrorCode.unknownError;
    }
  }
}
