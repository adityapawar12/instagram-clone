import 'package:flutter/material.dart';
import 'package:flutter_supa/Add.page.dart';
import 'package:flutter_supa/createPost.page.dart';
import 'package:flutter_supa/feed.page.dart';
import 'package:flutter_supa/profile.page.dart';

class ContainerPage extends StatefulWidget {
  const ContainerPage({super.key});

  static const List<Widget> _widgetOptions = <Widget>[
    FeedPage(),
    AddPage(),
    ProfilePage(),
    CreatePost(),
  ];

  @override
  State<ContainerPage> createState() => _ContainerPageState();
}

class _ContainerPageState extends State<ContainerPage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ContainerPage._widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(
              Icons.home,
              color: Colors.cyan,
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.add_circle_outline,
              color: Colors.cyan,
            ),
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.person_2,
              color: Colors.cyan,
            ),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.add_circle_outline,
              color: Colors.cyan,
            ),
            label: 'Add',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }
}
