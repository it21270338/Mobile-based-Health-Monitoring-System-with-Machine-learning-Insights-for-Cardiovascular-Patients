import 'package:flutter/material.dart';
import 'package:healthy_heart/commonComponents/customAppBar.dart';
import 'package:healthy_heart/screens/dashboard/health_records_screen.dart';
import 'package:healthy_heart/screens/dashboard/health_score_timeline_screen.dart';
import 'package:healthy_heart/screens/dashboard/health_tips_screen.dart';
import 'package:healthy_heart/screens/dashboard/revalidate_screen.dart';
import 'package:healthy_heart/screens/ecgReport/ecg_report_screen.dart';
import 'package:healthy_heart/screens/humanAnatomy/pain_history_screen.dart';
import 'package:healthy_heart/screens/humanAnatomy/pain_location_screen.dart';
import 'package:healthy_heart/screens/userFeel/emotion_analytics.dart';
import 'package:healthy_heart/screens/userFeel/feel.dart';
import 'package:healthy_heart/services/apiDio.dart';

import '../../utils/shared_prefs.dart';
import '../ecgReport/report_list_screen.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final apiClient = apiDio();
  bool isLoading = true;
  Map<String, dynamic> latestScores = {
    'health_score': 0.0,
    'risk_level': 'Unknown',
    'risk_probability': 0.0,
  };

  @override
  void initState() {
    super.initState();
    _fetchLatestScores();
  }

  Future<void> _fetchLatestScores() async {
    final id = await SharedPrefs.getUserId();
    setState(() {
      isLoading = true;
    });

    try {
      // String userId = '119'; // Replace with actual user ID
      final result = await apiClient.getLatestHealthRecord(id!);

      if (result['status'] == 'success') {
        setState(() {
          latestScores = result;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching latest scores: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Health Dashboard',
        showHomeButton: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Health Score Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Health Overview',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildScoreIndicator(
                                "Health Score",
                                "${latestScores['health_score']?.toStringAsFixed(1)}",
                                Colors.green,
                                Icons.favorite,
                              ),
                              _buildScoreIndicator(
                                "Risk Level",
                                "${latestScores['risk_probability']?.toStringAsFixed(1)}%",
                                latestScores['risk_level'] == 'High'
                                    ? Colors.red
                                    : Colors.orange,
                                Icons.warning_rounded,
                              ),
                            ],
                          ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RevalidateScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text("Revalidate"),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Quick Actions Section
              const Text(
                'Quick Actions',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildActionButton(
                "View Summary User Data",
                Icons.person_outline,
                Colors.blue,
                HealthRecordsScreen(),
              ),
              const SizedBox(height: 12),
              _buildActionButton(
                "Health Score Overtime",
                Icons.timeline,
                Colors.purple,
                HealthScoreTimelineScreen(),
              ),
              const SizedBox(height: 12),
              _buildActionButton(
                "Health Tips",
                Icons.lightbulb_outline,
                Colors.orange,
                HealthTipsScreen(),
              ),
              const SizedBox(height: 12),
              _buildActionButton(
                "ECG Report",
                Icons.document_scanner_outlined,
                Colors.red,
                ECGReportScreen(),
              ),
              const SizedBox(height: 12),
              _buildActionButton(
                "ECG Report Summary",
                Icons.document_scanner_outlined,
                Colors.red,
                ReportListScreen(),
              ),
              const SizedBox(height: 12),
              _buildActionButton(
                "Pain Localization",
                Icons.personal_injury,
                Colors.green,
                PainLocationScreen(),
              ),
              const SizedBox(height: 12),
              _buildActionButton(
                "Pain History",
                Icons.personal_injury,
                Colors.green,
                PainHistoryScreen(),
              ),
              const SizedBox(height: 12),
              _buildActionButton(
                "User Feeling",
                Icons.emoji_emotions_outlined,
                Colors.purpleAccent,
                UserFeel(),
              ),
              const SizedBox(height: 12),
              _buildActionButton(
                "User Emotion Analytics",
                Icons.emoji_emotions_outlined,
                Colors.purpleAccent,
                EmotionDashboardScreen(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreIndicator(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 32),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    Widget screen,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => screen),
          );
        },
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}
