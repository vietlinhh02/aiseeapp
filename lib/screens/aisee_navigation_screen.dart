/// Màn hình overlay toàn màn hình khi đang chỉ đường đi bộ trong app.
///
/// Hiển thị:
/// - Tên đích đến (lớn, dễ đọc)
/// - Quãng đường còn lại
/// - Bước tiếp theo (tiếng Việt)
/// - Thanh tiến trình
/// - Nút "Dừng chỉ đường" lớn
///
/// Được show/hide qua device command `show_navigation_screen` /
/// `hide_navigation_screen` từ Python agent.
library;

import 'package:flutter/material.dart';

class NavigationScreenData {
  const NavigationScreenData({
    required this.destinationName,
    required this.destinationQuery,
    required this.totalDistanceM,
    required this.totalDurationS,
    required this.totalSteps,
    required this.currentStepIndex,
    required this.currentStepName,
    required this.currentStepVoiceVi,
    required this.remainingDistanceM,
    required this.progressPct,
    required this.isDeviated,
    required this.isCompleted,
    required this.outcome,
  });

  final String destinationName;
  final String destinationQuery;
  final double totalDistanceM;
  final double totalDurationS;
  final int totalSteps;
  final int currentStepIndex;
  final String currentStepName;
  final String currentStepVoiceVi;
  final double remainingDistanceM;
  final double progressPct;
  final bool isDeviated;
  final bool isCompleted;
  final String outcome;
}

class AiseeNavigationScreen extends StatefulWidget {
  const AiseeNavigationScreen({
    super.key,
    required this.data,
    required this.onStop,
    this.onStepAnnounced,
  });

  final NavigationScreenData data;
  final Future<void> Function() onStop;
  final VoidCallback? onStepAnnounced;

  @override
  State<AiseeNavigationScreen> createState() => _AiseeNavigationScreenState();
}

class _AiseeNavigationScreenState extends State<AiseeNavigationScreen> {
  bool _stopping = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onStepAnnounced?.call();
    });
  }

  @override
  void didUpdateWidget(covariant AiseeNavigationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data.currentStepIndex != widget.data.currentStepIndex ||
        oldWidget.data.isDeviated != widget.data.isDeviated) {
      widget.onStepAnnounced?.call();
    }
  }

  Future<void> _handleStop() async {
    if (_stopping) return;
    setState(() => _stopping = true);
    try {
      await widget.onStop();
    } finally {
      if (mounted) setState(() => _stopping = false);
    }
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.toStringAsFixed(0)} m';
    return '${(meters / 1000).toStringAsFixed(2)} km';
  }

  @override
  Widget build(BuildContext context) {
    final NavigationScreenData d = widget.data;

    return Material(
      color: const Color(0xFF0F172A),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // ── Header: destination name (big) ──
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Đang chỉ đường đến',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    d.destinationName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── Stats row ──
              Row(
                children: <Widget>[
                  Expanded(
                    child: _StatTile(
                      label: 'Còn lại',
                      value: _formatDistance(d.remainingDistanceM),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatTile(
                      label: 'Bước',
                      value:
                          '${d.currentStepIndex.clamp(1, d.totalSteps)} / ${d.totalSteps}',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatTile(
                      label: 'Tổng',
                      value: _formatDistance(d.totalDistanceM),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── Progress bar ──
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: d.progressPct.clamp(0.0, 1.0),
                  minHeight: 12,
                  backgroundColor: const Color(0xFF334155),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF22D3EE),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Current step card (most important — for low vision users) ──
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: d.isDeviated
                        ? const Color(0xFF7F1D1D)
                        : const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(20),
                    border: d.isDeviated
                        ? Border.all(color: const Color(0xFFFCA5A5), width: 2)
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      if (d.isDeviated) ...<Widget>[
                        const Row(
                          children: <Widget>[
                            Icon(Icons.warning_amber_rounded,
                                color: Color(0xFFFCA5A5), size: 28),
                            SizedBox(width: 8),
                            Text(
                              'Có vẻ bạn đang đi lệch',
                              style: TextStyle(
                                color: Color(0xFFFCA5A5),
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                      Text(
                        d.currentStepVoiceVi.isEmpty
                            ? 'Đang đợi bước tiếp theo…'
                            : d.currentStepVoiceVi,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                      if (d.currentStepName.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 12),
                        Text(
                          'trên ${d.currentStepName}',
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Stop button (big, easy to tap) ──
              SizedBox(
                height: 72,
                child: FilledButton.icon(
                  onPressed: _stopping ? null : _handleStop,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    disabledBackgroundColor: const Color(0xFF7F1D1D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: _stopping
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Icon(Icons.stop_circle_outlined, size: 32),
                  label: Text(
                    _stopping ? 'Đang dừng…' : 'DỪNG CHỈ ĐƯỜNG',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
