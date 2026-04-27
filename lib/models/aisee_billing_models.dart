class AiseeCareGroupSummary {
  const AiseeCareGroupSummary({
    required this.id,
    required this.name,
    required this.currentUserRole,
    required this.canManageBilling,
    required this.caredUserCount,
    required this.memberCount,
    this.ownerUserId,
  });

  final String id;
  final String name;
  final String? ownerUserId;
  final String currentUserRole;
  final bool canManageBilling;
  final int caredUserCount;
  final int memberCount;

  factory AiseeCareGroupSummary.fromJson(Map<String, dynamic> json) {
    return AiseeCareGroupSummary(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'AiSee Care Group',
      ownerUserId: json['owner_user_id'] as String?,
      currentUserRole: json['current_user_role'] as String? ?? 'family',
      canManageBilling: json['can_manage_billing'] as bool? ?? false,
      caredUserCount: _asInt(json['cared_user_count']),
      memberCount: _asInt(json['member_count']),
    );
  }
}

class AiseeBillingPlan {
  const AiseeBillingPlan({
    required this.code,
    required this.name,
    required this.priceVnd,
    required this.billingPeriod,
    required this.status,
    this.id,
  });

  final String? id;
  final String code;
  final String name;
  final int priceVnd;
  final String billingPeriod;
  final String status;

  bool get isFree => priceVnd == 0 || code == 'free';

  factory AiseeBillingPlan.fromJson(Map<String, dynamic> json) {
    return AiseeBillingPlan(
      id: json['id'] as String?,
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      priceVnd: _asInt(json['price_vnd']),
      billingPeriod: json['billing_period'] as String? ?? 'month',
      status: json['status'] as String? ?? '',
    );
  }
}

class AiseeSubscription {
  const AiseeSubscription({
    required this.id,
    required this.planCode,
    required this.status,
    required this.cancelAtPeriodEnd,
    this.careGroupId,
    this.provider,
    this.currentPeriodEnd,
  });

  final String id;
  final String? careGroupId;
  final String planCode;
  final String status;
  final bool cancelAtPeriodEnd;
  final String? provider;
  final DateTime? currentPeriodEnd;

  factory AiseeSubscription.fromJson(Map<String, dynamic> json) {
    return AiseeSubscription(
      id: json['id'] as String? ?? '',
      careGroupId: json['care_group_id'] as String?,
      planCode: json['plan_code'] as String? ?? '',
      status: json['status'] as String? ?? '',
      cancelAtPeriodEnd: json['cancel_at_period_end'] as bool? ?? false,
      provider: json['provider'] as String?,
      currentPeriodEnd: _asDate(json['current_period_end']),
    );
  }
}

class AiseeEntitlementValue {
  const AiseeEntitlementValue({
    required this.limitValue,
    this.limitUnit,
    this.resetPeriod,
  });

  final Object? limitValue;
  final String? limitUnit;
  final String? resetPeriod;

  bool get enabled {
    final Object? value = limitValue;
    if (value is bool) return value;
    if (value is num) return value > 0;
    if (value is String) return value != 'none' && value != 'false';
    return value != null;
  }

  factory AiseeEntitlementValue.fromJson(Map<String, dynamic> json) {
    return AiseeEntitlementValue(
      limitValue: json['limit_value'],
      limitUnit: json['limit_unit'] as String?,
      resetPeriod: json['reset_period'] as String?,
    );
  }
}

class AiseeUsageQuota {
  const AiseeUsageQuota({
    required this.usageType,
    required this.limit,
    required this.used,
    required this.granted,
    required this.remaining,
    required this.unlimited,
    required this.upgradeSuggested,
    this.featureKey,
    this.unit,
    this.resetPeriod,
  });

  final String usageType;
  final String? featureKey;
  final double limit;
  final double used;
  final double granted;
  final double remaining;
  final String? unit;
  final String? resetPeriod;
  final bool unlimited;
  final bool upgradeSuggested;

  factory AiseeUsageQuota.fromJson(Map<String, dynamic> json) {
    return AiseeUsageQuota(
      usageType: json['usage_type'] as String? ?? '',
      featureKey: json['feature_key'] as String?,
      limit: _asDouble(json['limit']),
      used: _asDouble(json['used']),
      granted: _asDouble(json['granted']),
      remaining: _asDouble(json['remaining']),
      unit: json['unit'] as String?,
      resetPeriod: json['reset_period'] as String?,
      unlimited: json['unlimited'] as bool? ?? false,
      upgradeSuggested: json['upgrade_suggested'] as bool? ?? false,
    );
  }
}

class AiseeUsageSummary {
  const AiseeUsageSummary({required this.quotas});

  final Map<String, AiseeUsageQuota> quotas;

  factory AiseeUsageSummary.fromJson(Map<String, dynamic> json) {
    final Object? raw = json['quotas'];
    final Map<String, AiseeUsageQuota> quotas = <String, AiseeUsageQuota>{};
    if (raw is Map<String, dynamic>) {
      for (final MapEntry<String, dynamic> entry in raw.entries) {
        final Object? value = entry.value;
        if (value is Map<String, dynamic>) {
          quotas[entry.key] = AiseeUsageQuota.fromJson(value);
        }
      }
    }
    return AiseeUsageSummary(quotas: quotas);
  }
}

class AiseeSubscriptionEvent {
  const AiseeSubscriptionEvent({
    required this.id,
    required this.eventType,
    this.provider,
    this.createdAt,
  });

  final String id;
  final String eventType;
  final String? provider;
  final DateTime? createdAt;

  factory AiseeSubscriptionEvent.fromJson(Map<String, dynamic> json) {
    return AiseeSubscriptionEvent(
      id: json['id'] as String? ?? '',
      eventType: json['event_type'] as String? ?? '',
      provider: json['provider'] as String?,
      createdAt: _asDate(json['created_at']),
    );
  }
}

class AiseeStoreManagementInfo {
  const AiseeStoreManagementInfo({
    required this.instructions,
    this.provider,
    this.manageUrl,
  });

  final String? provider;
  final String? manageUrl;
  final String instructions;

  factory AiseeStoreManagementInfo.fromJson(Map<String, dynamic> json) {
    return AiseeStoreManagementInfo(
      provider: json['provider'] as String?,
      manageUrl: json['manage_url'] as String?,
      instructions:
          json['instructions'] as String? ??
          'Gói được quản lý theo cửa hàng ứng dụng.',
    );
  }
}

class AiseeBillingOverview {
  const AiseeBillingOverview({
    required this.careGroup,
    required this.effectivePlan,
    required this.entitlements,
    required this.usage,
    required this.events,
    required this.storeManagement,
    this.subscription,
  });

  final AiseeCareGroupSummary careGroup;
  final AiseeSubscription? subscription;
  final AiseeBillingPlan effectivePlan;
  final Map<String, AiseeEntitlementValue> entitlements;
  final AiseeUsageSummary usage;
  final List<AiseeSubscriptionEvent> events;
  final AiseeStoreManagementInfo storeManagement;

  AiseeUsageQuota? get aiQuota => usage.quotas['ai_minutes'];

  bool entitlementEnabled(String key) => entitlements[key]?.enabled ?? false;

  factory AiseeBillingOverview.fromJson(Map<String, dynamic> json) {
    final Object? entitlementsRaw = json['entitlements'];
    final Map<String, AiseeEntitlementValue> entitlements =
        <String, AiseeEntitlementValue>{};
    if (entitlementsRaw is Map<String, dynamic>) {
      for (final MapEntry<String, dynamic> entry in entitlementsRaw.entries) {
        final Object? value = entry.value;
        if (value is Map<String, dynamic>) {
          entitlements[entry.key] = AiseeEntitlementValue.fromJson(value);
        }
      }
    }

    final Object? eventsRaw = json['events'];
    final List<AiseeSubscriptionEvent> events = <AiseeSubscriptionEvent>[];
    if (eventsRaw is List<dynamic>) {
      for (final Object? value in eventsRaw) {
        if (value is Map<String, dynamic>) {
          events.add(AiseeSubscriptionEvent.fromJson(value));
        }
      }
    }

    final Object? subscriptionRaw = json['subscription'];
    return AiseeBillingOverview(
      careGroup: AiseeCareGroupSummary.fromJson(
        json['care_group'] as Map<String, dynamic>? ?? <String, dynamic>{},
      ),
      subscription: subscriptionRaw is Map<String, dynamic>
          ? AiseeSubscription.fromJson(subscriptionRaw)
          : null,
      effectivePlan: AiseeBillingPlan.fromJson(
        json['effective_plan'] as Map<String, dynamic>? ?? <String, dynamic>{},
      ),
      entitlements: entitlements,
      usage: AiseeUsageSummary.fromJson(
        json['usage'] as Map<String, dynamic>? ?? <String, dynamic>{},
      ),
      events: events,
      storeManagement: AiseeStoreManagementInfo.fromJson(
        json['store_management'] as Map<String, dynamic>? ??
            <String, dynamic>{},
      ),
    );
  }
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

double _asDouble(Object? value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

DateTime? _asDate(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value);
}
