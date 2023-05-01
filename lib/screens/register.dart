import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/api_response.dart';
import '../common/constants.dart';
import 'login.dart';

class Register extends StatefulWidget {
  const Register({Key? key}) : super(key: key);

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  TextEditingController txtName = TextEditingController();
  TextEditingController txtPhone = TextEditingController();
  TextEditingController txtPassword = TextEditingController();
  TextEditingController txtCPassword = TextEditingController();

  bool loading = false;

  void regUser() async {

    APIResponse apiResponse = APIResponse();
    try {
      final response = await http.post(Uri.parse(regURL), headers: {
        'Accept': 'application/json'
      }, body: {
        'name': txtName.text,
        'phone': txtPhone.text,
        'password': txtPassword.text,
        'password_confirmation': txtCPassword.text
      });
      print('$regURL \t ${response.statusCode} \t ${response.body}');
      switch (response.statusCode) {
        case 200:
          Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => Login()),
                  (route) => false);
          break;
        case 422:
          final errors = jsonDecode(response.body)['errors'];
          setState(() {
            loading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${errors}')),
          );
          break;
        case 403:
          setState(() {
            loading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${jsonDecode(response.body)['message']}')),
          );
          break;
        default:
          setState(() {
            loading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${somethingWrong}')),
          );
          break;
      }
    } catch (e) {
      apiResponse.error = serverError;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('নিবন্ধন করুন'),
        ),
        body: Center(
            child: Form(
              key: formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  TextFormField(
                      keyboardType: TextInputType.text,
                      controller: txtName,
                      validator: (val) =>
                      val!.isEmpty ? 'আপনার নামটি লিখুন' : null,
                      decoration: cInputDecoration('সম্পুর্ণ নাম')),
                  const SizedBox(
                    height: 20,
                  ),
                  TextFormField(
                      keyboardType: TextInputType.phone,
                      controller: txtPhone,
                      validator: (val) =>
                      val!.length < 11 ? 'সঠিক মোবাইল নম্বর দিন' : null,
                      decoration: cInputDecoration('মোবাইল নং')),
                  const SizedBox(
                    height: 20,
                  ),
                  TextFormField(
                      obscureText: true,
                      controller: txtPassword,
                      validator: (val) => val!.length < 5 ? 'সর্বনিম্ন ৫টি সংখ্যা দিন' : null,
                      decoration: cInputDecoration('গোপন নম্বর')),
                  const SizedBox(
                    height: 20,
                  ),
                  TextFormField(
                      obscureText: true,
                      controller: txtCPassword,
                      validator: (val) => val!=txtPassword.text ? 'পুণরায় গোপন সংখ্যাটি লিখুন' : null,
                      decoration: cInputDecoration('গোপন নম্বর নিশ্চিত করুন')),
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
                        padding: MaterialStateProperty.resolveWith((states) =>
                        const EdgeInsets.symmetric(vertical: 10)),
                      ),
                      child: const Text(
                        'নিবন্ধন করুন',
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          setState(() {
                            loading = true;
                            regUser();
                          });
                        }
                      }),
                  const SizedBox(
                    height: 20,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('আপনার কি ইতোমধ্যে নিবন্ধন করা আছে? '),
                      GestureDetector(
                        child: const Text(
                          'প্রবেশ করুন',
                          style: TextStyle(
                            color: Colors.green,
                          ),
                        ),
                        onTap: () {
                          Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (context) => Login()),
                                  (route) => false);
                        },
                      )
                    ],
                  )
                ],
              ),
            )));
  }
}
