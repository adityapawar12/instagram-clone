import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:instagram_clone/container.page.dart';
import 'package:instagram_clone/hashtagPosts.page.dart';
import 'package:instagram_clone/othersProfile.page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

TextSpan buildClickableTextSpan(String text, int userId, BuildContext context) {
  final List<String> words = text.split(' ');

  List<TextSpan> textSpans = [];

  for (var word in words) {
    if (word.startsWith('@')) {
      textSpans.add(
        TextSpan(
          text: '$word ',
          style: const TextStyle(
            color: Colors.blue,
            decoration: TextDecoration.none,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () async {
              var user = await Supabase.instance.client
                  .from('users')
                  .select<Map<String, dynamic>>('*')
                  .eq('user_tag_id', word.substring(1))
                  .single();
              if (user['id'] == userId) {
                // ignore: use_build_context_synchronously
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const ContainerPage(selectedPageIndex: 3),
                  ),
                );
              } else {
                // ignore: use_build_context_synchronously
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OthersProfile(
                      userId: user['id'],
                    ),
                  ),
                );
              }
            },
        ),
      );
    } else if (word.startsWith('#')) {
      textSpans.add(
        TextSpan(
          text: '$word ',
          style: const TextStyle(
            color: Colors.blue,
            decoration: TextDecoration.none,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () async {
              // ignore: use_build_context_synchronously
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HashtagPosts(
                    hashtag: word,
                  ),
                ),
              );
            },
        ),
      );
    } else {
      textSpans.add(
        TextSpan(
          text: '$word ',
          style: const TextStyle(
            color: Colors.black,
          ),
        ),
      );
    }
  }

  return TextSpan(children: textSpans);
}
