import 'package:flutter/material.dart';
import 'package:flutter_supa/feed.page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _selectedIndex = 0;
  late int _userId = 0;
  late String _userName = '';
  late String _userPhone = '';
  late String _userEmail = '';
  late String _userProfileUrl = '';
  var _posts = [];
  var _postsCount = 0;

  @override
  void initState() {
    _loadPreferences();
    _getPosts();
    super.initState();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      print('wwwwwwwwwwwww ${prefs.getInt('userId')}');
      _userId = prefs.getInt('userId') ?? 0;
      _userName = prefs.getString('userName') ?? "";
      _userPhone = prefs.getString('userPhone') ?? "";
      _userEmail = prefs.getString('userEmail') ?? "";
      _userProfileUrl = prefs.getString('profileImage') ?? "";
    });
  }

  Future<dynamic> _getPosts() async {
    final prefs = await SharedPreferences.getInstance();
    print("user id $prefs.getInt('userId')");
    _posts = await Supabase.instance.client
        .from('posts')
        .select<List<Map<String, dynamic>>>('''
    *,
    users (
      id,
      name,
      profile_image
    )
  ''').eq('user_id', prefs.getInt('userId'));
    print("FUTURE $_posts");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        shadowColor: Colors.white,
        elevation: 0,
        leadingWidth: 0,
        title: Text(
          _userName,
          style: const TextStyle(
            color: Colors.black,
            fontFamily: 'sans-serif',
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Row(
        children: [
          Container(
            margin: const EdgeInsets.all(15.0),
            child: Column(
              children: [
                if (_userProfileUrl.isNotEmpty)
                  Image.network(
                    _userProfileUrl,
                    height: 90,
                  )
                else
                  const Icon(
                    Icons.person,
                  ),
                Text(
                  _userName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                )
              ],
            ),
          )
        ],
      ),
      // body: ListView.builder(
      //   itemCount: posts.length,
      //   itemBuilder: ((context, index) {
      //     final post = posts[index];
      //     return Column(
      //       crossAxisAlignment: CrossAxisAlignment.start,
      //       children: <Widget>[
      //         ListTile(
      //           tileColor: Colors.white,
      //           leading: CircleAvatar(
      //             backgroundImage: NetworkImage(
      //               post['users']['profile_image'],
      //             ),
      //           ),
      //           title: Text(post['users']['name']),
      //           subtitle: Text(post['location']),
      //         ),
      //         if (post['post_type'] == 'image')
      //           Container(
      //             decoration: const BoxDecoration(
      //               border: Border(
      //                 bottom: BorderSide(width: 0.5, color: Colors.black26),
      //                 top: BorderSide(width: 0.5, color: Colors.black26),
      //               ),
      //             ),
      //             height: 380,
      //             width: double.infinity,
      //             child: Image.network(post['post_url']),
      //           )
      //         else if (post['post_type'] == 'video')
      //           Container(
      //             decoration: const BoxDecoration(
      //               border: Border(
      //                 bottom: BorderSide(width: 0.5, color: Colors.black26),
      //                 top: BorderSide(width: 0.5, color: Colors.black26),
      //               ),
      //             ),
      //             height: 600,
      //             width: double.infinity,
      //             child: Chewie(
      //               controller: ChewieController(
      //                 videoPlayerController: VideoPlayerController.network(
      //                   post['post_url'],
      //                 ),
      //                 aspectRatio: 16 / 9,
      //                 autoPlay: true,
      //                 looping: false,
      //                 allowMuting: true,
      //                 showControls: false,
      //                 errorBuilder: (context, errorMessage) {
      //                   return Center(
      //                     child: Text(
      //                       errorMessage,
      //                       style: const TextStyle(color: Colors.white),
      //                     ),
      //                   );
      //                 },
      //               ),
      //             ),
      //           ),
      //         Row(
      //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
      //           children: <Widget>[
      //             Row(
      //               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      //               children: [
      //                 IconButton(
      //                   icon: likes.contains(index)
      //                       ? const Icon(Icons.favorite, color: Colors.red)
      //                       : const Icon(Icons.favorite_border),
      //                   onPressed: () {
      //                     setState(() {
      //                       if (likes.contains(index)) {
      //                         likes.removeWhere((item) => item == index);
      //                       } else {
      //                         likes.add(index);
      //                       }
      //                     });
      //                   },
      //                 ),
      //                 const SizedBox(width: 4.0), // Add some space here
      //                 IconButton(
      //                   icon: const Icon(Icons.mode_comment_outlined),
      //                   onPressed: () {},
      //                 ),
      //               ],
      //             ),
      //             IconButton(
      //               icon: saves.contains(index)
      //                   ? const Icon(Icons.bookmark, color: Colors.black)
      //                   : const Icon(Icons.bookmark_border),
      //               onPressed: () {
      //                 setState(() {
      //                   if (saves.contains(index)) {
      //                     saves.removeWhere((item) => item == index);
      //                   } else {
      //                     saves.add(index);
      //                   }
      //                 });
      //               },
      //             ),
      //           ],
      //         ),
      //       ],
      //     );
      //   }),
      // ),
    );
  }
}

//  return FutureBuilder<List<Map<String, dynamic>>>(
//       future: _future,
//       builder: (context, snapshot) {
//         if (!snapshot.hasData) {
//           return const Scaffold(
//             body: Center(
//               child: CircularProgressIndicator(
//                 backgroundColor: Colors.white,
//               ),
//             ),
//           );
//         }
//         final posts = snapshot.data!;
//         return Scaffold(
//           appBar: AppBar(
//             backgroundColor: Colors.white,
//             shadowColor: Colors.white,
//             elevation: 0,
//             leading: Text(
//               _userName,
//               style: const TextStyle(
//                 color: Colors.black,
//               ),
//             ),
//           ),
          // body: ListView.builder(
          //   itemCount: posts.length,
          //   itemBuilder: ((context, index) {
          //     final post = posts[index];
          //     return Column(
          //       crossAxisAlignment: CrossAxisAlignment.start,
          //       children: <Widget>[
          //         ListTile(
          //           tileColor: Colors.white,
          //           leading: CircleAvatar(
          //             backgroundImage: NetworkImage(
          //               post['users']['profile_image'],
          //             ),
          //           ),
          //           title: Text(post['users']['name']),
          //           subtitle: Text(post['location']),
          //         ),
          //         if (post['post_type'] == 'image')
          //           Container(
          //             decoration: const BoxDecoration(
          //               border: Border(
          //                 bottom: BorderSide(width: 0.5, color: Colors.black26),
          //                 top: BorderSide(width: 0.5, color: Colors.black26),
          //               ),
          //             ),
          //             height: 380,
          //             width: double.infinity,
          //             child: Image.network(post['post_url']),
          //           )
          //         else if (post['post_type'] == 'video')
          //           Container(
          //             decoration: const BoxDecoration(
          //               border: Border(
          //                 bottom: BorderSide(width: 0.5, color: Colors.black26),
          //                 top: BorderSide(width: 0.5, color: Colors.black26),
          //               ),
          //             ),
          //             height: 600,
          //             width: double.infinity,
          //             child: Chewie(
          //               controller: ChewieController(
          //                 videoPlayerController: VideoPlayerController.network(
          //                   post['post_url'],
          //                 ),
          //                 aspectRatio: 16 / 9,
          //                 autoPlay: true,
          //                 looping: false,
          //                 allowMuting: true,
          //                 showControls: false,
          //                 errorBuilder: (context, errorMessage) {
          //                   return Center(
          //                     child: Text(
          //                       errorMessage,
          //                       style: const TextStyle(color: Colors.white),
          //                     ),
          //                   );
          //                 },
          //               ),
          //             ),
          //           ),
          //         Row(
          //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //           children: <Widget>[
          //             Row(
          //               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          //               children: [
          //                 IconButton(
          //                   icon: likes.contains(index)
          //                       ? const Icon(Icons.favorite, color: Colors.red)
          //                       : const Icon(Icons.favorite_border),
          //                   onPressed: () {
          //                     setState(() {
          //                       if (likes.contains(index)) {
          //                         likes.removeWhere((item) => item == index);
          //                       } else {
          //                         likes.add(index);
          //                       }
          //                     });
          //                   },
          //                 ),
          //                 const SizedBox(width: 4.0), // Add some space here
          //                 IconButton(
          //                   icon: const Icon(Icons.mode_comment_outlined),
          //                   onPressed: () {},
          //                 ),
          //               ],
          //             ),
          //             IconButton(
          //               icon: saves.contains(index)
          //                   ? const Icon(Icons.bookmark, color: Colors.black)
          //                   : const Icon(Icons.bookmark_border),
          //               onPressed: () {
          //                 setState(() {
          //                   if (saves.contains(index)) {
          //                     saves.removeWhere((item) => item == index);
          //                   } else {
          //                     saves.add(index);
          //                   }
          //                 });
          //               },
          //             ),
          //           ],
          //         ),
          //       ],
          //     );
          //   }),
          // ),
    //     );
    //   },
    // );
  