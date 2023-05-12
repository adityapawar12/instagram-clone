import 'dart:developer';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:instagram_clone/feed.page.dart';
import 'package:instagram_clone/signin.page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:instagram_clone/profile.page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // GET LIST OF AVAILABLE CAMERAS
    cameras = await availableCameras();
  } on CameraException catch (e) {
    log('Error in fetching the cameras: $e');
  }

  // GET ENV VARIABLES
  await dotenv.load(fileName: "lib/.env");

  // INTIALIZE SUPABASE
  await Supabase.initialize(
    url: "${dotenv.env['SUPABASE_URL']}",
    anonKey: "${dotenv.env['SUPABASE_ANON_KEY']}",
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final List<Widget> screens = [
    const SignInPage(),
    const FeedPage(),
    const ProfilePage(),
  ];

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Instagram Clone',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue)
            .copyWith(background: Colors.white),
        primaryColor: Colors.white,
      ),
      home: Navigator(
        pages: const [
          MaterialPage(
            child: SignInPage(),
            key: ValueKey('SignInPage'),
          ),
        ],
        onPopPage: (route, result) {
          if (!route.didPop(result)) {
            return false;
          }

          screens.removeLast();

          return true;
        },
      ),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/feed':
            return MaterialPageRoute(builder: (_) => const FeedPage());
          default:
            return null;
        }
      },
    );
  }
}
