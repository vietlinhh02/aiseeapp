// lib/screens/family_contacts_tab.dart
import 'package:flutter/material.dart';
import '../models/aisee_family_member.dart';
import '../services/aisee_family_service.dart';
import '../services/aisee_session_store.dart';
import '../theme/style_tokens.dart';
import '../utils/app_toast.dart';
import 'family_dashboard_screen.dart';

class FamilyContactsTab extends StatefulWidget {
  const FamilyContactsTab({super.key});

  @override
  State<FamilyContactsTab> createState() => _FamilyContactsTabState();
}

class _FamilyContactsTabState extends State<FamilyContactsTab> {
  final _familyService = AiseeFamilyService();
  List<AiseeFamilyMember> _members = [];
  bool _loading = true;
  String? _error;

  final _codeController = TextEditingController();
  bool _joining = false;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _familyService.close();
    super.dispose();
  }

  Future<String?> _token() async {
    final stored = await AiseeSessionStore.instance.read();
    return stored?.accessToken;
  }

  Future<void> _loadMembers() async {
    setState(() { _loading = true; _error = null; });
    try {
      final token = await _token();
      if (token == null) return;
      final members = await _familyService.fetchFamily(token);
      if (!mounted) return;
      setState(() { _members = members; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _joinFamily() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;
    setState(() => _joining = true);
    try {
      final token = await _token();
      if (token == null) return;
      await _familyService.joinFamily(token, code);
      _codeController.clear();
      if (!mounted) return;
      AppToast.show('Đã tham gia gia đình');
      await _loadMembers();
    } catch (e) {
      if (!mounted) return;
      AppToast.show(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _joining = false);
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
            TextButton(onPressed: _loadMembers,
                child: const Text('Thử lại')),
          ],
        ),
      );
    }
    if (_members.isEmpty) return _buildJoinView();
    return _buildMemberList();
  }

  Widget _buildJoinView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.family_restroom, size: 64,
              color: StyleTokens.textPrimary.withAlpha(77)),
          const SizedBox(height: 16),
          Text('Chưa có người thân nào',
              style: StyleTokens.titleScreen().copyWith(fontSize: 18)),
          const SizedBox(height: 8),
          Text('Nhập mã mời để tham gia gia đình',
              style: StyleTokens.bodySmall()),
          const SizedBox(height: 24),
          TextField(
            controller: _codeController,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: 'Nhập mã mời',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity, height: 48,
            child: ElevatedButton(
              onPressed: _joining ? null : _joinFamily,
              style: ElevatedButton.styleFrom(
                backgroundColor: StyleTokens.buttonPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _joining
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Tham gia gia đình',
                      style: TextStyle(color: Colors.white,
                          fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberList() {
    return RefreshIndicator(
      onRefresh: _loadMembers,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _members.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
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
            subtitle: Text(member.email,
                style: StyleTokens.bodySmall().copyWith(fontSize: 12)),
            trailing: const Icon(Icons.chevron_right),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            tileColor: Colors.white,
            onTap: () async {
              final token = await _token();
              if (token == null || !mounted) return;
              if (!context.mounted) return;
              Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => FamilyDashboardScreen(
                  accessToken: token, member: member,
                ),
              ));
            },
          );
        },
      ),
    );
  }
}
