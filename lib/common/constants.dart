import 'package:flutter/material.dart';

const serverError = 'তথ্য ভান্ডারে কিছু সমস্যা হয়েছে';//'Server Error';
const unAuthError = 'আপনার প্রবেশের অনুমোদন নেয়';//'Unauthorized';
const somethingWrong = 'কিছু সমস্যা হয়েছে, অনুগ্রহ করে আবার চেষ্টা করুন';//'Something went wrong, Please try again later.';

InputDecoration cInputDecoration(String label) {
  return InputDecoration(
      labelText: label,
      contentPadding: const EdgeInsets.all(10),
      border: const OutlineInputBorder(
          borderSide: BorderSide(
              color: Colors.green,
              width: 1,
              style: BorderStyle.solid,)));
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
