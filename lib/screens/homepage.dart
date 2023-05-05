import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:scmfp/common/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cultivation.dart';
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
  String? errorTxt;
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  TextEditingController deviceController = TextEditingController();

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  List pages = [Dashboard(), History(), Profile()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('চিংড়ি'),
          actions: <Widget>[
            TextButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => Cultivation()),
                          (route) => false);
                  //showDialogs(context);
                },
                child: const Text(
                  'চাষ পদ্ধতি',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ))
          ],
        ),
        body: pages[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'প্রথম পাতা',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: 'পূর্ববর্তী ফলাফল',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'আমার তথ্য',
            ),
          ],
          currentIndex: _selectedIndex,
          backgroundColor: Colors.green.shade100,
          selectedItemColor: Colors.green.shade900,
          selectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          onTap: _onItemTapped,
        ));
  }
}
