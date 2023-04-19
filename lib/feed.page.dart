import 'package:flutter/material.dart';
import 'package:flutter_supa/profile.page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({Key? key}) : super(key: key);

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  late int _userId;
  late String _userName = '';
  late String _userPhone = '';
  late String _userEmail = '';
  late String _userProfileUrl = '';

  List<int> likes = <int>[];
  List<int> saves = <int>[];

  @override
  void initState() {
    _loadPreferences();
    super.initState();
  }

  final _future = Supabase.instance.client
      .from('posts')
      .select<List<Map<String, dynamic>>>('''
    *,
    users (
      id,
      name,
      profile_image
    )
  ''');

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getInt('userId') ?? 0;
      _userName = prefs.getString('userName') ?? "";
      _userPhone = prefs.getString('userPhone') ?? "";
      _userEmail = prefs.getString('userEmail') ?? "";
      _userProfileUrl = prefs.getString('profileImage') ?? "";
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                backgroundColor: Colors.white,
              ),
            ),
          );
        }
        final posts = snapshot.data!;
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            shadowColor: Colors.white,
            elevation: 0,
            leading: Image.network(
              'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2a/Instagram_logo.svg/1280px-Instagram_logo.svg.png',
            ),
          ),
          body: ListView.builder(
            itemCount: posts.length,
            itemBuilder: ((context, index) {
              final post = posts[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  ListTile(
                    tileColor: Colors.white,
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(
                        post['users']['profile_image'],
                      ),
                    ),
                    title: Text(post['users']['name']),
                    subtitle: Text(post['location']),
                  ),
                  if (post['post_type'] == 'image')
                    SizedBox(
                      // decoration: const BoxDecoration(
                      //   border: Border(
                      //     bottom: BorderSide(width: 0.5, color: Colors.black26),
                      //     top: BorderSide(width: 0.5, color: Colors.black26),
                      //   ),
                      // ),
                      height: 400,
                      width: double.infinity,
                      child: FittedBox(
                          fit: BoxFit.contain,
                          child: Image.network(post['post_url'])),
                    )
                  else if (post['post_type'] == 'video')
                    SizedBox(
                      // decoration: const BoxDecoration(
                      //   border: Border(
                      //     bottom: BorderSide(width: 0.5, color: Colors.black26),
                      //     top: BorderSide(width: 0.5, color: Colors.black26),
                      //   ),
                      // ),
                      height: 600,
                      width: double.infinity,
                      child: FittedBox(
                        fit: BoxFit.fitWidth,
                        child: Chewie(
                          controller: ChewieController(
                            videoPlayerController:
                                VideoPlayerController.network(
                              post['post_url'],
                            ),
                            aspectRatio: 16 / 9,
                            autoPlay: true,
                            looping: false,
                            allowMuting: true,
                            showControls: false,
                            errorBuilder: (context, errorMessage) {
                              return Center(
                                child: Text(
                                  errorMessage,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            icon: likes.contains(index)
                                ? const Icon(Icons.favorite, color: Colors.red)
                                : const Icon(Icons.favorite_border),
                            onPressed: () {
                              setState(() {
                                if (likes.contains(index)) {
                                  likes.removeWhere((item) => item == index);
                                } else {
                                  likes.add(index);
                                }
                              });
                            },
                          ),
                          const SizedBox(width: 4.0),
                          IconButton(
                            icon: const Icon(Icons.mode_comment_outlined),
                            onPressed: () {},
                          ),
                        ],
                      ),
                      IconButton(
                        icon: saves.contains(index)
                            ? const Icon(Icons.bookmark, color: Colors.black)
                            : const Icon(Icons.bookmark_border),
                        onPressed: () {
                          setState(() {
                            if (saves.contains(index)) {
                              saves.removeWhere((item) => item == index);
                            } else {
                              saves.add(index);
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ],
              );
            }),
          ),
        );
      },
    );
  }
}
