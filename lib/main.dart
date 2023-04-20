import 'package:flutter/material.dart';
import 'package:flutter_supa/feed.page.dart';
import 'package:flutter_supa/login.page.dart';
import 'package:flutter_supa/profile.page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: "https://wjzgvpftlznhngujjmze.supabase.co",
    anonKey:
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Indqemd2cGZ0bHpuaG5ndWpqbXplIiwicm9sZSI6ImFub24iLCJpYXQiOjE2ODEyMDQ5MTgsImV4cCI6MTk5Njc4MDkxOH0.M8QuSuQWQFcP13_1nallkST1hIlP7WJrgWPwwXs9BPc",
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
