import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:http_parser/http_parser.dart';

class EmotionUploadScreen extends StatefulWidget {
  const EmotionUploadScreen({super.key});

  @override
  State<EmotionUploadScreen> createState() => _EmotionUploadScreenState();
}

class _EmotionUploadScreenState extends State<EmotionUploadScreen> {
  File? _selectedImage;
  String _response = '';
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _response = '';
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;

    final uri = Uri.parse('http://13.203.212.95:8000/predict-emotion-image');
    final request = http.MultipartRequest('POST', uri);

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        _selectedImage!.path,
        filename: basename(_selectedImage!.path),
        contentType: MediaType('image', 'jpeg'),
      ),
    );

    setState(() {
      _isLoading = true;
      _response = '';
    });

    try {
      final response = await request.send();
      final respStr = await response.stream.bytesToString();
      setState(() {
        _response = respStr;
      });
      final Map<String, dynamic> result = jsonDecode(respStr);

    } catch (e) {
      setState(() {
        _response = 'Upload failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildImagePreview() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        height: 550,
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        child: _selectedImage != null
            ? ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(_selectedImage!, fit: BoxFit.cover),
        )
            : const Center(child: Text("No image selected")),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          onPressed: () => _pickImage(ImageSource.gallery),
          icon: const Icon(Icons.photo_library),
          label: const Text("Gallery"),
        ),
        ElevatedButton.icon(
          onPressed: () => _pickImage(ImageSource.camera),
          icon: const Icon(Icons.camera_alt),
          label: const Text("Camera"),
        ),
      ],
    );
  }

  Widget _buildUploadButton() {
    return ElevatedButton.icon(
      onPressed: _uploadImage,
      icon: const Icon(Icons.cloud_upload),
      label: const Text("Upload"),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        textStyle: const TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildResponseSection() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: _response.isEmpty
          ? const SizedBox.shrink()
          : Container(
        key: ValueKey(_response),
        margin: const EdgeInsets.only(top: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          _response,
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }

  // void _showResultDialog(String emotion) {
  //   showDialog(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (context) => AlertDialog(
  //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  //       title: Row(
  //         children: [
  //           Icon(Icons.sentiment_satisfied_alt, color: Theme.of(context).primaryColor),
  //           const SizedBox(width: 8),
  //           const Text('Emotion Detected'),
  //         ],
  //       ),
  //       content: Text('We detected: $emotion'),
  //       actions: [
  //         TextButton(
  //           onPressed: () {
  //             Navigator.of(context).pop();
  //             setState(() {
  //               _showPreview = false;
  //               _capturedImage = null;
  //               _selectedImage = null;
  //             });
  //           },
  //           child: const Text('Retake'),
  //         ),
  //         ElevatedButton(
  //           onPressed: () {
  //             Navigator.of(context).pop();
  //             Navigator.of(context).pop();
  //           },
  //           child: const Text('Done'),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emotion Detection'),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildImagePreview(),
            const SizedBox(height: 16),
            _buildActionButtons(),
            const SizedBox(height: 16),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: CircularProgressIndicator(),
              ),
            _buildUploadButton(),
            _buildResponseSection(),
          ],
        ),
      ),
    );
  }

}
