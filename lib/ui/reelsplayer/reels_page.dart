import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:just_appartment_live/models/configuration.dart';
import 'package:just_appartment_live/ui/reels/trimmer_view.dart';
import 'package:just_appartment_live/ui/reelsplayer/comment_popup.dart';
import 'package:just_appartment_live/ui/reelsplayer/video.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Define the Video class
class Video {
  final int id;
  final String url;
  final String screenshotUrl;
  final String user;
  final String caption;
  final int likes;
  final int shares;
  final List comments;

  Video({
    required this.id,
    required this.url,
    required this.screenshotUrl,
    required this.user,
    required this.caption,
    required this.likes,
    required this.shares,
    required this.comments,
  });
}

class ReelsPage extends StatefulWidget {
  @override
  _ReelsPageState createState() => _ReelsPageState();
}

class _ReelsPageState extends State<ReelsPage> {
  final PageController _pageController = PageController();
  int _currentPageIndex = 0;
  List<Video> videos = [];

  @override
  void initState() {
    super.initState();
    _fetchVideos();
  }

  Future<void> _fetchVideos() async {
    try {
      final postData = {
        'key': 'value', // Replace with actual parameters
      };

      final response = await http.post(
        Uri.parse('https://justhomes.co.ke/api/reels/get-videos'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(postData),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            videos = (data['data'] as List).map((video) {
              return Video(
                id: video['id'],
                url: 'https://justhomes.co.ke/${video['video_path']}',
                screenshotUrl: 'https://justhomes.co.ke/${video['screenshot']}',
                user: video['user']['name'],
                caption: video['description'] ?? '',
                likes: video['likes'],
                shares: video['shares'],
                comments: video['comments'],
              );
            }).toList();
          });
        }
      } else {
        // Handle API error
        throw Exception('Failed to load videos');
      }
    } catch (e) {
      // Handle network or parsing errors
      print("Error fetching videos: $e");
      // Optionally, show an error message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching videos: $e')),
      );
    }
  }

  void _onVideoEnd() {
    if (_currentPageIndex < videos.length - 1) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    } else {
      // Show a snackbar when the user reaches the last video
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No more videos to show'),
          duration: Duration(seconds: 2), // Adjust duration as needed
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: videos.length,
            onPageChanged: (index) async {
              setState(() {
                _currentPageIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final video = videos[index];
              return Stack(
                children: [
                  VlcPlayerWidget(
                    videoUrl: video.url,
                    user: video.user,
                    caption: video.caption,
                    likes: video.likes.toString(),
                    shares: video.shares.toString(),
                    onVideoEnd: _onVideoEnd,
                    comments: video.comments,
                    videoID: video.id,
                    nextVideoUrl: index < videos.length - 1
                        ? videos[index + 1].url
                        : '', // Preload next video
                  ),
                  Positioned(
                    bottom: 55,
                    left: 20,
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '@${video.user}\n',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          TextSpan(
                            text: '${video.caption}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class VlcPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final String user;
  final String caption;
  final String likes;
  final String shares;
  final List comments;
  final VoidCallback onVideoEnd;
  final int videoID;
  final String nextVideoUrl;

  VlcPlayerWidget({
    required this.videoUrl,
    required this.user,
    required this.caption,
    required this.likes,
    required this.shares,
    required this.comments,
    required this.onVideoEnd,
    required this.videoID,
    required this.nextVideoUrl,
  });

  @override
  _VlcPlayerWidgetState createState() => _VlcPlayerWidgetState();
}

class _VlcPlayerWidgetState extends State<VlcPlayerWidget> {
  late VlcPlayerController _vlcPlayerController;
  bool _isMuted = false;
  bool _isPlaying = true;
  Duration _videoDuration = Duration.zero;
  Duration _currentPosition = Duration.zero;

  late int _likesCount;
  late int _shareCount;

  Future<void> _cacheVideo(String videoUrl) async {
    // Cache the video using flutter_cache_manager
    try {
      await DefaultCacheManager().downloadFile(videoUrl);
    } catch (e) {
      print("Error caching video: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _likesCount = int.parse(widget.likes);
    _shareCount = int.parse(widget.shares);

    _cacheVideo(widget.videoUrl); // Cache the current video
    if (widget.nextVideoUrl.isNotEmpty) {
      _cacheVideo(
          widget.nextVideoUrl); // Cache the next video for smooth playback
    }

    _vlcPlayerController = VlcPlayerController.network(
      widget.videoUrl,
      hwAcc: HwAcc.full,
      autoPlay: true,
      options: VlcPlayerOptions(),
    );

    _vlcPlayerController.addListener(() {
      if (_vlcPlayerController.value.isEnded) {
        widget.onVideoEnd();
      }
    });
  }

  @override
  void dispose() {
    _vlcPlayerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black, // Set the background color to black
      child: VlcPlayer(
        controller: _vlcPlayerController,
        aspectRatio:
            MediaQuery.of(context).size.aspectRatio, // Full screen aspect ratio
        placeholder: Center(child: CircularProgressIndicator()),
        // errorBuilder: (context, error) {
        //   // Handle VLC player error gracefully
        //   return Center(child: Text('Error playing video: $error'));
        // },
      ),
    );
  }
}
