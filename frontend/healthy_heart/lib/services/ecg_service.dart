import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ecg_report.dart';
import '../models/ecg_report_summary.dart';

class ECGService {
  static const String baseUrl = 'http://13.203.212.95:8000';
  late SharedPreferences prefs;

  Future<void> _initPrefs() async {
    prefs = await SharedPreferences.getInstance();
  }

  Future<ECGReportsList> getReports({
    int limit = 10,
    int offset = 0,
    String sortBy = 'timestamp',
    String sortOrder = 'desc',
  }) async {
    await _initPrefs();
    final userId = prefs.getString('user_id');

    final url = Uri.parse(
        '$baseUrl/users/$userId/ecg-reports?limit=$limit&offset=$offset&sort_by=$sortBy&sort_order=$sortOrder');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return ECGReportsList.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load ECG reports');
    }
  }

  Future<ECGReport> getReportDetail(String reportId) async {
    await _initPrefs();
    final userId = prefs.getString('user_id');

    final url = Uri.parse('$baseUrl/users/$userId/ecg-reports/$reportId');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return ECGReport.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load ECG report detail');
    }
  }
}
