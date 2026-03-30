// lib/screens/family_messages_tab.dart
import 'package:flutter/material.dart';
import '../models/aisee_family_member.dart';
import '../services/aisee_chat_service.dart';
import '../services/aisee_chat_socket.dart';
import '../services/aisee_family_service.dart';
import '../services/aisee_session_store.dart';
import '../theme/style_tokens.dart';
import 'chat_detail_screen.dart';

class FamilyMessagesTab extends StatefulWidget {
  const FamilyMessagesTab({
    required this.currentUserId,
    required this.chatSocket,
    super.key,
  });

  final String currentUserId;
  final AiseeChatSocket chatSocket;

  @override
  State<FamilyMessagesTab> createState() => _FamilyMessagesTabState();
}

class _FamilyMessagesTabState extends State<FamilyMessagesTab> {
  final _familyService = AiseeFamilyService();
  final _chatService = AiseeChatService();
  List<AiseeFamilyMember> _members = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _familyService.close();
    _chatService.close();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final stored = await AiseeSessionStore.instance.read();
      if (stored == null) return;
      final members = await _familyService.fetchFamily(
        stored.accessToken,
      );
      if (!mounted) return;
      setState(() { _members = members; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
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
          children: [
            Text(_error!, style: StyleTokens.bodySmall()),
            const SizedBox(height: 12),
            TextButton(onPressed: _load,
                child: const Text('Thu lai')),
          ],
        ),
      );
    }
    if (_members.isEmpty) {
      return Center(
        child: Text('Chua co nguoi than de nhan tin',
            style: StyleTokens.bodySmall()),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _members.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final member = _members[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: StyleTokens.buttonPrimary.withAlpha(26),
              child: Text(member.label[0].toUpperCase(),
                  style: TextStyle(color: StyleTokens.buttonPrimary,
                      fontWeight: FontWeight.w700)),
            ),
            title: Text(member.label,
                style: StyleTokens.bodySmall().copyWith(
                    fontWeight: FontWeight.w600, fontSize: 15)),
            trailing: const Icon(Icons.chat_bubble_outline),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            tileColor: Colors.white,
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => ChatDetailScreen(
                  contact: member,
                  currentUserId: widget.currentUserId,
                  chatSocket: widget.chatSocket,
                ),
              ));
            },
          );
        },
      ),
    );
  }
}
