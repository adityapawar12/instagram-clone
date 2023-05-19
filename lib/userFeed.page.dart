import 'comments.page.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'utils/clickable_text_utils.dart';
import 'package:video_player/video_player.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserFeedPage extends StatefulWidget {
  final int userId;

  const UserFeedPage({Key? key, required this.userId}) : super(key: key);

  @override
  State<UserFeedPage> createState() => _UserFeedPageState();
}

class _UserFeedPageState extends State<UserFeedPage> {
  // USER
  static int _userId = 0;

  // GET USER INFO FROM SESSION
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getInt('userId') ?? 0;
    });
  }

  // GET POSTS
  _getPosts() {
    var future = Supabase.instance.client
        .from('posts')
        .select<List<Map<String, dynamic>>>('''
    *,
    users (
      id,
      name,
      profile_image_url
    ),
    likes (
      id
    ),
    saves (
      id
    )
  ''')
        .eq('user_id', widget.userId)
        .order('id');
    return future;
  }

  // LIKE POST
  _likePost(post) async {
    final checkLike = await Supabase.instance.client
        .from('likes')
        .select()
        .eq('user_id', _userId)
        .eq('post_id', post['id']);
    if (checkLike.length > 0) {
      await Supabase.instance.client.from('likes').delete().match(
        {
          'user_id': _userId,
          'post_id': post['id'],
        },
      );
      setState(() {
        _getPosts();
      });
    } else if (checkLike.length < 1) {
      await Supabase.instance.client.from('likes').insert(
        {
          'user_id': _userId,
          'post_id': post['id'],
        },
      );
      setState(() {
        _getPosts();
      });
    }
  }

  // SAVE POST
  _savePost(post) async {
    final checkSave = await Supabase.instance.client
        .from('saves')
        .select()
        .eq('user_id', _userId)
        .eq('post_id', post['id']);
    if (checkSave.length > 0) {
      await Supabase.instance.client.from('saves').delete().match(
        {
          'user_id': _userId,
          'post_id': post['id'],
        },
      );
      setState(() {
        _getPosts();
      });
    } else if (checkSave.length < 1) {
      await Supabase.instance.client.from('saves').insert(
        {
          'user_id': _userId,
          'post_id': post['id'],
        },
      );
      setState(() {
        _getPosts();
      });
    }
  }

  // CHECK IF POST IS LIKED OR NOT
  Future<bool> _isPostLiked(post) async {
    final checkLike = await Supabase.instance.client
        .from('likes')
        .select()
        .eq('user_id', _userId)
        .eq('post_id', post['id']);
    if (checkLike.length > 0) {
      return true;
    }
    return false;
  }

  // CHECK IF POST IS SAVED OR NOT
  Future<bool> _isPostSaved(post) async {
    final checkSave = await Supabase.instance.client
        .from('saves')
        .select()
        .eq('user_id', _userId)
        .eq('post_id', post['id']);
    if (checkSave.length > 0) {
      return true;
    }
    return false;
  }

  // LIFECYCLE METHODS
  @override
  void initState() {
    _loadPreferences();
    super.initState();
  }
  // LIFECYCLE METHODS

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getPosts(),
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
            leading: BackButton(
              color: Colors.black,
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            title: Container(
              alignment: Alignment.centerLeft,
              child: const Text(
                'Posts',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          body: ListView.builder(
            itemCount: posts.length,
            itemBuilder: ((context, index) {
              final post = posts[index];
              return
                  // InkWell(
                  //   onTap: () {
                  //     postClick(post['id'], context);
                  //   },
                  //   child:
                  Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                    ),
                    child: ListTile(
                      tileColor: Colors.white,
                      leading: post['users']?['profile_image_url'] != null &&
                              post['users']['profile_image_url'].length > 0
                          ? CircleAvatar(
                              backgroundImage: NetworkImage(
                                post['users']['profile_image_url'],
                              ),
                            )
                          : ClipOval(
                              child: Container(
                                height: 40,
                                width: 40,
                                color: const Color.fromARGB(255, 240, 240, 240),
                                child: const SizedBox(
                                  child: Icon(
                                    Icons.person,
                                    size: 30,
                                  ),
                                ),
                              ),
                            ),
                      title: Text(
                        post['users']['name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        post['location'],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                  if (post['post_type'] == 'image')
                    Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            width: 0.5,
                            color: Color.fromARGB(255, 204, 204, 204),
                          ),
                        ),
                        color: Colors.white,
                      ),
                      height: 400,
                      width: double.infinity,
                      child: FittedBox(
                          fit: BoxFit.contain,
                          child: Image.network(post['post_url'])),
                    )
                  else if (post['post_type'] == 'video')
                    Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            width: 0.5,
                            color: Color.fromARGB(255, 204, 204, 204),
                          ),
                        ),
                        color: Colors.white,
                      ),
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
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                FutureBuilder<dynamic>(
                                    future: _isPostLiked(post),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData) {
                                        return IconButton(
                                          icon: snapshot.data || false
                                              ? const Icon(Icons.favorite,
                                                  color: Colors.red)
                                              : const Icon(
                                                  Icons.favorite_border),
                                          onPressed: () {
                                            _likePost(post);
                                          },
                                        );
                                      } else {
                                        return const Icon(
                                            Icons.favorite_border);
                                      }
                                    }),
                                const SizedBox(width: 4.0),
                                IconButton(
                                  icon: const Icon(Icons.mode_comment_outlined),
                                  onPressed: () async {
                                    final prefs =
                                        await SharedPreferences.getInstance();
                                    prefs.setInt('commentPostId', post['id']);
                                    // ignore: use_build_context_synchronously
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const CommentsPage(),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            FutureBuilder<dynamic>(
                                future: _isPostSaved(post),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData) {
                                    return IconButton(
                                      icon: snapshot.data || false
                                          ? const Icon(Icons.bookmark,
                                              color: Colors.black)
                                          : const Icon(Icons.bookmark_border),
                                      onPressed: () {
                                        _savePost(post);
                                      },
                                    );
                                  } else {
                                    return const Icon(Icons.bookmark_border);
                                  }
                                }),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 14.0,
                              ),
                              child: Text(
                                "${post['likes'].length.toString()} Likes",
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 14.0,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    "${post['users']['name']}",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 5.0,
                                  ),
                                  RichText(
                                    text: buildClickableTextSpan(
                                        post['caption'], _userId, context),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                // ),
              );
            }),
          ),
        );
      },
    );
  }
}
