String formatFamilyDashboardTime(DateTime dt) {
  final local = dt.toLocal();
  return '${local.day}/${local.month}/${local.year} '
      '${local.hour.toString().padLeft(2, "0")}:'
      '${local.minute.toString().padLeft(2, "0")}';
}
