class DashboardMedication {
  const DashboardMedication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.times,
    required this.frequency,
    this.active = true,
  });

  final String id;
  final String name;
  final String dosage;
  final List<String> times;
  final String frequency;
  final bool active;

  factory DashboardMedication.fromJson(Map<String, dynamic> j) {
    final List<dynamic> rawTimes = j['times'] as List<dynamic>? ?? [];
    return DashboardMedication(
      id: j['id'] as String,
      name: j['name'] as String? ?? '',
      dosage: j['dosage'] as String? ?? '',
      times: rawTimes.map((e) => e.toString()).toList(),
      frequency: j['frequency'] as String? ?? 'daily',
      active: j['active'] as bool? ?? true,
    );
  }
}

class MedWithAdherence {
  const MedWithAdherence({
    required this.medication,
    required this.takenToday,
  });

  final DashboardMedication medication;
  final bool takenToday;

  factory MedWithAdherence.fromJson(Map<String, dynamic> j) {
    return MedWithAdherence(
      medication: DashboardMedication.fromJson(
        j['medication'] as Map<String, dynamic>,
      ),
      takenToday: j['taken_today'] as bool? ?? false,
    );
  }
}

class MedStatus {
  const MedStatus({
    required this.medication,
    required this.taken,
    required this.skipped,
  });

  final DashboardMedication medication;
  final bool taken;
  final bool skipped;

  factory MedStatus.fromJson(Map<String, dynamic> j) {
    return MedStatus(
      medication: DashboardMedication.fromJson(
        j['medication'] as Map<String, dynamic>,
      ),
      taken: j['taken'] as bool? ?? false,
      skipped: j['skipped'] as bool? ?? false,
    );
  }
}

class HealthSymptom {
  const HealthSymptom({
    required this.id,
    required this.symptom,
    this.severity,
    this.notes,
    required this.loggedAt,
  });

  final String id;
  final String symptom;
  final String? severity;
  final String? notes;
  final DateTime loggedAt;

  factory HealthSymptom.fromJson(Map<String, dynamic> j) {
    return HealthSymptom(
      id: j['id'] as String,
      symptom: j['symptom'] as String? ?? '',
      severity: j['severity'] as String?,
      notes: j['notes'] as String?,
      loggedAt: DateTime.parse(j['logged_at'] as String),
    );
  }
}

class HealthMetric {
  const HealthMetric({
    required this.id,
    required this.metricType,
    required this.value,
    this.unit,
    required this.loggedAt,
  });

  final String id;
  final String metricType;
  final String value;
  final String? unit;
  final DateTime loggedAt;

  factory HealthMetric.fromJson(Map<String, dynamic> j) {
    return HealthMetric(
      id: j['id'] as String,
      metricType: j['metric_type'] as String? ?? '',
      value: j['value'] as String? ?? '',
      unit: j['unit'] as String?,
      loggedAt: DateTime.parse(j['logged_at'] as String),
    );
  }
}

class DashboardHealth {
  const DashboardHealth({
    required this.medications,
    required this.recentSymptoms,
    required this.recentMetrics,
  });

  final List<MedWithAdherence> medications;
  final List<HealthSymptom> recentSymptoms;
  final List<HealthMetric> recentMetrics;

  factory DashboardHealth.fromJson(Map<String, dynamic> j) {
    return DashboardHealth(
      medications: (j['medications'] as List<dynamic>? ?? [])
          .map((e) => MedWithAdherence.fromJson(e as Map<String, dynamic>))
          .toList(),
      recentSymptoms: (j['recent_symptoms'] as List<dynamic>? ?? [])
          .map((e) => HealthSymptom.fromJson(e as Map<String, dynamic>))
          .toList(),
      recentMetrics: (j['recent_metrics'] as List<dynamic>? ?? [])
          .map((e) => HealthMetric.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class AuditLogEntry {
  const AuditLogEntry({
    required this.id,
    required this.toolName,
    required this.params,
    this.result,
    required this.createdAt,
  });

  final String id;
  final String toolName;
  final Map<String, dynamic> params;
  final String? result;
  final DateTime createdAt;

  factory AuditLogEntry.fromJson(Map<String, dynamic> j) {
    return AuditLogEntry(
      id: j['id'] as String,
      toolName: j['tool_name'] as String? ?? '',
      params: j['params'] as Map<String, dynamic>? ?? {},
      result: j['result'] as String?,
      createdAt: DateTime.parse(j['created_at'] as String),
    );
  }

  String get toolLabel {
    const labels = {
      'make_voice_call': 'Gọi điện thoại',
      'make_video_call': 'Gọi video',
      'send_chat_message': 'Gửi tin nhắn',
      'emergency_alert': 'SOS khẩn cấp',
      'escalate_to_family': 'Gọi người thân',
      'escalate_to_volunteer': 'Gọi tình nguyện viên',
      'set_medication_reminder': 'Đặt nhắc thuốc',
      'mark_medication_taken': 'Đã uống thuốc',
      'mark_medication_skipped': 'Bỏ qua thuốc',
      'log_health_symptom': 'Ghi triệu chứng',
      'log_health_metric': 'Ghi chỉ số',
      'set_appointment_reminder': 'Đặt lịch hẹn',
      'play_music': 'Phát nhạc',
      'navigate_to': 'Chỉ đường',
      'family_create_medication': 'Người thân thêm thuốc',
      'family_update_medication': 'Người thân sửa thuốc',
      'family_delete_medication': 'Người thân xóa thuốc',
    };
    return labels[toolName] ?? toolName;
  }
}

class UserLocation {
  const UserLocation({this.lat, this.lng, this.updatedAt});

  final double? lat;
  final double? lng;
  final DateTime? updatedAt;

  bool get hasLocation => lat != null && lng != null;

  factory UserLocation.fromJson(Map<String, dynamic> j) {
    return UserLocation(
      lat: (j['lat'] as num?)?.toDouble(),
      lng: (j['lng'] as num?)?.toDouble(),
      updatedAt: j['updated_at'] != null
          ? DateTime.tryParse(j['updated_at'] as String)
          : null,
    );
  }
}
