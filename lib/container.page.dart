import 'package:flutter/material.dart';
import 'package:instagram_clone/feed.page.dart';
import 'package:instagram_clone/search.page.dart';
import 'package:instagram_clone/profile.page.dart';
import 'package:instagram_clone/imagePickerNew.page.dart';

class ContainerPage extends StatefulWidget {
  final int selectedPageIndex;

  const ContainerPage({super.key, required this.selectedPageIndex});

  // LIST OF WIDGETS
  static const List<Widget> _widgetOptions = <Widget>[
    FeedPage(),
    SearchPage(),
    ImagePickerNewPage(),
    ProfilePage(),
  ];

  @override
  State<ContainerPage> createState() => _ContainerPageState();
}

class _ContainerPageState extends State<ContainerPage> {
  // SELECTED PAGE INDEX
  int _selectedIndex = 0;

  // ON A INDEX CHANGE
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    _selectedIndex = widget.selectedPageIndex;
    super.initState();
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
              color: Colors.black,
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.search,
              color: Colors.black,
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.add_circle_outline,
              color: Colors.black,
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.person_2,
              color: Colors.black,
            ),
            label: '',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.black,
        onTap: _onItemTapped,
      ),
    );
  }
}
