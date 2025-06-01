import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:MediSafe/commonComponents/customAppBar.dart';
import 'package:MediSafe/commonComponents/healthAlert.dart';
import 'package:MediSafe/screens/dashboard/health_score_timeline_screen.dart';
import 'package:MediSafe/screens/dashboard/health_tips_screen.dart';
import 'package:MediSafe/services/apiDio.dart';
import 'package:MediSafe/utils/shared_prefs.dart';

class RevalidateScreen extends StatefulWidget {
  const RevalidateScreen({super.key});

  @override
  State<RevalidateScreen> createState() => _RevalidateScreenState();
}

void _showHealthResultsDialog(BuildContext context, Map<String, dynamic> results) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min, // Make row take minimum space
          children: [
            Icon(
              results['risk_level'] == 'High' ? Icons.warning : Icons.check_circle,
              color: results['risk_level'] == 'High' ? Colors.red : Colors.green,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Flexible( // Allows text to wrap
              child: Text(
                'Health Assessment Results',
                style: TextStyle(
                  fontSize: 18, // Slightly smaller text
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.visible, // Allow text to wrap
              ),
            ),
          ],
        ),
        content: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7, // Responsive height
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 12),
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
                            '${results['health_score'].toStringAsFixed(1)}',
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
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: results['risk_level'] == 'High'
                        ? Colors.red.withOpacity(0.1)
                        : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${results['risk_level']} Health Risk',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: results['risk_level'] == 'High'
                              ? Colors.red
                              : Colors.green,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Risk Level: ${results['risk_probability'].toStringAsFixed(1)}%',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Recommendations:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...List<Widget>.from(
                        results['recommendations'].map((recommendation) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.arrow_right, size: 20),
                              Expanded(
                                child: Text(recommendation),
                              ),
                            ],
                          ),
                        )),
                      ),
                    ],
                  ),
                ),

              ],
            ),
          ),
        ),

        actions: [

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HealthTipsScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.lightbulb_outline),
                  label: const Text('View Health Tips'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(12),
                    backgroundColor: Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HealthScoreTimelineScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.timeline, color: Colors.white),
                  label: const Text(
                    'View Health Timeline',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(12),
                    backgroundColor: Colors.purple,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}

class _RevalidateScreenState extends State<RevalidateScreen> {
  String? userId;
  final _formKey = GlobalKey<FormState>();
  final _bloodSugarController = TextEditingController();
  final _cholesterolController = TextEditingController();
  bool _isSmoking = false;
  bool _consumesAlcohol = false;
  bool _isLoading = true;

  // Health metrics from API
  double _heartRate = 0;
  double _height = 0;
  double _weight = 0;
  double _bmi = 0.0;

  final apiClient = apiDio();

  void _calculateBMI() {
    if (_height > 0 && _weight > 0) {
      double heightInMeters = _height / 100; // convert cm to m
      setState(() {
        _bmi = _weight / (heightInMeters * heightInMeters);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      // Load user ID
      final id = await SharedPrefs.getUserId();
      setState(() {
        userId = id;
      });

      // Load health metrics from API
      await _loadHealthMetrics();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading user data: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadHealthMetrics() async {
    try {
      final apiService = apiDio();
      final metrics = await apiService.getHealthMetrics(context);

      setState(() {
        _heartRate = (metrics['heart_rate'] ?? 0).toDouble();
        _height = (metrics['height'] ?? 0).toDouble();
        _weight = (metrics['weight'] ?? 0).toDouble();
      });

      // Calculate BMI with the loaded values
      _calculateBMI();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading health metrics: $e')),
      );
    }
  }

  Future<void> _submitData() async {
    if (_formKey.currentState!.validate()) {
      try {
        final result = await apiClient.predictHeartRisk(
            heartRate: _heartRate,
            bloodSugar: double.parse(_bloodSugarController.text),
            height: _height,
            weight: _weight,
            cholesterol: double.parse(_cholesterolController.text),
            smoking: _isSmoking,
            alcohol: _consumesAlcohol,
            bmi: _bmi,
            userId: userId!
        );

        if (result['status'] == 'success') {
          _showHealthResultsDialog(context, result);
          if (result['risk_level'] == 'High') {
            showHealthAlert(context, userId!);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${result['message']}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Health Metrics Revalidation'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                          'Your Current Metrics',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Display heart rate
                        ListTile(
                          leading: const Icon(Icons.favorite, color: Colors.red),
                          title: const Text('Heart Rate'),
                          trailing: Text(
                            '${_heartRate.toInt()} bpm',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),

                        // Display height and weight
                        ListTile(
                          leading: const Icon(Icons.height, color: Colors.blue),
                          title: const Text('Height'),
                          trailing: Text(
                            '${_height.toInt()} cm',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),

                        ListTile(
                          leading: const Icon(Icons.monitor_weight, color: Colors.green),
                          title: const Text('Weight'),
                          trailing: Text(
                            '${_weight.toInt()} kg',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),

                        // Display BMI
                        if (_bmi > 0) ...[
                          ListTile(
                            leading: const Icon(Icons.calculate, color: Colors.purple),
                            title: const Text('Body Mass Index (BMI)'),
                            trailing: Text(
                              '${_bmi.toStringAsFixed(1)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: _getBmiColor(_bmi),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

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
                          'Additional Health Metrics',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildNumericField(
                          controller: _bloodSugarController,
                          label: 'Blood Sugar (mg/dL)',
                          icon: Icons.water_drop,
                          hint: '70-140',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter blood sugar level';
                            }
                            int? sugar = int.tryParse(value);
                            if (sugar == null || sugar < 20 || sugar > 600) {
                              return 'Enter a valid blood sugar level';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildNumericField(
                          controller: _cholesterolController,
                          label: 'Cholesterol (mg/dL)',
                          icon: Icons.science,
                          hint: '150-200',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter cholesterol level';
                            }
                            int? chol = int.tryParse(value);
                            if (chol == null || chol < 50 || chol > 500) {
                              return 'Enter a valid cholesterol level';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

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
                          'Lifestyle Factors (occasional)',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          title: const Text('Do you smoke?'),
                          value: _isSmoking,
                          onChanged: (bool value) {
                            setState(() {
                              _isSmoking = value;
                            });
                          },
                          secondary: Icon(
                            Icons.smoking_rooms,
                            color: _isSmoking ? Colors.red : Colors.grey,
                          ),
                        ),
                        SwitchListTile(
                          title: const Text('Do you consume alcohol?'),
                          value: _consumesAlcohol,
                          onChanged: (bool value) {
                            setState(() {
                              _consumesAlcohol = value;
                            });
                          },
                          secondary: Icon(
                            Icons.local_bar,
                            color: _consumesAlcohol ? Colors.orange : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitData,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Submit',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Center(
                  child: TextButton.icon(
                    onPressed: _loadHealthMetrics,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh Health Data'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getBmiColor(double bmi) {
    if (bmi < 18.5) return Colors.blue; // Underweight
    if (bmi < 25) return Colors.green; // Normal
    if (bmi < 30) return Colors.orange; // Overweight
    return Colors.red; // Obese
  }

  Widget _buildNumericField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    required String? Function(String?) validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: validator,
      onChanged: onChanged,
    );
  }

  @override
  void dispose() {
    _bloodSugarController.dispose();
    _cholesterolController.dispose();
    super.dispose();
  }
}
