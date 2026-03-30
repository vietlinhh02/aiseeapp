// lib/screens/family_home_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/aisee_api_models.dart';
import '../services/aisee_chat_socket.dart';
import '../services/aisee_session_store.dart';
import '../theme/style_tokens.dart';
import 'family_contacts_tab.dart';
import 'family_messages_tab.dart';
import 'family_personal_tab.dart';

class FamilyHomeScreen extends StatefulWidget {
  const FamilyHomeScreen({
    this.googleUser,
    this.aiseeProfile,
    this.aiseeLoading = false,
    this.aiseeError,
    required this.onSignOut,
    super.key,
  });

  final GoogleSignInAccount? googleUser;
  final AiseeUserProfile? aiseeProfile;
  final bool aiseeLoading;
  final String? aiseeError;
  final VoidCallback onSignOut;

  @override
  State<FamilyHomeScreen> createState() => _FamilyHomeScreenState();
}

class _FamilyHomeScreenState extends State<FamilyHomeScreen> {
  int _tabIndex = 0;
  AiseeChatSocket? _chatSocket;

  @override
  void initState() {
    super.initState();
    _initSocket();
  }

  Future<void> _initSocket() async {
    final stored = await AiseeSessionStore.instance.read();
    if (stored == null || !mounted) return;
    _chatSocket = AiseeChatSocket();
    unawaited(_chatSocket!.connect(stored.accessToken));
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _chatSocket?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.aiseeLoading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }
    final profile = widget.aiseeProfile;
    if (profile == null) {
      return Scaffold(
        body: Center(
          child: Text(widget.aiseeError ?? 'Khong tai duoc thong tin',
              style: StyleTokens.bodySmall()),
        ),
      );
    }

    return Scaffold(
      backgroundColor: StyleTokens.background,
      body: SafeArea(
        child: IndexedStack(
          index: _tabIndex,
          children: [
            const FamilyContactsTab(),
            FamilyMessagesTab(
              currentUserId: profile.id,
              chatSocket: _chatSocket ?? AiseeChatSocket(),
            ),
            FamilyPersonalTab(
              profile: profile,
              onSignOut: widget.onSignOut,
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (i) => setState(() => _tabIndex = i),
        selectedItemColor: StyleTokens.buttonPrimary,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.family_restroom),
              label: 'Gia dinh'),
          BottomNavigationBarItem(
              icon: Icon(Icons.chat),
              label: 'Tin nhan'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Ca nhan'),
        ],
      ),
    );
  }
}
