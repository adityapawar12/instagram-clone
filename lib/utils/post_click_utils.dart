import 'package:flutter/material.dart';
import 'package:instagram_clone/post.page.dart';

void postClick(int postId, BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => PostPage(postId: postId),
    ),
  );
}
