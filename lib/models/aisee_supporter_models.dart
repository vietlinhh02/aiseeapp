class SupporterPersonalStats {
  final int supportedPeopleCount;
  final int totalAITurnsGifted;
  final int adsWatchedToday;
  final int coinBalance;
  final int totalEarned;
  final int totalRedeemed;

  const SupporterPersonalStats({
    required this.supportedPeopleCount,
    required this.totalAITurnsGifted,
    required this.adsWatchedToday,
    required this.coinBalance,
    required this.totalEarned,
    required this.totalRedeemed,
  });

  factory SupporterPersonalStats.fromJson(Map<String, dynamic> j) {
    return SupporterPersonalStats(
      supportedPeopleCount: (j['supported_people_count'] as num).toInt(),
      totalAITurnsGifted: (j['total_ai_turns_gifted'] as num).toInt(),
      adsWatchedToday: (j['ads_watched_today'] as num).toInt(),
      coinBalance: (j['coin_balance'] as num).toInt(),
      totalEarned: (j['total_earned'] as num).toInt(),
      totalRedeemed: (j['total_redeemed'] as num).toInt(),
    );
  }
}

class CommunitySupporterStats {
  final int totalCaredUsers;
  final int totalAITurnsGifted;
  final int activeSupporters;
  final List<CommunitySupporterProfile> supporters;

  const CommunitySupporterStats({
    required this.totalCaredUsers,
    required this.totalAITurnsGifted,
    required this.activeSupporters,
    this.supporters = const <CommunitySupporterProfile>[],
  });

  factory CommunitySupporterStats.fromJson(Map<String, dynamic> j) {
    return CommunitySupporterStats(
      totalCaredUsers: (j['total_cared_users'] as num).toInt(),
      totalAITurnsGifted: (j['total_ai_turns_gifted'] as num).toInt(),
      activeSupporters: (j['active_supporters'] as num).toInt(),
      supporters:
          (j['supporters'] as List<dynamic>?)
              ?.whereType<Map>()
              .map(
                (Map value) => CommunitySupporterProfile.fromJson(
                  Map<String, dynamic>.from(value),
                ),
              )
              .toList() ??
          const <CommunitySupporterProfile>[],
    );
  }
}

class CommunitySupporterProfile {
  final String id;
  final String displayName;
  final String? avatarUrl;

  const CommunitySupporterProfile({
    required this.id,
    required this.displayName,
    this.avatarUrl,
  });

  factory CommunitySupporterProfile.fromJson(Map<String, dynamic> j) {
    return CommunitySupporterProfile(
      id: j['id'] as String? ?? '',
      displayName: j['display_name'] as String? ?? '',
      avatarUrl: j['avatar_url'] as String?,
    );
  }
}

class SupporterOverviewResponse {
  final SupporterPersonalStats personal;
  final CommunitySupporterStats community;

  const SupporterOverviewResponse({
    required this.personal,
    required this.community,
  });

  factory SupporterOverviewResponse.fromJson(Map<String, dynamic> j) {
    return SupporterOverviewResponse(
      personal: SupporterPersonalStats.fromJson(
        j['personal'] as Map<String, dynamic>,
      ),
      community: CommunitySupporterStats.fromJson(
        j['community'] as Map<String, dynamic>,
      ),
    );
  }
}

class WatchAdResponse {
  final int coinsEarned;
  final int newBalance;
  final int adsWatchedToday;

  const WatchAdResponse({
    required this.coinsEarned,
    required this.newBalance,
    required this.adsWatchedToday,
  });

  factory WatchAdResponse.fromJson(Map<String, dynamic> j) {
    return WatchAdResponse(
      coinsEarned: (j['coins_earned'] as num).toInt(),
      newBalance: (j['new_balance'] as num).toInt(),
      adsWatchedToday: (j['ads_watched_today'] as num).toInt(),
    );
  }
}

class RedeemResponse {
  final int coinsRedeemed;
  final int newBalance;
  final int aiTurnsGranted;

  const RedeemResponse({
    required this.coinsRedeemed,
    required this.newBalance,
    required this.aiTurnsGranted,
  });

  factory RedeemResponse.fromJson(Map<String, dynamic> j) {
    return RedeemResponse(
      coinsRedeemed: (j['coins_redeemed'] as num).toInt(),
      newBalance: (j['new_balance'] as num).toInt(),
      aiTurnsGranted: (j['ai_turns_granted'] as num).toInt(),
    );
  }
}
