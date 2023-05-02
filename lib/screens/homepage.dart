import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'dashboard.dart';
import 'historys.dart';
import 'profile.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  int _selectedIndex = 0;


  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  List pages = [Dashboard(), History(), Profile()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('এসসিএমএফপি')),
        body: pages[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'প্রথম পাতা',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: 'পূর্ব্বর্তী ফলাফল',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'আমার তথ্য',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.green.shade700,
          onTap: _onItemTapped,
        ));
  }
}
