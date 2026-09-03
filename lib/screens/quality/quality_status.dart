enum QualityRecordState {
  notReady,
  pendingInspection,
  inspected,
  approved,
  rejected,
}

String _normalizedQualityValue(Object? value) =>
    value?.toString().trim().toLowerCase() ?? '';

QualityRecordState qualityRecordState(Map<String, dynamic> record) {
  final qualityStatus = _normalizedQualityValue(record['quality_status']);

  if (qualityStatus == 'approved') return QualityRecordState.approved;
  if (qualityStatus == 'rejected') return QualityRecordState.rejected;
  if (qualityStatus == 'inspected') return QualityRecordState.inspected;

  // Fulfillment status is retained as a migration fallback for records created
  // before the dedicated QA fields were introduced.
  final fulfillmentStatus = _normalizedQualityValue(
    record['status'] ?? record['delivery_status'],
  );
  if (fulfillmentStatus == 'sent to sales' ||
      fulfillmentStatus == 'approved' ||
      fulfillmentStatus == 'released' ||
      fulfillmentStatus == 'completed') {
    return QualityRecordState.approved;
  }
  if (fulfillmentStatus.contains('reject') ||
      fulfillmentStatus.contains('hold')) {
    return QualityRecordState.rejected;
  }
  if (fulfillmentStatus == 'packaged') {
    return QualityRecordState.pendingInspection;
  }
  return QualityRecordState.notReady;
}

bool isPendingQualityInspection(Map<String, dynamic> record) =>
    qualityRecordState(record) == QualityRecordState.pendingInspection;

bool hasCompletedQualityInspection(Map<String, dynamic> record) {
  final state = qualityRecordState(record);
  return state == QualityRecordState.inspected ||
      state == QualityRecordState.approved ||
      state == QualityRecordState.rejected;
}

bool isQualityRecord(Map<String, dynamic> record) =>
    qualityRecordState(record) != QualityRecordState.notReady;

String qualityRecordLabel(Map<String, dynamic> record) {
  return switch (qualityRecordState(record)) {
    QualityRecordState.pendingInspection => 'Pending Inspection',
    QualityRecordState.inspected => 'Awaiting Approval',
    QualityRecordState.approved => 'Approved',
    QualityRecordState.rejected => 'Rejected',
    QualityRecordState.notReady => 'Not Ready for QA',
  };
}
