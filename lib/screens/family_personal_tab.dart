import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

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
  final AiseeVolunteerService _volunteerService = AiseeVolunteerService();
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
    final AiseeAuthTokens? stored = await AiseeSessionStore.instance.read();
    return stored?.accessToken;
  }

  Future<void> _register() async {
    HapticFeedback.lightImpact();
    setState(() => _registering = true);
    try {
      final String? token = await _token();
      if (token == null) return;
      await _volunteerService.register(token);
      if (!mounted) return;
      setState(() {
        _isVolunteer = true;
        _available = true;
      });
      AppToast.show('Đã đăng ký tình nguyện viên');
    } catch (e) {
      if (!mounted) return;
      AppToast.show(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _registering = false);
    }
  }

  Future<void> _toggleAvailability(bool value) async {
    HapticFeedback.lightImpact();
    setState(() => _toggling = true);
    try {
      final String? token = await _token();
      if (token == null) return;
      await _volunteerService.setAvailability(token, available: value);
      if (!mounted) return;
      setState(() => _available = value);
    } catch (e) {
      if (!mounted) return;
      AppToast.show(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final DateTime dt = DateTime.parse(iso);
      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String joinDate = _formatDate(widget.profile.createdAt);
    return Semantics(
      container: true,
      label: 'Cá nhân. Thông tin tài khoản và tình nguyện viên.',
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          Text(
            'Thông tin tài khoản và đăng ký hỗ trợ của bạn.',
            style: StyleTokens.bodySmall().copyWith(
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          _InfoCard(
            iconAsset: 'assets/icons/nav/ic_profile.svg',
            title: 'Email',
            subtitle: widget.profile.email,
          ),
          const SizedBox(height: 10),
          _InfoCard(
            iconAsset: 'assets/icons/nav/ic_3user.svg',
            title: 'Vai trò',
            subtitle: 'Người hỗ trợ',
          ),
          if (joinDate.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            _InfoCard(
              iconAsset: 'assets/icons/nav/ic_calendar.svg',
              title: 'Ngày tham gia',
              subtitle: joinDate,
            ),
          ],
          const SizedBox(height: 10),
          _VolunteerCard(
            isVolunteer: _isVolunteer,
            available: _available,
            registering: _registering,
            toggling: _toggling,
            onRegister: _register,
            onToggle: _toggleAvailability,
          ),
          const SizedBox(height: 32),
          _buildSignOutButton(),
        ],
      ),
    );
  }

  Widget _buildSignOutButton() {
    return Semantics(
      button: true,
      label: 'Đăng xuất khỏi AiSee',
      child: Material(
        color: StyleTokens.buttonPrimary,
        borderRadius: BorderRadius.circular(31),
        child: InkWell(
          borderRadius: BorderRadius.circular(31),
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onSignOut();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                'Đăng xuất',
                style: StyleTokens.socialLabel().copyWith(fontSize: 14),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Static info card — no tap action, no arrow.
class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.iconAsset,
    required this.title,
    required this.subtitle,
  });

  final String iconAsset;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: StyleTokens.surfaceCard,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: StyleTokens.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: SvgPicture.asset(
                  iconAsset,
                  width: 20,
                  height: 20,
                  colorFilter: const ColorFilter.mode(
                    StyleTokens.buttonPrimary,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: StyleTokens.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: StyleTokens.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Volunteer card — shows registration button or availability toggle.
class _VolunteerCard extends StatelessWidget {
  const _VolunteerCard({
    required this.isVolunteer,
    required this.available,
    required this.registering,
    required this.toggling,
    required this.onRegister,
    required this.onToggle,
  });

  final bool isVolunteer;
  final bool available;
  final bool registering;
  final bool toggling;
  final VoidCallback onRegister;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: StyleTokens.surfaceCard,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: StyleTokens.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/icons/nav/ic_3user.svg',
                      width: 20,
                      height: 20,
                      colorFilter: const ColorFilter.mode(
                        StyleTokens.buttonPrimary,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Tình nguyện viên',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: StyleTokens.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Hỗ trợ người khiếm thị khi người thân không thể trả lời',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: StyleTokens.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!isVolunteer)
              _RegisterButton(registering: registering, onRegister: onRegister)
            else
              _AvailabilityToggle(
                available: available,
                toggling: toggling,
                onToggle: onToggle,
              ),
          ],
        ),
      ),
    );
  }
}

class _RegisterButton extends StatelessWidget {
  const _RegisterButton({
    required this.registering,
    required this.onRegister,
  });

  final bool registering;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Đăng ký tình nguyện viên',
      child: Material(
        color: StyleTokens.buttonPrimary,
        borderRadius: BorderRadius.circular(31),
        child: InkWell(
          borderRadius: BorderRadius.circular(31),
          onTap: registering ? null : onRegister,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 13),
            child: Center(
              child: registering
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Đăng ký tình nguyện viên',
                      style: StyleTokens.socialLabel().copyWith(fontSize: 14),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AvailabilityToggle extends StatelessWidget {
  const _AvailabilityToggle({
    required this.available,
    required this.toggling,
    required this.onToggle,
  });

  final bool available;
  final bool toggling;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Sẵn sàng hỗ trợ',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: StyleTokens.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                available
                    ? 'Bạn sẽ nhận cuộc gọi hỗ trợ'
                    : 'Tạm nghỉ, không nhận cuộc gọi',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: StyleTokens.textMuted,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: available,
          onChanged: toggling ? null : onToggle,
          activeThumbColor: StyleTokens.buttonPrimary,
        ),
      ],
    );
  }
}
