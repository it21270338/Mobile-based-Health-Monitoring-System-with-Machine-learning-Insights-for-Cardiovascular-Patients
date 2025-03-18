import 'package:flutter/material.dart';
import 'package:healthy_heart/commonComponents/customAppBar.dart';
import 'package:healthy_heart/commonComponents/healthAlert.dart';
import 'package:healthy_heart/screens/userFeel/relaxation.dart';
import 'package:healthy_heart/screens/userFeel/relaxation_music.dart';
import 'package:healthy_heart/screens/userFeel/relaxation_songs.dart';
import 'package:healthy_heart/utils/shared_prefs.dart';

class RelaxationMethod extends StatefulWidget {
  final String emotion;

  const RelaxationMethod({Key? key, required this.emotion}) : super(key: key);

  @override
  State<RelaxationMethod> createState() => _RelaxationMethodState();
}

class _RelaxationMethodState extends State<RelaxationMethod> {
  String get _getEmotionEmoji {
    switch (widget.emotion.toLowerCase()) {
      case 'anger':
        return '😠';
      case 'fear':
        return '😨';
      case 'sadness':
        return '😢';
      default:
        return '😔';
    }
  }

  @override
  void initState() {
    super.initState();
    _ShowNotify();
  }

  Future<void> _ShowNotify() async {
    final id = await SharedPrefs.getUserId();
    showEmotionAlert(context, id!, widget.emotion);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Relaxation Methods'),
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
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(
                          _getEmotionEmoji,
                          style: const TextStyle(fontSize: 48),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "We noticed you're feeling",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.emotion.toUpperCase(),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Let's help you feel better with these relaxation methods",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  "Choose your preferred method:",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    children: [
                      _buildRelaxationOption(
                        context,
                        "Calming Songs",
                        "Listen to soothing melodies",
                        Icons.music_note,
                        Colors.purple,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    RelaxationSongs(emotion: widget.emotion),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildRelaxationOption(
                        context,
                        "Relaxing Music",
                        "Immerse in peaceful tunes",
                        Icons.queue_music,
                        Colors.blue,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    RelaxationMusic(emotion: widget.emotion),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildRelaxationOption(
                        context,
                        "Mini Games",
                        "Take your mind off with fun activities",
                        Icons.games,
                        Colors.green,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const Relaxation(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "Take your time, you're on the path to feeling better",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRelaxationOption(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
