import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aiseeapp/theme/aisee_typography.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../generated/l10n/app_localizations.dart';
import '../models/aisee_supporter_models.dart';
import '../services/aisee_supporter_service.dart';
import '../services/aisee_token_provider.dart';
import '../theme/style_tokens.dart';
import '../utils/app_toast.dart';
import 'family_contacts_tab.dart';
import 'family_support_widgets.dart';

const Color _supportInk = Color(0xFF1B4965);
const Color _supportPrimary = Color(0xFF1B4965);
const Color _supportBorder = Color(0xFFC0E2EA);

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

  Future<T?> _withFreshToken<T>(Future<T> Function(String token) action) async {
    return AiseeTokenProvider.instance.withAccessToken(action);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _withFreshToken(_service.getOverview);
      if (data == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }
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

    final int? amount = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: StyleTokens.surfaceCard,
      builder: (BuildContext ctx) {
        int selected = (coinBalance ~/ 100) * 100;
        return StatefulBuilder(
          builder: (BuildContext ctx, StateSetter setDialogState) {
            final int turns = selected ~/ 100;
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.paddingOf(ctx).bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SizedBox(height: 8),
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _supportBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      l.supporterRedeemDialogTitle,
                      style: aiseeTextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: _supportInk,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      l.supporterRedeemConfirm(selected, turns),
                      style: aiseeTextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: StyleTokens.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      l.supporterRedeemRecipientLabel,
                      style: StyleTokens.bodySmall(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: _supportBorder),
                      ),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              l.supporterRedeemCommunityFund,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: aiseeTextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _supportInk,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                            size: 20,
                            color: _supportPrimary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: TextButton.styleFrom(
                              foregroundColor: _supportInk,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: const BorderSide(color: _supportBorder),
                              ),
                              textStyle: aiseeTextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            child: Text(l.actionCancel),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => Navigator.pop(ctx, selected),
                            style: FilledButton.styleFrom(
                              backgroundColor: _supportInk,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              textStyle: aiseeTextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            child: Text(l.actionConfirm),
                          ),
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
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: aiseeTextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: StyleTokens.textPrimary,
      ),
    );
  }
}
