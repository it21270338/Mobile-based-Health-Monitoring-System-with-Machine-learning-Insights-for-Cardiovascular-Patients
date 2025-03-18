import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class RelaxationMusic extends StatefulWidget {
  final String emotion;

  const RelaxationMusic({
    Key? key,
    required this.emotion,
  }) : super(key: key);

  @override
  State<RelaxationMusic> createState() => _RelaxationMusicState();
}

class _RelaxationMusicState extends State<RelaxationMusic> {
  final AudioPlayer audioPlayer = AudioPlayer();
  String? currentlyPlayingSong;
  Duration? totalDuration;
  Duration currentPosition = Duration.zero;
  bool isLoading = false;

  final Map<String, List<Map<String, String>>> emotionMusic = {
    'anger': [
      {
        'title': 'Ocean Waves',
        'asset': 'music/anger/ocean-waves-250310.mp3',
        'duration': '5:30',
        'description': 'Calming ocean waves for deep relaxation'
      },
      {
        'title': 'Forest Rain',
        'asset': 'music/anger/rainy-woods-ambience-31004.mp3',
        'duration': '4:45',
        'description': 'Peaceful rainforest ambience'
      },
    ],
    'fear': [
      {
        'title': 'Gentle Stream',
        'asset': 'music/fear/echoing-creek-2-288823.mp3',
        'duration': '6:15',
        'description': 'Soothing water stream sounds'
      },
      {
        'title': 'Soft Piano',
        'asset': 'music/fear/tinkling-keys-56693.mp3',
        'duration': '4:30',
        'description': 'Gentle piano melodies for relaxation'
      },
    ],
    'sadness': [
      {
        'title': 'Morning Birds',
        'asset': 'music/sadness/birds-in-the-morning-24614.mp3',
        'duration': '5:00',
        'description': 'Cheerful morning birdsong'
      },
      {
        'title': 'Wind Chimes',
        'asset': 'music/sadness/wind-chimes-37762.mp3',
        'duration': '4:20',
        'description': 'Peaceful wind chimes in gentle breeze'
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

    audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      if (state == PlayerState.playing) {
        setState(() => isLoading = false);
      }
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
      setState(() => isLoading = true);
      if (currentlyPlayingSong != null) {
        await audioPlayer.stop();
      }
      try {
        await audioPlayer.play(AssetSource(asset));
        setState(() => currentlyPlayingSong = asset);
      } catch (e) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to play audio: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  // Normalize emotion key to handle variations like 'angry' or 'anger'
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
    final musicList = emotionMusic[normalizedEmotion] ?? [];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Nature Sounds"),
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
                  "Natural Healing Sounds",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Let nature's harmony bring you peace",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView.builder(
                    itemCount: musicList.length,
                    itemBuilder: (context, index) {
                      final music = musicList[index];
                      final isPlaying = currentlyPlayingSong == music['asset'];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: isPlaying ? 8 : 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: InkWell(
                          onTap: () => playPause(music['asset']!),
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
                                      child: isLoading && currentlyPlayingSong == music['asset']
                                          ? const CircularProgressIndicator()
                                          : Icon(
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
                                            music['title']!,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            music['description']!,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      music['duration']!,
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
                                    backgroundColor: Colors.grey[300],
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
                      "Close your eyes and immerse yourself in nature's symphony",
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
