import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ecg_report.dart';
import '../models/ecg_report_summary.dart';

class ECGService {
  static const String baseUrl = 'http://13.201.188.36:8000';
  static const String userId =
      'AR462almiegbh8lTXw8jBMskQHn1'; // Replace with actual user ID or make dynamic

  Future<ECGReportsList> getReports({
    int limit = 10,
    int offset = 0,
    String sortBy = 'timestamp',
    String sortOrder = 'desc',
  }) async {
    final url = Uri.parse(
      '$baseUrl/users/$userId/ecg-reports?limit=$limit&offset=$offset&sort_by=$sortBy&sort_order=$sortOrder',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return ECGReportsList.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load ECG reports');
    }
  }

  Future<ECGReport> getReportDetail(String reportId) async {
    final url = Uri.parse('$baseUrl/users/$userId/ecg-reports/$reportId');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return ECGReport.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load ECG report detail');
    }
  }
}
