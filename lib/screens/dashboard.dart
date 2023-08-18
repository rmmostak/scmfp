import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../common/constants.dart';
import '../common/user_service.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({Key? key}) : super(key: key);

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int salts = 0, tds = 0, ec = 0;
  double ph = 0.0, bat = 0.0, salt = 0.0, temp = 0.0, dod = 0.0, saltt = 0.0;
  String phS = '-',
      batS = '',
      saltS = '',
      tempS = '-',
      saltsS = '-',
      tdsS = '-',
      doS = '-',
      ecS = '-';
  String data = '', stat = 'Connect', outputSt = '';
  String? device;

  BluetoothDevice? connectedDevice;
  StreamSubscription? scanSubscription;
  FlutterBluePlus flutterBluePlus = FlutterBluePlus.instance;
  ScanResult? scann;
  BluetoothCharacteristic? characteristic;

  bool connecting = false;
  bool sending = false;
  bool isConnected = true;
  bool decision = false;

  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  TextEditingController txtPh = TextEditingController();
  TextEditingController txtDo = TextEditingController();
  TextEditingController txtSalinity = TextEditingController();
  TextEditingController txtTemp = TextEditingController();
  TextEditingController txtComment = TextEditingController();
  TextEditingController deviceController = TextEditingController();

  String timeDate() {
    DateTime current = DateTime.now();
    String timeDate = DateFormat('dd-MM-yyyy h:mm a').format(current);
    return getBengali(timeDate);
  }

  Future<void> scanToConnect() async {
    if (flutterBluePlus.isOn == false) {
      flutterBluePlus.turnOn();
    }
    if (device!.isNotEmpty) {
      if (connectedDevice != null) {
        connectedDevice!.disconnect();
      }

      if (await flutterBluePlus.isScanning == true) {
        flutterBluePlus.stopScan();
      }
      // Start scanning for BLE devices
      scanSubscription = flutterBluePlus.scan().listen((scanResult) async {
        const Duration(seconds: 30);
        print(
            '${scanResult.device.id} \t ${scanResult.device.type} \t $device');
        print(scanResult.device.name);
        // If we find a device with the specified MAC address, connect to it
        if (scanResult.device.id.toString() == device) {
          try {
            // Connect to the specified device
            await scanResult.device.connect();
            await scanResult.device.requestMtu(512);
            print(scanResult.device.mtu);
            flutterBluePlus.stopScan();
            print('called');
            List<BluetoothService> services =
                await scanResult.device.discoverServices();
            services.forEach((service) async {
              var characteristics = service.characteristics;
              for (BluetoothCharacteristic c in characteristics) {
                print(c.uuid.toString());
                if (c.uuid.toString().contains('ff02')) {
                  scann = scanResult;
                  characteristic = c;
                  getChars(c, scanResult);
                }
              }
            });
            //flutterBluePlus.stopScan();
            // Do something with the connected device here...
          } catch (e) {
            print('Error connecting to device: $e');
          }
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('আপনাকে অবশ্যই প্রথমে ঠিকানা লিখতে হবে')),
      );
    }
  }

  Future<void> getChars(
      BluetoothCharacteristic chars, ScanResult scanResult) async {
    List<int> value = await chars.read();
    List<int> coded = deCode(value, value.length);
    await Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        isConnected = false;
        ph = ((coded[3]) << 8 | (coded[4])) / 100;
        phS = getBengali(ph.toString());
        txtPh.text = phS;

        dod = ((coded[18]) << 8 | (coded[19])) / 100;
        doS = "${getBengali(dod.toString())} পিপিএম";
        txtDo.text = '$doS পিপিএম';

        bat = ((coded[15]) << 8 | (coded[16])) * 0.125 - 275;
        batS = getBengali(bat.toString());

        temp = ((coded[13]) << 8 | (coded[14])) / 10;
        tempS = "${getBengali(temp.toString())} °সেঃ";
        txtTemp.text = '$tempS °সেঃ';

        salts = ((coded[9]) << 8 | (coded[10]));
        salt = ((coded[18]) << 8 | (coded[19])) / 1000;
        saltt = salts / 100;
        saltsS = "${getBengali(saltt.toString())} পিপিটি";
        saltS = getBengali(salt.toString());
        print('${saltsS} \t ${salts}');

        tds = ((coded[7]) << 8 | (coded[8]));
        tdsS = getBengali(tds.toString());

        ec = ((coded[5]) << 8 | (coded[6]));
        ecS = "${getBengali(ec.toString())} এমভি";

        connecting = false;
        connectedDevice = scanResult.device;
        stat = 'Disconnect';
      });
    });
  }

  void disconnect() async {
    if (connectedDevice != null) {
      try {
        // Disconnect from the currently connected device
        await connectedDevice!.disconnect();
        setState(() {
          connectedDevice = null;
          sending = false;
          stat = 'Connect';
        });
      } catch (e) {
        print('Error disconnecting from device: $e');
      }
    } else {
      connectedDevice = null;
      stat = 'Connect';
    }
  }

  List<int> deCode(List<int> pValue, int len) {
    int tmp = 0;
    int hibit = 0;
    int lobit = 0;
    int hibit1 = 0;
    int lobit1 = 0;

    for (int i = len - 1; i > 0; i--) {
      tmp = pValue[i];
      hibit1 = (tmp & 0x55) << 1;
      lobit1 = (tmp & 0xAA) >> 1;
      tmp = pValue[i - 1];
      hibit = (tmp & 0x55) << 1;
      lobit = (tmp & 0xAA) >> 1;

      pValue[i] = ~(hibit1 | lobit);
      pValue[i - 1] = ~(hibit | lobit1);
    }
    return pValue;
  }

  Future<bool> requestPerm() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
      Permission.storage
    ].request();

    if (statuses[Permission.bluetooth] != null &&
        statuses[Permission.location] != null) {
      return true;
    } else {
      return false;
    }
  }

  String makeResult(
      String ammonia, String d0, String pH, String salt, String temp) {
    double phI = double.parse(pH),
        saltI = double.parse(salt),
        ammI = double.parse(ammonia),
        doI = double.parse(d0),
        tempI = double.parse(temp);
    if (phI < 7) {
      outputSt =
          "•\tচুন প্রয়োগ করুন ৫০০ গ্রাম/শতক (প্রতি তিন ফুট গভীরতা পানির জন্য)\n";
    } else if (phI > 8.5) {
      outputSt = "•\tআংশিকভাবে ভূগর্ভস্থ পানি সংযোগ করুন\n" +
          "•\tবায়ু সঞ্চালন ও ঘেরের পরিবেশ উন্নয়ন করুন\n";
    } else {
      outputSt = "";
    }

    if (saltI < 10.0) {
      outputSt =
          "$outputSt•\tবেশি লবনাক্ত পানি বিশেষ করে সাগর সংযুক্ত নদী বা খালের পানি যুক্ত করুন অথবা অন্যান্য উপযুক্ত লবন মিশ্রিত পানি যুক্ত করুন।\n";
    } else if (saltI > 30) {
      outputSt =
          "$outputSt•\tকম লবণাক্ত পানি বিশেষ করে নলকূপ বা গভীর নলকূপের ভূগর্ভস্থ পানি (১০-১২ পিপিটি) যুক্ত করুন।\n";
    } else {
      outputSt = outputSt;
    }

    if (doI < 4.0) {
      outputSt =
          "$outputSt•\tপানিতে ঢেউ সৃষ্টির মাধ্যমে, যেমন- বাঁশ পিটিয়ে বা পাতিলের সাহাজ্যে বা পাওয়ার পাম্প দিয়ে ঘেরে পানি ছড়িয়ে দিন\n•\tআইরেটরের সাহায্যে কৃত্রিম বায়ু সরবরাহ করুন\n•\tঅক্সিজেন ট্যাবলেট/পাউডার প্রয়োগ করুন (অক্সিমোর ৫০০-১০০০ গ্রাম প্রতি একরে)\n•\tঅক্সিজেন সমৃদ্ধ পানি সংযোগকরত: পানি পরিবর্তন করুন।\n";
    } else if (doI > 8.5) {
      outputSt = "$outputSt•\tকৃত্রিম বায়ু সরবরাহ বন্ধ করুন\n";
    } else {
      outputSt = outputSt;
    }
/*
    if (ammI > 0.1) {
      outputSt =
          "$outputSt•\tচচিনি বা চিটাগুড় ব্যবহার করুন\n•\tশতক প্রতি ৫০০ গ্রাম লবণ ব্যবহার করুন\n•\tঘেরের পানি পরিবর্তন করুন\n";
    } else {
      outputSt = outputSt;
    }
*/

    if (tempI < 25.0) {
      outputSt =
          "$outputSt•\tভূগর্ভস্থ নতুন পানি সংযোগ এবং আংশিক পানি পরিবর্তন করুন।\n";
    } else if (tempI > 35.0) {
      outputSt =
          "$outputSt•\tআংশিক পানি পরিবর্র্তন করুন\n•\tপানির গভীরতা বৃদ্ধি করুন (পানির গভীরতা ৩-৫ ফুট)\n";
    } else {
      outputSt = outputSt;
    }
    return outputSt;
  }

  Future<void> sendData(
      String ammonia, String d0, String pH, String salt, String temp) async {
    String result = makeResult(ammonia, d0, pH, salt, temp);
    String token = await getToken();
    int uid = await getUserId();

    final response = await http.post(Uri.parse(sendURL), headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token'
    }, body: {
      'user_id': uid.toString(),
      'ammonia': txtComment.text,
      'do': getBengali(d0),
      'ph': getBengali(pH),
      'salinity': getBengali(salt),
      'temp': getBengali(temp),
      'result': result,
      'created': timeDate()
    });
    switch (response.statusCode) {
      case 200:
        setState(() {
          sending = false;
          decision = true;
          disconnect();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('তথ্য পাঠানো হয়েছে')),
          );
        });
        break;
      case 422:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$somethingWrong: ${response.statusCode}')),
        );
        break;
      case 403:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$somethingWrong: ${response.statusCode}')),
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$somethingWrong: ${response.statusCode}')),
        );
        break;
    }
  }

  @override
  void dispose() {
    super.dispose();
    // Stop scanning for BLE devices and disconnect from any connected device
    scanSubscription?.cancel();
    connectedDevice?.disconnect();
  }

  @override
  void initState() {
    txtComment.text = '-';
    Future.delayed(Duration.zero, () async {
      if (!await requestPerm()) {
        requestPerm();
      }
      device = await getDevice();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        alignment: Alignment.center,
        height: MediaQuery.of(context).size.height,
        color: Colors.grey.shade100,
        child: Center(
            child: Form(
                key: formKey,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Card(
                      color: Colors.white,
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            height: 10,
                          ),
                          const Text(
                            'বাস্তবায়নে',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Image(
                                image: AssetImage('assets/images/mb.png'),
                                height: 50,
                              ),
                              SizedBox(
                                width: 20,
                              ),
                              Image(
                                image: AssetImage('assets/images/sau.png'),
                                height: 50,
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Expanded(
                          flex: 10,
                          child: Card(
                            clipBehavior: Clip.antiAlias,
                            color: Colors.white60,
                            child: Column(
                              children: [
                                Container(
                                  padding:
                                      const EdgeInsets.fromLTRB(0, 15, 0, 10),
                                  child: const Text(
                                    'পিএইচ',
                                    style: TextStyle(
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding:
                                      const EdgeInsets.fromLTRB(0, 0, 0, 15),
                                  child: Text(
                                    phS,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                        const Spacer(
                          flex: 1,
                        ),
                        Expanded(
                          flex: 10,
                          child: Card(
                            clipBehavior: Clip.antiAlias,
                            color: Colors.white60,
                            child: Column(
                              children: [
                                Container(
                                  padding:
                                      const EdgeInsets.fromLTRB(0, 15, 0, 10),
                                  child: const Text(
                                    'তাপমাত্রা',
                                    style: TextStyle(
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding:
                                      const EdgeInsets.fromLTRB(10, 0, 10, 10),
                                  child: Text(
                                    tempS,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Expanded(
                          flex: 10,
                          child: Card(
                            clipBehavior: Clip.antiAlias,
                            color: Colors.white60,
                            child: Column(
                              children: [
                                Container(
                                  padding:
                                      const EdgeInsets.fromLTRB(0, 15, 0, 10),
                                  child: const Text(
                                    'লবণাক্ততা',
                                    style: TextStyle(
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding:
                                      const EdgeInsets.fromLTRB(10, 0, 10, 10),
                                  child: Text(
                                    saltsS,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                        const Spacer(
                          flex: 1,
                        ),
                        Expanded(
                          flex: 10,
                          child: Card(
                            clipBehavior: Clip.antiAlias,
                            color: Colors.white60,
                            child: Column(
                              children: [
                                Container(
                                  padding:
                                      const EdgeInsets.fromLTRB(0, 15, 0, 10),
                                  child: const Text(
                                    'ডিও',
                                    style: TextStyle(
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding:
                                      const EdgeInsets.fromLTRB(10, 0, 10, 10),
                                  child: Text(
                                    doS,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Expanded(
                          flex: 10,
                          child: Card(
                            child: TextFormField(
                                keyboardType: TextInputType.text,
                                controller: txtComment,
                                decoration: cInputDecoration('মন্তব্য')),
                          ),
                        ),
                        const Spacer(
                          flex: 1,
                        ),
                        Expanded(
                          flex: 10,
                          child: Card(
                            color: Colors.greenAccent,
                            clipBehavior: Clip.hardEdge,
                            child: InkWell(
                              splashColor: Colors.blue.withAlpha(30),
                              onTap: () {
                                setState(() {
                                  sending = true;
                                });
                                if (ph != 0.0 && salts != 0) {
                                  sendData(
                                    '0',
                                    dod.toString(),
                                    ph.toString(),
                                    saltt.toString(),
                                    temp.toString(),
                                  );
                                } else {
                                  setState(() {
                                    sending = false;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('প্রথমে ডিভাইস যুক্ত করুন')),
                                  );
                                }
                              },
                              child: (sending)
                                  ? Container(
                                      alignment: Alignment.center,
                                      padding: const EdgeInsets.fromLTRB(
                                          10, 18, 10, 18),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: const [
                                          Text(
                                            'তথ্য প্রেরণ করা হচ্ছে...   ',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                          SizedBox(
                                              height: 25,
                                              width: 25,
                                              child: Center(
                                                  child:
                                                      CircularProgressIndicator())),
                                        ],
                                      ))
                                  : Container(
                                      alignment: Alignment.center,
                                      padding: const EdgeInsets.all(15),
                                      child: const Text(
                                        'তথ্য প্রেরণ করুন',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 17,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    stat == 'Connect'
                        ? TextButton(
                            style: ButtonStyle(
                              backgroundColor: MaterialStateColor.resolveWith(
                                  (states) => Colors.blue),
                              padding: MaterialStateProperty.resolveWith(
                                  (states) =>
                                      const EdgeInsets.symmetric(vertical: 10)),
                            ),
                            onPressed: () async {
                              if (formKey.currentState!.validate()) {
                                setState(() {
                                  connecting = true;
                                  if (Permission.bluetoothConnect.isGranted ==
                                      false) {
                                    Permission.bluetoothConnect.request();
                                  } else {
                                    scanToConnect();
                                  }
                                });
                              }
                            },
                            child: (connecting)
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            disconnect();
                                          });
                                        },
                                        child: const Text(
                                          'ডিভাইস যুক্ত করা হচ্ছে...   ',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                          height: 25,
                                          width: 25,
                                          child: Center(
                                              child: CircularProgressIndicator(
                                            color: Colors.white,
                                          ))),
                                    ],
                                  )
                                : const Text(
                                    'ডিভাইস যুক্ত করুন',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          )
                        : Column(
                            children: [
                              Container(
                                  width: MediaQuery.of(context).size.width,
                                  child: TextButton(
                                      style: ButtonStyle(
                                        backgroundColor:
                                            MaterialStateColor.resolveWith(
                                                (states) => Colors.indigo),
                                        padding:
                                            MaterialStateProperty.resolveWith(
                                                (states) =>
                                                    const EdgeInsets.symmetric(
                                                        vertical: 10)),
                                      ),
                                      child: const Text(
                                        'আবার তথ্য নিন',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          getChars(characteristic!, scann!);
                                        });
                                      })),
                              Container(
                                  width: MediaQuery.of(context).size.width,
                                  child: TextButton(
                                      style: ButtonStyle(
                                        backgroundColor:
                                            MaterialStateColor.resolveWith(
                                                (states) => Colors.redAccent),
                                        padding:
                                            MaterialStateProperty.resolveWith(
                                                (states) =>
                                                    const EdgeInsets.symmetric(
                                                        vertical: 10)),
                                      ),
                                      child: const Text(
                                        'ডিভাইসের সংযোগ বিচ্ছিন্ন করুন',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          connecting = false;
                                          disconnect();
                                        });
                                      })),
                            ],
                          ),
                    const SizedBox(
                      height: 30,
                    ),
                    Visibility(
                      visible: decision,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          SizedBox(
                              width: MediaQuery.of(context).size.width,
                              child: const Text(
                                'ফলাফল: ',
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 18),
                              )),
                          const Divider(
                            height: 10,
                            thickness: 1,
                            color: Colors.grey,
                            indent: 0,
                          ),
                          SizedBox(
                            width: MediaQuery.of(context).size.width,
                            child: Text(
                              outputSt,
                              textAlign: TextAlign.start,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ))));
  }
}
