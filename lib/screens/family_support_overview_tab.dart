import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aiseeapp/theme/aisee_typography.dart';

import '../generated/l10n/app_localizations.dart';
import '../models/aisee_supporter_models.dart';
import '../services/aisee_session_store.dart';
import '../services/aisee_supporter_service.dart';
import '../theme/style_tokens.dart';
import '../utils/app_toast.dart';
import 'family_contacts_tab.dart';
import 'family_support_widgets.dart';

class FamilySupportOverviewTab extends StatefulWidget {
  const FamilySupportOverviewTab({super.key});

  @override
  State<FamilySupportOverviewTab> createState() =>
      _FamilySupportOverviewTabState();
}

class _FamilySupportOverviewTabState extends State<FamilySupportOverviewTab> {
  late final AiseeSupporterService _service;

  SupporterOverviewResponse? _data;
  bool _loading = true;
  String? _error;
  bool _busy = false;

  AppLocalizations get l => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();
    _service = AiseeSupporterService();
    _load();
  }

  @override
  void dispose() {
    _service.close();
    super.dispose();
  }

  Future<String?> _token() async {
    final stored = await AiseeSessionStore.instance.read();
    return stored?.accessToken;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await _token();
      if (token == null) return;
      final data = await _service.getOverview(token);
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _watchAd() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final token = await _token();
      if (token == null) return;
      await _service.watchAd(token);
      if (!mounted) return;
      AppToast.show(l.supporterAdWatchSuccess);
      await _load();
    } catch (e) {
      if (!mounted) return;
      AppToast.show(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _redeem() async {
    if (_busy || _data == null) return;

    final int coinBalance = _data!.personal.coinBalance;
    if (coinBalance < 100) {
      AppToast.show(l.supporterInsufficientBalance, isError: true);
      return;
    }

    final int? amount = await showDialog<int>(
      context: context,
      builder: (BuildContext ctx) {
        int selected = (coinBalance ~/ 100) * 100;
        return StatefulBuilder(
          builder: (BuildContext ctx, StateSetter setDialogState) {
            final int turns = selected ~/ 100;
            return AlertDialog(
              title: Text(l.supporterRedeemDialogTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l.supporterRedeemConfirm(selected, turns),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: <Widget>[
                      Text(
                        l.supporterRedeemRecipientLabel,
                        style: StyleTokens.bodySmall(),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 160,
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          hint: Text(l.supporterRedeemCommunityFund),
                          items: const <DropdownMenuItem<String>>[
                            DropdownMenuItem<String>(
                              value: null,
                              child: Text('(cộng đồng)'),
                            ),
                          ],
                          onChanged: (String? _) {},
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l.actionCancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, selected),
                  child: Text(l.actionConfirm),
                ),
              ],
            );
          },
        );
      },
    );
    if (amount == null || !mounted) return;

    setState(() => _busy = true);
    try {
      final token = await _token();
      if (token == null) return;
      final resp = await _service.redeem(token, amount, null);
      if (!mounted) return;
      AppToast.show(
        l.supporterRedeemSuccess(resp.aiTurnsGranted),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      AppToast.show(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(_error!, style: StyleTokens.bodySmall()),
            const SizedBox(height: 12),
            Material(
              color: StyleTokens.buttonPrimary,
              borderRadius: BorderRadius.circular(31),
              child: InkWell(
                borderRadius: BorderRadius.circular(31),
                onTap: _load,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: Text(
                    l.remindersRetry,
                    style: aiseeTextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final SupporterOverviewResponse data = _data!;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          SupporterPersonalStatsRow(
            peopleCount: data.personal.supportedPeopleCount,
            aiTurns: data.personal.totalAITurnsGifted,
            adsWatched: data.personal.adsWatchedToday,
            labelPeople: l.supporterPersonalPeopleSupported,
            labelAITurns: l.supporterPersonalAITurnsGifted,
            labelAds: l.supporterPersonalAdsWatched,
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _busy ? null : _watchAd,
              icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
              label: Text(l.supporterWatchAdButton),
              style: FilledButton.styleFrom(
                backgroundColor: StyleTokens.buttonPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Material(
            color: StyleTokens.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (BuildContext _) {
                      return Scaffold(
                        backgroundColor: StyleTokens.background,
                        appBar: AppBar(
                          centerTitle: false,
                          titleSpacing: 20,
                          toolbarHeight: 48,
                          scrolledUnderElevation: 0,
                          title: Text(
                            l.supporterMyFamilyLink,
                            style: aiseeTextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              height: 1,
                              letterSpacing: -0.5,
                              color: StyleTokens.textPrimary,
                            ),
                          ),
                        ),
                        body: const FamilyContactsTab(),
                      );
                    },
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: <Widget>[
                    Icon(
                      Icons.group_rounded,
                      size: 20,
                      color: StyleTokens.buttonPrimary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l.supporterMyFamilyLink,
                        style: aiseeTextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: StyleTokens.textPrimary,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: StyleTokens.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SupporterBalancePoolCard(
            coinBalance: data.personal.coinBalance,
            title: l.supporterBalanceTitle,
            conversionLabel: l.supporterBalanceConversion(
              data.personal.coinBalance ~/ 100,
            ),
            redeemLabel: l.supporterRedeemButton,
            rateHint: l.supporterRateHint,
            coinLabel: l.supporterCoinLabel,
            busy: _busy,
            onRedeem: _redeem,
          ),
          const SizedBox(height: 20),
          SupporterCommunityStatsRow(
            totalCaredUsers: data.community.totalCaredUsers,
            totalAITurns: data.community.totalAITurnsGifted,
            activeSupporters: data.community.activeSupporters,
            title: l.supporterCommunityTitle,
            labelPeople: l.supporterCommunityPeopleSupported,
            labelAITurns: l.supporterCommunityAITurnsGifted,
            labelSupporters: l.supporterCommunityActiveSupporters,
          ),
          const SizedBox(height: 20),
          SupporterInfoCard(
            title: l.supporterInfoTitle,
            steps: <String>[
              l.supporterInfoStep1,
              l.supporterInfoStep2,
              l.supporterInfoStep3,
            ],
            dailyLimit: l.supporterInfoDailyLimit,
            learnMoreLabel: l.supporterInfoLearnMore,
          ),
          SizedBox(height: MediaQuery.paddingOf(context).bottom + 16),
        ],
      ),
    );
  }
}
