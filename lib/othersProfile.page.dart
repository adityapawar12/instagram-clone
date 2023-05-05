import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';

class OthersProfile extends StatefulWidget {
  final int userId;

  const OthersProfile({super.key, required this.userId});

  @override
  State<OthersProfile> createState() => _OthersProfileState();
}

class _OthersProfileState extends State<OthersProfile> {
  // POSTS
  var _posts = [];
  var _postsCount = 0;

  // USER
  static int _userId = 0;

  // FOLLOWERS AND FOLLOWED USERS COUNT
  late int _followersCount = 0;
  late int _followedCount = 0;

  // GET USER INFO FROM SESSION
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getInt('userId') ?? 0;
    });
  }

  // GET USER INFO
  _getUser() {
    var user =
        Supabase.instance.client.from('users').select<Map<String, dynamic>>('''
          id,
          name,
          bio,
          user_tag_id,
          profile_image_url
      ''').eq('id', widget.userId).single();
    return user;
  }

  // GET POSTS
  Future<dynamic> _getPosts() async {
    _posts = await Supabase.instance.client
        .from('posts')
        .select<List<Map<String, dynamic>>>('''
        *,
        users (
          id,
          name,
          profile_image_url
        )
      ''').eq('user_id', widget.userId);
    setState(() {
      _postsCount = _posts.length;
    });
  }

  // Follow User
  Future<dynamic> _follow() async {
    var obj = {
      'follower_user_id': _userId,
      'followed_user_id': widget.userId,
      'is_close': false
    };

    await Supabase.instance.client.from('followers').insert(obj);
    setState(() {
      _postsCount = _posts.length;
    });
  }

  // CHECK IF USER IS FOLLOWED OR NOT
  Future<bool> _isUserFollowed() async {
    final checkLike = await Supabase.instance.client
        .from('followers')
        .select()
        .eq('follower_user_id', _userId)
        .eq('followed_user_id', widget.userId);
    if (checkLike.length > 0) {
      return true;
    }
    return false;
  }

  // GET FOLLOWERS COUNT
  Future<dynamic> _getFollowersCount() async {
    var followersCount = await Supabase.instance.client
        .from('followers')
        .select<List<Map<String, dynamic>>>('*')
        .eq('follower_user_id', widget.userId);

    setState(() {
      _followersCount = followersCount.length;
    });
  }

  // GET FOLLOWED COUNT
  Future<dynamic> _getFollowedCount() async {
    var followedCount = await Supabase.instance.client
        .from('followers')
        .select<List<Map<String, dynamic>>>('*')
        .eq('followed_user_id', widget.userId);

    setState(() {
      _followedCount = followedCount.length;
    });
  }

  // LIFECYCLE METHODS
  @override
  void initState() {
    _loadPreferences();
    _getPosts();
    _getFollowersCount();
    _getFollowedCount();
    super.initState();
  }
  // LIFECYCLE METHODS

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _getUser(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.white,
              shadowColor: Colors.white,
              elevation: 0,
              leading: BackButton(
                color: Colors.black,
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
            body: const Center(
              child: Text('User Not Found!'),
            ),
          );
        }

        dynamic user = snapshot.data!;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            shadowColor: Colors.white,
            elevation: 0,
            leading: BackButton(
              color: Colors.black,
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            title: Text(
              user['user_tag_id'],
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black,
                fontFamily: 'sans-serif',
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      margin: const EdgeInsets.all(15.0),
                      child: Column(
                        children: [
                          if (user['profile_image_url'] != null &&
                              user['profile_image_url'].isNotEmpty)
                            ClipOval(
                              child: Container(
                                height: 90,
                                width: 90,
                                color: const Color.fromARGB(255, 243, 243, 243),
                                child: SizedBox(
                                  child: Image.network(
                                    user['profile_image_url'],
                                    height: 90,
                                  ),
                                ),
                              ),
                            )
                          else
                            ClipOval(
                              child: Container(
                                height: 90,
                                width: 90,
                                color: const Color.fromARGB(255, 243, 243, 243),
                                child: SizedBox(
                                  child: Image.network(
                                    'https://simg.nicepng.com/png/small/128-1280406_view-user-icon-png-user-circle-icon-png.png',
                                    height: 90,
                                  ),
                                ),
                              ),
                            ),
                          Text(
                            user['name'],
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          )
                        ],
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(
                          top: 40.0, left: 20.0, bottom: 15.0, right: 20.0),
                      child: Column(
                        children: [
                          Text(
                            _postsCount > 0 ? _postsCount.toString() : '0',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 40),
                          ),
                          const Text(
                            'Posts',
                            style: TextStyle(
                                fontWeight: FontWeight.w500, fontSize: 17),
                          )
                        ],
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(
                          top: 40.0, left: 20.0, bottom: 15.0, right: 20.0),
                      child: Column(
                        children: [
                          Text(
                            _followersCount > 0
                                ? _followersCount.toString()
                                : '0',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 40),
                          ),
                          const Text(
                            'Followers',
                            style: TextStyle(
                                fontWeight: FontWeight.w500, fontSize: 17),
                          )
                        ],
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(
                          top: 40.0, left: 20.0, bottom: 15.0, right: 20.0),
                      child: Column(
                        children: [
                          Text(
                            _followedCount > 0
                                ? _followedCount.toString()
                                : '0',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 40),
                          ),
                          const Text(
                            'Followed',
                            style: TextStyle(
                                fontWeight: FontWeight.w500, fontSize: 17),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(25.0, 0, 25.0, 0),
                      child: Text(
                        user['bio'],
                      ),
                    )
                  ],
                ),
                Container(
                  height: 16.0,
                ),
                Row(
                  children: [
                    FutureBuilder<dynamic>(
                      future: _isUserFollowed(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          if (snapshot.data.toString() != 'true') {
                            return Expanded(
                              flex: 1,
                              child: Container(
                                padding:
                                    const EdgeInsets.fromLTRB(25.0, 0, 25.0, 0),
                                child: TextButton(
                                  onPressed: () {
                                    _follow();
                                  },
                                  style: ButtonStyle(
                                    backgroundColor:
                                        MaterialStateProperty.all<Color>(
                                      Colors.blue,
                                    ),
                                    shadowColor:
                                        MaterialStateProperty.all<Color>(
                                      const Color.fromARGB(255, 236, 236, 236),
                                    ),
                                    foregroundColor:
                                        MaterialStateProperty.all<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                  child: const Text(
                                    'Follow',
                                  ),
                                ),
                              ),
                            );
                          } else {
                            return Expanded(
                              flex: 1,
                              child: Container(
                                padding:
                                    const EdgeInsets.fromLTRB(25.0, 0, 25.0, 0),
                                child: TextButton(
                                  onPressed: () {},
                                  style: ButtonStyle(
                                    backgroundColor:
                                        MaterialStateProperty.all<Color>(
                                      Colors.white,
                                    ),
                                    shadowColor:
                                        MaterialStateProperty.all<Color>(
                                      const Color.fromARGB(255, 236, 236, 236),
                                    ),
                                    foregroundColor:
                                        MaterialStateProperty.all<Color>(
                                      const Color.fromARGB(255, 216, 216, 216),
                                    ),
                                  ),
                                  child: const Text('Followed'),
                                ),
                              ),
                            );
                          }
                        } else {
                          return Expanded(
                            flex: 1,
                            child: Container(
                              padding:
                                  const EdgeInsets.fromLTRB(25.0, 0, 25.0, 0),
                              child: TextButton(
                                onPressed: () {},
                                style: ButtonStyle(
                                  backgroundColor:
                                      MaterialStateProperty.all<Color>(
                                    Colors.white,
                                  ),
                                  shadowColor: MaterialStateProperty.all<Color>(
                                    const Color.fromARGB(255, 236, 236, 236),
                                  ),
                                  foregroundColor:
                                      MaterialStateProperty.all<Color>(
                                    const Color.fromARGB(255, 216, 216, 216),
                                  ),
                                ),
                                child: const Text('Followed'),
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
                Container(
                  height: 16.0,
                ),
                const TabBar(
                  tabs: [
                    Tab(text: 'Posts'),
                    Tab(text: 'Tagged'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      Column(
                        children: [
                          Expanded(
                            child: GridView.count(
                              crossAxisCount: 3,
                              crossAxisSpacing: 0,
                              mainAxisSpacing: 0,
                              physics: const BouncingScrollPhysics(),
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
                                                    VideoPlayerController
                                                        .network(
                                                  post['post_url'],
                                                ),
                                                autoPlay: true,
                                                aspectRatio: 16 / 9,
                                                looping: false,
                                                allowFullScreen: true,
                                                allowMuting: true,
                                                showControls: false,
                                                errorBuilder:
                                                    (context, errorMessage) {
                                                  return Center(
                                                    child: Text(
                                                      errorMessage,
                                                      style: const TextStyle(
                                                          color: Colors.white),
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
                      Column(
                        children: const [
                          Center(
                            child: Text('tagged posts'),
                          ),
                          // Expanded(
                          // child: GridView.count(
                          //   crossAxisCount: 3,
                          //   crossAxisSpacing: 0,
                          //   mainAxisSpacing: 0,
                          //   physics: const BouncingScrollPhysics(),
                          //   children: List.generate(
                          //     _savedPosts.length,
                          //     (index) {
                          //       final savedPost = _savedPosts[index];
                          //       return Column(
                          //         children: [
                          //           if (savedPost['posts']['post_type'] ==
                          //               'image')
                          //             SizedBox(
                          //               width: 129,
                          //               height: 129,
                          //               child: FittedBox(
                          //                 fit: BoxFit.contain,
                          //                 child: Image.network(
                          //                   savedPost['posts']['post_url'],
                          //                   height: 129,
                          //                 ),
                          //               ),
                          //             )
                          //           else if (savedPost['posts']
                          //                   ['post_type'] ==
                          //               'video')
                          //             SizedBox(
                          //               width: 129,
                          //               height: 129,
                          //               child: FittedBox(
                          //                 fit: BoxFit.fitWidth,
                          //                 child: Chewie(
                          //                   controller: ChewieController(
                          //                     videoPlayerController:
                          //                         VideoPlayerController
                          //                             .network(
                          //                       savedPost['posts']
                          //                           ['post_url'],
                          //                     ),
                          //                     autoPlay: true,
                          //                     aspectRatio: 16 / 9,
                          //                     looping: false,
                          //                     allowFullScreen: true,
                          //                     allowMuting: true,
                          //                     showControls: false,
                          //                     errorBuilder:
                          //                         (context, errorMessage) {
                          //                       return Center(
                          //                         child: Text(
                          //                           errorMessage,
                          //                           style: const TextStyle(
                          //                               color: Colors.white),
                          //                         ),
                          //                       );
                          //                     },
                          //                   ),
                          //                 ),
                          //               ),
                          //             ),
                          //         ],
                          //       );
                          //     },
                          //   ),
                          // ),
                          // ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
