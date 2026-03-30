import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/aisee_api_models.dart';
import '../models/aisee_call_info.dart';
import '../models/aisee_family_member.dart';
import '../services/aisee_call_service.dart';
import '../services/aisee_chat_service.dart';
import '../services/aisee_family_service.dart';
import '../services/aisee_session_store.dart';
import '../theme/style_tokens.dart';
import 'call_screen.dart';
import 'chat_detail_screen.dart';

class ContactsTab extends StatefulWidget {
  const ContactsTab({super.key, this.aiseeProfile});

  final AiseeUserProfile? aiseeProfile;

  @override
  State<ContactsTab> createState() => _ContactsTabState();
}

class _ContactsTabState extends State<ContactsTab> {
  final AiseeFamilyService _familyService = AiseeFamilyService();
  final AiseeChatService _chatService = AiseeChatService();

  bool _loading = true;
  String? _error;
  List<AiseeFamilyMember> _contacts = <AiseeFamilyMember>[];
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _familyService.close();
    _chatService.close();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final AiseeAuthTokens? tokens =
        await AiseeSessionStore.instance.read();
    if (tokens == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Chưa đăng nhập. Vui lòng đăng nhập lại.';
      });
      return;
    }

    try {
      final List<AiseeFamilyMember> family =
          await _familyService.fetchFamily(tokens.accessToken);
      int unread = 0;
      try {
        unread =
            await _chatService.fetchUnreadCount(tokens.accessToken);
      } catch (_) {
        // Non-critical — ignore unread count errors.
      }
      if (!mounted) return;
      setState(() {
        _contacts = family;
        _unreadCount = unread;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final String msg = e is AiseeApiException
          ? e.message
          : 'Không tải được danh sách liên lạc.';
      setState(() {
        _loading = false;
        _error = msg;
      });
    }
  }

  Future<void> _startCall(
    AiseeFamilyMember contact,
    String callType,
  ) async {
    HapticFeedback.lightImpact();
    final AiseeAuthTokens? tokens =
        await AiseeSessionStore.instance.read();
    if (tokens == null) return;

    try {
      final result = await AiseeCallService().createRoom(
        tokens.accessToken,
        contact.id,
        callType,
      );
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => CallScreen(
            callInfo: AiseeCallInfo(
              roomName: result.roomName,
              token: result.token,
              callType: callType,
              contact: contact,
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final String msg = e is AiseeApiException
          ? e.message
          : 'Không tạo được cuộc gọi';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  Future<void> _showInviteFlow() async {
    final String? relationship = await _showRelationshipDialog();
    if (relationship == null || relationship.trim().isEmpty) return;

    final AiseeAuthTokens? tokens =
        await AiseeSessionStore.instance.read();
    if (tokens == null) return;

    try {
      final String code = await _familyService.createInvite(
        tokens.accessToken,
        relationship.trim(),
      );
      if (!mounted) return;
      await _showInviteCodeDialog(code);
    } catch (e) {
      if (!mounted) return;
      final String msg = e is AiseeApiException
          ? e.message
          : 'Không tạo được mã mời.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  Future<String?> _showRelationshipDialog() {
    final TextEditingController ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Mời người thân'),
          content: TextField(
            controller: ctrl,
            decoration: const InputDecoration(
              hintText: 'Mối quan hệ (VD: Con, Bố, Mẹ...)',
            ),
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Huỷ'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text),
              child: const Text('Tạo mã'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showInviteCodeDialog(String code) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Mã mời'),
          content: SelectableText(
            code,
            style: StyleTokens.titleScreen().copyWith(fontSize: 20),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: code));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã sao chép mã mời'),
                  ),
                );
              },
              child: const Text('Sao chép'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Liên lạc. Nhắn tin và gọi điện người thân.',
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          _buildHeader(),
          const SizedBox(height: 20),
          _buildBody(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                'Liên lạc',
                style: StyleTokens.titleScreen().copyWith(
                  fontSize: 18,
                ),
              ),
            ),
            if (_unreadCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: StyleTokens.error,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$_unreadCount',
                  style: StyleTokens.socialLabel().copyWith(
                    fontSize: 11,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Nhắn tin và gọi điện người thân.',
          style: StyleTokens.bodySmall().copyWith(
            fontSize: 12,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.only(top: 48),
        child: Center(
          child: CircularProgressIndicator(
            color: StyleTokens.buttonPrimary,
          ),
        ),
      );
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_contacts.isEmpty) {
      return _buildEmptyState();
    }

    return _buildContactsList();
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Column(
        children: <Widget>[
          Text(
            _error!,
            style: StyleTokens.bodySmall().copyWith(
              fontSize: 13,
              color: StyleTokens.error,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Semantics(
            button: true,
            label: 'Thử lại tải danh sách liên lạc',
            child: Material(
              color: StyleTokens.buttonPrimary,
              borderRadius: BorderRadius.circular(31),
              child: InkWell(
                borderRadius: BorderRadius.circular(31),
                onTap: () {
                  HapticFeedback.lightImpact();
                  _loadData();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: Text(
                    'Thử lại',
                    style: StyleTokens.socialLabel().copyWith(
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: <Widget>[
        Material(
          color: StyleTokens.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: <Widget>[
                SvgPicture.asset(
                  'assets/icons/nav/ic_3user.svg',
                  width: 36,
                  height: 36,
                  colorFilter: const ColorFilter.mode(
                    StyleTokens.textMuted,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Chưa có người thân.\n'
                  'Mời qua mã mời bên dưới.',
                  style: StyleTokens.bodySmall().copyWith(
                    fontSize: 13,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildInviteButton(),
      ],
    );
  }

  Widget _buildContactsList() {
    return Column(
      children: <Widget>[
        for (int i = 0; i < _contacts.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: 10),
          _ContactCard(
            member: _contacts[i],
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ChatDetailScreen(
                    contact: _contacts[i],
                    currentUserId:
                        widget.aiseeProfile?.id ?? '',
                  ),
                ),
              );
            },
            onVoiceCall: () =>
                _startCall(_contacts[i], 'voice'),
            onVideoCall: () =>
                _startCall(_contacts[i], 'video'),
          ),
        ],
        const SizedBox(height: 16),
        _buildInviteButton(),
      ],
    );
  }

  Widget _buildInviteButton() {
    return Semantics(
      button: true,
      label: 'Mời người thân vào danh sách liên lạc',
      child: Material(
        color: StyleTokens.buttonPrimary,
        borderRadius: BorderRadius.circular(31),
        child: InkWell(
          borderRadius: BorderRadius.circular(31),
          onTap: () {
            HapticFeedback.lightImpact();
            _showInviteFlow();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                'Mời người thân',
                style: StyleTokens.socialLabel().copyWith(
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.member,
    required this.onTap,
    required this.onVoiceCall,
    required this.onVideoCall,
  });

  final AiseeFamilyMember member;
  final VoidCallback onTap;
  final VoidCallback onVoiceCall;
  final VoidCallback onVideoCall;

  String get _initial {
    final String name = member.label;
    if (name.isEmpty) return '?';
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${member.label}. Chạm để nhắn tin.',
      child: Material(
        color: StyleTokens.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 22,
                  backgroundColor: StyleTokens.buttonPrimary,
                  child: Text(
                    _initial,
                    style: StyleTokens.socialLabel().copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        member.label,
                        style: StyleTokens.titleScreen().copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Chạm để nhắn tin',
                        style: StyleTokens.bodySmall().copyWith(
                          fontSize: 11,
                          color: StyleTokens.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Semantics(
                  button: true,
                  label: 'Gọi thoại ${member.label}',
                  child: IconButton(
                    icon: SvgPicture.asset(
                      'assets/icons/nav/ic_voice.svg',
                      width: 20,
                      height: 20,
                      colorFilter: const ColorFilter.mode(
                        StyleTokens.buttonPrimary,
                        BlendMode.srcIn,
                      ),
                    ),
                    tooltip: 'Gọi thoại',
                    onPressed: onVoiceCall,
                  ),
                ),
                Semantics(
                  button: true,
                  label: 'Gọi video ${member.label}',
                  child: IconButton(
                    icon: SvgPicture.asset(
                      'assets/icons/nav/ic_camera.svg',
                      width: 20,
                      height: 20,
                      colorFilter: const ColorFilter.mode(
                        StyleTokens.buttonPrimary,
                        BlendMode.srcIn,
                      ),
                    ),
                    tooltip: 'Gọi video',
                    onPressed: onVideoCall,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
