import 'package:flutter/material.dart';
import 'package:scmfp/screens/profile.dart';
import 'package:scmfp/screens/loading.dart';

import 'screens/dashboard.dart';
import 'screens/historys.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'চিংড়ি',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const Loading(),
    );
  }
}