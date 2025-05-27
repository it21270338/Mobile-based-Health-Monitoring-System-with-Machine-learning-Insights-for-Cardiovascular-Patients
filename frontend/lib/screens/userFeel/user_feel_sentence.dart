import 'package:flutter/material.dart';
import 'package:MediSafe/commonComponents/healthAlert.dart';
import 'package:MediSafe/screens/userFeel/relaxation_method.dart';
import 'package:MediSafe/services/apiDio.dart';
import 'package:MediSafe/utils/shared_prefs.dart';

class UserFeelSentence extends StatefulWidget {
  const UserFeelSentence({super.key});

  @override
  State<UserFeelSentence> createState() => _UserFeelSentenceState();
}

class _UserFeelSentenceState extends State<UserFeelSentence> {
  final TextEditingController _textController = TextEditingController();
  final apiDio _apiDio = apiDio();
  bool _isLoading = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      setState(() {
        _hasText = _textController.text.trim().isNotEmpty;
      });
    });
  }

  bool needsRelaxation(String emotion) {
    return ['anger', 'fear', 'sadness'].contains(emotion.toLowerCase());
  }

  Future<void> _predictEmotion() async {
    if (!_hasText) {
      _showErrorSnackbar('Please share how you\'re feeling');
      return;
    }

    setState(() => _isLoading = true);

    final userId = await SharedPrefs.getUserId();

    try {
      final result = await _apiDio.predictEmotion(_textController.text,userId!);

      if (result['status'] == 'success') {
        final emotion = result['emotion'];

        if (needsRelaxation(emotion)) {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RelaxationMethod(
                  emotion: emotion,
                  // userText: _textController.text,
                ),
              ),
            );
          }
        } else {
          _showSuccessSnackbar(
            emotion.toLowerCase() == 'joy' || emotion.toLowerCase() == 'love'
                ? "That's wonderful! Keep embracing this positive feeling! 🌟"
                : "Thank you for sharing we detect your emotion as $emotion",
          );
        }
      } else {
        _showErrorSnackbar(result['message']);
      }
    } catch (e) {
      _showErrorSnackbar(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.green.shade400,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    // Auto dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
    });
  }


  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Express Your Feelings"),
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.inversePrimary.withOpacity(0.3),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "How are you feeling today?",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  "Your feelings matter. Share them freely...",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                Expanded(
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: _textController,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        style: const TextStyle(
                          fontSize: 18,
                          height: 1.5,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Type your feelings here...',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 18,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _predictEmotion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      elevation: _hasText ? 4 : 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _hasText ? Icons.send : Icons.edit_note,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _hasText ? "Share Feelings" : "Start Writing",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Your input is confidential and helps us understand your emotional state",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
