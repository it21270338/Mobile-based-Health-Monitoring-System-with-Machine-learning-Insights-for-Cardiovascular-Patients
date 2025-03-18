import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:healthy_heart/screens/userFeel/relaxation_method.dart';
import 'dart:io';

import 'package:healthy_heart/services/apiDio.dart';

class UserFeelCamera extends StatefulWidget {
  const UserFeelCamera({super.key});

  @override
  State<UserFeelCamera> createState() => _UserFeelCameraState();
}

class _UserFeelCameraState extends State<UserFeelCamera>
    with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  bool _isCapturing = false;
  bool _showPreview = false;
  File? _capturedImage;
  final apiDio _apiDio = apiDio();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      frontCamera,
      ResolutionPreset.high, // Use a higher resolution preset
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      await _controller!.setFocusMode(FocusMode.auto); // Set focus mode
      await _controller!.setFlashMode(FlashMode.auto); // Set flash mode

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  Future<void> _captureImage() async {
    if (!_isCameraInitialized || _isCapturing) return;

    setState(() {
      _isCapturing = true;
    });

    try {
      // Add a delay to allow the camera to stabilize
      await Future.delayed(const Duration(milliseconds: 500));

      final XFile image = await _controller!.takePicture();
      setState(() {
        _capturedImage = File(image.path);
        _showPreview = true;
      });

      // Debug the captured image
      print('Image path: ${image.path}');
      print('Image size: ${await image.length()} bytes');
    } catch (e) {
      print('Error capturing image: $e');
    } finally {
      setState(() {
        _isCapturing = false;
      });
    }
  }

  bool needsRelaxation(String emotion) {
    return ['angry', 'fear', 'sad'].contains(emotion.toLowerCase());
  }

  Future<void> _uploadImage() async {
    if (_capturedImage == null) return;

    setState(() {
      _isCapturing = true;
    });

    try {
      final result = await _apiDio.predictEmotionViaCamera(_capturedImage!);

      if (result['status'] == 'success') {
        final emotion = result['emotion'];

        if (needsRelaxation(emotion)) {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RelaxationMethod(emotion: emotion),
              ),
            );
          }
        } else {
          _showResultDialog(result['emotion']);
        }
      } else {
        _showErrorSnackbar(result['message']);
      }
    } catch (e) {
      _showErrorSnackbar('Error uploading image: $e');
    } finally {
      setState(() {
        _isCapturing = false;
      });
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showResultDialog(String emotion) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.sentiment_satisfied_alt,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                const Text('Emotion Detected'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Text('We detected: $emotion')],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _showPreview = false;
                    _capturedImage = null;
                  });
                },
                child: const Text('Retake'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(); // Return to previous screen
                },
                child: const Text('Done'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emotion Detection'),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Camera guide card
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Theme.of(context).primaryColor),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Position your face in the center and maintain a neutral expression',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          // Camera preview or captured image
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_isCameraInitialized && !_showPreview)
                  CameraPreview(_controller!)
                else if (_showPreview && _capturedImage != null)
                  Image.file(_capturedImage!),

                // Face outline guide
                if (!_showPreview)
                  Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      shape: BoxShape.circle,
                    ),
                  ),

                if (_isCapturing) const CircularProgressIndicator(),
              ],
            ),
          ),
          // Bottom controls
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (_showPreview) ...[
                  _buildControlButton(
                    icon: Icons.refresh,
                    label: 'Retake',
                    onPressed: () {
                      setState(() {
                        _showPreview = false;
                        _capturedImage = null;
                      });
                    },
                  ),
                  _buildControlButton(
                    icon: Icons.check,
                    label: 'Upload',
                    onPressed: _uploadImage,
                  ),
                ] else
                  _buildControlButton(
                    icon: Icons.camera,
                    label: 'Capture',
                    onPressed: _captureImage,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(24),
            backgroundColor: Theme.of(context).primaryColor,
          ),
          child: Icon(icon, size: 32, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(label),
      ],
    );
  }
}
