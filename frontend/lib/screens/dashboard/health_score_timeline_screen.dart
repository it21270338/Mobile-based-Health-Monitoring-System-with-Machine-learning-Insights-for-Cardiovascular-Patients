import 'package:flutter/material.dart';
import 'package:MediSafe/commonComponents/customAppBar.dart';
import 'package:MediSafe/services/apiDio.dart';
import 'package:MediSafe/utils/shared_prefs.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class HealthScoreTimelineScreen extends StatefulWidget {
  const HealthScoreTimelineScreen({super.key});

  @override
  State<HealthScoreTimelineScreen> createState() => _HealthScoreTimelineScreenState();
}

class _HealthScoreTimelineScreenState extends State<HealthScoreTimelineScreen> {
  String selectedPeriod = 'Monthly';

  List<HealthData> healthScores = [];
  List<HealthData> riskScores = [];
  bool isLoading = false;
  final apiClient = apiDio();

  @override
  void initState() {
    super.initState();
    _fetchHealthData();
  }

  Future<void> _fetchHealthData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final id = await SharedPrefs.getUserId();

      final records = await apiClient.getHealthRecords(
        id!,
        selectedPeriod.toLowerCase(),
      );

      // Format the data for visualization
      List<HealthData> newHealthScores = [];
      List<HealthData> newRiskScores = [];

      for (var record in records) {
        // Format the timestamp based on selected period
        String formattedDate = _formatDate(record['timestamp']);

        newHealthScores.add(HealthData(
          formattedDate,
          record['health_score'].toDouble(),
        ));

        newRiskScores.add(HealthData(
          formattedDate,
          record['risk_probability'].toDouble(),
        ));
      }

      setState(() {
        healthScores = newHealthScores;
        riskScores = newRiskScores;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching health data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  String _formatDate(String timestamp) {
    DateTime date = DateTime.parse(timestamp);
    switch (selectedPeriod) {
      case 'Daily':
        return '${date.day}/${date.month}';
      case 'Weekly':
        return 'Week ${date.day ~/ 7 + 1}';
      case 'Monthly':
        return '${_getMonthName(date.month)}';
      default:
        return timestamp;
    }
  }

  String _getMonthName(int month) {
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return monthNames[month - 1];
  }

  // Sample data for different time periods
  final Map<String, List<HealthData>> healthScoreData = {
    'Daily': [
      HealthData('Mon', 82),
      HealthData('Tue', 85),
      HealthData('Wed', 83),
      HealthData('Thu', 87),
      HealthData('Fri', 84),
      HealthData('Sat', 86),
      HealthData('Sun', 85),
    ],
    'Weekly': [
      HealthData('Week 1', 84),
      HealthData('Week 2', 86),
      HealthData('Week 3', 82),
      HealthData('Week 4', 85),
    ],
    'Monthly': [
      HealthData('Jan', 85),
      HealthData('Feb', 83),
      HealthData('Mar', 87),
      HealthData('Apr', 82),
      HealthData('May', 88),
      HealthData('Jun', 84),
    ],
  };

  final Map<String, List<HealthData>> riskScoreData = {
    'Daily': [
      HealthData('Mon', 18),
      HealthData('Tue', 15),
      HealthData('Wed', 17),
      HealthData('Thu', 14),
      HealthData('Fri', 16),
      HealthData('Sat', 13),
      HealthData('Sun', 15),
    ],
    'Weekly': [
      HealthData('Week 1', 16),
      HealthData('Week 2', 14),
      HealthData('Week 3', 18),
      HealthData('Week 4', 15),
    ],
    'Monthly': [
      HealthData('Jan', 15),
      HealthData('Feb', 18),
      HealthData('Mar', 14),
      HealthData('Apr', 20),
      HealthData('May', 12),
      HealthData('Jun', 16),
    ],
  };


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Health Score Timeline'),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildFilterChip('Daily'),
                    _buildFilterChip('Weekly'),
                    _buildFilterChip('Monthly'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            if (healthScores.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    'No health records found.\nComplete a health assessment to see your trends.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
              )
            else
              ...[
                Expanded(
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildGraph(
                        'Health Score Trend',
                        healthScores,
                        // healthScoreData[selectedPeriod]!,
                        Colors.blue,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Expanded(
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildGraph(
                        'Heart Failure Risk Trend',
                        riskScores,
                        // riskScoreData[selectedPeriod]!,
                        Colors.red,
                        isRisk: true,
                      ),
                    ),
                  ),
                ),
              ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String period) {
    return FilterChip(
      label: Text(period),
      selected: selectedPeriod == period,
      onSelected: (selected) {
        setState(() {
          selectedPeriod = period;
        });
        _fetchHealthData();  // Fetch new data when period changes
      },
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      checkmarkColor: Theme.of(context).primaryColor,
      backgroundColor: Colors.grey.withOpacity(0.1),
    );
  }

  Widget _buildGraph(String title, List<HealthData> data, Color color, {bool isRisk = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              selectedPeriod,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: SfCartesianChart(
            plotAreaBorderWidth: 0,
            legend: const Legend(isVisible: false),
            tooltipBehavior: TooltipBehavior(
                enable: true,
                format: 'point.x : point.y${isRisk ? '%' : ''}'
            ),
            primaryXAxis: CategoryAxis(
              majorGridLines: const MajorGridLines(width: 0),
              labelRotation: selectedPeriod == 'Monthly' ? 0 : 45,
              labelStyle: const TextStyle(fontSize: 12),
            ),
            primaryYAxis: NumericAxis(
              minimum: 0,
              maximum: isRisk ? 100 : 100,
              interval: 20,
              axisLine: const AxisLine(width: 0),
              labelFormat: '{value}${isRisk ? '%' : ''}',
            ),
            series: <CartesianSeries>[
              SplineAreaSeries<HealthData, String>(
                dataSource: data,
                xValueMapper: (HealthData health, _) => health.period,
                yValueMapper: (HealthData health, _) => health.value,
                color: color.withOpacity(0.3),
                borderColor: color,
                borderWidth: 3,
                markerSettings: MarkerSettings(
                  isVisible: true,
                  color: color,
                  borderColor: Colors.white,
                  borderWidth: 2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class HealthData {
  final String period;
  final double value;

  HealthData(this.period, this.value);
}
