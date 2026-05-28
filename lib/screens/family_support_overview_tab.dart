import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import 'package:aiseeapp/theme/aisee_typography.dart';

import 'package:phosphor_flutter/phosphor_flutter.dart';


import '../generated/l10n/app_localizations.dart';

import '../models/aisee_supporter_models.dart';

import '../services/aisee_rewarded_ad_service.dart';

import '../services/aisee_supporter_cache.dart';

import '../services/aisee_supporter_service.dart';

import '../services/aisee_token_provider.dart';

import '../theme/style_tokens.dart';

import '../utils/app_toast.dart';

import '../utils/jwt_expiry.dart';

import 'family_contacts_tab.dart';

import 'family_support_community_screen.dart';

import 'family_support_widgets.dart';
import '../widgets/app_loading_indicator.dart';


const Color _supportInk = StyleTokens.buttonPrimary;

class FamilySupportOverviewTab extends StatefulWidget {
  const FamilySupportOverviewTab({super.key});

  @override
  State<FamilySupportOverviewTab> createState() =>
      _FamilySupportOverviewTabState();
}

class _FamilySupportOverviewTabState extends State<FamilySupportOverviewTab> {
  late final AiseeSupporterService _service;
  final AiseeRewardedAdService _adService = AiseeRewardedAdService();

  SupporterOverviewResponse? _data;
  bool _loading = true;
  bool _initialCacheLoaded = false;
  String? _error;
  bool _busy = false;

  AppLocalizations get l => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();
    _service = AiseeSupporterService();
    _loadCached();
    _load();
  }

  @override
  void dispose() {
    _service.close();
    _adService.dispose();
    super.dispose();
  }

  Future<T?> _withFreshToken<T>(Future<T> Function(String token) action) async {
    return AiseeTokenProvider.instance.withAccessToken(action);
  }

  Future<void> _loadCached() async {
    final cached = await AiseeSupporterCache.instance.read();
    if (cached != null && mounted) {
      setState(() {
        _data = cached;
        _loading = false;
        _initialCacheLoaded = true;
      });
    }
  }

  Future<void> _load() async {
    if (!_initialCacheLoaded) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final data = await _withFreshToken(_service.getOverview);
      if (data == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      if (!mounted) return;
      AiseeSupporterCache.instance.write(data);
      setState(() {
        _data = data;
        _loading = false;
        _error = null;
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
      final bool rewarded = await _adService.show();
      if (!rewarded) {
        if (mounted) setState(() => _busy = false);
        return;
      }
      final result = await _withFreshToken(_service.watchAd);
      if (result == null) return;
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

    final int maxCoins = (coinBalance ~/ 100) * 100;
    double sliderValue = maxCoins.toDouble();

    final int? amount = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext ctx, StateSetter setDialogState) {
            final int currentCoins = sliderValue.round();
            final int turns = (currentCoins / 100).floor();

            return Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              decoration: BoxDecoration(
                color: StyleTokens.surfaceCard,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: StyleTokens.cardBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        // -- Title
                        Text(
                          l.supporterRedeemDialogTitle,
                          style: aiseeTextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: StyleTokens.textPrimary,
                          ),
                        ),

                        // -- Slider row: label left, value right
                        const SizedBox(height: 14),
                        Row(
                          children: <Widget>[
                            Text(
                              _coinInputLabel(ctx),
                              style: aiseeTextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: StyleTokens.textSecondary,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '$currentCoins',
                              style: aiseeTextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: _supportInk,
                                fontFeatures: const <FontFeature>[
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              l.supporterCoinLabel,
                              style: aiseeTextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: StyleTokens.textMuted,
                              ),
                            ),
                          ],
                        ),

                        // -- Slider
                        const SizedBox(height: 4),
                        SliderTheme(
                          data: SliderTheme.of(ctx).copyWith(
                            trackHeight: 6,
                            activeTrackColor: _supportInk,
                            inactiveTrackColor:
                                _supportInk.withValues(alpha: 0.12),
                            thumbColor: _supportInk,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 10,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 18,
                            ),
                            overlayColor:
                                _supportInk.withValues(alpha: 0.12),
                          ),
                          child: Slider(
                            value: sliderValue,
                            min: 0,
                            max: maxCoins.toDouble(),
                            divisions: maxCoins > 0 ? maxCoins ~/ 100 : 1,
                            onChanged: (double v) {
                              setDialogState(() => sliderValue = v);
                            },
                          ),
                        ),

                        // -- Turns display
                        Row(
                          children: <Widget>[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: _supportInk.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '$currentCoins ${l.supporterCoinLabel} = $turns',
                                style: aiseeTextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _supportInk,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              l.supporterBalanceConversion(turns),
                              style: aiseeTextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: StyleTokens.textPrimary,
                              ),
                            ),
                          ],
                        ),

                        // -- Recipient field
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 11,
                          ),
                          decoration: BoxDecoration(
                            color: StyleTokens.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: StyleTokens.cardBorder,
                            ),
                          ),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  l.supporterRedeemCommunityFund,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: aiseeTextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: StyleTokens.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                PhosphorIcons.checkCircle(
                                  PhosphorIconsStyle.fill,
                                ),
                                size: 18,
                                color: _supportInk,
                              ),
                            ],
                          ),
                        ),

                        // -- Action buttons
                        const SizedBox(height: 18),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Material(
                                color: StyleTokens.surfaceCard,
                                borderRadius: BorderRadius.circular(31),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(31),
                                  onTap: () => Navigator.pop(ctx),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 13,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(31),
                                      border: Border.all(
                                        color: StyleTokens.cardBorder,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        l.actionCancel,
                                        style: aiseeTextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: StyleTokens.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Material(
                                color: _supportInk,
                                borderRadius: BorderRadius.circular(31),
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(31),
                                  onTap: turns > 0
                                      ? () =>
                                          Navigator.pop(ctx, currentCoins)
                                      : null,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 13,
                                    ),
                                    child: Center(
                                      child: Text(
                                        l.actionConfirm,
                                        style: aiseeTextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height:
                              MediaQuery.paddingOf(ctx).bottom + 16,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (amount == null || !mounted) return;

    setState(() => _busy = true);
    try {
      final resp = await _withFreshToken(
        (String token) => _service.redeem(token, amount, null),
      );
      if (resp == null) return;
      if (!mounted) return;
      AppToast.show(l.supporterRedeemSuccess(resp.aiTurnsGranted));
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
    if (_loading && _data == null) {
      return const AppLoadingIndicator();
    }

    if (_error != null && _data == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(_error!, style: StyleTokens.bodySmall()),
            const SizedBox(height: 12),
            Material(
              color: _supportInk,
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
        padding: EdgeInsets.zero,
        children: <Widget>[
          SupporterWelcomeBanner(title: _heroTitle(), message: _heroMessage()),
          const SizedBox(height: 16),
          SupporterHeroCard(
            title: l.supporterBalanceTitle,
            rateHint: l.supporterRateHint,
            coinBalance: data.personal.coinBalance,
            coinLabel: l.supporterCoinLabel,
            adsWatchedToday: data.personal.adsWatchedToday,
            adsLabel: l.supporterPersonalAdsWatched,
          ),
          const SizedBox(height: 22),
          _SectionTitle(text: _actionTitle()),
          const SizedBox(height: 10),
          SupporterActionPanel(
            watchAdLabel: l.supporterWatchAdButton,
            redeemLabel: l.supporterRedeemButton,
            familyLinkLabel: l.supporterMyFamilyLink,
            busy: _busy,
            canRedeem: data.personal.coinBalance >= 100,
            onWatchAd: _watchAd,
            onRedeem: _redeem,
            onOpenFamily: _openFamilyLink,
          ),
          const SizedBox(height: 22),
          SupporterPersonalStatsRow(
            title: _personalTitle(),
            peopleCount: data.personal.supportedPeopleCount,
            aiTurns: data.personal.totalAITurnsGifted,
            adsWatched: data.personal.adsWatchedToday,
            labelPeople: l.supporterPersonalPeopleSupported,
            labelAITurns: l.supporterPersonalAITurnsGifted,
            labelAds: l.supporterPersonalAdsWatched,
          ),
          const SizedBox(height: 22),
          SupporterCommunityStatsRow(
            totalCaredUsers: data.community.totalCaredUsers,
            totalAITurns: data.community.totalAITurnsGifted,
            activeSupporters: data.community.activeSupporters,
            supporters: data.community.supporters,
            title: l.supporterCommunityTitle,
            labelPeople: l.supporterCommunityPeopleSupported,
            labelAITurns: l.supporterCommunityAITurnsGifted,
            labelSupporters: l.supporterCommunityActiveSupporters,
            onTap: () => _openCommunity(data),
          ),
          const SizedBox(height: 10),
          SizedBox(height: MediaQuery.paddingOf(context).bottom + 16),
        ],
      ),
    );
  }

  String _heroTitle() {
    final bool vi = Localizations.localeOf(context).languageCode == 'vi';
    return vi
        ? 'Mỗi đóng góp của bạn đều tạo nên sự khác biệt.'
        : 'Every contribution you make creates a difference.';
  }

  String _heroMessage() {
    final bool vi = Localizations.localeOf(context).languageCode == 'vi';
    return vi
        ? 'Hỗ trợ quảng cáo, nhận xu và đổi lượt hỗ trợ để giúp nhiều người hơn nữa.'
        : 'Watch ads, earn coins and redeem support credits to help more people.';
  }

  String _actionTitle() {
    final bool vi = Localizations.localeOf(context).languageCode == 'vi';
    return vi ? 'Bạn muốn làm gì?' : 'What would you like to do?';
  }

  String _personalTitle() {
    final bool vi = Localizations.localeOf(context).languageCode == 'vi';
    return vi ? 'Tác động của bạn' : 'Your impact';
  }

  void _openFamilyLink() {
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
                  color: _supportInk,
                ),
              ),
            ),
            body: const FamilyContactsTab(),
          );
        },
      ),
    );
  }

  void _openCommunity(SupporterOverviewResponse data) async {
    HapticFeedback.lightImpact();
    final String? token = await AiseeTokenProvider.instance.accessToken();
    final String? userId = token != null ? getUserIdFromToken(token) : null;
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext _) =>
            FamilySupportCommunityScreen(data: data, userId: userId),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: aiseeTextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: StyleTokens.textPrimary,
      ),
    );
  }
}

String _coinInputLabel(BuildContext context) {
  final bool vi = Localizations.localeOf(context).languageCode == 'vi';
  return vi ? 'Số xu muốn đổi' : 'Coins to redeem';
}

