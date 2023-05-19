import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:instagram_clone/othersProfile.page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  // USER
  static int _userId = 0;

  // SEARCH BAR TEXT FIELD
  final TextEditingController _searchController = TextEditingController();

  // OTHER
  late bool _showSearchResult = false;

  // GET USER INFO FROM SESSION
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getInt('userId') ?? 0;
    });
  }

  // GET SEARCH RESULTS
  _getSearchResults(String searchText) {
    final future = Supabase.instance.client
        .from('users')
        .select<List<Map<String, dynamic>>>(
            'id, name, user_tag_id, profile_image_url')
        .or('name.ilike.%$searchText%, user_tag_id.ilike.%$searchText%')
        .neq('id', _userId)
        .order('id');
    return future;
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
  ''').order('id');
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        elevation: 0,
        title: Container(
          height: 36.0,
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 240, 240, 240),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(10.0, 0, 10.0, 0),
                child: Icon(
                  Icons.search,
                  color: _searchController.text.isNotEmpty
                      ? Colors.black
                      : const Color.fromARGB(255, 204, 204, 204),
                ),
              ),
              Expanded(
                child: TextField(
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      setState(() {});
                    }
                  },
                  onSubmitted: (value) {
                    setState(() {
                      _showSearchResult = true;
                    });
                  },
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search',
                    border: InputBorder.none,
                    hintStyle: TextStyle(
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.clear,
                        color: Colors.black,
                      ),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _showSearchResult = false;
                        });
                      },
                    )
                  : Container(),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          _showSearchResult
              ? FutureBuilder(
                  future: _getSearchResults(_searchController.text),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child: Center(
                          child: CircularProgressIndicator(
                            backgroundColor: Colors.white,
                          ),
                        ),
                      );
                    }

                    dynamic users = snapshot.data!;

                    return Expanded(
                      child: ListView.builder(
                        itemCount: users!.length,
                        itemBuilder: (context, index) {
                          final user = users[index];
                          if (user.isNotEmpty) {
                            return ListTile(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => OthersProfile(
                                      userId: user['id'],
                                    ),
                                  ),
                                );
                              },
                              tileColor: Colors.white,
                              leading: user['profile_image_url'] != null &&
                                      user['profile_image_url'].length > 0
                                  ? CircleAvatar(
                                      backgroundImage: NetworkImage(
                                        user['profile_image_url'],
                                      ),
                                    )
                                  : ClipOval(
                                      child: Container(
                                        height: 50,
                                        width: 50,
                                        color: const Color.fromARGB(
                                            255, 240, 240, 240),
                                        child: const SizedBox(
                                          child: Icon(
                                            Icons.person,
                                            size: 40,
                                          ),
                                        ),
                                      ),
                                    ),
                              title: Text(
                                user['name'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                '@${user['user_tag_id']}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            );
                          }
                          return ListTile(
                            onTap: () {},
                          );
                        },
                      ),
                    );
                  },
                )
              : FutureBuilder<dynamic>(
                  future: _getPosts(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Container();
                    }

                    return Expanded(
                      child: MasonryGridView.count(
                        // itemCount: _items.length,
                        itemCount: snapshot.data.length,
                        padding: const EdgeInsets.symmetric(
                            vertical: 0, horizontal: 0),
                        // the number of columns
                        crossAxisCount: 3,
                        // vertical gap between two items
                        mainAxisSpacing: 4,
                        // horizontal gap between two items
                        crossAxisSpacing: 4,
                        itemBuilder: (context, index) {
                          // display each item with a card
                          final post = snapshot.data[index];

                          return SingleChildScrollView(
                            child: Column(
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
                                    height: 190,
                                    child: FittedBox(
                                      fit: BoxFit.fitWidth,
                                      child: Chewie(
                                        controller: ChewieController(
                                          videoPlayerController:
                                              VideoPlayerController.network(
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
                            ),
                          );
                        },
                      ),
                    );
                  }),
        ],
      ),
    );
  }
}
