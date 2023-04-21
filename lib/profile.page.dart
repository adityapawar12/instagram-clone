import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late String _userName = '';
  late String _userProfileUrl = '';
  var _posts = [];
  var _postsCount = 0;

  @override
  void initState() {
    _loadPreferences();
    _getPosts();
    super.initState();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? "";
      _userProfileUrl = prefs.getString('profileImage') ?? "";
    });
  }

  Future<dynamic> _getPosts() async {
    final prefs = await SharedPreferences.getInstance();
    _posts = await Supabase.instance.client
        .from('posts')
        .select<List<Map<String, dynamic>>>('''
        *,
        users (
          id,
          name,
          profile_image
        )
      ''').eq('user_id', prefs.getInt('userId'));
    setState(() {
      _postsCount = _posts.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        shadowColor: Colors.white,
        elevation: 0,
        leadingWidth: 0,
        title: Text(
          _userName,
          style: const TextStyle(
            color: Colors.black,
            fontFamily: 'sans-serif',
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Row(
            children: [
              Container(
                margin: const EdgeInsets.all(15.0),
                child: Column(
                  children: [
                    if (_userProfileUrl.isNotEmpty)
                      Image.network(
                        _userProfileUrl,
                        height: 90,
                      )
                    else
                      const Icon(
                        Icons.person,
                        size: 90,
                      ),
                    Text(
                      _userName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    )
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.only(
                    top: 40.0, left: 25.0, bottom: 15.0, right: 25.0),
                child: Column(
                  children: [
                    Text(
                      _postsCount > 0 ? _postsCount.toString() : '0',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 40),
                    ),
                    const Text(
                      'Posts',
                      style:
                          TextStyle(fontWeight: FontWeight.w500, fontSize: 17),
                    )
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.only(
                    top: 40.0, left: 25.0, bottom: 15.0, right: 25.0),
                child: Column(
                  children: [
                    Text(
                      _postsCount > 0 ? _postsCount.toString() : '0',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 40),
                    ),
                    const Text(
                      'Posts',
                      style:
                          TextStyle(fontWeight: FontWeight.w500, fontSize: 17),
                    )
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.only(
                    top: 40.0, left: 25.0, bottom: 15.0, right: 25.0),
                child: Column(
                  children: [
                    Text(
                      _postsCount > 0 ? _postsCount.toString() : '0',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 40),
                    ),
                    const Text(
                      'Posts',
                      style:
                          TextStyle(fontWeight: FontWeight.w500, fontSize: 17),
                    )
                  ],
                ),
              ),
            ],
          ),
          Container(
            height: 16.0,
          ),
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              crossAxisSpacing: 0,
              mainAxisSpacing: 0,
              physics: const BouncingScrollPhysics(),
              // childAspectRatio: cardWidth / cardHeight,
              children: List.generate(
                _posts.length,
                (index) {
                  final post = _posts[index];

                  return Column(
                    children: [
                      if (post['post_type'] == 'image')
                        SizedBox(
                          width: 129,
                          height: 129,
                          child: FittedBox(
                            fit: BoxFit.contain,
                            child: Image.network(
                              post['post_url'],
                              height: 129,
                            ),
                          ),
                        )
                      else if (post['post_type'] == 'video')
                        SizedBox(
                          width: 129,
                          height: 129,
                          child: FittedBox(
                            fit: BoxFit.fitWidth,
                            child: Chewie(
                              controller: ChewieController(
                                videoPlayerController:
                                    VideoPlayerController.network(
                                  post['post_url'],
                                ),
                                autoPlay: true,
                                aspectRatio: 16 / 9,
                                looping: false,
                                allowFullScreen: true,
                                allowMuting: true,
                                showControls: false,
                                errorBuilder: (context, errorMessage) {
                                  return Center(
                                    child: Text(
                                      errorMessage,
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
