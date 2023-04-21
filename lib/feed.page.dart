import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:image/image.dart' as img;

class FeedPage extends StatefulWidget {
  const FeedPage({Key? key}) : super(key: key);

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  List<int> likes = <int>[];
  List<int> saves = <int>[];

  @override
  void initState() {
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
  ''').order('id');

  // Future<void> _getPosts() async {final postsData = await Supabase.instance.client.rpc('fp_get_posts');setState(() {posts = postsData;});}

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
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                    ),
                    child: ListTile(
                      tileColor: Colors.white,
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(
                          post['users']['profile_image'],
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
                          top: BorderSide(width: 0.5, color: Colors.black26),
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
                          top: BorderSide(width: 0.5, color: Colors.black26),
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
                                IconButton(
                                  icon: likes.contains(index)
                                      ? const Icon(Icons.favorite,
                                          color: Colors.red)
                                      : const Icon(Icons.favorite_border),
                                  onPressed: () {
                                    setState(
                                      () {
                                        if (likes.contains(index)) {
                                          likes.removeWhere(
                                              (item) => item == index);
                                        } else {
                                          likes.add(index);
                                        }
                                      },
                                    );
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
                                  ? const Icon(Icons.bookmark,
                                      color: Colors.black)
                                  : const Icon(Icons.bookmark_border),
                              onPressed: () {
                                setState(
                                  () {
                                    if (saves.contains(index)) {
                                      saves
                                          .removeWhere((item) => item == index);
                                    } else {
                                      saves.add(index);
                                    }
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const <Widget>[
                            Padding(
                              padding: EdgeInsets.only(
                                left: 14.0,
                              ),
                              child: Text(
                                "Number Of Likes Or liked by",
                                style: TextStyle(
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
                                  Text(
                                    "${post['caption']}",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                    ),
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
              );
            }),
          ),
        );
      },
    );
  }
}
