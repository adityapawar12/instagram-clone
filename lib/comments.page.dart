import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CommentsPage extends StatefulWidget {
  const CommentsPage({super.key});

  @override
  State<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  late int? _postId = 0;
  late int? _userId = 0;
  late String? _userProfileUrl = '';
  late bool _shouldWaitForComments = true;
  Timer? _timer;
  late dynamic _selectedComment;
  late bool _isReplying = false;
  // late bool _showReplies = false;

  // FORM
  final _commentController = TextEditingController();

  @override
  void initState() {
    _getPostId();
    _waitSevenSeconds();
    super.initState();
  }

  void _getPostId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _postId = prefs.getInt('commentPostId');
      _userId = prefs.getInt('userId');
      _userProfileUrl = prefs.getString('profileImageUrl');
    });
  }

  // GET POST
  _getPost() {
    final future = Supabase.instance.client
        .from('posts')
        .select<List<Map<String, dynamic>>>('''
          *,
          users (
            id,
            name,
            profile_image_url
          )
        ''')
        .eq('id', _postId)
        .order('id');
    return future;
  }

  // GET COMMENTS
  _getComments() {
    final future = Supabase.instance.client
        .from('comments')
        .select<List<Map<String, dynamic>>>('''
          *,
    users!comments_user_id_fkey (
            id,
            name,
            user_tag_id,
            profile_image_url
          )
        ''')
        .eq('post_id', _postId)
        .eq('is_reply', false)
        .order('id');
    return future;
  }

  // COMMENT ON POST
  _comment() async {
    if (_commentController.text.isNotEmpty) {
      var obj = {
        'user_id': _userId,
        'post_id': _postId,
        'comment': _commentController.text,
        'is_reply': false
      };
      await Supabase.instance.client.from('comments').insert(obj);

      _commentController.clear();

      setState(() {
        _getComments();
      });
    }
  }

  // LIKE COMMENT
  _likeComment(comment) async {
    final checkLike = await Supabase.instance.client
        .from('comment_likes')
        .select()
        .eq('user_id', _userId)
        .eq('comment_id', comment['id']);
    if (checkLike.length > 0) {
      await Supabase.instance.client.from('comment_likes').delete().match(
        {
          'user_id': _userId,
          'comment_id': comment['id'],
        },
      );
      setState(() {
        _getComments();
      });
    } else if (checkLike.length < 1) {
      await Supabase.instance.client.from('comment_likes').insert(
        {
          'user_id': _userId,
          'comment_id': comment['id'],
        },
      );
      setState(() {
        _getComments();
      });
    }
  }

  // CHECK IF COMMENT IS LIKED OR NOT
  Future<bool> _isCommentLiked(comment) async {
    final checkLike = await Supabase.instance.client
        .from('comment_likes')
        .select()
        .eq('user_id', _userId)
        .eq('comment_id', comment['id']);
    if (checkLike.length > 0) {
      return true;
    }
    return false;
  }

  // GET COMMENTS
  _getCommentsLikeCount(comment) {
    final future = Supabase.instance.client
        .from('comment_likes')
        .select('id')
        .eq('comment_id', comment['id']);
    return future;
  }

  // REPLY ON COMMENT
  void _waitSevenSeconds() {
    _timer = Timer(const Duration(seconds: 7), () {
      if (mounted) {
        // check if the widget is still mounted before calling setState()
        setState(() {
          // your code here
          _shouldWaitForComments = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // REPLY ON COMMENT
  _reply(comment) async {
    if (_commentController.text.isNotEmpty) {
      var obj = {
        'user_id': _userId,
        'post_id': _postId,
        'comment': _commentController.text,
        'comment_id': comment['id'],
        'reply_user_id': comment['user_id'],
        'is_reply': true
      };
      await Supabase.instance.client.from('comments').insert(obj);
      _commentController.clear();
      setState(() {
        _reply(comment);
      });
    }
  }

  // GET REPLIES
  // _getReplies(comment) {
  //   final future = Supabase.instance.client
  //       .from('comments')
  //       .select<List<Map<String, dynamic>>>('''
  //         *,
  //   users!comments_user_id_fkey (
  //           id,
  //           name,
  //           user_tag_id,
  //           profile_image_url
  //         )
  //       ''')
  //       .eq('post_id', _postId)
  //       .eq('is_reply', true)
  //       .eq('comment_id', comment['id'])
  //       .order('id');
  //   return future;
  // }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getComments(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.white,
              iconTheme: const IconThemeData(
                color: Colors.black,
              ),
              surfaceTintColor: Colors.black,
              shadowColor: Colors.white,
              elevation: 0,
              title: const Text(
                'Comments',
                style: TextStyle(
                  fontSize: 22.0,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
            body: Column(
              children: [
                SizedBox(
                  height: 60,
                  child: FutureBuilder(
                    future: _getPost(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Scaffold(
                          body: Center(
                            // child: CircularProgressIndicator(
                            //   backgroundColor: Colors.white,
                            // ),
                            child: SizedBox(
                              height: 100,
                              width: double.infinity,
                            ),
                          ),
                        );
                      }
                      final dynamic post = snapshot.data!;
                      return SizedBox(
                        height: 60,
                        child: Row(
                          children: [
                            Container(
                              width: 16,
                            ),
                            post[0]['users']['profile_image_url'] != null &&
                                    post[0]['users']['profile_image_url']
                                            .length >
                                        0
                                ? ClipOval(
                                    child: Container(
                                      height: 40,
                                      width: 40,
                                      color: const Color.fromARGB(
                                          255, 243, 243, 243),
                                      child: SizedBox(
                                          child: Image.network(
                                        post[0]['users']['profile_image_url'],
                                        height: 40,
                                        width: 40,
                                      )),
                                    ),
                                  )
                                : ClipOval(
                                    child: Container(
                                      height: 40,
                                      width: 40,
                                      color: const Color.fromARGB(
                                          255, 243, 243, 243),
                                      child: SizedBox(
                                        child: Image.network(
                                          'https://simg.nicepng.com/png/small/128-1280406_view-user-icon-png-user-circle-icon-png.png',
                                          height: 40,
                                          width: 40,
                                        ),
                                      ),
                                    ),
                                  ),
                            Container(
                              width: 16,
                            ),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  post[0]['caption'] != null &&
                                          post[0]['caption'].length > 0
                                      ? Container(
                                          margin: const EdgeInsets.fromLTRB(
                                            0,
                                            10,
                                            0,
                                            0,
                                          ),
                                          padding: const EdgeInsets.all(
                                            0,
                                          ),
                                          child: Text(
                                            post[0]['users']['name'],
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        )
                                      : const Text(''),
                                  post[0]['caption'] != null &&
                                          post[0]['caption'].length > 0
                                      ? Container(
                                          margin: const EdgeInsets.fromLTRB(
                                            0,
                                            10,
                                            0,
                                            0,
                                          ),
                                          padding: const EdgeInsets.all(
                                            0,
                                          ),
                                          child: Text(
                                            post[0]['caption'],
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        )
                                      : const Text(''),
                                ],
                              ),
                            ),
                            Container(
                              width: 16,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(
                  height: 16.0,
                ),
                Expanded(
                  child: Center(
                    child: _shouldWaitForComments == true
                        ? const CircularProgressIndicator(
                            color: Colors.black,
                          )
                        : const Text(
                            'No Comments',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w400),
                          ),
                  ),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 20,
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: _userProfileUrl != null &&
                                _userProfileUrl!.isNotEmpty
                            ? ClipOval(
                                child: Container(
                                  height: 40,
                                  width: 40,
                                  color:
                                      const Color.fromARGB(255, 243, 243, 243),
                                  child: SizedBox(
                                      child: Image.network(
                                    _userProfileUrl!,
                                    height: 40,
                                    width: 40,
                                  )),
                                ),
                              )
                            : ClipOval(
                                child: Container(
                                  height: 40,
                                  width: 40,
                                  color:
                                      const Color.fromARGB(255, 243, 243, 243),
                                  child: SizedBox(
                                      child: Image.network(
                                    'https://simg.nicepng.com/png/small/128-1280406_view-user-icon-png-user-circle-icon-png.png',
                                    height: 40,
                                    width: 40,
                                  )),
                                ),
                              ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(45.0, 0, 0, 0),
                        child: TextFormField(
                          controller: _commentController,
                          decoration: const InputDecoration(
                            hintText: 'Add a comment',
                            border: OutlineInputBorder(
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                            MediaQuery.of(context).size.width - 80, 0, 8, 0),
                        child: TextButton(
                          onPressed: _comment,
                          child: const Text('post'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 16.0,
                ),
              ],
            ),
          );
        }
        final comments = snapshot.data!;
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            iconTheme: const IconThemeData(
              color: Colors.black,
            ),
            surfaceTintColor: Colors.black,
            shadowColor: Colors.white,
            elevation: 0,
            title: const Text(
              'Comments',
              style: TextStyle(
                fontSize: 22.0,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
          body: Column(
            children: [
              SizedBox(
                height: 60,
                child: FutureBuilder(
                  future: _getPost(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Scaffold(
                        body: Center(
                          // child: CircularProgressIndicator(
                          //   backgroundColor: Colors.white,
                          // ),
                          child: SizedBox(
                            height: 100,
                            width: double.infinity,
                          ),
                        ),
                      );
                    }
                    final dynamic post = snapshot.data!;
                    return SizedBox(
                      height: 60,
                      child: Row(
                        children: [
                          Container(
                            width: 16,
                          ),
                          post[0]['users']['profile_image_url'] != null &&
                                  post[0]['users']['profile_image_url'].length >
                                      0
                              ? ClipOval(
                                  child: Container(
                                    height: 40,
                                    width: 40,
                                    color: const Color.fromARGB(
                                        255, 243, 243, 243),
                                    child: SizedBox(
                                        child: Image.network(
                                      post[0]['users']['profile_image_url'],
                                      height: 40,
                                      width: 40,
                                    )),
                                  ),
                                )
                              : ClipOval(
                                  child: Container(
                                    height: 40,
                                    width: 40,
                                    color: const Color.fromARGB(
                                        255, 243, 243, 243),
                                    child: SizedBox(
                                      child: Image.network(
                                        'https://simg.nicepng.com/png/small/128-1280406_view-user-icon-png-user-circle-icon-png.png',
                                        height: 40,
                                        width: 40,
                                      ),
                                    ),
                                  ),
                                ),
                          Container(
                            width: 16,
                          ),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                post[0]['caption'] != null &&
                                        post[0]['caption'].length > 0
                                    ? Container(
                                        margin: const EdgeInsets.fromLTRB(
                                          0,
                                          10,
                                          0,
                                          0,
                                        ),
                                        padding: const EdgeInsets.all(
                                          0,
                                        ),
                                        child: Text(
                                          post[0]['users']['name'],
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      )
                                    : const Text(''),
                                post[0]['caption'] != null &&
                                        post[0]['caption'].length > 0
                                    ? Container(
                                        margin: const EdgeInsets.fromLTRB(
                                          0,
                                          10,
                                          0,
                                          0,
                                        ),
                                        padding: const EdgeInsets.all(
                                          0,
                                        ),
                                        child: Text(
                                          post[0]['caption'],
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      )
                                    : const Text(''),
                              ],
                            ),
                          ),
                          Container(
                            width: 16,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(
                height: 16.0,
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: ListView.builder(
                    scrollDirection: Axis.vertical,
                    shrinkWrap: true,
                    itemCount: comments.length,
                    itemBuilder: ((context, index) {
                      final comment = comments[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          SizedBox(
                            child: Row(
                              children: [
                                Container(
                                  width: 16,
                                ),
                                comment['users']['profile_image_url'] != null &&
                                        comment['users']['profile_image_url']
                                                .length >
                                            0
                                    ? ClipOval(
                                        child: Container(
                                          height: 40,
                                          width: 40,
                                          color: const Color.fromARGB(
                                              255, 243, 243, 243),
                                          child: SizedBox(
                                              child: Image.network(
                                            comment['users']
                                                ['profile_image_url'],
                                            height: 40,
                                            width: 40,
                                          )),
                                        ),
                                      )
                                    : ClipOval(
                                        child: Container(
                                          height: 40,
                                          width: 40,
                                          color: const Color.fromARGB(
                                              255, 243, 243, 243),
                                          child: SizedBox(
                                              child: Image.network(
                                            'https://simg.nicepng.com/png/small/128-1280406_view-user-icon-png-user-circle-icon-png.png',
                                            height: 40,
                                            width: 40,
                                          )),
                                        ),
                                      ),
                                Container(
                                  width: 16,
                                ),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      comment['users']['name'] != null &&
                                              comment['users']['name'].length >
                                                  0
                                          ? Container(
                                              margin: const EdgeInsets.fromLTRB(
                                                0,
                                                10,
                                                0,
                                                0,
                                              ),
                                              padding: const EdgeInsets.all(
                                                0,
                                              ),
                                              child: Text(
                                                comment['users']['name'],
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            )
                                          : const Text(''),
                                      comment['comment'] != null &&
                                              comment['comment'].length > 0
                                          ? Container(
                                              margin: const EdgeInsets.fromLTRB(
                                                0,
                                                10,
                                                0,
                                                0,
                                              ),
                                              padding: const EdgeInsets.all(
                                                0,
                                              ),
                                              child: Text(
                                                comment['comment'],
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                            )
                                          : const Text(''),
                                      TextButton(
                                        style: ButtonStyle(
                                          padding: MaterialStateProperty.all(
                                            EdgeInsets.zero,
                                          ),
                                          alignment: Alignment.centerLeft,
                                        ),
                                        onPressed: () {
                                          _isReplying = true;
                                          _selectedComment = comment;
                                          _commentController.text =
                                              "@${comment['users']['user_tag_id']} ";
                                        },
                                        child: const Text(
                                          'Reply',
                                          textAlign: TextAlign.start,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w300,
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        style: ButtonStyle(
                                          padding: MaterialStateProperty.all(
                                            EdgeInsets.zero,
                                          ),
                                          alignment: Alignment.centerLeft,
                                        ),
                                        onPressed: () {
                                          // _showReplies = true;
                                        },
                                        child: const Text(
                                          '---- See all replies',
                                          textAlign: TextAlign.start,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w300,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 16,
                                ),
                                SizedBox(
                                  width: 50,
                                  height: 60,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 50,
                                        height: 40,
                                        child: FutureBuilder<dynamic>(
                                          future: _isCommentLiked(comment),
                                          builder: (context, snapshot) {
                                            if (snapshot.hasData) {
                                              return IconButton(
                                                icon: snapshot.data || false
                                                    ? const Icon(
                                                        Icons.favorite,
                                                        color: Colors.red,
                                                        size: 20,
                                                      )
                                                    : const Icon(
                                                        Icons.favorite_border,
                                                        color: Colors.grey,
                                                        size: 20,
                                                      ),
                                                onPressed: () {
                                                  _likeComment(comment);
                                                },
                                              );
                                            } else {
                                              return const Icon(
                                                Icons.favorite_border,
                                                size: 20,
                                              );
                                            }
                                          },
                                        ),
                                      ),
                                      Container(
                                        width: 50,
                                        height: 20,
                                        alignment: Alignment.center,
                                        child: FutureBuilder<dynamic>(
                                          future:
                                              _getCommentsLikeCount(comment),
                                          builder: (context, snapshot) {
                                            if (snapshot.hasData) {
                                              return Text(
                                                snapshot.data.length.toString(),
                                              );
                                            } else {
                                              return const Text('0');
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(
                height: 16.0,
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width - 20,
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: _userProfileUrl != null &&
                              _userProfileUrl!.isNotEmpty
                          ? ClipOval(
                              child: Container(
                                height: 40,
                                width: 40,
                                color: const Color.fromARGB(255, 243, 243, 243),
                                child: SizedBox(
                                    child: Image.network(
                                  _userProfileUrl!,
                                  height: 40,
                                  width: 40,
                                )),
                              ),
                            )
                          : ClipOval(
                              child: Container(
                                height: 40,
                                width: 40,
                                color: const Color.fromARGB(255, 243, 243, 243),
                                child: SizedBox(
                                    child: Image.network(
                                  'https://simg.nicepng.com/png/small/128-1280406_view-user-icon-png-user-circle-icon-png.png',
                                  height: 40,
                                  width: 40,
                                )),
                              ),
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(45.0, 0, 0, 0),
                      child: TextFormField(
                        controller: _commentController,
                        decoration: const InputDecoration(
                          hintText: 'Add a comment',
                          border: OutlineInputBorder(
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                          MediaQuery.of(context).size.width - 80, 0, 8, 0),
                      child: TextButton(
                        onPressed: () {
                          if (_isReplying == false) {
                            _comment();
                          } else if (_isReplying == true) {
                            _reply(_selectedComment);
                          }
                        },
                        child: const Text('post'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 16.0,
              ),
            ],
          ),
        );
      },
    );
  }
}
