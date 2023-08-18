import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:scmfp/models/api_response.dart';
import 'package:scmfp/common/constants.dart';
import 'package:scmfp/common/user_service.dart';

import 'homepage.dart';
import 'login.dart';

class Loading extends StatefulWidget {
  const Loading({Key? key}) : super(key: key);

  @override
  State<Loading> createState() => _LoadingState();
}

class _LoadingState extends State<Loading> {
  Future<bool> checkConnection() async {
    ConnectivityResult result = await (Connectivity().checkConnectivity());

    if ((result == ConnectivityResult.mobile) ||
        (result == ConnectivityResult.wifi)) {
      return Future<bool>.value(true);
    } else {
      return Future<bool>.value(false);
    }
  }

  Future<void> loadUser() async {
    String token = await getToken();
    if (token == '') {
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => Login()), (route) => false);
    } else {
      APIResponse apiResponse = APIResponse();
      try {
        String token = await getToken();
        final response = await http.get(Uri.parse(userURL), headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token'
        });
        //print('$userURL, \t${response.statusCode}');
        switch (response.statusCode) {
          case 200:
          //print('Code: ${response.statusCode} \t ${response.body}');
            Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => HomePage()),
                    (route) => false);
            break;
          case 401:
            Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => Login()),
                    (route) => false);
            break;
          default:
            print(somethingWrong);
            break;
        }
      } catch (e) {
        apiResponse.error = serverError;
      }
    }
  }

  @override
  void initState() {
    /*Future.delayed(Duration.zero, () async {
      if(await checkConnection()) {
        loadUser();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('আপনার ইন্টারনেট সেবা চালু করে আবার চেষ্টা করুন')),
        );
      }
    });*/
    Future.delayed(Duration.zero, () async {
      String token = await getToken();
      if (token == '') {
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => Login()), (route) => false);
      } else {
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => HomePage()),
                (route) => false);
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      color: Colors.white,
      child: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Image(
            image: AssetImage('assets/images/scmfp.png'),
            height: 60,
            width: 60,
          ),
          const SizedBox(
            height: 10,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'তথ্য অনুসন্ধান করা হচ্ছে...  ',
                style: Theme.of(context).textTheme.subtitle1,
              ),
              const CircularProgressIndicator(
                semanticsLabel: 'অপেক্ষা করুন...',
              ),
            ],
          )
        ]),
      ),
    );
  }
}
