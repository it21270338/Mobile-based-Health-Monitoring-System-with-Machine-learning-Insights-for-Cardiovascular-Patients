import 'package:flutter/material.dart';
import 'package:MediSafe/screens/dashboard/dashboard.dart';
import 'package:MediSafe/services/apiDio.dart';
import 'package:MediSafe/utils/shared_prefs.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import '../../commonComponents/healthAlert.dart';

class PainHistoryScreen extends StatefulWidget {
  final String riskLevel;

  const PainHistoryScreen({Key? key,required this.riskLevel}) : super(key: key);

  @override
  _PainHistoryScreenState createState() => _PainHistoryScreenState();
}

class _PainHistoryScreenState extends State<PainHistoryScreen> {
  List<PainRecord> painHistory = [];
  List<String> insights = [];
  Map<String, dynamic> locationFrequencies = {};
  bool isLoading = true;
  String selectedTimeRange = 'all';

  final List<String> timeRanges = ['all', 'day', 'week', 'month', 'year'];

  Future<void> _checkAndShowHealthAlert() async {
    if (widget.riskLevel == "high") {
      final id = await SharedPrefs.getUserId();
      if (context.mounted) {
        showHealthAlert(context, id!);
      }
    }
  }


  @override
  void initState() {
    super.initState();
    fetchPainHistory();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowHealthAlert();
    });
  }


  Map<String, dynamic> processLocationFrequencies(Map<String, dynamic> frequencies) {
    return frequencies.map((key, value) =>
        MapEntry(key, (value as num).toInt()));
  }

  Map<String, dynamic> processSymptomCorrelations(Map<String, dynamic> correlations) {
    final processed = <String, dynamic>{};

    // Process symptom heart rate correlations
    if (correlations['symptom_heart_rate'] != null) {
      processed['symptom_heart_rate'] = (correlations['symptom_heart_rate'] as Map<String, dynamic>)
          .map((key, value) => MapEntry(key, (value as num).toDouble()));
    }

    // Process symptom risk distribution
    if (correlations['symptom_risk_distribution'] != null) {
      final riskDist = correlations['symptom_risk_distribution'] as Map<String, dynamic>;
      processed['symptom_risk_distribution'] = riskDist.map((symptom, risks) =>
          MapEntry(symptom, (risks as Map<String, dynamic>).map((risk, count) =>
              MapEntry(risk, (count as num).toInt()))));
    }

    // Process common symptom activities
    if (correlations['common_symptom_activities'] != null) {
      processed['common_symptom_activities'] =
          (correlations['common_symptom_activities'] as Map<String, dynamic>)
              .map((key, value) => MapEntry(key, (value as num).toInt()));
    }

    return processed;
  }

  Future<void> fetchPainHistory() async {
    try {
      final id = await SharedPrefs.getUserId();
      final response = await apiDio().getPainHistory(id!, selectedTimeRange);
      print(response);
      setState(() {
        painHistory = (response['pain_history'] as List)
            .map((record) => PainRecord.fromJson(record))
            .toList();
        insights = List<String>.from(response['insights']);
        locationFrequencies = processLocationFrequencies(
            response['location_frequencies'] as Map<String, dynamic>);
        isLoading = false;
      });
    } catch (e) {
      print('Error in fetchPainHistory: ${e.toString()}');
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading pain history: ${e.toString()}')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Pain History & Trends'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => Dashboard()),
              );
            },
          ),
          actions: [
            // Dropdown for time range selection
            // DropdownButton<String>(
            //   value: selectedTimeRange,
            //   onChanged: (String? newValue) {
            //     setState(() {
            //       selectedTimeRange = newValue!;
            //       fetchPainHistory(); // Fetch data for the new time range
            //     });
            //   },
            //   items: timeRanges.map<DropdownMenuItem<String>>((String value) {
            //     return DropdownMenuItem<String>(
            //       value: value,
            //       child: Text(
            //         value[0].toUpperCase() + value.substring(1), // Capitalize first letter
            //       ),
            //     );
            //   }).toList(),
            // ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: 'Timeline'),
              Tab(text: 'Trends'),
              Tab(text: 'Insights'),
            ],
          ),
        ),
        body: isLoading
            ? Center(child: CircularProgressIndicator())
            : TabBarView(
          children: [
            _buildTimelineTab(),
            _buildTrendsTab(),
            _buildInsightsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineTab() {
    return ListView.builder(
      itemCount: painHistory.length,
      itemBuilder: (context, index) {
        final record = painHistory[index];
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text('Pain in ${record.painLocation}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Date: ${DateFormat.yMMMd().format(record.timestamp)}'),
                Text('Activity: ${record.activityType}'),
                Text('Symptoms: ${record.accompanyingSymptoms}'),
              ],
            ),
            trailing: _getRiskBadge(record.riskLevel),
          ),
        );
      },
    );
  }

  Widget _buildTrendsTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildPainDurationChart(),
          SizedBox(height: 16),
          _buildHeartRateChart(),
          SizedBox(height: 16),
          _buildLocationFrequencyChart(),
          SizedBox(height: 16),
          _buildActivityDistributionChart(),
        ],
      ),
    );
  }

  Widget _buildPainDurationChart() {
    return Container(
      height: 300,
      padding: EdgeInsets.all(16),
      child: SfCartesianChart(
        title: ChartTitle(text: 'Pain Duration Over Time'),
        legend: Legend(isVisible: true),
        tooltipBehavior: TooltipBehavior(enable: true),
        primaryXAxis: DateTimeAxis(
          dateFormat: DateFormat.yMMMd(),
          intervalType: DateTimeIntervalType.auto,
        ),
        primaryYAxis: NumericAxis(
          title: AxisTitle(text: 'Duration (minutes)'),
        ),
        series: <CartesianSeries<PainRecord, DateTime>>[
          LineSeries<PainRecord, DateTime>(
            name: 'Pain Duration',
            dataSource: painHistory,
            xValueMapper: (PainRecord record, _) => record.timestamp,
            yValueMapper: (PainRecord record, _) => record.painDurationMinutes,
            markerSettings: MarkerSettings(isVisible: true),
          ),
        ],
      ),
    );
  }

  Widget _buildHeartRateChart() {
    return Container(
      height: 300,
      padding: EdgeInsets.all(16),
      child: SfCartesianChart(
        title: ChartTitle(text: 'Heart Rate Trends'),
        legend: Legend(isVisible: true),
        tooltipBehavior: TooltipBehavior(enable: true),
        primaryXAxis: DateTimeAxis(
          dateFormat: DateFormat.yMMMd(),
          intervalType: DateTimeIntervalType.auto,
        ),
        primaryYAxis: NumericAxis(
          title: AxisTitle(text: 'Heart Rate (bpm)'),
        ),
        series: <CartesianSeries<PainRecord, DateTime>>[
          LineSeries<PainRecord, DateTime>(
            name: 'Heart Rate',
            dataSource: painHistory,
            xValueMapper: (PainRecord record, _) => record.timestamp,
            yValueMapper: (PainRecord record, _) => record.heartRate,
            markerSettings: MarkerSettings(isVisible: true),
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationFrequencyChart() {
    List<LocationFrequency> data = locationFrequencies.entries
        .map((e) => LocationFrequency(e.key, e.value))
        .toList();

    return Container(
      height: 300,
      padding: EdgeInsets.all(16),
      child: SfCircularChart(
        title: ChartTitle(text: 'Pain Location Distribution'),
        legend: Legend(isVisible: true),
        tooltipBehavior: TooltipBehavior(enable: true),
        series: <CircularSeries>[
          DoughnutSeries<LocationFrequency, String>(
            dataSource: data,
            xValueMapper: (LocationFrequency data, _) => data.location,
            yValueMapper: (LocationFrequency data, _) => data.frequency,
            dataLabelSettings: DataLabelSettings(isVisible: true),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityDistributionChart() {
    Map<String, int> activityCount = {};
    for (var record in painHistory) {
      activityCount[record.activityType] =
          (activityCount[record.activityType] ?? 0) + 1;
    }

    List<ActivityFrequency> data = activityCount.entries
        .map((e) => ActivityFrequency(e.key, e.value))
        .toList();

    return Container(
      height: 300,
      padding: EdgeInsets.all(16),
      child: SfCartesianChart(
        title: ChartTitle(text: 'Activity Distribution'),
        legend: Legend(isVisible: true),
        tooltipBehavior: TooltipBehavior(enable: true),
        primaryXAxis: CategoryAxis(),
        primaryYAxis: NumericAxis(
          title: AxisTitle(text: 'Frequency'),
        ),
        series: <CartesianSeries<ActivityFrequency, String>>[
          BarSeries<ActivityFrequency, String>(
            dataSource: data,
            xValueMapper: (ActivityFrequency data, _) => data.activity,
            yValueMapper: (ActivityFrequency data, _) => data.frequency,
            dataLabelSettings: DataLabelSettings(isVisible: true),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsTab() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: insights.length,
      itemBuilder: (context, index) {
        return Card(
          margin: EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.amber),
                SizedBox(width: 16),
                Expanded(
                  child: Text(insights[index]),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _getRiskBadge(String riskLevel) {
    final color = {
      'low': Colors.green,
      'medium': Colors.orange,
      'high': Colors.red,
    }[riskLevel.toLowerCase()] ?? Colors.grey;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        riskLevel.toUpperCase(),
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}

class PainRecord {
  final DateTime timestamp;
  final double heartRate; // Change to double
  final double painDurationMinutes; // Change to double
  final String activityType;
  final String painLocation;
  final String accompanyingSymptoms;
  final String riskLevel;

  PainRecord({
    required this.timestamp,
    required this.heartRate,
    required this.painDurationMinutes,
    required this.activityType,
    required this.painLocation,
    required this.accompanyingSymptoms,
    required this.riskLevel,
  });

  factory PainRecord.fromJson(Map<String, dynamic> json) {
    return PainRecord(
      timestamp: DateTime.parse(json['timestamp']),
      heartRate: json['heart_rate'].toDouble(), // Ensure it's double
      painDurationMinutes: json['pain_duration_minutes'].toDouble(), // Ensure it's double
      activityType: json['activity_type'],
      painLocation: json['pain_location'],
      accompanyingSymptoms: json['accompanying_symptoms'],
      riskLevel: json['risk_level'],
    );
  }
}

class LocationFrequency {
  final String location;
  final int frequency;

  LocationFrequency(this.location, this.frequency);
}

class ActivityFrequency {
  final String activity;
  final int frequency;

  ActivityFrequency(this.activity, this.frequency);
}
