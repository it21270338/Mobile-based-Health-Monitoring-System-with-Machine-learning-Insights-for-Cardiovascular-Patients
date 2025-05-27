import 'package:flutter/material.dart';
import 'package:MediSafe/commonComponents/customAppBar.dart';
import 'package:MediSafe/services/apiDio.dart';
import 'package:intl/intl.dart';
import 'package:MediSafe/screens/dashboard/health_score_timeline_screen.dart';
import 'package:MediSafe/screens/dashboard/health_tips_screen.dart';

class HealthRecordsScreen extends StatefulWidget {
  const HealthRecordsScreen({Key? key}) : super(key: key);

  @override
  _HealthRecordsScreenState createState() => _HealthRecordsScreenState();
}

class _HealthRecordsScreenState extends State<HealthRecordsScreen> {
  final apiClient = apiDio();
  bool _isLoading = true;
  List<dynamic> _healthRecords = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadHealthRecords();
  }

  Future<void> _loadHealthRecords() async {
    setState(() => _isLoading = true);

    try {
      final records = await apiClient.getUserHealthRecords(context, limit: 20);
      setState(() {
        _healthRecords = records;
        _isLoading = false;
        _errorMessage = '';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  String _formatDate(String isoDateString) {
    try {
      final date = DateTime.parse(isoDateString);
      return DateFormat('MMM d, yyyy - h:mm a').format(date);
    } catch (e) {
      return 'Unknown date';
    }
  }

  void _showRecordDetails(Map<String, dynamic> record) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                record['risk_level'] == 'High' ? Icons.warning : Icons.check_circle,
                color: record['risk_level'] == 'High' ? Colors.red : Colors.green,
                size: 24,
              ),
              const SizedBox(width: 8),
              Flexible( // Allows text to wrap
                child: Text(
                  'Health Record (${_formatDate(record['timestamp'])})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.visible,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Health Score
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          const Text(
                            'Health Score',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            '${record['health_score'].toStringAsFixed(1)}',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Risk Level
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: record['risk_level'] == 'High'
                        ? Colors.red.withOpacity(0.1)
                        : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${record['risk_level']} Health Risk',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: record['risk_level'] == 'High'
                              ? Colors.red
                              : Colors.green,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Risk Level: ${record['risk_probability'].toStringAsFixed(1)}%',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Health Metrics
                if (record['user_data'] != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Health Metrics:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildMetricRow('Heart Rate', '${record['user_data']['heart_rate']} bpm', Icons.favorite),
                        _buildMetricRow('Blood Sugar', '${record['user_data']['blood_sugar']} mg/dL', Icons.water_drop),
                        _buildMetricRow('Height', '${record['user_data']['height']} cm', Icons.height),
                        _buildMetricRow('Weight', '${record['user_data']['weight']} kg', Icons.monitor_weight),
                        _buildMetricRow('Cholesterol', '${record['user_data']['cholesterol']} mg/dL', Icons.science),
                        _buildMetricRow('BMI', '${record['user_data']['bmi'].toStringAsFixed(1)}', Icons.calculate),
                        _buildMetricRow('BMI Category', '${record['bmi_category']}', Icons.category),
                        _buildMetricRow('Smoking', record['user_data']['smoking'] == 1 ? 'Yes' : 'No', Icons.smoking_rooms),
                        _buildMetricRow('Alcohol', record['user_data']['alcohol'] == 1 ? 'Yes' : 'No', Icons.local_bar),
                        _buildMetricRow('Reason', record['user_data']['alcohol'] == 1 ? 'Yes' : 'No', Icons.local_bar),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Health Records',
        showHomeButton: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error loading records',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(_errorMessage),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadHealthRecords,
              child: const Text('Retry'),
            ),
          ],
        ),
      )
          : _healthRecords.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.note_alt_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No Health Records',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text('Complete a health assessment to see your records here.'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Navigate to health assessment screen
                Navigator.pop(context);
              },
              child: const Text('Start Assessment'),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadHealthRecords,
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: _healthRecords.length,
          itemBuilder: (context, index) {
            final record = _healthRecords[index];
            final date = _formatDate(record['timestamp']);
            final isHighRisk = record['risk_level'] == 'High';

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isHighRisk ? Colors.red.withOpacity(0.5) : Colors.green.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: InkWell(
                  onTap: () => _showRecordDetails(record),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isHighRisk ? Icons.warning : Icons.check_circle,
                              color: isHighRisk ? Colors.red : Colors.green,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                date,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isHighRisk
                                    ? Colors.red.withOpacity(0.1)
                                    : Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${record['risk_level']} Risk',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isHighRisk ? Colors.red : Colors.green,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Health Score',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    '${record['health_score'].toStringAsFixed(1)}',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Risk Probability',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    '${record['risk_probability'].toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: isHighRisk ? Colors.red : Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _showRecordDetails(record),
                                icon: const Icon(Icons.visibility),
                                label: const Text('View Details'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
