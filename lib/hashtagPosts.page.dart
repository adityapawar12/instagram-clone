import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HashtagPosts extends StatefulWidget {
  final String hashtag;

  const HashtagPosts({super.key, required this.hashtag});

  @override
  State<HashtagPosts> createState() => _HashtagPostsState();
}

class _HashtagPostsState extends State<HashtagPosts> {
  late dynamic _hashtag = {};

  // USER
  static int _userId = 0;

  // GET USER INFO FROM SESSION
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getInt('userId') ?? 0;
    });
  }

  // GET HASHTAG INFO
  Future<void> getHashtag() async {
    var hashtag = await Supabase.instance.client
        .from('hashtags')
        .select<List<Map<String, dynamic>>>("*")
        .eq('hashtag', widget.hashtag);

    log(hashtag.toString());

    setState(() {
      _hashtag = hashtag;
    });
  }

  // GET HASHTAG POSTS COUNT
  getHashtagPostsCount(int hashtagId) {
    var hashtagPostsCount = Supabase.instance.client
        .from('hashtag_posts')
        .select('id')
        .eq('hashtag_id', hashtagId);

    return hashtagPostsCount;
  }

  // GET HASHTAG POSTS
  Future<void> getHashtagPosts(int hashtagId) async {
    var hashtagPosts = await Supabase.instance.client
        .from('hashtag_posts')
        .select<List<Map<String, dynamic>>>("*")
        .eq('hashtag_id', hashtagId);

    log(hashtagPosts.toString());
  }

  // CHECK IF USER IS FOLLOWED OR NOT
  Future<bool> _isHashtagFollowed(hashTagId) async {
    final checkLike = await Supabase.instance.client
        .from('hashtag_followers')
        .select()
        .eq('follower_user_id', _userId)
        .eq('followed_hashtag_id', hashTagId);
    if (checkLike.length > 0) {
      return true;
    }
    return false;
  }

  // FOLLOW HASHTAG
  Future<dynamic> _follow(int hashTagId) async {
    var obj = {'follower_user_id': _userId, 'followed_hashtag_id': hashTagId};

    await Supabase.instance.client.from('hashtag_followers').insert(obj);

    setState(() {});
  }

  // GET POST
  _getPost(postId) {
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
        .eq('id', postId)
        .order('id');
    return future;
  }

  @override
  void initState() {
    _loadPreferences();
    getHashtag();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
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
            _hashtag != null && _hashtag.length > 0
                ? _hashtag[0]['hashtag']
                : '',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black,
              fontFamily: 'sans-serif',
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Column(
          children: <Widget>[
            Expanded(
              flex: 1,
              child: Row(
                children: <Widget>[
                  Container(
                    width: 75,
                    margin: const EdgeInsets.fromLTRB(10.0, 0, 0, 0),
                    alignment: Alignment.center,
                    child: FutureBuilder(
                      future: _getPost(_hashtag != null && _hashtag.length > 0
                          ? _hashtag[0]['post_id']
                          : 0),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return ClipOval(
                            child: Container(
                              alignment: Alignment.center,
                              height: 75,
                              width: 75,
                              color: const Color.fromARGB(255, 240, 240, 240),
                              child: SizedBox(
                                child: Image.network(
                                  'https://simg.nicepng.com/png/small/128-1280406_view-user-icon-png-user-circle-icon-png.png',
                                  height: 75,
                                  width: 75,
                                ),
                              ),
                            ),
                          );
                        }
                        final dynamic post = snapshot.data!;

                        log(snapshot.data!.toString());

                        return post[0]['users']['profile_image_url'] != null &&
                                post[0]['users']['profile_image_url'].length > 0
                            ? ClipOval(
                                child: Container(
                                  alignment: Alignment.center,
                                  height: 75,
                                  width: 75,
                                  color:
                                      const Color.fromARGB(255, 240, 240, 240),
                                  child: SizedBox(
                                      child: Image.network(
                                    post[0]['users']['profile_image_url'],
                                    height: 75,
                                    width: 75,
                                  )),
                                ),
                              )
                            : ClipOval(
                                child: Container(
                                  alignment: Alignment.center,
                                  height: 75,
                                  width: 75,
                                  color:
                                      const Color.fromARGB(255, 240, 240, 240),
                                  child: SizedBox(
                                    child: Image.network(
                                      'https://simg.nicepng.com/png/small/128-1280406_view-user-icon-png-user-circle-icon-png.png',
                                      height: 75,
                                      width: 75,
                                    ),
                                  ),
                                ),
                              );
                      },
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: double.infinity,
                          alignment: Alignment.center,
                          child: FutureBuilder(
                            future: getHashtagPostsCount(
                                _hashtag != null && _hashtag.length > 0
                                    ? _hashtag[0]['id']
                                    : 0),
                            builder: (context, snapshot) {
                              log(snapshot.data.toString());
                              if (!snapshot.hasData) {
                                return const Text(
                                  '0',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontFamily: 'sans-serif',
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              }

                              dynamic hashtagPosts = snapshot.data;

                              return Text(
                                hashtagPosts.length.toString(),
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontFamily: 'sans-serif',
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                            // ),
                          ),
                        ),
                        Container(
                          alignment: Alignment.center,
                          child: FutureBuilder<dynamic>(
                            future: _isHashtagFollowed(
                                _hashtag != null && _hashtag.length > 0
                                    ? _hashtag[0]['id']
                                    : 0),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                if (snapshot.data.toString() != 'true') {
                                  return Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.fromLTRB(
                                        10.0, 0, 10.0, 0),
                                    child: TextButton(
                                      onPressed: () {
                                        _follow(_hashtag != null &&
                                                _hashtag.length > 0
                                            ? _hashtag[0]['id']
                                            : 0);
                                      },
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
                                  );
                                } else {
                                  return Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.fromLTRB(
                                        10.0, 0, 10.0, 0),
                                    child: TextButton(
                                      onPressed: () {},
                                      style: ButtonStyle(
                                        backgroundColor:
                                            MaterialStateProperty.all<Color>(
                                          const Color.fromARGB(
                                              255, 240, 240, 240),
                                        ),
                                        foregroundColor:
                                            MaterialStateProperty.all<Color>(
                                          Colors.black,
                                        ),
                                      ),
                                      child: const Text('Followed'),
                                    ),
                                  );
                                }
                              } else {
                                return Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.fromLTRB(
                                      10.0, 0, 10.0, 0),
                                  child: TextButton(
                                    onPressed: () {},
                                    style: ButtonStyle(
                                      backgroundColor:
                                          MaterialStateProperty.all<Color>(
                                        const Color.fromARGB(
                                            255, 240, 240, 240),
                                      ),
                                      foregroundColor:
                                          MaterialStateProperty.all<Color>(
                                        Colors.black,
                                      ),
                                    ),
                                    child: const Text('Followed'),
                                  ),
                                );
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
            Expanded(
              flex: 6,
              child: Row(
                children: const <Widget>[
                  Text('The hashtag'),
                ],
              ),
            ),
          ],
        ));
  }
}
