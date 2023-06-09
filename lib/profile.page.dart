import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'utils/clickable_text_utils.dart';
import 'package:video_player/video_player.dart';
import 'package:instagram_clone/signin.page.dart';
import 'package:instagram_clone/followed.page.dart';
import 'package:instagram_clone/userFeed.page.dart';
import 'package:instagram_clone/followers.page.dart';
import 'package:instagram_clone/editProfile.page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // USER
  late int _userId = 0;
  late String _userName = '';
  late String _userTagId = '';
  late String _userBio = '';
  late String _userProfileUrl = '';

  // POSTS
  var _posts = [];
  var _postsCount = 0;

  // SAVED POSTS
  var _savedPosts = [];

  // FOLLOWERS AND FOLLOWED USERS COUNT
  late int _followersCount = 0;
  late int _followedCount = 0;

  // GET USER INFO FROM SESSION
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getInt('userId') ?? 0;
      _userName = prefs.getString('userName') ?? "";
      _userTagId = prefs.getString('userTagId') ?? "";
      _userBio = prefs.getString('bio') ?? "";
      _userProfileUrl = prefs.getString('profileImageUrl') ?? "";
    });
  }

  // GET POSTS
  Future<dynamic> _getPosts() async {
    final prefs = await SharedPreferences.getInstance();
    _posts = await Supabase.instance.client
        .from('posts')
        .select<List<Map<String, dynamic>>>('''
        *,
        users (
          id,
          name,
          profile_image_url
        )
      ''').eq('user_id', prefs.getInt('userId'));
    setState(() {
      _postsCount = _posts.length;
    });
  }

  // GET SAVED POSTS
  Future<dynamic> _getSavedPosts() async {
    final prefs = await SharedPreferences.getInstance();
    _savedPosts = await Supabase.instance.client
        .from('saves')
        .select<List<Map<String, dynamic>>>('''
        *,
        posts (
          *
        )
      ''').eq('user_id', prefs.getInt('userId'));
  }

  // GET SAVED POSTS
  Future<dynamic> _logOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('userName');
    await prefs.remove('userEmail');
    await prefs.remove('userPhone');
    await prefs.remove('profileImageUrl');

    // ignore: use_build_context_synchronously
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SignInPage()),
    );
  }

  // GET FOLLOWERS COUNT
  Future<dynamic> _getFollowersCount() async {
    final prefs = await SharedPreferences.getInstance();
    var followersCount = await Supabase.instance.client
        .from('followers')
        .select<List<Map<String, dynamic>>>('*')
        .eq('followed_user_id', prefs.getInt('userId'));

    setState(() {
      _followersCount = followersCount.length;
    });
  }

  // GET FOLLOWED COUNT
  Future<dynamic> _getFollowedCount() async {
    final prefs = await SharedPreferences.getInstance();
    var followedCount = await Supabase.instance.client
        .from('followers')
        .select<List<Map<String, dynamic>>>('*')
        .eq('follower_user_id', prefs.getInt('userId'));

    setState(() {
      _followedCount = followedCount.length;
    });
  }

  // LIFECYCLE METHODS
  @override
  void initState() {
    _loadPreferences();
    _getPosts();
    _getSavedPosts();
    _getFollowersCount();
    _getFollowedCount();
    super.initState();
  }
  // LIFECYCLE METHODS

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        shadowColor: Colors.white,
        elevation: 0,
        leadingWidth: 0,
        title: Text(
          _userTagId,
          style: const TextStyle(
            color: Colors.black,
            fontFamily: 'sans-serif',
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _logOut,
            child: const Text(
              'Logout',
              style: TextStyle(
                color: Colors.black,
              ),
            ),
          ),
        ],
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
                      if (_userProfileUrl.isNotEmpty)
                        ClipOval(
                          child: Container(
                            height: 90,
                            width: 90,
                            color: const Color.fromARGB(255, 240, 240, 240),
                            child: SizedBox(
                              child: Image.network(
                                _userProfileUrl,
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
                            color: const Color.fromARGB(255, 240, 240, 240),
                            child: const SizedBox(
                              child: Icon(
                                Icons.person,
                                size: 80,
                              ),
                            ),
                          ),
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
                      top: 40.0, left: 10.0, bottom: 15.0, right: 10.0),
                  child: Column(
                    children: [
                      TextButton(
                        onPressed: () {},
                        style: ButtonStyle(
                          foregroundColor: MaterialStateProperty.all<Color>(
                            Colors.black,
                          ),
                        ),
                        child: Text(
                          _postsCount > 0 ? _postsCount.toString() : '0',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 40),
                        ),
                      ),
                      const Text(
                        'Posts',
                        style: TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 17),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(
                      top: 40.0, left: 10.0, bottom: 15.0, right: 10.0),
                  child: Column(
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FollowersPage(
                                userId: _userId,
                              ),
                            ),
                          );
                        },
                        style: ButtonStyle(
                          foregroundColor: MaterialStateProperty.all<Color>(
                            Colors.black,
                          ),
                        ),
                        child: Text(
                          _followersCount > 0
                              ? _followersCount.toString()
                              : '0',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 40),
                        ),
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
                      top: 40.0, left: 10.0, bottom: 15.0, right: 10.0),
                  child: Column(
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FollowedPage(
                                userId: _userId,
                              ),
                            ),
                          );
                        },
                        style: ButtonStyle(
                          foregroundColor: MaterialStateProperty.all<Color>(
                            Colors.black,
                          ),
                        ),
                        child: Text(
                          _followedCount > 0 ? _followedCount.toString() : '0',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 40),
                        ),
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
                  child: RichText(
                    text: buildClickableTextSpan(_userBio, _userId, context),
                  ),
                )
              ],
            ),
            Container(
              height: 16.0,
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(10.0, 0.0, 10.0, 0.0),
              width: double.infinity,
              child: TextButton(
                  style: ButtonStyle(
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(45.0),
                      ),
                    ),
                    backgroundColor: MaterialStateProperty.all<Color>(
                      const Color.fromARGB(255, 240, 240, 240),
                    ),
                    foregroundColor: MaterialStateProperty.all<Color>(
                      Colors.black,
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EditProfilePage(),
                      ),
                    );
                  },
                  child: const Text('Edit Profile')),
            ),
            Container(
              height: 16.0,
            ),
            const TabBar(
              tabs: [
                Tab(text: 'Posts'),
                Tab(text: 'Saved'),
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
                                  InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => UserFeedPage(
                                            userId: post['users']['id'],
                                          ),
                                        ),
                                      );
                                    },
                                    child: post['post_type'] == 'image'
                                        ? SizedBox(
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
                                        : Container(),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => UserFeedPage(
                                            userId: post['users']['id'],
                                          ),
                                        ),
                                      );
                                    },
                                    child: post['post_type'] == 'video'
                                        ? SizedBox(
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
                                                            color:
                                                                Colors.white),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                          )
                                        : Container(),
                                  )
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Expanded(
                        child: GridView.count(
                          crossAxisCount: 3,
                          crossAxisSpacing: 0,
                          mainAxisSpacing: 0,
                          physics: const BouncingScrollPhysics(),
                          children: List.generate(
                            _savedPosts.length,
                            (index) {
                              final savedPost = _savedPosts[index];

                              return Column(
                                children: [
                                  InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => UserFeedPage(
                                            userId: _userId,
                                          ),
                                        ),
                                      );
                                    },
                                    child: savedPost['posts']['post_type'] ==
                                            'image'
                                        ? SizedBox(
                                            width: 129,
                                            height: 129,
                                            child: FittedBox(
                                              fit: BoxFit.contain,
                                              child: Image.network(
                                                savedPost['posts']['post_url'],
                                                height: 129,
                                              ),
                                            ),
                                          )
                                        : Container(),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => UserFeedPage(
                                            userId: _userId,
                                          ),
                                        ),
                                      );
                                    },
                                    child: savedPost['posts']['post_type'] ==
                                            'video'
                                        ? SizedBox(
                                            width: 129,
                                            height: 129,
                                            child: FittedBox(
                                              fit: BoxFit.fitWidth,
                                              child: Chewie(
                                                controller: ChewieController(
                                                  videoPlayerController:
                                                      VideoPlayerController
                                                          .network(
                                                    savedPost['posts']
                                                        ['post_url'],
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
                                                            color:
                                                                Colors.white),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                          )
                                        : Container(),
                                  )
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
