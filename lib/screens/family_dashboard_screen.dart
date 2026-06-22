// lib/screens/family_dashboard_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../generated/l10n/app_localizations.dart';
import '../models/aisee_dashboard_models.dart';
import '../models/aisee_family_member.dart';
import '../services/aisee_analytics_service.dart';
import '../services/aisee_dashboard_service.dart';
import '../services/aisee_family_context_store.dart';
import '../theme/style_tokens.dart';
import '../theme/aisee_typography.dart';
import '../utils/app_toast.dart';
import '../widgets/app_wordmark.dart';
import '../widgets/user_low_vision_bottom_nav.dart';
import 'family_care_tab.dart';
import 'family_dashboard_audit_tab.dart';
import 'family_dashboard_location_tab.dart';
import 'family_dashboard_nav_items.dart';

class FamilyDashboardScreen extends StatefulWidget {
  const FamilyDashboardScreen({
    required this.accessToken,
    required this.member,
    super.key,
  });

  final String accessToken;
  final AiseeFamilyMember member;

  @override
  State<FamilyDashboardScreen> createState() => _FamilyDashboardScreenState();
}

class _FamilyDashboardScreenState extends State<FamilyDashboardScreen>
    with SingleTickerProviderStateMixin {
  final _dashService = AiseeDashboardService();
  int _currentTab = 0;
  late final TabController _tabController;

  List<AuditLogEntry> _logs = [];
  UserLocation? _location;

  bool _loadingLogs = true;
  bool _loadingLocation = true;

  AppLocalizations get l10n => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();
    unawaited(
      AiseeFamilyContextStore.instance.writeLastCaredUserId(widget.member.id),
    );
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!mounted) return;
      if (_currentTab != _tabController.index) {
        setState(() => _currentTab = _tabController.index);
        unawaited(
          AiseeAnalyticsService.instance.trackScreen(
            'family_dashboard_${familyDashboardNavItems[_currentTab].label}',
          ),
        );
      }
    });
    unawaited(AiseeAnalyticsService.instance.trackScreen('family_dashboard'));
    unawaited(
      AiseeAnalyticsService.instance.trackOnce(
        AiseeAnalyticsEvent.firstFamilyDashboardViewed,
        parameters: <String, Object?>{'member_id': widget.member.id},
        key:
            '${AiseeAnalyticsEvent.firstFamilyDashboardViewed}.${widget.member.id}',
      ),
    );
    _loadAll();
  }

  @override
  void dispose() {
    _dashService.close();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    await Future.wait([
      _loadLogs(),
      _loadLocation(),
    ]);
  }

  Future<void> _loadLogs() async {
    setState(() => _loadingLogs = true);
    try {
      final logs = await _dashService.getAuditLog(
        widget.accessToken,
        widget.member.id,
      );
      if (!mounted) return;
      setState(() {
        _logs = logs;
        _loadingLogs = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingLogs = false);
    }
  }

  Future<void> _loadLocation() async {
    setState(() => _loadingLocation = true);
    try {
      final loc = await _dashService.getLocation(
        widget.accessToken,
        widget.member.id,
      );
      if (!mounted) return;
      setState(() {
        _location = loc;
        _loadingLocation = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: StyleTokens.background,
      appBar: AppBar(
        backgroundColor: StyleTokens.background,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    familyDashboardNavItemsLocalized(l10n)[_currentTab].label,
                    style: aiseeTextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1,
                      letterSpacing: -0.5,
                      color: StyleTokens.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.member.label,
                    style: aiseeTextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: StyleTokens.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const AppWordmark(fontSize: 15),
          ],
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 90 + bottomInset),
            child: TabBarView(
              controller: _tabController,
              children: [
                FamilyCareTab(
                  accessToken: widget.accessToken,
                  caredUserId: widget.member.id,
                ),
                FamilyDashboardAuditTab(
                  loading: _loadingLogs,
                  logs: _logs,
                  onRefresh: _loadLogs,
                  onLogTap: (log) => showFamilyDashboardLogDetail(context, log),
                ),
                FamilyDashboardLocationTab(
                  loading: _loadingLocation,
                  location: _location,
                  onRefresh: _loadLocation,
                  onOpenMaps: _openMaps,
                ),
              ],
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16 + bottomInset,
            child: UserLowVisionBottomNav(
              currentIndex: _currentTab,
              onChanged: (i) {
                _tabController.animateTo(i);
              },
              items: familyDashboardNavItemsLocalized(
                AppLocalizations.of(context),
              ),
              showLabel: false,
            ),
          ),
        ],
      ),
      floatingActionButton: null,
    );
  }

  Future<void> _openMaps(double lat, double lng) async {
    final Uri uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    try {
      final bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        AppToast.show(l10n.familyDashboardCannotOpenMaps, isError: true);
      }
    } catch (_) {
      if (mounted) {
        AppToast.show(l10n.familyDashboardCannotOpenAppMaps, isError: true);
      }
    }
  }
}
