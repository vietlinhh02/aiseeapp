import 'package:flutter/material.dart';
import 'package:aiseeapp/theme/aisee_typography.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../models/aisee_supporter_models.dart';
import '../theme/style_tokens.dart';

const Color _communityInk = StyleTokens.textPrimary;
const Color _communityPrimary = StyleTokens.buttonPrimary;
const Color _communityBorder = Color(0xFFE7ECF4);
const Color _communityLilac = Color(0xFFF1EEFF);
const Color _communityMint = Color(0xFFE9F8F0);
const Color _communityGold = Color(0xFFFFF2D6);

String _avatarUrl(String seed) {
  return 'https://api.dicebear.com/9.x/notionists/png?seed=${Uri.encodeComponent(seed)}&size=96&backgroundColor=e8e8e8';
}

String _fmtInt(int value) {
  final String raw = value.toString();
  final StringBuffer out = StringBuffer();
  for (int i = 0; i < raw.length; i++) {
    final int left = raw.length - i;
    out.write(raw[i]);
    if (left > 1 && left % 3 == 1) out.write('.');
  }
  return out.toString();
}

class FamilySupportCommunityScreen extends StatelessWidget {
  const FamilySupportCommunityScreen({super.key, required this.data, this.userId});

  final SupporterOverviewResponse data;
  final String? userId;

  @override
  Widget build(BuildContext context) {
    final bool vi = Localizations.localeOf(context).languageCode == 'vi';
    return Scaffold(
      backgroundColor: StyleTokens.background,
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: 0,
        toolbarHeight: 48,
        scrolledUnderElevation: 0,
        title: Text(
          vi ? 'Cộng đồng' : 'Community',
          style: aiseeTextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _communityInk,
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          20,
          4,
          20,
          MediaQuery.paddingOf(context).bottom + 24,
        ),
        children: <Widget>[
          _CommunitySummaryCard(data: data),
          const SizedBox(height: 16),
          _SectionHeader(title: vi ? 'Hoạt động gần đây' : 'Recent activity'),
          const SizedBox(height: 10),
          _ActivityList(
            activities: (data.community.activities ??
                    const <CommunitySupporterActivity>[])
                .take(5)
                .toList(),
          ),
          const SizedBox(height: 16),
          _InviteFriendsCard(userId: userId),
        ],
      ),
    );
  }
}

class _CommunitySummaryCard extends StatelessWidget {
  const _CommunitySummaryCard({required this.data});

  final SupporterOverviewResponse data;

  @override
  Widget build(BuildContext context) {
    final bool vi = Localizations.localeOf(context).languageCode == 'vi';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: StyleTokens.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _communityBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              _IconBubble(
                icon: PhosphorIcons.usersThree(PhosphorIconsStyle.regular),
                color: _communityPrimary,
                background: _communityLilac,
                size: 36,
                iconSize: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      vi ? 'Cộng đồng của bạn' : 'Your community',
                      style: aiseeTextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _communityInk,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      vi
                          ? 'Bạn và ${_fmtInt(data.community.activeSupporters)} người khác'
                          : 'You and ${_fmtInt(data.community.activeSupporters)} others',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: aiseeTextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        height: 1.08,
                        color: _communityInk,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      vi
                          ? 'đang cùng nhau tạo tác động'
                          : 'creating impact together',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: aiseeTextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: StyleTokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _AvatarStrip(supporters: data.community.supporters),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: _SummaryMetric(
                  value: data.community.totalCaredUsers,
                  label: vi ? 'Người nhận' : 'People',
                  icon: PhosphorIcons.handHeart(PhosphorIconsStyle.regular),
                  color: _communityPrimary,
                  background: _communityLilac,
                ),
              ),
              const _MetricDivider(),
              Expanded(
                child: _SummaryMetric(
                  value: data.community.totalAITurnsGifted,
                  label: vi ? 'Lượt hỗ trợ' : 'Credits',
                  icon: PhosphorIcons.trendUp(PhosphorIconsStyle.bold),
                  color: const Color(0xFF25A96A),
                  background: _communityMint,
                ),
              ),
              const _MetricDivider(),
              Expanded(
                child: _SummaryMetric(
                  value: data.personal.adsWatchedToday,
                  label: vi ? 'Quảng cáo' : 'Ads',
                  icon: PhosphorIcons.playCircle(PhosphorIconsStyle.fill),
                  color: const Color(0xFFD69A1E),
                  background: _communityGold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.background,
  });

  final int value;
  final String label;
  final IconData icon;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        _IconBubble(
          icon: icon,
          color: color,
          background: background,
          size: 32,
          iconSize: 16,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                _fmtInt(value),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: aiseeTextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  color: _communityInk,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: aiseeTextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: StyleTokens.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 34,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: _communityBorder,
    );
  }
}

class _AvatarStrip extends StatelessWidget {
  const _AvatarStrip({required this.supporters});

  final List<CommunitySupporterProfile> supporters;

  @override
  Widget build(BuildContext context) {
    final int visibleCount = supporters.length.clamp(0, 4);
    if (visibleCount == 0) return const SizedBox.shrink();
    return SizedBox(
      width: 28 + ((visibleCount - 1) * 17),
      height: 30,
      child: Stack(
        children: <Widget>[
          for (int i = 0; i < visibleCount; i++)
            Positioned(
              left: i * 17,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.network(
                  _avatarUrl(supporters[i].anonSeed),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const ColoredBox(color: _communityLilac),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: aiseeTextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: _communityInk,
      ),
    );
  }
}

class _ActivityList extends StatelessWidget {
  const _ActivityList({required this.activities});

  final List<CommunitySupporterActivity> activities;

  @override
  Widget build(BuildContext context) {
    final bool vi = Localizations.localeOf(context).languageCode == 'vi';
    return Container(
      decoration: BoxDecoration(
        color: StyleTokens.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _communityBorder),
      ),
      child: Column(
        children: <Widget>[
          if (activities.isEmpty)
            _EmptyRow(
              icon: PhosphorIcons.clockCounterClockwise(
                PhosphorIconsStyle.regular,
              ),
              text: vi ? 'Chưa có hoạt động gần đây' : 'No recent activity yet',
            ),
          for (int i = 0; i < activities.length; i++) ...<Widget>[
            _ActivityTile(activity: activities[i]),
            if (i != activities.length - 1)
              const Divider(height: 1, color: _communityBorder),
          ],
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.activity});

  final CommunitySupporterActivity activity;

  @override
  Widget build(BuildContext context) {
    final _ActivityVisual visual = _activityVisual(activity.type);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          _ActivityAvatar(
            seed: activity.anonSeed,
            visual: visual,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _activityTitle(context, activity),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: aiseeTextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _communityInk,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _activityMessage(context, activity),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: aiseeTextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: StyleTokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _ActivityAmountChip(activity: activity, visual: visual),
        ],
      ),
    );
  }

  String _activityTitle(
    BuildContext context,
    CommunitySupporterActivity activity,
  ) {
    final bool vi = Localizations.localeOf(context).languageCode == 'vi';
    return switch (activity.type) {
      'watch_ad' => vi ? 'Người hỗ trợ xem quảng cáo' : 'A supporter watched an ad',
      'redeem' => vi ? 'Người hỗ trợ đổi lượt' : 'A supporter redeemed credits',
      _ => vi ? 'Người hỗ trợ vừa hoạt động' : 'A supporter was active',
    };
  }

  String _activityMessage(
    BuildContext context,
    CommunitySupporterActivity activity,
  ) {
    final bool vi = Localizations.localeOf(context).languageCode == 'vi';
    final String time = _relativeTime(context, activity.occurredAt);
    final String body = switch (activity.type) {
      'watch_ad' =>
        vi
            ? 'Nhận ${_fmtInt(activity.amount)} xu'
            : 'Earned ${_fmtInt(activity.amount)} coins',
      'redeem' =>
        vi
            ? 'Trao ${_fmtInt(activity.amount)} lượt cho cộng đồng'
            : 'Gifted ${_fmtInt(activity.amount)} support credits',
      _ => vi ? 'Cập nhật cộng đồng' : 'Community update',
    };
    return time.isEmpty ? body : '$body • $time';
  }

  String _relativeTime(BuildContext context, String raw) {
    final DateTime? occurredAt = DateTime.tryParse(raw)?.toLocal();
    if (occurredAt == null) return '';
    final bool vi = Localizations.localeOf(context).languageCode == 'vi';
    final Duration diff = DateTime.now().difference(occurredAt);
    if (diff.inMinutes < 1) return vi ? 'vừa xong' : 'just now';
    if (diff.inHours < 1) {
      return vi ? '${diff.inMinutes} phút trước' : '${diff.inMinutes}m ago';
    }
    if (diff.inDays < 1) {
      return vi ? '${diff.inHours} giờ trước' : '${diff.inHours}h ago';
    }
    return vi ? '${diff.inDays} ngày trước' : '${diff.inDays}d ago';
  }

  _ActivityVisual _activityVisual(String type) {
    return switch (type) {
      'watch_ad' => _ActivityVisual(
        icon: PhosphorIcons.playCircle(PhosphorIconsStyle.fill),
        color: const Color(0xFFD69A1E),
        background: _communityGold,
      ),
      'redeem' => _ActivityVisual(
        icon: PhosphorIcons.gift(PhosphorIconsStyle.duotone),
        color: _communityPrimary,
        background: _communityLilac,
      ),
      _ => _ActivityVisual(
        icon: PhosphorIcons.clockCounterClockwise(PhosphorIconsStyle.regular),
        color: StyleTokens.textSecondary,
        background: const Color(0xFFF0F0F0),
      ),
    };
  }
}

class _ActivityAvatar extends StatelessWidget {
  const _ActivityAvatar({required this.seed, required this.visual});

  final String seed;
  final _ActivityVisual visual;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 42,
      height: 42,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          _Avatar(seed: seed, size: 38),
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              width: 17,
              height: 17,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: visual.background,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: StyleTokens.surfaceCard, width: 1.5),
              ),
              child: Icon(visual.icon, size: 10, color: visual.color),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityAmountChip extends StatelessWidget {
  const _ActivityAmountChip({required this.activity, required this.visual});

  final CommunitySupporterActivity activity;
  final _ActivityVisual visual;

  @override
  Widget build(BuildContext context) {
    final bool vi = Localizations.localeOf(context).languageCode == 'vi';
    final String suffix = activity.type == 'watch_ad'
        ? (vi ? ' xu' : '')
        : (vi ? '' : ' cr');
    return Container(
      constraints: const BoxConstraints(minWidth: 48),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: visual.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            '+${_fmtInt(activity.amount)}$suffix',
            maxLines: 1,
            style: aiseeTextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: visual.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityVisual {
  const _ActivityVisual({
    required this.icon,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final Color color;
  final Color background;
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.seed, required this.size});

  final String seed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(shape: BoxShape.circle),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        _avatarUrl(seed),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const ColoredBox(color: _communityLilac),
      ),
    );
  }
}

class _EmptyRow extends StatelessWidget {
  const _EmptyRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: <Widget>[
          _IconBubble(
            icon: icon,
            color: StyleTokens.textSecondary,
            background: const Color(0xFFF0F2F5),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: aiseeTextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: StyleTokens.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBubble extends StatelessWidget {
  const _IconBubble({
    required this.icon,
    required this.color,
    required this.background,
    this.size = 42,
    this.iconSize = 21,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, size: iconSize, color: color),
    );
  }
}

class _InviteFriendsCard extends StatefulWidget {
  const _InviteFriendsCard({required this.userId});

  final String? userId;

  @override
  State<_InviteFriendsCard> createState() => _InviteFriendsCardState();
}

class _InviteFriendsCardState extends State<_InviteFriendsCard> {
  bool _showQr = false;

  @override
  Widget build(BuildContext context) {
    final bool vi = Localizations.localeOf(context).languageCode == 'vi';
    final String refLink = widget.userId != null && widget.userId!.isNotEmpty
        ? 'https://aisee.app/invite?ref=${widget.userId}'
        : 'https://aisee.app';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: StyleTokens.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _communityBorder),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _communityLilac,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  PhosphorIcons.usersThree(PhosphorIconsStyle.duotone),
                  size: 22,
                  color: _communityPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      vi ? 'Mời bạn bè' : 'Invite friends',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: aiseeTextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _communityInk,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      vi
                          ? 'Cùng nhau tạo tác động, nhận 200 xu mỗi người'
                          : 'Make an impact together, earn 200 coins each',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: aiseeTextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        height: 1.25,
                        color: StyleTokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() => _showQr = !_showQr),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _showQr
                        ? _communityPrimary
                        : _communityPrimary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        _showQr
                            ? PhosphorIcons.qrCode(PhosphorIconsStyle.duotone)
                            : PhosphorIcons.qrCode(PhosphorIconsStyle.regular),
                        size: 15,
                        color: _showQr
                            ? Colors.white
                            : _communityPrimary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _showQr ? (vi ? 'Ẩn QR' : 'Hide QR')
                            : (vi ? 'Mã QR' : 'QR code'),
                        style: aiseeTextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _showQr
                              ? Colors.white
                              : _communityPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Column(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _communityBorder.withValues(alpha: 0.6),
                      ),
                      boxShadow: const <BoxShadow>[
                        BoxShadow(
                          color: Color(0x0A000000),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: QrImageView(
                        data: refLink,
                        version: QrVersions.auto,
                        size: 160,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: _communityPrimary,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: _communityPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    vi ? 'Quét mã để tải app' : 'Scan code to download',
                    style: aiseeTextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: StyleTokens.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: Material(
                      color: _communityPrimary,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          final String text = vi
                              ? 'Tham gia AiSee cùng tôi để hỗ trợ người thân! $refLink'
                              : 'Join me on AiSee to support our loved ones! $refLink';
                          SharePlus.instance.share(ShareParams(text: text));
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(
                                PhosphorIcons.shareNetwork(
                                  PhosphorIconsStyle.duotone,
                                ),
                                size: 18,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                vi ? 'Chia sẻ link' : 'Share link',
                                style: aiseeTextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            crossFadeState:
                _showQr ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }
}
