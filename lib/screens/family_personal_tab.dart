// lib/screens/family_personal_tab.dart
import 'package:flutter/material.dart';
import '../models/aisee_api_models.dart';
import '../services/aisee_session_store.dart';
import '../services/aisee_volunteer_service.dart';
import '../theme/style_tokens.dart';
import '../utils/app_toast.dart';

class FamilyPersonalTab extends StatefulWidget {
  const FamilyPersonalTab({
    required this.profile,
    required this.onSignOut,
    super.key,
  });

  final AiseeUserProfile profile;
  final VoidCallback onSignOut;

  @override
  State<FamilyPersonalTab> createState() => _FamilyPersonalTabState();
}

class _FamilyPersonalTabState extends State<FamilyPersonalTab> {
  final _volunteerService = AiseeVolunteerService();
  late bool _isVolunteer;
  bool _available = false;
  bool _registering = false;
  bool _toggling = false;

  @override
  void initState() {
    super.initState();
    _isVolunteer = widget.profile.isVolunteer;
  }

  @override
  void dispose() {
    _volunteerService.close();
    super.dispose();
  }

  Future<String?> _token() async {
    final stored = await AiseeSessionStore.instance.read();
    return stored?.accessToken;
  }

  Future<void> _register() async {
    setState(() => _registering = true);
    try {
      final token = await _token();
      if (token == null) return;
      await _volunteerService.register(token);
      if (!mounted) return;
      setState(() { _isVolunteer = true; _available = true; });
      AppToast.show('Da dang ky tinh nguyen vien');
    } catch (e) {
      if (!mounted) return;
      AppToast.show(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _registering = false);
    }
  }

  Future<void> _toggleAvailability(bool value) async {
    setState(() => _toggling = true);
    try {
      final token = await _token();
      if (token == null) return;
      await _volunteerService.setAvailability(
        token, available: value,
      );
      if (!mounted) return;
      setState(() => _available = value);
    } catch (e) {
      if (!mounted) return;
      AppToast.show(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Profile card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: StyleTokens.buttonPrimary.withAlpha(26),
              child: Text(
                (widget.profile.displayName ?? widget.profile.email)
                    [0].toUpperCase(),
                style: TextStyle(fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: StyleTokens.buttonPrimary),
              ),
            ),
            const SizedBox(height: 12),
            Text(widget.profile.displayName ?? '',
                style: StyleTokens.titleScreen().copyWith(fontSize: 18)),
            const SizedBox(height: 4),
            Text(widget.profile.email,
                style: StyleTokens.bodySmall()),
          ]),
        ),
        const SizedBox(height: 16),

        // Volunteer section
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tinh nguyen vien',
                  style: StyleTokens.titleScreen().copyWith(fontSize: 16)),
              const SizedBox(height: 8),
              Text('Ho tro nguoi khiem thi khi nguoi than '
                  'khong the tra loi',
                  style: StyleTokens.bodySmall()),
              const SizedBox(height: 16),
              if (!_isVolunteer)
                SizedBox(
                  width: double.infinity, height: 44,
                  child: ElevatedButton.icon(
                    onPressed: _registering ? null : _register,
                    icon: _registering
                        ? const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.volunteer_activism,
                            color: Colors.white),
                    label: const Text('Dang ky tinh nguyen vien',
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: StyleTokens.buttonPrimary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                )
              else
                SwitchListTile(
                  title: const Text('San sang ho tro'),
                  subtitle: Text(_available
                      ? 'Ban se nhan cuoc goi ho tro'
                      : 'Tam nghi, khong nhan cuoc goi'),
                  value: _available,
                  onChanged: _toggling ? null : _toggleAvailability,
                  activeThumbColor: StyleTokens.buttonPrimary,
                  contentPadding: EdgeInsets.zero,
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Sign out
        TextButton(
          onPressed: widget.onSignOut,
          child: Text('Dang xuat',
              style: StyleTokens.bodySmall().copyWith(
                  color: Colors.red, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
