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
  int salts = 0, tds = 0;
  double ph = 0.0, bat = 0.0, salt = 0.0, temp = 0.0;
  String phS = '-', batS = '', saltS = '', tempS = '-', saltsS = '-', tdsS = '';
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
  TextEditingController txtSalinity = TextEditingController();
  TextEditingController txtTemp = TextEditingController();
  TextEditingController deviceController = TextEditingController();

  String timeDate() {
    DateTime current = DateTime.now();
    String timeDate = DateFormat('dd-MM-yyyy h:mm a').format(current);
    return getBengali(timeDate);
  }

  Future<void> scanToConnect() async {

    if (device!.isNotEmpty) {
      if (connectedDevice != null) {
        connectedDevice!.disconnect();
      }

      if (await flutterBluePlus.isScanning.first) {
        flutterBluePlus.stopScan();
      }
      // Start scanning for BLE devices
      scanSubscription = flutterBluePlus.scan().listen((scanResult) async {
        const Duration(seconds: 5);

        // If we find a device with the specified MAC address, connect to it
        if (scanResult.device.id.toString() == device) {
          try {
            flutterBluePlus.stopScan();
            // Connect to the specified device
            await scanResult.device.connect();
            await scanResult.device.requestMtu(512);
            List<BluetoothService> services =
            await scanResult.device.discoverServices();
            services.forEach((service) async {
              var characteristics = service.characteristics;
              for (BluetoothCharacteristic c in characteristics) {
                if (c.uuid.toString().contains('ff02')) {
                  scann = scanResult;
                  characteristic = c;
                  getChars(c, scanResult);
                }
              }
            });
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
        bat = ((coded[15]) << 8 | (coded[16])) * 0.125 - 275;
        batS = getBengali(bat.toString());
        temp = ((coded[13]) << 8 | (coded[14])) / 10;
        tempS = "${getBengali(temp.toString())} °সেঃ";
        txtTemp.text = '$tempS °সেঃ';
        salts = ((coded[9]) << 8 | (coded[10]));
        saltsS = "${getBengali(salts.toString())}  পিপিএম";
        txtSalinity.text = '$saltsS পিপিএম';
        salt = ((coded[18]) << 8 | (coded[19])) / 1000;
        saltS = getBengali(salt.toString());
        tds = ((coded[7]) << 8 | (coded[8]));
        tdsS = getBengali(tds.toString());

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
      Permission.speech,
      Permission.storage
    ].request();

    if (statuses[Permission.location] != null &&
        statuses[Permission.bluetooth] != null) {
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
    if (phI < 7.5) {
      outputSt = "•\tচুন ব্যবহার করুন ২০০ গ্রাম/ডিসে\n";
    } else if (phI > 8.5) {
      outputSt =
          "•\tতেঁতুল ৫ গ্রাম/ডিসে\n" + "•\tব্লিচিং পাউডার ১০ গ্রাম/ডেসিমেল\n";
    } else {
      outputSt = "";
    }

    if (saltI < 10.0) {
      outputSt = "$outputSt•\tলবণ বা লবণের মিশ্রণ যোগ করুন\n";
    } else if (saltI > 20) {
      outputSt = "$outputSt•\tমিঠা পানির সংযোজন\n";
    } else {
      outputSt = outputSt;
    }

    /*
    if (doI < 4.0) {
      outputSt =
          "$outputSt•\tম্যানুয়ালি (পানিতে বাঁশ পিটিয়ে) বা এয়ারেটর ব্যবহার করে বায়ুচলাচল বৃদ্ধি করুন\n•\tবাজারে পাওয়া অক্সিজেন ট্যাবলেট বা ওষুধ ব্যবহার করুন\n•\tপটাসিয়াম পারম্যাঙ্গনেট (KMnO4) ২ পিপিএম ব্যবহার করুন\n•\tপানি পরিবর্র্তন করুন\n";
    } else if (doI > 8.0) {
      outputSt = "$outputSt•\tপানি পরিবর্র্তন করুন\n";
    } else {
      outputSt = outputSt;
    }

    if (ammI > 0.1) {
      outputSt =
          "$outputSt•\tচিনি বা গুড় যোগ করুন\n•\tলবণ ব্যবহার করুন ৫০০ গ্রাম/ডিসে\n•\tপানি পরিবর্র্তন করুন\n";
    } else {
      outputSt = outputSt;
    }
*/

    if (tempI < 28.0) {
      outputSt = "$outputSt•\tভূগর্ভস্থ মিঠা পানির সংযোজন\n";
    } else if (tempI > 32.0) {
      outputSt =
          "$outputSt•\tপানি পরিবর্র্তন করুন\n•\tপানির স্তরের গভীরতা বাড়ান\n";
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
      'ammonia': '-', //getBengali(ammonia),
      'do': '-', //getBengali(d0),
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
                          const SizedBox(height: 10,),
                          const Text(
                            'বাস্তবায়নে',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600
                            ),
                          ),
                          const SizedBox(height: 10,),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Image(
                                image: AssetImage('assets/images/mb.png'),
                                height: 50,
                              ),
                              SizedBox(width: 20,),
                              Image(
                                image: AssetImage('assets/images/sau.png'),
                                height: 50,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10,),
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
                                      fontSize: 16,
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
                                      fontSize: 18,
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
                                      fontSize: 16,
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
                                      fontSize: 18,
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
                                      fontSize: 16,
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
                                      fontSize: 18,
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
                                    'অ্যামোনিয়া',
                                    style: TextStyle(
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding:
                                      const EdgeInsets.fromLTRB(10, 0, 10, 10),
                                  child: const Text(
                                    '-',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
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
                                    'ডিও',
                                    style: TextStyle(
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding:
                                      const EdgeInsets.fromLTRB(10, 0, 10, 10),
                                  child: const Text(
                                    '-',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
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
                                    '0',
                                    ph.toString(),
                                    salts.toString(),
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
                                          fontSize: 18,
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
                            onPressed: () {
                              if (formKey.currentState!.validate()) {
                                setState(() {
                                  connecting = true;
                                  scanToConnect();
                                });
                              }
                            },
                            child: (connecting)
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Text(
                                        'ডিভাইস যুক্ত করা হচ্ছে...   ',
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
