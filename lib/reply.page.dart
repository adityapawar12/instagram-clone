import 'package:flutter/material.dart';
import 'utils/clickable_text_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReplyPage extends StatefulWidget {
  final dynamic reply;
  final Function(bool isReply, dynamic reply, String replyText) onReplyPressed;

  const ReplyPage(
      {super.key, required this.reply, required this.onReplyPressed});

  @override
  State<ReplyPage> createState() => _ReplyPageState();
}

class _ReplyPageState extends State<ReplyPage> {
  // USER ID
  static int _userId = 0;

  // GET USER INFO FROM SESSION
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getInt('userId') ?? 0;
    });
  }

  // LIKE REPLY
  _likeReply(reply) async {
    final checkLike = await Supabase.instance.client
        .from('comment_likes')
        .select()
        .eq('user_id', _userId)
        .eq('comment_id', reply['id']);
    if (checkLike.length > 0) {
      await Supabase.instance.client.from('comment_likes').delete().match(
        {
          'user_id': _userId,
          'comment_id': reply['id'],
        },
      );
    } else if (checkLike.length < 1) {
      await Supabase.instance.client.from('comment_likes').insert(
        {
          'user_id': _userId,
          'comment_id': reply['id'],
        },
      );
    }
  }

  // CHECK IF COMMENT IS LIKED OR NOT
  Future<bool> _isReplyLiked(comment) async {
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

  // GET LIKES COUNT OF REPLY
  _getRepliessLikeCount(reply) {
    final future = Supabase.instance.client
        .from('comment_likes')
        .select('id')
        .eq('comment_id', reply['id']);
    return future;
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
          child: Row(
            children: [
              Container(
                width: 16,
              ),
              widget.reply['users']['profile_image_url'] != null &&
                      widget.reply['users']['profile_image_url'].length > 0
                  ? ClipOval(
                      child: Container(
                        height: 40,
                        width: 40,
                        color: const Color.fromARGB(255, 240, 240, 240),
                        child: SizedBox(
                            child: Image.network(
                          widget.reply['users']['profile_image_url'],
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
                    widget.reply['users']['name'] != null &&
                            widget.reply['users']['name'].length > 0
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
                              widget.reply['users']['name'],
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        : const Text(''),
                    widget.reply['comment'] != null &&
                            widget.reply['comment'].length > 0
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
                                  widget.reply['comment'], _userId, context),
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
                        widget.onReplyPressed(true, widget.reply,
                            "@${widget.reply['users']['user_tag_id']} ");
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
                        future: _isReplyLiked(widget.reply),
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
                                      color: Color.fromARGB(255, 240, 240, 240),
                                      size: 20,
                                    ),
                              onPressed: () {
                                _likeReply(widget.reply);
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
                        future: _getRepliessLikeCount(widget.reply),
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
  }
}
