import 'package:flutter/material.dart';
import 'package:flutter_supa/othersProfile.page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
                      : Colors.grey,
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
                  decoration: InputDecoration(
                    hintText: 'Search',
                    border: InputBorder.none,
                    hintStyle: TextStyle(
                      color: Colors.black.withOpacity(0.7),
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
                                  : const CircleAvatar(
                                      backgroundImage: NetworkImage(
                                          'https://simg.nicepng.com/png/small/128-1280406_view-user-icon-png-user-circle-icon-png.png'),
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
              : Container()
        ],
      ),
    );
  }
}
