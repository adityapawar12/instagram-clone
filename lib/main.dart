import 'dart:developer';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_supa/feed.page.dart';
import 'package:flutter_supa/login.page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_supa/profile.page.dart';
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
    const LoginPage(),
    const FeedPage(),
    const ProfilePage(),
  ];

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue)
            .copyWith(background: Colors.white),
        primaryColor: Colors.white,
      ),
      home: Navigator(
        pages: const [
          MaterialPage(
            child: LoginPage(),
            key: ValueKey('LoginPage'),
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
