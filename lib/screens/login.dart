import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:scmfp/common/constants.dart';
import 'package:scmfp/common/user_service.dart';
import 'package:scmfp/models/user.dart';
import 'package:scmfp/screens/register.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/api_response.dart';
import 'homepage.dart';

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  TextEditingController txtPhone = TextEditingController();
  TextEditingController txtPassword = TextEditingController();

  bool loading = false;

  void loginUser() async {
    APIResponse response = await login(txtPhone.text, txtPassword.text);
    print('$loginURL ${response.data} \n ${response.error}');
    if (response.error == null) {
      User? user = response.data as User?;

      SharedPreferences preferences = await SharedPreferences.getInstance();
      await preferences.setString('token', user?.api_token ?? '');
      await preferences.setInt('userId', user?.id ?? 0);
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => HomePage()),
          (route) => false);
    } else {
      setState(() {
        loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${response.error}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('প্রবেশ করুন'),
        ),
        body: Container(
            alignment: Alignment.center,
            height: MediaQuery.of(context).size.height,
            color: Colors.white,
            child: Center(
                child: Form(
              key: formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    'প্রবেশ করুন',
                    style: Theme.of(context).textTheme.headline5
                  ),
                  const SizedBox(height: 20,),
                  TextFormField(
                      keyboardType: TextInputType.phone,
                      controller: txtPhone,
                      validator: (val) =>
                          val!.isEmpty ? 'সঠিক নম্বরটি দিন' : null,
                      decoration: cInputDecoration('মোবাইল নম্বর')),
                  const SizedBox(
                    height: 20,
                  ),
                  TextFormField(
                      obscureText: true,
                      controller: txtPassword,
                      validator: (val) =>
                          val!.isEmpty ? 'গোপন সংখ্যাটি লিখুন' : null,
                      decoration: cInputDecoration('গোপন নম্বর')),
                  const SizedBox(
                    height: 20,
                  ),
                  loading
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : TextButton(
                          style: ButtonStyle(
                            backgroundColor: MaterialStateColor.resolveWith(
                                (states) => Colors.green),
                            padding: MaterialStateProperty.resolveWith(
                                (states) =>
                                    const EdgeInsets.symmetric(vertical: 10)),
                          ),
                          child: const Text(
                            'প্রবেশ করুন',
                            style: TextStyle(color: Colors.white),
                          ),
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              setState(() {
                                loading = true;
                                loginUser();
                              });
                            }
                          }),
                  const SizedBox(
                    height: 20,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('আপনি এখনো নিবন্ধন করেননি? '),
                      GestureDetector(
                        child: const Text(
                          'নিবন্ধন করুন',
                          style: TextStyle(
                            color: Colors.green,
                          ),
                        ),
                        onTap: () {
                          Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                  builder: (context) => Register()),
                              (route) => false);
                        },
                      )
                    ],
                  )
                ],
              ),
            ))));
  }
}
