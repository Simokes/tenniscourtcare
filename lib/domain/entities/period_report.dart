class PeriodReport {
  final DateTime start;
  final DateTime end;
  final int totalInterventions;
  final int totalSacksManto;
  final int totalSacksSottomanto;
  final int totalSacksSilice;
  final String? mostMaintainedTerrainName;
  final int mostMaintainedTerrainCount;

  const PeriodReport({
    required this.start,
    required this.end,
    required this.totalInterventions,
    required this.totalSacksManto,
    required this.totalSacksSottomanto,
    required this.totalSacksSilice,
    this.mostMaintainedTerrainName,
    this.mostMaintainedTerrainCount = 0,
  });
}
