import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:MediSafe/commonComponents/customAppBar.dart';
import 'package:MediSafe/screens/ecgReport/qaScreen.dart';
import 'package:MediSafe/services/apiDio.dart';
import 'package:MediSafe/utils/shared_prefs.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';


class ECGReportScreen extends StatefulWidget {
  const ECGReportScreen({super.key});

  @override
  State<ECGReportScreen> createState() => _ECGReportScreenState();
}

class _ECGReportScreenState extends State<ECGReportScreen> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool isLoading = false;
  String? uploadStatus;
  final apiClient = apiDio();

  Map<String, dynamic> latestScores = {
    'health_score': 0.0,
    'risk_level': 'Unknown',
    'risk_probability': 0.0,
  };

  Future<void> _uploadImage() async {
    if (_imageFile == null) return;

    try {
      setState(() {
        isLoading = true;
        uploadStatus = 'Uploading...';
      });

      String userId = 'current-user-id'; // Replace with actual user ID
      final id = await SharedPrefs.getUserId();

      final result = await apiClient.uploadECGReport(_imageFile!, id!);
      final UserRiskresult = await apiClient.getLatestHealthRecord(id!);

      setState(() {
        if (result['status'] == 'success') {
          uploadStatus = 'Upload successful!';
          latestScores = UserRiskresult;

          // Navigate to Q&A screen if questions are available
          if (result['questions_and_answers'] != null &&
              result['questions_and_answers'].isNotEmpty) {

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ECGQuestionsScreen(
                  questionsAndAnswers: result['questions_and_answers'],
                  healthScore: latestScores['health_score'], //result['health_score'].toString(),
                  riskLevel: latestScores['risk_level'], //result['risk_level'],
                  riskProbability: latestScores['risk_probability'], // result['risk_probability'],
                ),
              ),
            );
          }
        } else {
          uploadStatus = 'Upload failed: ${result['message']}';
          print(result);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.red,
            ),
          );

        }
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        uploadStatus = 'Upload failed: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1800,
        maxHeight: 1800,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          uploadStatus = null;
        });
      }
    } catch (e) {
      setState(() {
        uploadStatus = 'Error picking image: $e';
      });
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choose ECG Report Image',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildOptionButton(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onTap: () {
                      Navigator.pop(context);
                      _getImage(ImageSource.camera);
                    },
                  ),
                  _buildOptionButton(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: () {
                      Navigator.pop(context);
                      _getImage(ImageSource.gallery);
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              size: 30,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(label),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'ECG Report'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Upload ECG Report',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please upload a clear image of your ECG report',
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_imageFile != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _imageFile!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 300,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Center(
                      child: _imageFile == null
                          ? ElevatedButton.icon(
                        onPressed: _showImagePickerOptions,
                        icon: const Icon(Icons.add_photo_alternate),
                        label: const Text('Select Image'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      )
                          : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _showImagePickerOptions,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Change Image'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed:
                            isLoading ? null : _uploadImage,
                            icon: const Icon(Icons.upload),
                            label: const Text('Upload'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (uploadStatus != null) ...[
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          uploadStatus!,
                          style: TextStyle(
                            color: uploadStatus!.contains('successful')
                                ? Colors.green
                                : uploadStatus!.contains('failed')
                                ? Colors.red
                                : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    if (isLoading) ...[
                      const SizedBox(height: 16),
                      const Center(child: CircularProgressIndicator()),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
