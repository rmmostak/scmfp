import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:scmfp/common/user_service.dart';
import 'package:scmfp/screens/about.dart';
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
            backgroundColor: Colors.grey.shade100,
            elevation: 0.2,
            title: const Text(
              'চিংড়ি',
              style: TextStyle(color: Colors.black),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => About()),
                      (route) => false);
                },
                child: Container(
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(15)),
                      color: Colors.greenAccent,
                    ),
                    padding: const EdgeInsets.only(
                        left: 10, right: 10, top: 5, bottom: 5),
                    child: const Text(
                      'যোগাযোগ',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                      ),
                    )),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => Cultivation()),
                      (route) => false);
                  //showDialogs(context);
                },
                child: Container(
                    //color: Colors.green,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(15)),
                      color: Colors.blue,
                    ),
                    padding: const EdgeInsets.only(
                        left: 10, right: 10, top: 5, bottom: 5),
                    child: const Text(
                      'চাষ পদ্ধতি',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    )),
              ),
            ]),
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
          backgroundColor: Colors.grey.shade300,
          selectedItemColor: Colors.green.shade900,
          elevation: 3,
          selectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          onTap: _onItemTapped,
        ));
  }
}
