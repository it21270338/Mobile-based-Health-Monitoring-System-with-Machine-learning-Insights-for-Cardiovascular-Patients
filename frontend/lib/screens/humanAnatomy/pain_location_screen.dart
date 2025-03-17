import 'package:flutter/material.dart';
import 'package:body_part_selector/body_part_selector.dart';
import 'package:healthy_heart/commonComponents/healthAlert.dart';
import 'package:healthy_heart/screens/humanAnatomy/pain_history_screen.dart';
import 'package:healthy_heart/services/apiDio.dart';
import 'package:healthy_heart/utils/shared_prefs.dart';

class PainDetails {
  final String bodyPart;
  final String accompanyingSymptoms;
  final String activityType;
  final int painDurationMinutes;
  final int heartRate;

  PainDetails({
    required this.bodyPart,
    required this.accompanyingSymptoms,
    required this.activityType,
    required this.painDurationMinutes,
    required this.heartRate,
  });
}

class PainLocationScreen extends StatefulWidget {
  @override
  _PainLocationScreenState createState() => _PainLocationScreenState();
}

class _PainLocationScreenState extends State<PainLocationScreen> {
  // Helper method to get color based on risk level
  Color _getRiskColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  BodyParts _bodyParts = const BodyParts(
    head: false,
    neck: false,
    leftShoulder: false,
    leftUpperArm: false,
    leftElbow: false,
    leftLowerArm: false,
    leftHand: false,
    rightShoulder: false,
    rightUpperArm: false,
    rightElbow: false,
    rightLowerArm: false,
    rightHand: false,
    upperBody: false,
    lowerBody: false,
    leftUpperLeg: false,
    leftKnee: false,
    leftLowerLeg: false,
    leftFoot: false,
    rightUpperLeg: false,
    rightKnee: false,
    rightLowerLeg: false,
    rightFoot: false,
    abdomen: false,
    vestibular: false,
  );

  String? selectedBodyPart;
  String? selectedSymptom;
  String? selectedActivity;
  TextEditingController durationController = TextEditingController();

  // Heart rate from API
  int _heartRate = 0;
  bool _isLoadingHeartRate = false;
  String? _heartRateError;

  final List<String> accompanyingSymptoms = [
    'none',
    'shortness_of_breath',
    'sweating',
    'nausea',
    'dizziness',
    'multiple',
  ];

  final List<String> activityTypes = [
    'resting',
    'walking',
    'running',
    'weightlifting',
    'swimming',
    'cycling',
    'yoga',
    'hiit',
    'climbing',
    'sleeping',
    'desk_work',
    'housework',
    'gardening',
  ];

  Future<void> _loadHeartRate() async {
    setState(() {
      _isLoadingHeartRate = true;
      _heartRateError = null;
    });

    try {
      final apiService = apiDio();
      final metrics = await apiService.getHealthMetrics(context);

      setState(() {
        _heartRate = (metrics['heart_rate'] ?? 0).toInt();
        _isLoadingHeartRate = false;
      });
    } catch (e) {
      setState(() {
        _heartRateError = e.toString();
        _isLoadingHeartRate = false;
      });
    }
  }

  void _showDetailsForm() async {
    // Load heart rate before showing the form
    await _loadHeartRate();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Pain Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),

                      // Heart Rate Display
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.favorite, color: Colors.red),
                                SizedBox(width: 8),
                                Text(
                                  'Heart Rate',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Spacer(),
                                if (_isLoadingHeartRate)
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                else
                                  IconButton(
                                    icon: Icon(Icons.refresh, size: 20),
                                    onPressed: () {
                                      _loadHeartRate();
                                      setState(() {});
                                    },
                                  ),
                              ],
                            ),
                            SizedBox(height: 8),
                            if (_heartRateError != null)
                              Text(
                                'Error loading heart rate. Using default value.',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              )
                            else
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '$_heartRate bpm',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),

                      // Accompanying Symptoms Dropdown
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Accompanying Symptoms',
                          border: OutlineInputBorder(),
                        ),
                        value: selectedSymptom,
                        items:
                            accompanyingSymptoms.map((String symptom) {
                              return DropdownMenuItem<String>(
                                value:
                                    symptom, // Original lowercase value for API
                                child: Text(
                                  // Display with first letter of each word capitalized
                                  symptom
                                      .split('_')
                                      .map(
                                        (word) =>
                                            word.isNotEmpty
                                                ? '${word[0].toUpperCase()}${word.substring(1)}'
                                                : '',
                                      )
                                      .join(' '),
                                ),
                              );
                            }).toList(),
                        onChanged: (String? value) {
                          setState(() {
                            selectedSymptom =
                                value; // Store original lowercase value
                          });
                        },
                      ),

                      SizedBox(height: 16),

                      // Activity Type Dropdown
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Latest Activity',
                          border: OutlineInputBorder(),
                        ),
                        value: selectedActivity,
                        items:
                            activityTypes.map((String activity) {
                              return DropdownMenuItem<String>(
                                value:
                                    activity, // Original lowercase value for API
                                child: Text(
                                  // Display with first letter of each word capitalized
                                  activity
                                      .split('_')
                                      .map(
                                        (word) =>
                                            word.isNotEmpty
                                                ? '${word[0].toUpperCase()}${word.substring(1)}'
                                                : '',
                                      )
                                      .join(' '),
                                ),
                              );
                            }).toList(),
                        onChanged: (String? value) {
                          setState(() {
                            selectedActivity =
                                value; // Store original lowercase value
                          });
                        },
                      ),
                      SizedBox(height: 16),

                      // Pain Duration TextField
                      TextField(
                        controller: durationController,
                        decoration: InputDecoration(
                          labelText: 'Pain Duration (minutes)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      SizedBox(height: 24),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (selectedSymptom != null &&
                                selectedActivity != null &&
                                durationController.text.isNotEmpty &&
                                _heartRate > 0) {
                              PainDetails details = PainDetails(
                                bodyPart: selectedBodyPart!,
                                accompanyingSymptoms: selectedSymptom!,
                                activityType: selectedActivity!,
                                painDurationMinutes: int.parse(
                                  durationController.text,
                                ),
                                heartRate: _heartRate,
                              );

                              // Call the API to predict heart risk
                              try {
                                final id = await SharedPrefs.getUserId();
                                final apiService = apiDio();
                                final riskLevel = await apiService
                                    .predictHeartRiskViaLocation(
                                      heartRate: details.heartRate,
                                      painDurationMinutes:
                                          details.painDurationMinutes,
                                      activityType: details.activityType,
                                      painLocation: details.bodyPart,
                                      accompanyingSymptoms:
                                          details.accompanyingSymptoms,
                                      userID: id!,
                                    );
                                print(riskLevel);

                                // Close the bottom sheet
                                Navigator.pop(context);

                                // Show success message with risk level
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Pain details saved. Risk level: ${riskLevel.toString()}',
                                    ),
                                    backgroundColor: _getRiskColor(
                                      riskLevel.toString(),
                                    ),
                                  ),
                                );

                                if (riskLevel == "high") {
                                  showHealthAlert(context, id);
                                }

                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PainHistoryScreen(),
                                  ),
                                );
                              } catch (e) {
                                // Show error message
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: ${e.toString()}'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Please fill all fields and ensure heart rate is available',
                                  ),
                                ),
                              );
                            }
                          },
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Text('Save Pain Details'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _handleBodyPartSelection(BodyParts parts) {
    setState(() => _bodyParts = parts);

    // Reset selectedBodyPart
    selectedBodyPart = null;

    // Determine which body part was selected
    if (parts.head == true)
      selectedBodyPart = "head";
    else if (parts.neck == true)
      selectedBodyPart = "neck";
    else if (parts.leftShoulder == true)
      selectedBodyPart = "left_shoulder";
    else if (parts.leftUpperArm == true)
      selectedBodyPart = "left_upper_arm";
    else if (parts.leftElbow == true)
      selectedBodyPart = "left_elbow";
    else if (parts.leftLowerArm == true)
      selectedBodyPart = "left_lower_arm";
    else if (parts.leftHand == true)
      selectedBodyPart = "left_hand";
    else if (parts.rightShoulder == true)
      selectedBodyPart = "right_shoulder";
    else if (parts.rightUpperArm == true)
      selectedBodyPart = "right_upper_arm";
    else if (parts.rightElbow == true)
      selectedBodyPart = "right_elbow";
    else if (parts.rightLowerArm == true)
      selectedBodyPart = "right_lower_arm";
    else if (parts.rightHand == true)
      selectedBodyPart = "right_hand";
    else if (parts.upperBody == true)
      selectedBodyPart = "upper_body";
    else if (parts.lowerBody == true)
      selectedBodyPart = "lower_body";
    else if (parts.leftUpperLeg == true)
      selectedBodyPart = "left_upper_leg";
    else if (parts.leftKnee == true)
      selectedBodyPart = "left_knee";
    else if (parts.leftLowerLeg == true)
      selectedBodyPart = "left_lower_leg";
    else if (parts.leftFoot == true)
      selectedBodyPart = "left_foot";
    else if (parts.rightUpperLeg == true)
      selectedBodyPart = "right_upper_leg";
    else if (parts.rightKnee == true)
      selectedBodyPart = "right_knee";
    else if (parts.rightLowerLeg == true)
      selectedBodyPart = "right_lower_leg";
    else if (parts.rightFoot == true)
      selectedBodyPart = "right_foot";
    else if (parts.abdomen == true)
      selectedBodyPart = "abdomen";
    else if (parts.vestibular == true)
      selectedBodyPart = "vestibular";

    // Only show form if a body part is actually selected
    if (selectedBodyPart != null) {
      _showDetailsForm();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Mark The Pain Location")),
      body: SafeArea(
        child: BodyPartSelectorTurnable(
          bodyParts: _bodyParts,
          onSelectionUpdated: _handleBodyPartSelection,
          labelData: const RotationStageLabelData(
            front: 'Front',
            left: 'Left',
            right: 'Right',
            back: 'Back',
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    durationController.dispose();
    super.dispose();
  }
}
