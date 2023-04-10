import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Flutter Instagram Feed',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  static List<Widget> _widgetOptions = <Widget>[Feed()];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Instagram Feed'),
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
    );
  }
}

class Feed extends StatefulWidget {
  const Feed({Key? key}) : super(key: key);

  @override
  _FeedState createState() => _FeedState();
}

class _FeedState extends State<Feed> {
  List<int> likes = <int>[]; 
  List<int> saves = <int>[]; 

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 10, // Replace with the number of posts
      itemBuilder: (BuildContext context, int index) {
        return Card(
          child: Column(
            children: <Widget>[
              ListTile(
                leading: const CircleAvatar(
                  backgroundImage: NetworkImage(
                      'https://picsum.photos/200'), // Replace with post image
                ),
                title: Text('Aditya'),
                subtitle: Text('Mumbai'),
              ),
              Image.network(
                  'https://picsum.photos/400?random=$index'), // Replace with post image
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  IconButton(
                    icon: likes.contains(index) ? const Icon(Icons.favorite) : const Icon(Icons.favorite_border),
                    onPressed: () {
                      setState(() {
                        likes.add(index);
                      });
                    },
                  ),
                  IconButton(
                    icon: saves.contains(index) ? const Icon(Icons.bookmark) : const Icon(Icons.bookmark_border),
                    onPressed: () {
                      setState(() {
                        saves.add(index);
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
