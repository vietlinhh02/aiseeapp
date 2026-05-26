import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/app_env.dart';

class AiseeRewardedAdService {
  AiseeRewardedAdService() {
    _load();
  }

  RewardedAd? _ad;
  bool _loading = false;
  bool _disposed = false;

  String get _adUnitId {
    if (kDebugMode) {
      return _testAdUnitId;
    }
    return AppEnv.admobRewardedAdUnitId;
  }

  static const String _testAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  void _load() {
    if (_loading || _disposed) return;
    _loading = true;
    RewardedAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _ad = ad;
          _loading = false;
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('[AiSee:Ad] Load failed: $error');
          _ad = null;
          _loading = false;
        },
      ),
    );
  }

  Future<bool> show() async {
    final RewardedAd? ad = _ad;
    if (ad == null) {
      debugPrint('[AiSee:Ad] No ad ready, reloading');
      _load();
      return false;
    }

    final Completer<bool> completer = Completer<bool>();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (Ad ad) {
        ad.dispose();
        _ad = null;
        _load();
        if (!completer.isCompleted) completer.complete(false);
      },
      onAdFailedToShowFullScreenContent: (Ad ad, AdError error) {
        debugPrint('[AiSee:Ad] Show failed: $error');
        ad.dispose();
        _ad = null;
        _load();
        if (!completer.isCompleted) completer.complete(false);
      },
      onAdShowedFullScreenContent: (Ad ad) {
        debugPrint('[AiSee:Ad] Ad showed');
      },
    );

    ad.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        debugPrint('[AiSee:Ad] Earned reward: ${reward.amount}');
        if (!completer.isCompleted) completer.complete(true);
      },
    );

    return completer.future;
  }

  void dispose() {
    _disposed = true;
    _ad?.dispose();
    _ad = null;
  }
}