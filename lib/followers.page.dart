import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:instagram_clone/othersProfile.page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FollowersPage extends StatefulWidget {
  final int userId;

  const FollowersPage({super.key, required this.userId});

  @override
  State<FollowersPage> createState() => _FollowersPageState();
}

class _FollowersPageState extends State<FollowersPage> {
  // GET FOLLOWERS
  Future<dynamic> _getFollowers() async {
    var followers = await Supabase.instance.client
        .from('followers')
        .select<List<Map<String, dynamic>>>('*')
        .eq('followed_user_id', widget.userId);

    return followers;
  }

  // GET USER INFO
  _getUser(int id) {
    var user =
        Supabase.instance.client.from('users').select<Map<String, dynamic>>('''
          id,
          name,
          bio,
          user_tag_id,
          profile_image_url
      ''').eq('id', id).single();
    return user;
  }

  // LIFECYCLE METHODS
  @override
  void initState() {
    _getFollowers();
    super.initState();
  }
  // LIFECYCLE METHODS

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _getFollowers(),
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
              title: FutureBuilder(
                future: _getUser(widget.userId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Text(
                      'user',
                      style: TextStyle(color: Colors.black),
                    );
                  }
                  final dynamic user = snapshot.data!;

                  return Text(
                    user['name'],
                    style: const TextStyle(color: Colors.black),
                  );
                },
              ),
            ),
            body: const Center(
              child: Text('No Followers!'),
            ),
          );
        }

        dynamic followers = snapshot.data!;

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
            title: FutureBuilder(
              future: _getUser(widget.userId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Text(
                    'user',
                    style: TextStyle(color: Colors.black),
                  );
                }
                final dynamic user = snapshot.data!;

                return Text(
                  user['name'],
                  style: const TextStyle(color: Colors.black),
                );
              },
            ),
          ),
          body: ListView.builder(
            itemCount: followers.length,
            itemBuilder: ((context, index) {
              final dynamic follower = followers[index];

              return FutureBuilder(
                future: _getUser(follower['follower_user_id']),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox(
                      height: 100,
                      width: double.infinity,
                      child: SizedBox(),
                    );
                  }
                  final dynamic user = snapshot.data!;

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
              );
            }),
          ),
        );
      },
    );
  }
}
