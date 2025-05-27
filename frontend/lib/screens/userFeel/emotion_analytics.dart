import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_charts/charts.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// Models for emotion data
class EmotionDistribution {
  final String emotion;
  final int count;
  final double percentage;

  EmotionDistribution({
    required this.emotion,
    required this.count,
    required this.percentage,
  });

  factory EmotionDistribution.fromJson(Map<String, dynamic> json) {
    return EmotionDistribution(
      emotion: json['emotion'],
      count: json['count'],
      percentage: json['percentage'],
    );
  }
}

class EmotionFrequency {
  final String emotion;
  final int count;

  EmotionFrequency({
    required this.emotion,
    required this.count,
  });

  factory EmotionFrequency.fromJson(Map<String, dynamic> json) {
    return EmotionFrequency(
      emotion: json['emotion'],
      count: json['count'],
    );
  }
}

class EmotionAnalytics {
  final List<EmotionDistribution> distribution;
  final List<EmotionFrequency> frequency;
  final int totalRecords;
  final String timeRange;

  EmotionAnalytics({
    required this.distribution,
    required this.frequency,
    required this.totalRecords,
    required this.timeRange,
  });

  factory EmotionAnalytics.fromJson(Map<String, dynamic> json) {
    return EmotionAnalytics(
      distribution: (json['distribution'] as List)
          .map((e) => EmotionDistribution.fromJson(e))
          .toList(),
      frequency: (json['frequency'] as List)
          .map((e) => EmotionFrequency.fromJson(e))
          .toList(),
      totalRecords: json['total_records'],
      timeRange: json['time_range'],
    );
  }
}

// API service
class EmotionAnalyticsService {
  final String baseUrl;

  EmotionAnalyticsService({required this.baseUrl});

  Future<EmotionAnalytics> getEmotionAnalytics({
    required String userId,
    String timeRange = 'all',
    String? emotionFilter,
  }) async {
    final queryParams = {
      'time_range': timeRange,
    };

    if (emotionFilter != null) {
      queryParams['emotion_filter'] = emotionFilter;
    }

    final uri = Uri.parse('$baseUrl/users/$userId/emotions/analytics')
        .replace(queryParameters: queryParams);

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return EmotionAnalytics.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load emotion analytics');
    }
  }
}

// Color mapping for emotions
Map<String, Color> emotionColors = {
  'joy': Colors.yellow,
  'sadness': Colors.blue,
  'anger': Colors.red,
  'fear': Colors.purple,
  'disgust': Colors.green,
  'surprise': Colors.orange,
  'neutral': Colors.grey,
  // Add more emotions as needed
};

// Main emotion dashboard screen
class EmotionDashboardScreen extends StatefulWidget {
  @override
  _EmotionDashboardScreenState createState() => _EmotionDashboardScreenState();
}

class _EmotionDashboardScreenState extends State<EmotionDashboardScreen> {
  late EmotionAnalyticsService _analyticsService;
  late String _userId;
  String _selectedTimeRange = 'all';
  EmotionAnalytics? _emotionData;
  bool _isLoading = true;

  final List<String> _timeRanges = ['day', 'week', 'month', 'all'];

  @override
  void initState() {
    super.initState();
    _analyticsService = EmotionAnalyticsService(baseUrl: 'http://13.203.212.95:8000');
    _loadUserId().then((_) {
      _fetchEmotionData();
    });
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('user_id') ?? '';
    if (_userId.isEmpty) {
      // Handle case where user is not logged in
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User not logged in')),
      );
    }
  }

  Future<void> _fetchEmotionData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await _analyticsService.getEmotionAnalytics(
        userId: _userId,
        timeRange: _selectedTimeRange,
      );

      setState(() {
        _emotionData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load emotion data: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Emotion Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchEmotionData,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _emotionData == null || _emotionData!.totalRecords == 0
          ? Center(child: Column(
        children: [
          Text('No emotion data available'),
          _buildTimeRangeSelector(),
        ],
      ) )
          : SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTimeRangeSelector(),
            SizedBox(height: 24),
            _buildSummaryCard(),
            SizedBox(height: 24),
            _buildPieChartSection(),
            SizedBox(height: 32),
            _buildBarChartSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRangeSelector() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Time Range',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _timeRanges.map((range) {
                  return Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(range.capitalize()),
                      selected: _selectedTimeRange == range,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedTimeRange = range;
                          });
                          _fetchEmotionData();
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Summary',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Total Emotions Recorded: ${_emotionData!.totalRecords}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            if (_emotionData!.frequency.isNotEmpty)
              Text(
                'Most Frequent: ${_emotionData!.frequency[0].emotion.capitalize()} (${_emotionData!.frequency[0].count} times)',
                style: TextStyle(fontSize: 16),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChartSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Emotion Distribution',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        SizedBox(height: 16),
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                SizedBox(
                  height: 300,
                  child: SfCircularChart(
                    title: ChartTitle(
                      text: 'Emotion Distribution',
                      textStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    legend: Legend(
                      isVisible: true,
                      overflowMode: LegendItemOverflowMode.wrap,
                      position: LegendPosition.bottom,
                    ),
                    tooltipBehavior: TooltipBehavior(
                      enable: true,
                      format: 'point.x: point.y%',
                    ),
                    series: <CircularSeries<EmotionDistribution, String>>[
                      PieSeries<EmotionDistribution, String>(
                        dataSource: _emotionData!.distribution,
                        xValueMapper: (EmotionDistribution data, _) => data.emotion.capitalize(),
                        yValueMapper: (EmotionDistribution data, _) => data.percentage,
                        dataLabelMapper: (EmotionDistribution data, _) =>
                        '${data.emotion.capitalize()} ${data.percentage.toStringAsFixed(1)}% ',
                        pointColorMapper: (EmotionDistribution data, _) =>
                        emotionColors[data.emotion] ?? Colors.grey,
                        dataLabelSettings: DataLabelSettings(
                          isVisible: true,
                          labelPosition: ChartDataLabelPosition.outside,
                          connectorLineSettings: ConnectorLineSettings(
                            type: ConnectorType.line,
                            length: '5%',
                          ),
                          textStyle: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        explode: false,
                        explodeIndex: 0,
                        explodeOffset: '10%',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBarChartSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Emotion Frequency',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        SizedBox(height: 16),
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: SizedBox(
              height: 350,
              child: SfCartesianChart(
                primaryXAxis: CategoryAxis(
                  title: AxisTitle(
                    text: 'Emotions',
                    textStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                primaryYAxis: NumericAxis(
                  title: AxisTitle(
                    text: 'Frequency',
                    textStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  majorGridLines: MajorGridLines(width: 0.5),
                ),
                tooltipBehavior: TooltipBehavior(
                  enable: true,
                  format: 'point.x: point.y',
                ),
                legend: Legend(
                  isVisible: false,
                ),
                series: <CartesianSeries<EmotionDistribution, String>>[
                  ColumnSeries<EmotionDistribution, String>(
                    dataSource: _emotionData!.distribution,
                    xValueMapper: (EmotionDistribution data, _) => data.emotion.capitalize(),
                    yValueMapper: (EmotionDistribution data, _) => data.percentage,
                    dataLabelMapper: (EmotionDistribution data, _) =>
                    '${data.percentage.toStringAsFixed(1)}% ',
                    pointColorMapper: (EmotionDistribution data, _) =>
                    emotionColors[data.emotion] ?? Colors.grey,
                    dataLabelSettings: DataLabelSettings(
                      isVisible: true,
                      labelPosition: ChartDataLabelPosition.outside,
                      connectorLineSettings: ConnectorLineSettings(
                        type: ConnectorType.line,
                        length: '5%',
                      ),
                      textStyle: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                // series: <CartesianSeries<EmotionFrequency, String>>[
                //   ColumnSeries<EmotionFrequency, String>(
                //     dataSource: _emotionData!.frequency,
                //     xValueMapper: (EmotionFrequency data, _) => data.emotion.capitalize(),
                //     yValueMapper: (EmotionFrequency data, _) => data.count,
                //     pointColorMapper: (EmotionFrequency data, _) =>
                //     emotionColors[data.emotion] ?? Colors.grey,
                //     borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
                //     dataLabelSettings: DataLabelSettings(
                //       isVisible: true,
                //       textStyle: TextStyle(
                //         fontSize: 12,
                //         fontWeight: FontWeight.bold,
                //       ),
                //     ),
                //   ),
                // ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Extension for string capitalization
extension StringExtension on String {
  String capitalize() {
    return isEmpty ? '' : '${this[0].toUpperCase()}${substring(1)}';
  }
}
