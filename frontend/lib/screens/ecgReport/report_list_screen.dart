import 'package:flutter/material.dart';
import 'package:healthy_heart/screens/ecgReport/report_detail_screen.dart';
import 'package:intl/intl.dart';

import '../../models/ecg_report_summary.dart';
import '../../services/ecg_service.dart';

class ReportListScreen extends StatefulWidget {
  const ReportListScreen({Key? key}) : super(key: key);

  @override
  _ReportListScreenState createState() => _ReportListScreenState();
}

class _ReportListScreenState extends State<ReportListScreen> {
  final ECGService _ecgService = ECGService();
  late Future<ECGReportsList> _reportsFuture;
  int _currentOffset = 0;
  int _totalReports = 0;
  List<ECGReportSummary> _reports = [];
  bool _isLoading = false;
  final int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports({bool refresh = false}) async {
    setState(() {
      _isLoading = true;
    });

    if (refresh) {
      _currentOffset = 0;
      _reports = [];
    }

    try {
      final reportsData = await _ecgService.getReports(
        limit: _pageSize,
        offset: _currentOffset,
      );

      setState(() {
        _reports.addAll(reportsData.reports);
        _totalReports = reportsData.totalCount;
        _currentOffset += _pageSize;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading reports: $e')));
    }
  }

  Future<void> _refreshReports() async {
    await _loadReports(refresh: true);
    return;
  }

  String _formatDateTime(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      return DateFormat('MMM d, yyyy - h:mm a').format(dateTime);
    } catch (e) {
      return timestamp;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ECG Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshReports,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshReports,
        child:
            _reports.isEmpty && !_isLoading
                ? const Center(child: Text('No ECG reports found'))
                : NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification scrollInfo) {
                    if (!_isLoading &&
                        scrollInfo.metrics.pixels ==
                            scrollInfo.metrics.maxScrollExtent &&
                        _reports.length < _totalReports) {
                      _loadReports();
                      return true;
                    }
                    return false;
                  },
                  child: ListView.builder(
                    itemCount: _reports.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _reports.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final report = _reports[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        ReportDetailScreen(reportId: report.id),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                Text(
                                  _formatDateTime(report.timestamp),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  report.shortDescription,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
      ),
    );
  }
}
