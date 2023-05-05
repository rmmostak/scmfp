import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../common/constants.dart';
import '../common/user_service.dart';
import '../models/api_response.dart';
import '../models/user.dart';
import 'login.dart';

class Profile extends StatefulWidget {
  const Profile({Key? key}) : super(key: key);

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  TextEditingController txtName = TextEditingController();
  TextEditingController txtPhone = TextEditingController();
  TextEditingController txtNid = TextEditingController();
  TextEditingController txtFather = TextEditingController();
  TextEditingController txtAddress = TextEditingController();
  TextEditingController txtGher = TextEditingController();
  TextEditingController txtLocation = TextEditingController();
  TextEditingController deviceController = TextEditingController();

  bool loading = false;
  bool isShow = false;

  Future<void> loadUserInfo() async {
    String token = await getToken();
    final response = await http.get(Uri.parse(userURL), headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token'
    });

    switch (response.statusCode) {
      case 200:
        User? user = User.fromJson(jsonDecode(response.body));
        txtName.text = user.name.toString();
        txtPhone.text = user.phone.toString();
        txtNid.text = user.nid.toString();
        txtFather.text = user.father_name.toString();
        txtAddress.text = user.address.toString();
        txtGher.text = user.gher_size.toString();
        txtLocation.text = user.location.toString();
        setState(() {
          isShow = false;
        });
        break;
      case 401:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.body)),
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(somethingWrong)),
        );
        break;
    }
  }

  Future<void> updateUser() async {
    APIResponse apiResponse = APIResponse();
    String token = await getToken();
    try {
      final response = await http.post(Uri.parse(editUserURL), headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token'
      }, body: {
        'name': txtName.text.toString(),
        'phone': txtPhone.text.toString(),
        'nid': txtNid.text.toString(),
        'father_name': txtFather.text.toString(),
        'address': txtAddress.text.toString(),
        'gher_size': txtGher.text.toString(),
        'location': txtLocation.text.toString(),
      });
      switch (response.statusCode) {
        case 200:
          setState(() {
            loading = false;
            isShow = true;
            loadUserInfo();
          });
          break;
        case 422:
          final errors = jsonDecode(response.body)['errors'];
          apiResponse.error = errors[0][0];
          break;
        case 403:
          apiResponse.error = jsonDecode(response.body)['message'];
          break;
        default:
          apiResponse.error = somethingWrong;
          break;
      }
    } catch (e) {
      apiResponse.error = serverError;
    }
  }

  @override
  void initState() {
    isShow = true;
    loadUserInfo();
    Future.delayed(Duration.zero, () async {
      deviceController.text = await getDevice();
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        alignment: Alignment.center,
        height: MediaQuery.of(context).size.height,
        color: Colors.white,
        child: Center(
            child: Form(
                key: formKey,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    const SizedBox(
                      height: 20,
                    ),
                    Visibility(
                      visible: isShow,
                      child: SizedBox(
                          height: 30,
                          width: 20,
                          child: Center(
                              child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text('তথ্য অনুসন্ধান করা হচ্ছে...  '),
                              CircularProgressIndicator(),
                            ],
                          ))),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    TextFormField(
                        keyboardType: TextInputType.text,
                        controller: txtName,
                        validator: (val) =>
                            val!.isEmpty ? 'আপনার নামটি লিখুন' : null,
                        decoration: cInputDecoration('সম্পুর্ন নাম')),
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
                        keyboardType: TextInputType.text,
                        controller: txtNid,
                        validator: (val) => val!.isEmpty
                            ? 'জাতীয় পরিচয় পত্রের নম্বরটি দিন'
                            : null,
                        decoration:
                            cInputDecoration('জাতীয় পরিচয় পত্রের নম্বর')),
                    const SizedBox(
                      height: 20,
                    ),
                    TextFormField(
                        keyboardType: TextInputType.text,
                        controller: txtFather,
                        validator: (val) => val!.isEmpty
                            ? 'আপনার পিতা/স্বামীর নাম লিখুন'
                            : null,
                        decoration: cInputDecoration('পিতা/স্বামীর নাম')),
                    const SizedBox(
                      height: 20,
                    ),
                    TextFormField(
                        keyboardType: TextInputType.text,
                        controller: txtAddress,
                        validator: (val) =>
                            val!.isEmpty ? 'আপনার ঠিকানা লিখুন' : null,
                        decoration: cInputDecoration('আপনার ঠিকানা')),
                    const SizedBox(
                      height: 20,
                    ),
                    TextFormField(
                        keyboardType: TextInputType.text,
                        controller: txtGher,
                        validator: (val) =>
                            val!.isEmpty ? 'আপনার ঘের এর পরিমান লিখুন' : null,
                        decoration: cInputDecoration('ঘের এর পরিমান')),
                    const SizedBox(
                      height: 20,
                    ),
                    TextFormField(
                        keyboardType: TextInputType.text,
                        controller: txtLocation,
                        validator: (val) =>
                            val!.isEmpty ? 'আপনার ঘের এর অবস্থান লিখুন' : null,
                        decoration: cInputDecoration('ঘের এর অবস্থান')),
                    const SizedBox(
                      height: 20,
                    ),
                    TextFormField(
                        keyboardType: TextInputType.text,
                        controller: deviceController,
                        validator: (val) =>
                        val!.isEmpty ? 'আপনাকে অবশ্যই ঠিকানা লিখতে হবে' : null,
                        decoration: cInputDecoration('ডিভাইসের ঠিকানা')),
                    const SizedBox(
                      height: 20,
                    ),
                    loading
                        ? Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                                border: Border.all(
                                    color: Colors.green,
                                    width: 2,
                                    style: BorderStyle.solid),
                                color: Colors.green),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Text(
                                  'তথ্য হালনাগাদ করা হচ্ছে...   ',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(
                                    height: 25,
                                    width: 25,
                                    child: Center(
                                        child: CircularProgressIndicator(
                                      color: Colors.white,
                                    ))),
                              ],
                            ),
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
                              'তথ্য হালনাগাদ করুন',
                              style: TextStyle(color: Colors.white),
                            ),
                            onPressed: () {
                              if (formKey.currentState!.validate()) {
                                setState(() async {
                                  loading = true;
                                  SharedPreferences preferences =
                                      await SharedPreferences.getInstance();
                                  await preferences.setString(
                                      'device', deviceController.text ?? '');
                                  updateUser();
                                });
                              }
                            }),
                    TextButton(
                        style: ButtonStyle(
                          backgroundColor: MaterialStateColor.resolveWith(
                              (states) => Colors.redAccent),
                          padding: MaterialStateProperty.resolveWith((states) =>
                              const EdgeInsets.symmetric(vertical: 10)),
                        ),
                        child: const Text(
                          'প্রস্থান করুন',
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: () async {
                          if (await logout()) {
                            Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                    builder: (context) => Login()),
                                (route) => false);
                          }
                        }),
                  ],
                ))));
  }
}
