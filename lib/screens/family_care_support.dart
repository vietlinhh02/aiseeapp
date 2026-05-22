import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../generated/l10n/app_localizations.dart';
import '../models/aisee_api_models.dart';
import '../services/aisee_analytics_service.dart';
import '../theme/style_tokens.dart';
import 'subscription_screen.dart';

/// Sheet nâng gói / quota — chỉ dùng trong luồng Family (không gọi từ màn người khiếm thị).
Future<void> showFamilyCareBillingSheet(
  BuildContext context, {
  required String title,
  required String body,
  bool fromQuota = false,
  AiseeQuotaApiException? quota,
  String? caredUserId,
}) async {
  await AiseeAnalyticsService.instance.track(
    fromQuota
        ? AiseeAnalyticsEvent.quotaExceeded
        : AiseeAnalyticsEvent.featureGateSeen,
    parameters: <String, Object?>{
      'context': 'family_care',
      'usage_type': quota?.usageType,
      'plan_code': quota?.planCode,
      'cared_user_id': caredUserId,
    },
  );
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext ctx) {
      final AppLocalizations l = AppLocalizations.of(ctx);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: StyleTokens.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                body,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  height: 1.45,
                  color: StyleTokens.textSecondary,
                ),
              ),
              if (quota?.remaining != null) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  l.careBillingQuotaRemaining(quota!.remaining!),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: StyleTokens.textPrimary,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  unawaited(
                    AiseeAnalyticsService.instance.track(
                      AiseeAnalyticsEvent.upgradeClicked,
                      parameters: <String, Object?>{
                        'source': 'family_care_sheet',
                        'usage_type': quota?.usageType,
                        'cared_user_id': caredUserId,
                      },
                    ),
                  );
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => SubscriptionScreen(
                        familyFirst: true,
                        caredUserId: caredUserId,
                      ),
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: StyleTokens.buttonPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  l.careBillingSheetViewPlan,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> handleFamilyCareApiError(
  BuildContext context,
  Object error, {
  String? fallbackTitle,
  String? caredUserId,
}) async {
  final AppLocalizations l = AppLocalizations.of(context);
  final String title = fallbackTitle ?? l.careBillingFallbackTitle;
  if (error is AiseeQuotaApiException) {
    await showFamilyCareBillingSheet(
      context,
      title: l.careBillingQuotaExhausted,
      body: error.message,
      fromQuota: true,
      quota: error,
      caredUserId: caredUserId,
    );
    return;
  }
  if (error is AiseeApiException) {
    final String code = error.code ?? '';
    if (code == 'entitlement_required' ||
        code.contains('not_available') ||
        code == 'permission_denied') {
      await showFamilyCareBillingSheet(
        context,
        title: title,
        body: error.message,
        fromQuota: false,
        caredUserId: caredUserId,
      );
      return;
    }
  }
  if (!context.mounted) return;
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(error.toString())));
}
