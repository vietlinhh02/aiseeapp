import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/aisee_api_models.dart';
import '../models/aisee_call_info.dart';
import '../services/aisee_chat_socket.dart';
import '../services/aisee_push_service.dart';
import '../services/aisee_session_store.dart';
import '../theme/style_tokens.dart';
import '../widgets/app_wordmark.dart';
import '../widgets/user_low_vision_bottom_nav.dart';
import 'call_screen.dart';
import 'family_contacts_tab.dart';
import 'family_messages_tab.dart';
import 'family_personal_tab.dart';

/// Home thành viên gia đình — 3 tab + pill nav nổi, khớp layout UserHomeScreen.
class FamilyHomeScreen extends StatefulWidget {
  const FamilyHomeScreen({
    super.key,
    this.googleUser,
    this.aiseeProfile,
    this.aiseeLoading = false,
    this.aiseeError,
    required this.onSignOut,
  });

  final GoogleSignInAccount? googleUser;
  final AiseeUserProfile? aiseeProfile;
  final bool aiseeLoading;
  final String? aiseeError;
  final VoidCallback onSignOut;

  @override
  State<FamilyHomeScreen> createState() => _FamilyHomeScreenState();
}

class _FamilyHomeScreenState extends State<FamilyHomeScreen>
    with SingleTickerProviderStateMixin {
  int _tabIndex = 0;
  late final AnimationController _tabFade;
  AiseeChatSocket? _chatSocket;

  /// Tăng mỗi khi tab Gia đình tải lại danh sách — tab Tin nhắn lắng nghe để đồng bộ.
  final ValueNotifier<int> _familyRosterVersion = ValueNotifier<int>(0);

  static const List<String> _tabTitles = ['Gia đình', 'Tin nhắn', 'Cá nhân'];

  @override
  void initState() {
    super.initState();
    _tabFade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      value: 1.0,
    );
    final AiseeCallInfo? pending =
        AiseePushService.instance.consumePendingCall();
    if (pending != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || CallScreen.openRouteCount > 0) return;
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute<void>(
            fullscreenDialog: true,
            builder: (_) => CallScreen(callInfo: pending),
          ),
        );
      });
    }
    _initSocket();
  }

  Future<void> _initSocket() async {
    final stored = await AiseeSessionStore.instance.read();
    if (stored == null || !mounted) return;
    _chatSocket = AiseeChatSocket();
    unawaited(_chatSocket!.connect(stored.accessToken));
    if (mounted) setState(() {});
  }

  void _onTabChanged(int index) {
    if (index == _tabIndex) return;
    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.click);
    _tabFade.reverse().then((_) {
      if (!mounted) return;
      setState(() => _tabIndex = index);
      _tabFade.forward();
    });
  }

  @override
  void dispose() {
    _familyRosterVersion.dispose();
    _tabFade.dispose();
    _chatSocket?.dispose();
    super.dispose();
  }

  Widget _buildAppBarTitle() {
    return Row(
      children: [
        Expanded(
          child: Text(
            _tabTitles[_tabIndex],
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              height: 1,
              letterSpacing: -0.5,
              color: StyleTokens.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const AppWordmark(fontSize: 15),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.aiseeLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final profile = widget.aiseeProfile;
    if (profile == null) {
      return Scaffold(
        body: Center(
          child: Text(
            widget.aiseeError ?? 'Không tải được thông tin',
            style: StyleTokens.bodySmall(),
          ),
        ),
      );
    }

    final double bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: StyleTokens.background,
      extendBody: true,
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: 20,
        toolbarHeight: 48,
        scrolledUnderElevation: 0,
        title: _buildAppBarTitle(),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 8,
              bottom: 112 + bottomInset,
            ),
            child: FadeTransition(
              opacity: _tabFade,
              child: IndexedStack(
                index: _tabIndex,
                children: [
                  FamilyContactsTab(
                    onFamilyListChanged: () {
                      _familyRosterVersion.value++;
                    },
                  ),
                  FamilyMessagesTab(
                    currentUserId: profile.id,
                    chatSocket: _chatSocket ?? AiseeChatSocket(),
                    familyRosterVersion: _familyRosterVersion,
                    messagesTabActive: _tabIndex == 1,
                  ),
                  FamilyPersonalTab(
                    profile: profile,
                    onSignOut: widget.onSignOut,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16 + bottomInset,
            child: UserLowVisionBottomNav(
              currentIndex: _tabIndex,
              onChanged: _onTabChanged,
              items: UserLowVisionBottomNav.familyItems,
            ),
          ),
        ],
      ),
    );
  }
}
