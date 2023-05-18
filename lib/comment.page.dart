import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:instagram_clone/reply.page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'utils/clickable_text_utils.dart';

class CommentPage extends StatefulWidget {
  final dynamic comment;
  final Function(bool isReply, dynamic comment, String replyText)
      onReplyPressed;

  const CommentPage(
      {super.key, required this.comment, required this.onReplyPressed});

  @override
  State<CommentPage> createState() => _CommentPageState();
}

class _CommentPageState extends State<CommentPage> {
  // late bool _isReplying = false;
  // late dynamic _selectedComment;

  // POST ID
  late int? _postId = 0;

  // USER ID
  static int _userId = 0;

  // SHOW REPLIES
  late bool _showReplies = false;

  // GET USER INFO FROM SESSION
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _postId = prefs.getInt('commentPostId');
      _userId = prefs.getInt('userId') ?? 0;
    });
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
    } else if (checkLike.length < 1) {
      await Supabase.instance.client.from('comment_likes').insert(
        {
          'user_id': _userId,
          'comment_id': comment['id'],
        },
      );
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

  // GET REPLIES
  _getReplies(comment) {
    final replies = Supabase.instance.client
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
        .eq('is_reply', true)
        .eq('comment_id', comment['id'])
        .order('id');

    log(replies.toString());
    return replies;
  }

  void openTextField(bool isReply, dynamic comment, String replyText) {
    setState(() {
      widget.onReplyPressed(isReply, widget.comment, replyText);
    });
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 16,
                  ),
                  widget.comment['users']['profile_image_url'] != null &&
                          widget.comment['users']['profile_image_url'].length >
                              0
                      ? ClipOval(
                          child: Container(
                            height: 40,
                            width: 40,
                            color: const Color.fromARGB(255, 240, 240, 240),
                            child: SizedBox(
                                child: Image.network(
                              widget.comment['users']['profile_image_url'],
                              height: 40,
                              width: 40,
                            )),
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
                  Container(
                    width: 16,
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        widget.comment['users']['name'] != null &&
                                widget.comment['users']['name'].length > 0
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
                                  widget.comment['users']['name'],
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              )
                            : const Text(''),
                        widget.comment['comment'] != null &&
                                widget.comment['comment'].length > 0
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
                                child: RichText(
                                  text: buildClickableTextSpan(
                                      widget.comment['comment'],
                                      _userId,
                                      context),
                                ),
                              )
                            : const Text(''),
                        SizedBox(
                          height: 20,
                          child: TextButton(
                            style: ButtonStyle(
                              padding: MaterialStateProperty.all(
                                EdgeInsets.zero,
                              ),
                              alignment: Alignment.centerLeft,
                            ),
                            onPressed: () {
                              widget.onReplyPressed(true, widget.comment,
                                  "@${widget.comment['users']['user_tag_id']} ");
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
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 50,
                          height: 40,
                          child: FutureBuilder<dynamic>(
                            future: _isCommentLiked(widget.comment),
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
                                          color: Color.fromARGB(
                                              255, 240, 240, 240),
                                          size: 20,
                                        ),
                                  onPressed: () {
                                    _likeComment(widget.comment);
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
                            future: _getCommentsLikeCount(widget.comment),
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
              Container(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _getReplies(widget.comment),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox(
                        width: 0,
                        height: 0,
                      );
                    }
                    var replies = snapshot.data!;
                    log(replies.toString());
                    return Column(
                      children: [
                        _showReplies
                            ? SingleChildScrollView(
                                child: ListView.builder(
                                  scrollDirection: Axis.vertical,
                                  shrinkWrap: true,
                                  itemCount: replies.length,
                                  itemBuilder: ((context, index) {
                                    final reply = replies[index];
                                    return Container(
                                      padding: _showReplies
                                          ? const EdgeInsets.fromLTRB(
                                              50.0, 0, 0, 0)
                                          : const EdgeInsets.all(0),
                                      child: ReplyPage(
                                          reply: reply,
                                          onReplyPressed: openTextField),
                                    );
                                  }),
                                ),
                              )
                            : const SizedBox(
                                height: 0,
                                width: 0,
                              ),
                        replies.isNotEmpty
                            ? Container(
                                padding:
                                    const EdgeInsets.fromLTRB(70.0, 0, 0, 0),
                                alignment: Alignment.centerLeft,
                                height: 20,
                                child: TextButton(
                                  style: ButtonStyle(
                                    padding: MaterialStateProperty.all(
                                      EdgeInsets.zero,
                                    ),
                                    alignment: Alignment.centerLeft,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _showReplies = !_showReplies;
                                    });
                                  },
                                  child: Text(
                                    _showReplies
                                        ? 'Hide replies'
                                        : 'View ${replies.length} more ${replies.length < 2 ? "reply" : "replies"}',
                                    textAlign: TextAlign.start,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w300,
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox(),
                      ],
                    );
                  },
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
}
