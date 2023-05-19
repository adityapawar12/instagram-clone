import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'utils/clickable_text_utils.dart';
import 'package:video_player/video_player.dart';
import 'package:instagram_clone/followed.page.dart';
import 'package:instagram_clone/userFeed.page.dart';
import 'package:instagram_clone/followers.page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  late dynamic _followInfo = {};

  // FOLLOWERS AND FOLLOWED USERS COUNT
  late int _followersCount = 0;
  late int _followedCount = 0;

  // SHOW BOTTOM SECTION
  bool _isSectionVisible = false;

  // FOLLOW/UNFOLLOW SUBMITTED
  bool _isFollwingOrUnfollowing = false;

  // ADD/REMOVE CLOSE FRIEND SUBMITTED
  bool _isAddOrRemoveCF = false;

  // ADD/REMOVE FAVOURITE USER SUBMITTED
  bool _isAddOrRemoveFU = false;

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

  // FOLLOW USER
  Future<dynamic> _followUser() async {
    setState(() {
      _isFollwingOrUnfollowing = true;
    });

    final bool checkAlreadyFollowed = await _isUserFollowed();

    // ALREADY FOLLOWED HASHTAG
    if (checkAlreadyFollowed == true) {
      setState(() {
        _isFollwingOrUnfollowing = false;
      });
      return;
    }

    var obj = {
      'follower_user_id': _userId,
      'followed_user_id': widget.userId,
    };

    await Supabase.instance.client.from('followers').insert(obj);
    setState(() {
      _isFollwingOrUnfollowing = false;
      _postsCount = _posts.length;
    });
  }

  // UNFOLLOW USER
  Future<dynamic> _unfollowUser() async {
    setState(() {
      _isFollwingOrUnfollowing = true;
    });

    final bool checkAlreadyFollowed = await _isUserFollowed();

    // ALREADY FOLLOWED HASHTAG
    if (checkAlreadyFollowed == true) {
      await Supabase.instance.client
          .from('followers')
          .delete()
          .eq('follower_user_id', _userId)
          .eq('followed_user_id', widget.userId);

      setState(() {
        _isFollwingOrUnfollowing = false;
        _postsCount = _posts.length;
      });
      return;
    }

    setState(() {
      _isFollwingOrUnfollowing = false;
      _postsCount = _posts.length;
    });
  }

  // CHECK IF USER IS FOLLOWED OR NOT
  Future<bool> _isUserFollowed() async {
    final userAlreadyFollowed = await Supabase.instance.client
        .from('followers')
        .select()
        .eq('follower_user_id', _userId)
        .eq('followed_user_id', widget.userId);
    if (userAlreadyFollowed.length > 0) {
      _followInfo = userAlreadyFollowed;
      return true;
    }
    return false;
  }

  // GET FOLLOWERS COUNT
  Future<dynamic> _getFollowersCount() async {
    var followersCount = await Supabase.instance.client
        .from('followers')
        .select<List<Map<String, dynamic>>>('*')
        .eq('followed_user_id', widget.userId);

    setState(() {
      _followersCount = followersCount.length;
    });
  }

  // GET FOLLOWED COUNT
  Future<dynamic> _getFollowedCount() async {
    var followedCount = await Supabase.instance.client
        .from('followers')
        .select<List<Map<String, dynamic>>>('*')
        .eq('follower_user_id', widget.userId);

    setState(() {
      _followedCount = followedCount.length;
    });
  }

  // CHECK IF USER IS ALREADY A CLOSE FRIEND
  Future<bool> _isCloseFriend() async {
    final checkAlreadyCloseFriends = await Supabase.instance.client
        .from('close_friends')
        .select()
        .eq('follow_id', _followInfo[0]['id']);

    if (checkAlreadyCloseFriends.length > 0) {
      return true;
    }
    return false;
  }

  // ADD CLOSE FRIEND
  Future<dynamic> _addCloseFriend() async {
    setState(() {
      _isAddOrRemoveCF = true;
    });

    final bool checkAlreadyCloseFriends = await _isCloseFriend();

    if (checkAlreadyCloseFriends == true) {
      setState(() {
        _isAddOrRemoveCF = false;
      });
      return;
    }

    var obj = {
      'follow_id': _followInfo[0]['id'],
    };

    await Supabase.instance.client.from('close_friends').insert(obj);

    setState(() {
      _isAddOrRemoveCF = false;
    });
  }

  // REMOVE CLOSE FRIEND
  Future<dynamic> _removeCloseFriend() async {
    setState(() {
      _isAddOrRemoveCF = true;
    });
    final bool checkAlreadyFavouriteUsers = await _isCloseFriend();
    if (checkAlreadyFavouriteUsers == true) {
      await Supabase.instance.client
          .from('close_friends')
          .delete()
          .eq('follow_id', _followInfo[0]['id']);
      setState(() {
        _isAddOrRemoveCF = false;
      });
      return;
    }
    setState(() {
      _isAddOrRemoveCF = false;
    });
  }

  // CHECK IF USER IS ALREADY A FAVOURITE USER
  Future<bool> _isFavouriteUser() async {
    final checkAlreadyFavouriteUsers = await Supabase.instance.client
        .from('favourite_users')
        .select()
        .eq('follow_id', _followInfo[0]['id']);

    if (checkAlreadyFavouriteUsers.length > 0) {
      return true;
    }
    return false;
  }

  // ADD FAVOURITE USER
  Future<dynamic> _addFavouriteUser() async {
    setState(() {
      _isAddOrRemoveFU = true;
    });

    final bool checkAlreadyFavouriteUsers = await _isFavouriteUser();

    if (checkAlreadyFavouriteUsers == true) {
      setState(() {
        _isAddOrRemoveFU = false;
      });
      return;
    }

    var obj = {
      'follow_id': _followInfo[0]['id'],
    };

    await Supabase.instance.client.from('favourite_users').insert(obj);

    setState(() {
      _isAddOrRemoveFU = false;
    });
  }

  // REMOVE FAVOURITE USER
  Future<dynamic> _removeFavouriteUser() async {
    setState(() {
      _isAddOrRemoveFU = true;
    });
    final bool checkAlreadyFavouriteUsers = await _isCloseFriend();
    if (checkAlreadyFavouriteUsers == true) {
      await Supabase.instance.client
          .from('favourite_users')
          .delete()
          .eq('follow_id', _followInfo[0]['id']);
      setState(() {
        _isAddOrRemoveFU = false;
      });
      return;
    }
    setState(() {
      _isAddOrRemoveFU = false;
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
                                color: const Color.fromARGB(255, 240, 240, 240),
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
                                color: const Color.fromARGB(255, 240, 240, 240),
                                child: ClipOval(
                                  child: Container(
                                    height: 90,
                                    width: 90,
                                    color: const Color.fromARGB(
                                        255, 240, 240, 240),
                                    child: const SizedBox(
                                      child: Icon(
                                        Icons.person,
                                        size: 80,
                                      ),
                                    ),
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
                              _followedCount > 0
                                  ? _followedCount.toString()
                                  : '0',
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
                        text: buildClickableTextSpan(
                            user['bio'], _userId, context),
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
                                  onPressed: !_isFollwingOrUnfollowing
                                      ? () {
                                          _followUser();
                                        }
                                      : null,
                                  style: ButtonStyle(
                                    backgroundColor:
                                        MaterialStateProperty.all<Color>(
                                      Colors.blue,
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
                                  onPressed: () {
                                    setState(() {
                                      _isSectionVisible = !_isSectionVisible;
                                    });
                                  },
                                  style: ButtonStyle(
                                    backgroundColor:
                                        MaterialStateProperty.all<Color>(
                                      const Color.fromARGB(255, 240, 240, 240),
                                    ),
                                    foregroundColor:
                                        MaterialStateProperty.all<Color>(
                                      Colors.black,
                                    ),
                                  ),
                                  child: RichText(
                                    text: const TextSpan(
                                      children: [
                                        TextSpan(
                                          text:
                                              'Following', // Replace with your desired text
                                          style: TextStyle(
                                            color: Colors.black,
                                          ),
                                        ),
                                        WidgetSpan(
                                          child: SizedBox(
                                              width:
                                                  5), // Optional: Add some spacing between the icon and text
                                        ),
                                        WidgetSpan(
                                          child: Icon(Icons
                                              .arrow_drop_down), // Replace with the desired icon
                                        ),
                                      ],
                                    ),
                                  ),
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
                                onPressed: () {
                                  setState(() {
                                    _isSectionVisible = !_isSectionVisible;
                                  });
                                },
                                style: ButtonStyle(
                                  backgroundColor:
                                      MaterialStateProperty.all<Color>(
                                    const Color.fromARGB(255, 240, 240, 240),
                                  ),
                                  foregroundColor:
                                      MaterialStateProperty.all<Color>(
                                    Colors.black,
                                  ),
                                ),
                                child: RichText(
                                  text: const TextSpan(
                                    children: [
                                      TextSpan(
                                        text:
                                            'Following', // Replace with your desired text
                                        style: TextStyle(
                                          color: Colors.black,
                                        ),
                                      ),
                                      WidgetSpan(
                                        child: SizedBox(
                                            width:
                                                5), // Optional: Add some spacing between the icon and text
                                      ),
                                      WidgetSpan(
                                        child: Icon(Icons
                                            .arrow_drop_down), // Replace with the desired icon
                                      ),
                                    ],
                                  ),
                                ),
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
                                                    controller:
                                                        ChewieController(
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
                                                      errorBuilder: (context,
                                                          errorMessage) {
                                                        return Center(
                                                          child: Text(
                                                            errorMessage,
                                                            style:
                                                                const TextStyle(
                                                                    color: Colors
                                                                        .white),
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
                _isSectionVisible
                    ? // Bottom section
                    AnimatedPositioned(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        bottom: _isSectionVisible
                            ? 0
                            : -200, // Adjust the height as needed
                        left: 0,
                        right: 0,
                        child: Container(
                          alignment: Alignment.centerLeft,
                          width: double.infinity,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  border: Border(
                                    top: BorderSide(
                                      color: Color.fromARGB(255, 240, 240, 240),
                                      width: 1.0,
                                    ),
                                  ),
                                ),
                                padding: const EdgeInsets.fromLTRB(
                                    20.0, 20.0, 20.0, 20.0),
                                width: double.infinity,
                                alignment: Alignment.center,
                                child: Text(
                                  user['name'],
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Container(
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  border: Border(
                                    top: BorderSide(
                                      color: Color.fromARGB(255, 240, 240, 240),
                                      width: 1.0,
                                    ),
                                  ),
                                ),
                                padding: const EdgeInsets.fromLTRB(
                                    20.0, 4.0, 20.0, 4.0),
                                width: double.infinity,
                                alignment: Alignment.centerLeft,
                                child: FutureBuilder<dynamic>(
                                  future: _isCloseFriend(),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      if (snapshot.data.toString() == 'true') {
                                        return Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: TextButton(
                                                  onPressed: !_isAddOrRemoveCF
                                                      ? () {
                                                          _removeCloseFriend();
                                                          setState(() {
                                                            _isSectionVisible =
                                                                false;
                                                          });
                                                        }
                                                      : null,
                                                  style: TextButton.styleFrom(
                                                    foregroundColor:
                                                        Colors.black,
                                                    backgroundColor:
                                                        Colors.white,
                                                  ),
                                                  child: const Text(
                                                      'Remove Close Friend'),
                                                ),
                                              ),
                                            ),
                                            ShaderMask(
                                              shaderCallback: (Rect bounds) {
                                                return const LinearGradient(
                                                  colors: [
                                                    Colors.green,
                                                    Colors.cyan
                                                  ],
                                                  begin: Alignment.centerLeft,
                                                  end: Alignment.centerRight,
                                                ).createShader(bounds);
                                              },
                                              child: const Icon(
                                                Icons.stars_outlined,
                                                color: Colors.white,
                                              ),
                                            )
                                          ],
                                        );
                                      }
                                      return Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: TextButton(
                                                onPressed: !_isAddOrRemoveCF
                                                    ? () {
                                                        _addCloseFriend();
                                                        setState(() {
                                                          _isSectionVisible =
                                                              false;
                                                        });
                                                      }
                                                    : null,
                                                style: TextButton.styleFrom(
                                                  foregroundColor: Colors.black,
                                                  backgroundColor: Colors.white,
                                                ),
                                                child: const Text(
                                                    'Add Close Friend'),
                                              ),
                                            ),
                                          ),
                                          const Align(
                                            alignment: Alignment.center,
                                            child: Icon(Icons.stars),
                                          ),
                                        ],
                                      );
                                    }
                                    return Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: TextButton(
                                              onPressed: !_isAddOrRemoveCF
                                                  ? () {
                                                      _addCloseFriend();
                                                      setState(() {
                                                        _isSectionVisible =
                                                            false;
                                                      });
                                                    }
                                                  : null,
                                              style: TextButton.styleFrom(
                                                foregroundColor: Colors.black,
                                                backgroundColor: Colors.white,
                                              ),
                                              child: const Text(
                                                  'Add Close Friend'),
                                            ),
                                          ),
                                        ),
                                        const Align(
                                          alignment: Alignment.center,
                                          child: Icon(Icons.stars),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                              Container(
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                ),
                                padding: const EdgeInsets.fromLTRB(
                                    20.0, 4.0, 20.0, 4.0),
                                width: double.infinity,
                                alignment: Alignment.centerLeft,
                                child: FutureBuilder<dynamic>(
                                  future: _isFavouriteUser(),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      if (snapshot.data.toString() == 'true') {
                                        return Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: TextButton(
                                                  onPressed: !_isAddOrRemoveFU
                                                      ? () {
                                                          _removeFavouriteUser();
                                                          setState(() {
                                                            _isSectionVisible =
                                                                false;
                                                          });
                                                        }
                                                      : null,
                                                  style: TextButton.styleFrom(
                                                    foregroundColor:
                                                        Colors.black,
                                                    backgroundColor:
                                                        Colors.white,
                                                  ),
                                                  child: const Text(
                                                      'Remove Favourite User'),
                                                ),
                                              ),
                                            ),
                                            ShaderMask(
                                              shaderCallback: (Rect bounds) {
                                                return const LinearGradient(
                                                  colors: [
                                                    Colors.yellow,
                                                    Colors.cyan
                                                  ],
                                                  begin: Alignment.centerLeft,
                                                  end: Alignment.centerRight,
                                                ).createShader(bounds);
                                              },
                                              child: const Icon(
                                                Icons.star_rounded,
                                                color: Colors.white,
                                              ),
                                            )
                                          ],
                                        );
                                      }
                                      return Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: TextButton(
                                                onPressed: !_isAddOrRemoveFU
                                                    ? () {
                                                        _addFavouriteUser();
                                                        setState(() {
                                                          _isSectionVisible =
                                                              false;
                                                        });
                                                      }
                                                    : null,
                                                style: TextButton.styleFrom(
                                                  foregroundColor: Colors.black,
                                                  backgroundColor: Colors.white,
                                                ),
                                                child: const Text(
                                                    'Add Favourite User'),
                                              ),
                                            ),
                                          ),
                                          const Icon(
                                              Icons.star_outline_rounded),
                                        ],
                                      );
                                    }
                                    return Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: TextButton(
                                              onPressed: !_isAddOrRemoveFU
                                                  ? () {
                                                      _addFavouriteUser();
                                                      setState(() {
                                                        _isSectionVisible =
                                                            false;
                                                      });
                                                    }
                                                  : null,
                                              style: TextButton.styleFrom(
                                                foregroundColor: Colors.black,
                                                backgroundColor: Colors.white,
                                              ),
                                              child: const Text(
                                                  'Add Favourite User'),
                                            ),
                                          ),
                                        ),
                                        const Icon(Icons.star_outline_rounded),
                                      ],
                                    );
                                  },
                                ),
                              ),
                              Container(
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                ),
                                padding: const EdgeInsets.fromLTRB(
                                    20.0, 4.0, 20.0, 4.0),
                                width: double.infinity,
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: TextButton(
                                          onPressed: !_isFollwingOrUnfollowing
                                              ? () {
                                                  _unfollowUser();
                                                  setState(() {
                                                    _isSectionVisible = false;
                                                  });
                                                }
                                              : null,
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.black,
                                            backgroundColor: Colors.white,
                                          ),
                                          child: const Text('Unfollow'),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Container()
              ],
            ),
          ),
        );
      },
    );
  }
}
