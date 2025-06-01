class ECGReportSummary {
  final String id;
  final String filename;
  final String timestamp;
  final String shortDescription;

  ECGReportSummary({
    required this.id,
    required this.filename,
    required this.timestamp,
    required this.shortDescription,
  });

  factory ECGReportSummary.fromJson(Map<String, dynamic> json) {
    return ECGReportSummary(
      id: json['id'],
      filename: json['filename'],
      timestamp: json['timestamp'],
      shortDescription: json['short_description'],
    );
  }
}

class ECGReportsList {
  final List<ECGReportSummary> reports;
  final int totalCount;

  ECGReportsList({
    required this.reports,
    required this.totalCount,
  });

  factory ECGReportsList.fromJson(Map<String, dynamic> json) {
    return ECGReportsList(
      reports: (json['reports'] as List)
          .map((report) => ECGReportSummary.fromJson(report))
          .toList(),
      totalCount: json['total_count'],
    );
  }
}
