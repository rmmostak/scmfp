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
  final GlobalKey<FormState> formKeys = GlobalKey<FormState>();
  TextEditingController txtPhone = TextEditingController();
  TextEditingController txtPassword = TextEditingController();
  TextEditingController deviceController = TextEditingController();

  bool loading = false;
  String? device;

  void loginUser() async {
    APIResponse response = await login(txtPhone.text, txtPassword.text);
    if (response.error == null) {
      User? user = response.data as User?;

      SharedPreferences preferences = await SharedPreferences.getInstance();
      await preferences.setString('token', user?.api_token ?? '');
      await preferences.setInt('userId', user?.id ?? 0);

      if (device!.isNotEmpty) {
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => HomePage()),
                (route) => false);
      } else {
        showDialogs(context);
        setState(() {
          loading = false;
        });
      }
    } else {
      setState(() {
        loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${response.error}')),
      );
    }
  }

  Future<void> showDialogs(BuildContext context) async {
    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return Form(
            key: formKeys,
            child: AlertDialog(
              title: const Text('ডিভাইস এর ঠিকানা দিন'),
              content: TextFormField(
                controller: deviceController,
                validator: (value) =>
                value!.isEmpty ? 'আপনাকে অবশ্যই ঠিকানা লিখতে হবে' : null,
                decoration: const InputDecoration(
                    labelText: 'ডিভাইসের ঠিকানা',
                    hintText: 'C0:00:00:00:8B:4D',
                    contentPadding: EdgeInsets.all(10),
                    border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.green,
                          width: 1,
                          style: BorderStyle.solid,
                        ))),
              ),
              actions: [
                TextButton(
                    onPressed: () async {
                      SharedPreferences preferences =
                      await SharedPreferences.getInstance();
                      await preferences.setString(
                          'device', deviceController.text ?? '');
                      String dev = await getDevice();
                      if (dev.isNotEmpty) {
                        Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (context) => HomePage()),
                                (route) => false);
                      }
                    },
                    child: Container(
                      color: Colors.green,
                      padding: const EdgeInsets.all(5),
                      child:  const Text('সংরক্ষণ করুন', style: TextStyle(color: Colors.white),)),
                    )
              ],
            ),
          );
        });
  }


  @override
  void initState() {
    Future.delayed(Duration.zero, () async {
      device = await getDevice();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('প্রবেশ করুন'),
        ),
        body: Container(
            alignment: Alignment.center,
            width: MediaQuery
                .of(context)
                .size
                .width,
            color: Colors.white,
            child: Center(
                child: Form(
                  key: formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Text('প্রবেশ করুন',
                          style: Theme
                              .of(context)
                              .textTheme
                              .headline5),
                      const SizedBox(
                        height: 20,
                      ),
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
