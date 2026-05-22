// Models khớp backend internal/care (JSON snake_case).

int _careAsInt(Object? value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.round();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

class CareTimelineEvent {
  const CareTimelineEvent({
    required this.kind,
    required this.title,
    this.detail,
    required this.occurredAt,
    this.metadata,
  });

  final String kind;
  final String title;
  final String? detail;
  final DateTime occurredAt;
  final Map<String, dynamic>? metadata;

  factory CareTimelineEvent.fromJson(Map<String, dynamic> j) {
    return CareTimelineEvent(
      kind: j['kind'] as String? ?? '',
      title: j['title'] as String? ?? '',
      detail: j['detail'] as String?,
      occurredAt: DateTime.parse(j['occurred_at'] as String),
      metadata: j['metadata'] is Map<String, dynamic>
          ? j['metadata'] as Map<String, dynamic>
          : null,
    );
  }
}

class CareTimelineResponse {
  const CareTimelineResponse({
    required this.requestedDays,
    required this.effectiveDays,
    required this.limit,
    required this.windowStart,
    required this.windowEnd,
    required this.events,
  });

  final int requestedDays;
  final int effectiveDays;
  final int limit;
  final DateTime windowStart;
  final DateTime windowEnd;
  final List<CareTimelineEvent> events;

  factory CareTimelineResponse.fromJson(Map<String, dynamic> j) {
    final List<dynamic> raw = j['events'] as List<dynamic>? ?? [];
    final int reqDays = _careAsInt(j['requested_days']);
    final int effDays = _careAsInt(j['effective_days']);
    final int lim = _careAsInt(j['limit']);
    return CareTimelineResponse(
      requestedDays: reqDays > 0 ? reqDays : 7,
      effectiveDays: effDays > 0 ? effDays : 7,
      limit: lim > 0 ? lim : 50,
      windowStart: DateTime.parse(j['window_start'] as String),
      windowEnd: DateTime.parse(j['window_end'] as String),
      events: raw
          .map((e) => CareTimelineEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CareReportTotals {
  const CareReportTotals({
    required this.activeMedications,
    required this.takenMedications,
    required this.skippedMedications,
    required this.symptomCount,
    required this.metricCount,
    required this.sosAlertCount,
    required this.escalationCount,
    required this.videoCallCount,
    required this.videoCallMinutes,
    required this.voiceCallMinutes,
  });

  final int activeMedications;
  final int takenMedications;
  final int skippedMedications;
  final int symptomCount;
  final int metricCount;
  final int sosAlertCount;
  final int escalationCount;
  final int videoCallCount;
  final double videoCallMinutes;
  final double voiceCallMinutes;

  factory CareReportTotals.fromJson(Map<String, dynamic> j) {
    return CareReportTotals(
      activeMedications: _careAsInt(j['active_medications']),
      takenMedications: _careAsInt(j['taken_medications']),
      skippedMedications: _careAsInt(j['skipped_medications']),
      symptomCount: _careAsInt(j['symptom_count']),
      metricCount: _careAsInt(j['metric_count']),
      sosAlertCount: _careAsInt(j['sos_alert_count']),
      escalationCount: _careAsInt(j['escalation_count']),
      videoCallCount: _careAsInt(j['video_call_count']),
      videoCallMinutes: (j['video_call_minutes'] as num?)?.toDouble() ?? 0,
      voiceCallMinutes: (j['voice_call_minutes'] as num?)?.toDouble() ?? 0,
    );
  }
}

class CareDailyBriefResponse {
  const CareDailyBriefResponse({
    required this.date,
    required this.summary,
    required this.totals,
  });

  final String date;
  final List<String> summary;
  final CareReportTotals totals;

  factory CareDailyBriefResponse.fromJson(Map<String, dynamic> j) {
    final List<dynamic> s = j['summary'] as List<dynamic>? ?? [];
    return CareDailyBriefResponse(
      date: j['date'] as String? ?? '',
      summary: s.map((e) => e.toString()).toList(),
      totals: CareReportTotals.fromJson(
        j['totals'] as Map<String, dynamic>? ?? <String, dynamic>{},
      ),
    );
  }
}

class CareWeeklyReportResponse {
  const CareWeeklyReportResponse({
    required this.startDate,
    required this.endDate,
    required this.summary,
    required this.totals,
  });

  final String startDate;
  final String endDate;
  final List<String> summary;
  final CareReportTotals totals;

  factory CareWeeklyReportResponse.fromJson(Map<String, dynamic> j) {
    final List<dynamic> s = j['summary'] as List<dynamic>? ?? [];
    return CareWeeklyReportResponse(
      startDate: j['start_date'] as String? ?? '',
      endDate: j['end_date'] as String? ?? '',
      summary: s.map((e) => e.toString()).toList(),
      totals: CareReportTotals.fromJson(
        j['totals'] as Map<String, dynamic>? ?? <String, dynamic>{},
      ),
    );
  }
}

class CareIncidentEscalation {
  const CareIncidentEscalation({
    required this.occurredAt,
    required this.status,
    this.contactName,
    this.tried,
    this.remaining,
    this.rawToolName,
  });

  final DateTime occurredAt;
  final String status;
  final String? contactName;
  final String? tried;
  final List<String>? remaining;
  final String? rawToolName;

  factory CareIncidentEscalation.fromJson(Map<String, dynamic> j) {
    final List<dynamic>? rem = j['remaining'] as List<dynamic>?;
    return CareIncidentEscalation(
      occurredAt: DateTime.parse(j['occurred_at'] as String),
      status: j['status'] as String? ?? '',
      contactName: j['contact_name'] as String?,
      tried: j['tried'] as String?,
      remaining: rem?.map((e) => e.toString()).toList(),
      rawToolName: j['raw_tool_name'] as String?,
    );
  }
}

class CareGeoPoint {
  const CareGeoPoint({required this.lat, required this.lng});

  final double lat;
  final double lng;

  factory CareGeoPoint.fromJson(Map<String, dynamic> j) {
    return CareGeoPoint(
      lat: (j['lat'] as num?)?.toDouble() ?? 0,
      lng: (j['lng'] as num?)?.toDouble() ?? 0,
    );
  }
}

class CareIncidentReportResponse {
  const CareIncidentReportResponse({
    required this.alertAt,
    required this.familyNotified,
    required this.location,
    required this.escalations,
    required this.summary,
  });

  final DateTime alertAt;
  final int familyNotified;
  final CareGeoPoint location;
  final List<CareIncidentEscalation> escalations;
  final List<String> summary;

  factory CareIncidentReportResponse.fromJson(Map<String, dynamic> j) {
    final List<dynamic> esc = j['escalations'] as List<dynamic>? ?? [];
    final List<dynamic> sum = j['summary'] as List<dynamic>? ?? [];
    return CareIncidentReportResponse(
      alertAt: DateTime.parse(j['alert_at'] as String),
      familyNotified: _careAsInt(j['family_notified']),
      location: CareGeoPoint.fromJson(
        j['location'] as Map<String, dynamic>? ?? <String, dynamic>{},
      ),
      escalations: esc
          .map(
            (e) => CareIncidentEscalation.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      summary: sum.map((e) => e.toString()).toList(),
    );
  }
}

class CareExportResponse {
  const CareExportResponse({
    required this.exportId,
    required this.reportType,
    required this.format,
    this.usageRecordId,
    required this.generatedAt,
    this.data,
  });

  final String exportId;
  final String reportType;
  final String format;
  final String? usageRecordId;
  final DateTime generatedAt;
  final Object? data;

  factory CareExportResponse.fromJson(Map<String, dynamic> j) {
    return CareExportResponse(
      exportId: j['export_id'] as String? ?? '',
      reportType: j['report_type'] as String? ?? '',
      format: j['format'] as String? ?? '',
      usageRecordId: j['usage_record_id'] as String?,
      generatedAt: DateTime.parse(j['generated_at'] as String),
      data: j['data'],
    );
  }
}

class CareAlert {
  const CareAlert({
    required this.id,
    required this.userId,
    required this.ruleCode,
    required this.severity,
    required this.title,
    this.body,
    required this.status,
    this.metadata,
    this.acknowledgedBy,
    this.acknowledgedAt,
    this.resolvedAt,
    this.dismissedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String ruleCode;
  final String severity;
  final String title;
  final String? body;
  final String status;
  final Map<String, dynamic>? metadata;
  final String? acknowledgedBy;
  final DateTime? acknowledgedAt;
  final DateTime? resolvedAt;
  final DateTime? dismissedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory CareAlert.fromJson(Map<String, dynamic> j) {
    return CareAlert(
      id: j['id'] as String? ?? '',
      userId: j['user_id'] as String? ?? '',
      ruleCode: j['rule_code'] as String? ?? '',
      severity: j['severity'] as String? ?? '',
      title: j['title'] as String? ?? '',
      body: j['body'] as String?,
      status: j['status'] as String? ?? '',
      metadata: j['metadata'] is Map<String, dynamic>
          ? j['metadata'] as Map<String, dynamic>
          : null,
      acknowledgedBy: j['acknowledged_by'] as String?,
      acknowledgedAt: j['acknowledged_at'] != null
          ? DateTime.tryParse(j['acknowledged_at'] as String)
          : null,
      resolvedAt: j['resolved_at'] != null
          ? DateTime.tryParse(j['resolved_at'] as String)
          : null,
      dismissedAt: j['dismissed_at'] != null
          ? DateTime.tryParse(j['dismissed_at'] as String)
          : null,
      createdAt: DateTime.parse(j['created_at'] as String),
      updatedAt: DateTime.parse(j['updated_at'] as String),
    );
  }
}

class CareTask {
  const CareTask({
    required this.id,
    required this.userId,
    required this.createdBy,
    required this.title,
    this.dueAt,
    required this.status,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });

  final String id;
  final String userId;
  final String createdBy;
  final String title;
  final DateTime? dueAt;
  final String status;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  factory CareTask.fromJson(Map<String, dynamic> j) {
    return CareTask(
      id: j['id'] as String? ?? '',
      userId: j['user_id'] as String? ?? '',
      createdBy: j['created_by'] as String? ?? '',
      title: j['title'] as String? ?? '',
      dueAt: j['due_at'] != null
          ? DateTime.tryParse(j['due_at'] as String)
          : null,
      status: j['status'] as String? ?? '',
      metadata: j['metadata'] is Map<String, dynamic>
          ? j['metadata'] as Map<String, dynamic>
          : null,
      createdAt: DateTime.parse(j['created_at'] as String),
      updatedAt: DateTime.parse(j['updated_at'] as String),
      completedAt: j['completed_at'] != null
          ? DateTime.tryParse(j['completed_at'] as String)
          : null,
    );
  }
}
