// lib/screens/family_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/aisee_dashboard_models.dart';
import '../models/aisee_family_member.dart';
import '../services/aisee_dashboard_service.dart';
import '../theme/style_tokens.dart';
import '../utils/app_toast.dart';

class FamilyDashboardScreen extends StatefulWidget {
  const FamilyDashboardScreen({
    required this.accessToken,
    required this.member,
    super.key,
  });

  final String accessToken;
  final AiseeFamilyMember member;

  @override
  State<FamilyDashboardScreen> createState() =>
      _FamilyDashboardScreenState();
}

class _FamilyDashboardScreenState extends State<FamilyDashboardScreen> {
  final _dashService = AiseeDashboardService();
  int _currentTab = 0;

  DashboardHealth? _health;
  List<MedStatus> _meds = [];
  List<AuditLogEntry> _logs = [];
  UserLocation? _location;

  bool _loadingHealth = true;
  bool _loadingMeds = true;
  bool _loadingLogs = true;
  bool _loadingLocation = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _dashService.close();
    super.dispose();
  }

  Future<void> _loadAll() async {
    await Future.wait([
      _loadHealth(),
      _loadMeds(),
      _loadLogs(),
      _loadLocation(),
    ]);
  }

  Future<void> _loadHealth() async {
    setState(() => _loadingHealth = true);
    try {
      final health = await _dashService.getHealth(
        widget.accessToken, widget.member.id,
      );
      if (!mounted) return;
      setState(() { _health = health; _loadingHealth = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingHealth = false);
    }
  }

  Future<void> _loadMeds() async {
    setState(() => _loadingMeds = true);
    try {
      final meds = await _dashService.getMedications(
        widget.accessToken, widget.member.id,
      );
      if (!mounted) return;
      setState(() { _meds = meds; _loadingMeds = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingMeds = false);
    }
  }

  Future<void> _loadLogs() async {
    setState(() => _loadingLogs = true);
    try {
      final logs = await _dashService.getAuditLog(
        widget.accessToken, widget.member.id,
      );
      if (!mounted) return;
      setState(() { _logs = logs; _loadingLogs = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingLogs = false);
    }
  }

  Future<void> _loadLocation() async {
    setState(() => _loadingLocation = true);
    try {
      final loc = await _dashService.getLocation(
        widget.accessToken, widget.member.id,
      );
      if (!mounted) return;
      setState(() { _location = loc; _loadingLocation = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: StyleTokens.background,
        appBar: AppBar(
          backgroundColor: StyleTokens.background,
          elevation: 0,
          centerTitle: false,
          title: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage(
                  'https://api.dicebear.com/9.x/notionists/png'
                  '?seed=${Uri.encodeComponent(widget.member.id)}'
                  '&size=96&backgroundColor=e8e8e8',
                ),
              ),
              const SizedBox(width: 10),
              Text(
                widget.member.label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: StyleTokens.textPrimary,
                ),
              ),
            ],
          ),
          bottom: TabBar(
            isScrollable: true,
            onTap: (i) => setState(() => _currentTab = i),
            labelColor: StyleTokens.buttonPrimary,
            unselectedLabelColor: StyleTokens.textMuted,
            indicatorColor: StyleTokens.buttonPrimary,
            labelStyle: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            tabs: const [
              Tab(text: 'Sức khỏe'),
              Tab(text: 'Thuốc'),
              Tab(text: 'Hoạt động'),
              Tab(text: 'Vị trí'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildHealthTab(),
            _buildMedsTab(),
            _buildAuditTab(),
            _buildLocationTab(),
          ],
        ),
        floatingActionButton: _currentTab == 1
            ? FloatingActionButton(
                backgroundColor: StyleTokens.buttonPrimary,
                onPressed: _showAddMedDialog,
                child: const Icon(Icons.add, color: Colors.white),
              )
            : null,
      ),
    );
  }

  // --- Health tab ---

  Widget _buildHealthTab() {
    if (_loadingHealth) {
      return const Center(child: CircularProgressIndicator());
    }
    final h = _health;
    if (h == null) return const Center(child: Text('Không có dữ liệu'));
    return RefreshIndicator(
      onRefresh: _loadHealth,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('Thuốc hôm nay'),
          if (h.medications.isEmpty)
            _emptyCard('Chưa có thuốc nào')
          else
            ...h.medications.map(_buildMedAdherenceCard),
          const SizedBox(height: 16),
          _sectionTitle('Triệu chứng gần đây'),
          if (h.recentSymptoms.isEmpty)
            _emptyCard('Không có triệu chứng')
          else
            ...h.recentSymptoms.map(_buildSymptomCard),
          const SizedBox(height: 16),
          _sectionTitle('Chỉ số sức khỏe'),
          if (h.recentMetrics.isEmpty)
            _emptyCard('Không có chỉ số')
          else
            ...h.recentMetrics.map(_buildMetricCard),
        ],
      ),
    );
  }

  Widget _buildMedAdherenceCard(MedWithAdherence m) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: StyleTokens.surfaceCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            m.takenToday ? Icons.check_circle : Icons.circle_outlined,
            color: m.takenToday ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.medication.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: StyleTokens.textPrimary,
                  ),
                ),
                Text(
                  '${m.medication.dosage} - ${m.medication.times.join(", ")}',
                  style: StyleTokens.bodySmall(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSymptomCard(HealthSymptom s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: StyleTokens.surfaceCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.healing, color: Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.symptom,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: StyleTokens.textPrimary,
                  ),
                ),
                Text(
                  [if (s.severity != null) s.severity!, _formatTime(s.loggedAt)]
                      .join(' - '),
                  style: StyleTokens.bodySmall(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(HealthMetric m) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: StyleTokens.surfaceCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.monitor_heart, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${m.metricType}: ${m.value} ${m.unit ?? ""}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: StyleTokens.textPrimary,
                  ),
                ),
                Text(_formatTime(m.loggedAt), style: StyleTokens.bodySmall()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Medications tab ---

  Widget _buildMedsTab() {
    if (_loadingMeds) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_meds.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadMeds,
        child: ListView(
          children: [
            const SizedBox(height: 200),
            Center(
              child: Text(
                'Chưa có thuốc nào',
                style: StyleTokens.bodySmall(),
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadMeds,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _meds.length,
        itemBuilder: (context, index) {
          final m = _meds[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: StyleTokens.surfaceCard,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  m.taken
                      ? Icons.check_circle
                      : m.skipped
                          ? Icons.cancel
                          : Icons.circle_outlined,
                  color: m.taken
                      ? Colors.green
                      : m.skipped
                          ? Colors.red
                          : Colors.grey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.medication.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: StyleTokens.textPrimary,
                        ),
                      ),
                      Text(
                        '${m.medication.dosage} - '
                        '${m.medication.times.join(", ")}',
                        style: StyleTokens.bodySmall(),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (action) => _onMedAction(action, m.medication),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Sửa')),
                    PopupMenuItem(value: 'delete', child: Text('Xóa')),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _onMedAction(
    String action, DashboardMedication med,
  ) async {
    if (action == 'delete') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(
            'Xóa thuốc',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
          ),
          content: Text(
            'Bạn có chắc muốn xóa ${med.name}?',
            style: GoogleFonts.plusJakartaSans(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xóa', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
      if (confirm != true) return;
      try {
        await _dashService.deleteMedication(
          widget.accessToken, widget.member.id, med.id,
        );
        await _loadMeds();
        if (mounted) AppToast.show('Đã xóa ${med.name}');
      } catch (e) {
        if (mounted) AppToast.show(e.toString(), isError: true);
      }
    } else if (action == 'edit') {
      _showEditMedDialog(med);
    }
  }

  Future<void> _showAddMedDialog() async {
    final result = await _showMedForm();
    if (result == null) return;
    try {
      await _dashService.createMedication(
        widget.accessToken, widget.member.id,
        name: result['name']!,
        dosage: result['dosage']!,
        times: result['times']!.split(',').map((e) => e.trim()).toList(),
        frequency: result['frequency'] ?? 'daily',
      );
      await _loadMeds();
      if (mounted) AppToast.show('Đã thêm thuốc');
    } catch (e) {
      if (mounted) AppToast.show(e.toString(), isError: true);
    }
  }

  Future<void> _showEditMedDialog(DashboardMedication med) async {
    final result = await _showMedForm(
      name: med.name,
      dosage: med.dosage,
      times: med.times.join(', '),
      frequency: med.frequency,
    );
    if (result == null) return;
    try {
      await _dashService.updateMedication(
        widget.accessToken, widget.member.id, med.id,
        name: result['name']!,
        dosage: result['dosage']!,
        times: result['times']!.split(',').map((e) => e.trim()).toList(),
        frequency: result['frequency'] ?? 'daily',
      );
      await _loadMeds();
      if (mounted) AppToast.show('Đã cập nhật thuốc');
    } catch (e) {
      if (mounted) AppToast.show(e.toString(), isError: true);
    }
  }

  Future<Map<String, String>?> _showMedForm({
    String name = '', String dosage = '',
    String times = '', String frequency = 'daily',
  }) {
    final nameC = TextEditingController(text: name);
    final dosageC = TextEditingController(text: dosage);
    final timesC = TextEditingController(text: times);
    final freqC = TextEditingController(text: frequency);

    return showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: StyleTokens.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              name.isEmpty ? 'Thêm thuốc' : 'Sửa thuốc',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: StyleTokens.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: nameC,
              style: GoogleFonts.plusJakartaSans(),
              decoration: InputDecoration(
                labelText: 'Tên thuốc',
                labelStyle: GoogleFonts.plusJakartaSans(
                  color: StyleTokens.textMuted,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: dosageC,
              style: GoogleFonts.plusJakartaSans(),
              decoration: InputDecoration(
                labelText: 'Liều lượng',
                labelStyle: GoogleFonts.plusJakartaSans(
                  color: StyleTokens.textMuted,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: timesC,
              style: GoogleFonts.plusJakartaSans(),
              decoration: InputDecoration(
                labelText: 'Giờ uống (VD: 07:00, 21:00)',
                labelStyle: GoogleFonts.plusJakartaSans(
                  color: StyleTokens.textMuted,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: freqC,
              style: GoogleFonts.plusJakartaSans(),
              decoration: InputDecoration(
                labelText: 'Tần suất (daily)',
                labelStyle: GoogleFonts.plusJakartaSans(
                  color: StyleTokens.textMuted,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      'Hủy',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: StyleTokens.buttonPrimary,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      if (nameC.text.trim().isEmpty) return;
                      Navigator.pop(ctx, {
                        'name': nameC.text.trim(),
                        'dosage': dosageC.text.trim(),
                        'times': timesC.text.trim(),
                        'frequency': freqC.text.trim(),
                      });
                    },
                    child: Text(
                      'Lưu',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).then((result) {
      nameC.dispose();
      dosageC.dispose();
      timesC.dispose();
      freqC.dispose();
      return result;
    });
  }

  // --- Audit log tab ---

  Widget _buildAuditTab() {
    if (_loadingLogs) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_logs.isEmpty) {
      return const Center(child: Text('Chưa có hoạt động nào'));
    }
    return RefreshIndicator(
      onRefresh: _loadLogs,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _logs.length,
        itemBuilder: (context, index) {
          final log = _logs[index];
          return GestureDetector(
            onTap: () => _showLogDetail(log),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: StyleTokens.surfaceCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _auditIcon(log.toolName),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          log.toolLabel,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: StyleTokens.textPrimary,
                          ),
                        ),
                        Text(
                          _formatTime(log.createdAt),
                          style: StyleTokens.bodySmall(),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: StyleTokens.textMuted,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _auditIcon(String toolName) {
    if (toolName.contains('call')) {
      return const Icon(Icons.phone, color: Colors.green);
    }
    if (toolName.contains('message')) {
      return const Icon(Icons.chat, color: Colors.blue);
    }
    if (toolName.contains('emergency') || toolName.contains('sos')) {
      return const Icon(Icons.warning, color: Colors.red);
    }
    if (toolName.contains('medication') || toolName.contains('med')) {
      return const Icon(Icons.medication, color: Colors.purple);
    }
    return const Icon(Icons.history, color: Colors.grey);
  }

  void _showLogDetail(AuditLogEntry log) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: StyleTokens.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              log.toolLabel,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: StyleTokens.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Thời gian: ${_formatTime(log.createdAt)}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: StyleTokens.textSecondary,
              ),
            ),
            if (log.params.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Chi tiết: ${log.params.entries.map(
                      (e) => '${e.key}: ${e.value}',
                    ).join(', ')}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: StyleTokens.textSecondary,
                ),
              ),
            ],
            if (log.result != null) ...[
              const SizedBox(height: 8),
              Text(
                'Kết quả: ${log.result}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: StyleTokens.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: StyleTokens.buttonPrimary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Đóng',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Location tab ---

  Widget _buildLocationTab() {
    if (_loadingLocation) {
      return const Center(child: CircularProgressIndicator());
    }
    final loc = _location;
    if (loc == null || !loc.hasLocation) {
      return const Center(child: Text('Chưa có vị trí'));
    }
    return RefreshIndicator(
      onRefresh: _loadLocation,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: StyleTokens.surfaceCard,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Icon(Icons.location_on, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text(
                  '${loc.lat!.toStringAsFixed(6)}, '
                  '${loc.lng!.toStringAsFixed(6)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: StyleTokens.textPrimary,
                  ),
                ),
                if (loc.updatedAt != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Cập nhật: ${_formatTime(loc.updatedAt!)}',
                    style: StyleTokens.bodySmall(),
                  ),
                ],
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _openMaps(loc.lat!, loc.lng!),
                  icon: const Icon(Icons.map),
                  label: const Text('Mở bản đồ'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: StyleTokens.buttonPrimary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openMaps(double lat, double lng) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // --- Helpers ---

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: StyleTokens.textPrimary,
          ),
        ),
      );

  Widget _emptyCard(String text) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: StyleTokens.surfaceCard,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(child: Text(text, style: StyleTokens.bodySmall())),
      );

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    return '${local.day}/${local.month}/${local.year} '
        '${local.hour.toString().padLeft(2, "0")}:'
        '${local.minute.toString().padLeft(2, "0")}';
  }
}
