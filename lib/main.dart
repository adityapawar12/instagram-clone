import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://wjzgvpftlznhngujjmze.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Indqemd2cGZ0bHpuaG5ndWpqbXplIiwicm9sZSI6ImFub24iLCJpYXQiOjE2ODEyMDQ5MTgsImV4cCI6MTk5Njc4MDkxOH0.M8QuSuQWQFcP13_1nallkST1hIlP7WJrgWPwwXs9BPc',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Countries',
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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

  List<int> likes = <int>[];
  List<int> saves = <int>[];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        shadowColor: Colors.white,
        elevation: 0,
        leading: Image.network(
            'https://1000logos.net/wp-content/uploads/2017/02/Logo-Instagram.png'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final posts = snapshot.data!;
          return ListView.builder(
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
                    Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(width: 0.5, color: Colors.black26),
                          top: BorderSide(width: 0.5, color: Colors.black26),
                        ),
                      ),
                      height: 380,
                      width: double.infinity,
                      child: Image.network(post['post_url']),
                    )
                  else if (post['post_type'] == 'video')
                    Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(width: 0.5, color: Colors.black26),
                          top: BorderSide(width: 0.5, color: Colors.black26),
                        ),
                      ),
                      height: 380,
                      width: double.infinity,
                      child: Chewie(
                        controller: ChewieController(
                          videoPlayerController: VideoPlayerController.network(
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
                          const SizedBox(width: 4.0), // Add some space here
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
          );
        },
      ),
    );
  }
}
