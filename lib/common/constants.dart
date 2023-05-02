import 'package:flutter/material.dart';

const baseURL = 'https://server.smartaquaculture.info/api';
const loginURL = '$baseURL/login';
const regURL = '$baseURL/register';
const logoutURL = '$baseURL/logout';
const userURL = '$baseURL/user';
const editUserURL = '$baseURL/save';
const sendURL = '$baseURL/submit';
const historyURL = '$baseURL/history';

const serverError = 'তথ্য ভান্ডারে কিছু সমস্যা হয়েছে';//'Server Error';
const unAuthError = 'আপনার প্রবেশের অনুমোদন নেয়';//'Unauthorized';
const somethingWrong = 'কিছু সমস্যা হয়েছে, অনুগ্রহ করে আবার চেষ্টা করুন';//'Something went wrong, Please try again later.';

InputDecoration cInputDecoration(String label) {
  return InputDecoration(
      labelText: label,
      contentPadding: EdgeInsets.all(10),
      border: const OutlineInputBorder(
          borderSide: BorderSide(
              color: Colors.green,
              width: 1,
              style: BorderStyle.solid,
              strokeAlign: StrokeAlign.inside)));
}

TextButton cTextButton(String label, Function onPressed) {
  return TextButton(
    onPressed: () => onPressed,
    style: ButtonStyle(
      backgroundColor: MaterialStateColor.resolveWith((states) => Colors.green),
      padding: MaterialStateProperty.resolveWith(
          (states) => const EdgeInsets.symmetric(vertical: 10)),
    ),
    child: Text(
      label,
      style: const TextStyle(color: Colors.white),
    ),
  );
}

Row cLoginOrReg(String text, String label, Function onTap) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(text),
      GestureDetector(
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.green,
          ),
        ),
        onTap: () => onTap,
      )
    ],
  );
}
