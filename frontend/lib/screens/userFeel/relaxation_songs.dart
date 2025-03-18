import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class RelaxationSongs extends StatefulWidget {
  final String emotion;

  const RelaxationSongs({
    Key? key,
    required this.emotion,
  }) : super(key: key);

  @override
  State<RelaxationSongs> createState() => _RelaxationSongsState();
}

class _RelaxationSongsState extends State<RelaxationSongs> {
  final AudioPlayer audioPlayer = AudioPlayer();
  String? currentlyPlayingSong;
  Duration? totalDuration;
  Duration currentPosition = Duration.zero;

  final Map<String, List<Map<String, String>>> emotionSongs = {
    'anger': [
      {
        'title': 'Calm Down',
        'asset': 'songs/anger/meditation-relaxation-track-287420.mp3',
        'duration': '3:45',
        'description': 'Soothing meditation track for stress relief'
      },
      {
        'title': 'Peaceful Mind',
        'asset': 'songs/anger/relax-calm-piano-261486.mp3',
        'duration': '4:20',
        'description': 'Calming piano melody for inner peace'
      },
    ],
    'fear': [
      {
        'title': 'Courage',
        'asset': 'songs/fear/epic-story-of-courage-231643.mp3',
        'duration': '5:15',
        'description': 'Inspiring melody to build confidence'
      },
    ],
    'sadness': [
      {
        'title': 'Hope',
        'asset': 'songs/sadness/hope-295455.mp3',
        'duration': '4:10',
        'description': 'Uplifting tune to brighten your mood'
      },
      {
        'title': 'New Day',
        'asset': 'songs/sadness/sahara-267660.mp3',
        'duration': '3:55',
        'description': 'Fresh and energizing morning melody'
      },
    ],
  };

  @override
  void initState() {
    super.initState();
    setupAudioPlayer();
  }

  void setupAudioPlayer() {
    audioPlayer.onDurationChanged.listen((Duration d) {
      setState(() => totalDuration = d);
    });

    audioPlayer.onPositionChanged.listen((Duration p) {
      setState(() => currentPosition = p);
    });

    audioPlayer.onPlayerComplete.listen((_) {
      setState(() {
        currentlyPlayingSong = null;
        currentPosition = Duration.zero;
      });
    });
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }

  Future<void> playPause(String asset) async {
    if (currentlyPlayingSong == asset) {
      await audioPlayer.pause();
      setState(() => currentlyPlayingSong = null);
    } else {
      if (currentlyPlayingSong != null) {
        await audioPlayer.stop();
      }
      await audioPlayer.play(AssetSource(asset));
      setState(() => currentlyPlayingSong = asset);
    }
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  String _normalizeEmotion(String emotion) {
    emotion = emotion.toLowerCase();
    if (emotion.contains('anger') || emotion.contains('angry')) {
      return 'anger';
    }
    if (emotion.contains('fear') || emotion.contains('scared')) {
      return 'fear';
    }
    if (emotion.contains('sadness') || emotion.contains('sad')) {
      return 'sadness';
    }
    return emotion;
  }

  @override
  Widget build(BuildContext context) {
    final normalizedEmotion = _normalizeEmotion(widget.emotion);
    final songs = emotionSongs[normalizedEmotion] ?? [];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Soothing Melodies"),
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Recommended for ${widget.emotion}",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Let these melodies guide you to tranquility",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView.builder(
                    itemCount: songs.length,
                    itemBuilder: (context, index) {
                      final song = songs[index];
                      final isPlaying = currentlyPlayingSong == song['asset'];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: isPlaying ? 8 : 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: InkWell(
                          onTap: () => playPause(song['asset']!),
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .primaryColor
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        isPlaying
                                            ? Icons.pause_rounded
                                            : Icons.play_arrow_rounded,
                                        size: 32,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            song['title']!,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            song['description']!,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      song['duration']!,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                if (isPlaying && totalDuration != null) ...[
                                  const SizedBox(height: 16),
                                  LinearProgressIndicator(
                                    value: currentPosition.inMilliseconds /
                                        totalDuration!.inMilliseconds,
                                    backgroundColor:
                                    Colors.grey[300],
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Theme.of(context).primaryColor),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(formatDuration(currentPosition)),
                                      Text(formatDuration(totalDuration!)),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (currentlyPlayingSong != null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      "Find a comfortable position and breathe deeply",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
