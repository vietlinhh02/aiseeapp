import 'package:aiseeapp/screens/subscription_screen.dart';
import 'package:aiseeapp/services/aisee_billing_service.dart';
import 'package:aiseeapp/services/aisee_family_service.dart';
import 'package:aiseeapp/services/aisee_revenuecat_service.dart';
import 'package:aiseeapp/models/aisee_billing_models.dart';
import 'package:aiseeapp/models/aisee_family_group.dart';
import 'package:aiseeapp/models/aisee_api_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aiseeapp/generated/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('planNameForProduct matches the backend care catalog labels', () {
    expect(planNameForProduct(AiseeRevenueCatProduct.basic149k), 'Care Basic');
    expect(planNameForProduct(AiseeRevenueCatProduct.plus399k), 'Care Plus');
    expect(
      planNameForProduct(AiseeRevenueCatProduct.premium599k),
      'Care Premium',
    );
  });

  test('free plan does not expose purchase CTA without billing permission', () {
    final overview = AiseeBillingOverview(
      careGroup: const AiseeCareGroupSummary(
        id: 'group-1',
        name: 'Gia dinh',
        currentUserRole: 'family',
        canManageBilling: false,
        caredUserCount: 1,
        memberCount: 2,
      ),
      effectivePlan: const AiseeBillingPlan(
        code: 'free',
        name: 'Free / Essential',
        priceVnd: 0,
        billingPeriod: 'month',
        status: 'active',
      ),
      entitlements: const <String, AiseeEntitlementValue>{},
      usage: const AiseeUsageSummary(quotas: <String, AiseeUsageQuota>{}),
      events: const <AiseeSubscriptionEvent>[],
      storeManagement: const AiseeStoreManagementInfo(instructions: ''),
    );

    expect(
      canShowSubscriptionPurchaseCta(overview, familyFirst: true),
      isFalse,
    );
  });

  test(
    'premium plan does not expose purchase CTA when already at top tier',
    () {
      final overview = AiseeBillingOverview(
        careGroup: const AiseeCareGroupSummary(
          id: 'group-1',
          name: 'Gia dinh',
          currentUserRole: 'owner',
          canManageBilling: true,
          caredUserCount: 1,
          memberCount: 2,
        ),
        effectivePlan: const AiseeBillingPlan(
          code: 'premium_599k',
          name: 'Care Premium',
          priceVnd: 599000,
          billingPeriod: 'month',
          status: 'active',
        ),
        entitlements: const <String, AiseeEntitlementValue>{},
        usage: const AiseeUsageSummary(quotas: <String, AiseeUsageQuota>{}),
        events: const <AiseeSubscriptionEvent>[],
        storeManagement: const AiseeStoreManagementInfo(instructions: ''),
      );

      expect(hasAvailableSubscriptionUpgrade(overview), isFalse);
      expect(
        canShowSubscriptionPurchaseCta(overview, familyFirst: true),
        isFalse,
      );
    },
  );

  test('billing admin cannot purchase when not the group owner', () {
    final overview = AiseeBillingOverview(
      careGroup: const AiseeCareGroupSummary(
        id: 'group-1',
        name: 'Gia dinh',
        currentUserRole: 'billing_admin',
        canManageBilling: true,
        caredUserCount: 1,
        memberCount: 2,
      ),
      effectivePlan: const AiseeBillingPlan(
        code: 'free',
        name: 'Free / Essential',
        priceVnd: 0,
        billingPeriod: 'month',
        status: 'active',
      ),
      entitlements: const <String, AiseeEntitlementValue>{},
      usage: const AiseeUsageSummary(quotas: <String, AiseeUsageQuota>{}),
      events: const <AiseeSubscriptionEvent>[],
      storeManagement: const AiseeStoreManagementInfo(instructions: ''),
    );

    expect(
      canShowSubscriptionPurchaseCta(overview, familyFirst: true),
      isFalse,
    );
  });

  test('disabled RevenueCat hides purchase CTA even for group owner', () {
    final overview = AiseeBillingOverview(
      careGroup: const AiseeCareGroupSummary(
        id: 'group-1',
        name: 'Gia dinh',
        currentUserRole: 'owner',
        canManageBilling: true,
        caredUserCount: 1,
        memberCount: 2,
      ),
      effectivePlan: const AiseeBillingPlan(
        code: 'free',
        name: 'Free / Essential',
        priceVnd: 0,
        billingPeriod: 'month',
        status: 'active',
      ),
      entitlements: const <String, AiseeEntitlementValue>{},
      usage: const AiseeUsageSummary(quotas: <String, AiseeUsageQuota>{}),
      events: const <AiseeSubscriptionEvent>[],
      storeManagement: const AiseeStoreManagementInfo(instructions: ''),
    );

    expect(
      canShowSubscriptionPurchaseCta(
        overview,
        familyFirst: true,
        revenueCatEnabled: false,
      ),
      isFalse,
    );
    expect(
      canShowRevenueCatStoreActions(
        overview,
        familyFirst: true,
        revenueCatEnabled: false,
      ),
      isFalse,
    );
  });

  test('only higher tiers are valid upgrade targets', () {
    final basicOverview = AiseeBillingOverview(
      careGroup: const AiseeCareGroupSummary(
        id: 'group-1',
        name: 'Gia dinh',
        currentUserRole: 'owner',
        canManageBilling: true,
        caredUserCount: 1,
        memberCount: 2,
      ),
      effectivePlan: const AiseeBillingPlan(
        code: 'basic_149k',
        name: 'Care Basic',
        priceVnd: 149000,
        billingPeriod: 'month',
        status: 'active',
      ),
      entitlements: const <String, AiseeEntitlementValue>{},
      usage: const AiseeUsageSummary(quotas: <String, AiseeUsageQuota>{}),
      events: const <AiseeSubscriptionEvent>[],
      storeManagement: const AiseeStoreManagementInfo(instructions: ''),
    );
    final premiumOverview = AiseeBillingOverview(
      careGroup: basicOverview.careGroup,
      effectivePlan: const AiseeBillingPlan(
        code: 'premium_599k',
        name: 'Care Premium',
        priceVnd: 599000,
        billingPeriod: 'month',
        status: 'active',
      ),
      entitlements: basicOverview.entitlements,
      usage: basicOverview.usage,
      events: basicOverview.events,
      storeManagement: basicOverview.storeManagement,
    );

    expect(
      canUpgradeToSubscriptionProduct(
        basicOverview,
        AiseeRevenueCatProduct.basic149k,
      ),
      isFalse,
    );
    expect(
      canUpgradeToSubscriptionProduct(
        basicOverview,
        AiseeRevenueCatProduct.plus399k,
      ),
      isTrue,
    );
    expect(
      canUpgradeToSubscriptionProduct(
        premiumOverview,
        AiseeRevenueCatProduct.plus399k,
      ),
      isFalse,
    );
    expect(
      canUpgradeToSubscriptionProduct(
        premiumOverview,
        AiseeRevenueCatProduct.premium599k,
      ),
      isFalse,
    );
  });

  testWidgets(
    'subscription screen resolves current group before loading billing overview',
    (WidgetTester tester) async {
      final _FakeBillingService billingService = _FakeBillingService();
      final _FakeFamilyService familyService = _FakeFamilyService(
        currentGroup: const AiseeCurrentGroup(
          id: 'group-shared',
          name: 'Gia dinh',
          ownerUserId: 'family-owner',
          currentUserRole: 'cared_user',
          canManageGroup: false,
          canManageBilling: false,
          familyMembers: <AiseeCareGroupPerson>[
            AiseeCareGroupPerson(
              id: 'family-owner',
              email: 'owner@example.com',
              accountRole: 'family',
              groupRole: 'owner',
            ),
          ],
          caredUsers: <AiseeCareGroupPerson>[
            AiseeCareGroupPerson(
              id: 'user-1',
              email: 'user@example.com',
              accountRole: 'user',
              groupRole: 'cared_user',
            ),
          ],
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SubscriptionScreen(
            billingService: billingService,
            familyService: familyService,
            readTokens: () async => const AiseeAuthTokens(
              accessToken: 'access-token',
              refreshToken: 'refresh-token',
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(billingService.lastAccessToken, 'access-token');
      expect(billingService.lastCareGroupId, 'group-shared');
      expect(billingService.lastCaredUserId, isNull);
      expect(find.text('AiSee Plus Trial'), findsOneWidget);
      expect(find.text('Phút gọi video'), findsOneWidget);
      expect(find.text('video_calls'), findsNothing);
    },
  );
}

class _FakeBillingService extends AiseeBillingService {
  String? lastAccessToken;
  String? lastCareGroupId;
  String? lastCaredUserId;

  @override
  Future<AiseeBillingOverview> fetchBillingOverview(
    String accessToken, {
    String? careGroupId,
    String? caredUserId,
  }) async {
    lastAccessToken = accessToken;
    lastCareGroupId = careGroupId;
    lastCaredUserId = caredUserId;
    return AiseeBillingOverview(
      careGroup: AiseeCareGroupSummary(
        id: careGroupId ?? 'group-default',
        name: 'Gia dinh',
        ownerUserId: 'family-owner',
        currentUserRole: 'cared_user',
        canManageBilling: false,
        caredUserCount: 1,
        memberCount: 2,
      ),
      effectivePlan: const AiseeBillingPlan(
        code: 'plus_399k',
        name: 'AiSee Plus Trial',
        priceVnd: 399000,
        billingPeriod: 'month',
        status: 'active',
      ),
      entitlements: const <String, AiseeEntitlementValue>{},
      usage: const AiseeUsageSummary(
        quotas: <String, AiseeUsageQuota>{
          'video_calls': AiseeUsageQuota(
            usageType: 'video_calls',
            limit: 0,
            used: 0,
            granted: 0,
            remaining: 0,
            unlimited: true,
            upgradeSuggested: false,
          ),
        },
      ),
      events: const <AiseeSubscriptionEvent>[],
      storeManagement: const AiseeStoreManagementInfo(instructions: ''),
    );
  }

  @override
  void close() {}
}

class _FakeFamilyService extends AiseeFamilyService {
  _FakeFamilyService({required this.currentGroup});

  final AiseeCurrentGroup? currentGroup;

  @override
  Future<AiseeCurrentGroup?> fetchCurrentGroup(String accessToken) async {
    return currentGroup;
  }

  @override
  void close() {}
}
