import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../common/user_service.dart';
import 'login.dart';

class Profile extends StatefulWidget {
  const Profile({Key? key}) : super(key: key);

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: TextButton(
        onPressed: () {
          setState(() async {
            if(await logout()) {
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => Login()), (route) => false);
            }
          });
        },
        child: Text(
          'প্রস্থান করুন',
          style: Theme.of(context).textTheme.bodyText1,
        ),
      )
    );
  }
}
