import 'package:flutter/material.dart';
import 'package:MediSafe/commonComponents/customAppBar.dart';

class HealthTipsScreen extends StatelessWidget {
  const HealthTipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Health Tips'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTipCard(
            title: 'Diet & Nutrition',
            icon: Icons.restaurant,
            color: Colors.green,
            tips: [
              'Eat plenty of fruits and vegetables daily',
              'Choose whole grains over refined grains',
              'Limit processed foods and added sugars',
              'Stay hydrated - drink at least 8 glasses of water daily',
              'Control portion sizes during meals',
            ],
          ),
          const SizedBox(height: 16),
          _buildTipCard(
            title: 'Physical Activity',
            icon: Icons.directions_run,
            color: Colors.blue,
            tips: [
              'Aim for 150 minutes of moderate exercise weekly',
              'Include both cardio and strength training',
              'Take regular breaks from sitting',
              'Try to walk at least 10,000 steps daily',
              'Start with small goals and gradually increase',
            ],
          ),
          const SizedBox(height: 16),
          _buildTipCard(
            title: 'Mental Wellness',
            icon: Icons.psychology,
            color: Colors.purple,
            tips: [
              'Practice daily meditation or mindfulness',
              'Maintain a regular sleep schedule',
              'Take breaks during work hours',
              'Stay connected with friends and family',
              'Set realistic goals and celebrate achievements',
            ],
          ),
          const SizedBox(height: 16),
          _buildTipCard(
            title: 'Heart Health',
            icon: Icons.favorite,
            color: Colors.red,
            tips: [
              'Monitor your blood pressure regularly',
              'Reduce salt intake in your diet',
              'Practice stress management techniques',
              'Maintain a healthy weight',
              'Avoid smoking and limit alcohol consumption',
            ],
          ),
          const SizedBox(height: 16),
          _buildTipCard(
            title: 'Sleep Hygiene',
            icon: Icons.bedtime,
            color: Colors.indigo,
            tips: [
              'Maintain consistent sleep and wake times',
              'Create a relaxing bedtime routine',
              'Keep your bedroom cool and dark',
              'Avoid screens 1 hour before bedtime',
              'Limit caffeine intake after noon',
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<String> tips,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: tips.map((tip) => _buildTipItem(tip)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle,
            size: 20,
            color: Colors.green,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tip,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
