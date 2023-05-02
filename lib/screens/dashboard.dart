import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

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
  String phS = '', batS = '', saltS = '', tempS = '', saltsS = '', tdsS = '';
  String data = '', stat = 'Connect';

  BluetoothDevice? connectedDevice;
  StreamSubscription? scanSubscription;
  FlutterBluePlus flutterBluePlus = FlutterBluePlus.instance;

  bool connecting = false;
  bool sending = false;
  bool isConnected = true;

  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  TextEditingController txtPh = TextEditingController();
  TextEditingController txtSalinity = TextEditingController();
  TextEditingController txtTemp = TextEditingController();

  Future<void> scanToConnect() async {
    if (connectedDevice != null) {
      print('Connected: ${connectedDevice!.id.toString()}');
      connectedDevice!.disconnect();
    }
    if (await flutterBluePlus.isScanning.first) {
      print('Scanning: ${flutterBluePlus.isScanning.first}');
      flutterBluePlus.stopScan();
    }
    // Start scanning for BLE devices
    scanSubscription = flutterBluePlus.scan().listen((scanResult) async {
      const Duration(seconds: 5);

      print(
          'Found device: ${scanResult.device.name} (${scanResult.device.id})');
      // If we find a device with the specified MAC address, connect to it
      if (scanResult.device.id.toString() == 'C0:00:00:00:8B:4D') {
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
                List<int> value = await c.read();
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
                    tempS = getBengali(temp.toString());
                    txtTemp.text = '$tempS °সেঃ';
                    salts = ((coded[9]) << 8 | (coded[10]));
                    saltsS = getBengali(salts.toString());
                    txtSalinity.text = '$saltsS পিপিএম';
                    salt = ((coded[18]) << 8 | (coded[19])) / 1000;
                    saltS = getBengali(salt.toString());
                    tds = ((coded[7]) << 8 | (coded[8]));
                    tdsS = getBengali(tds.toString());
                    print(
                        'pH: $ph\nBattery: $bat %\nTemperature: $temp°C\nTDS: $tds ppm\nSalt: $salt ppm');
                    //c.write([0x01, 0x00]);

                    connecting = false;
                    connectedDevice = scanResult.device;
                    stat = 'Disconnect';
                  });
                });
              }
            }
          });
          print(
              'Connected to ${scanResult.device.name} (${scanResult.device.id})');
          // Do something with the connected device here...
        } catch (e) {
          print('Error connecting to device: $e');
        }
      }
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
          temp = 0.0;
        });
        print(
            'Disconnected from ${connectedDevice!.name} (${connectedDevice!.id})');
      } catch (e) {
        print('Error disconnecting from device: $e');
      }
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
    print("deCoded: $pValue");
    return pValue;
  }

  String getBengali(String input) {
    String result = '';
    final formatter = NumberFormat.decimalPattern('bn_BD');
    for (int i = 0; i < input.length; i++) {
      if (int.tryParse(input[i]) != null) {
        result += formatter.format(int.parse(input[i]));
      } else {
        result += input[i];
      }
    }
    return result;
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
    return 'Result';
  }

  Future<void> sendData(
      String ammonia, String d0, String pH, String salt, String temp) async {
    String result = makeResult(ammonia, d0, pH, salt, temp);
    String token = await getToken();
    try {
      final response = await http.post(Uri.parse(sendURL), headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token'
      }, body: {
        'user_id': '0',
        'ammonia': ammonia,
        'do': d0,
        'ph': pH,
        'salinity': salt,
        'temp': temp,
        'result': result,
      });
      switch (response.statusCode) {
        case 200:
          setState(() {});
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('$serverError')),
      );
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
    super.initState();
    Future.delayed(Duration.zero, () async {
      if (!await requestPerm()) {
        requestPerm();
      }
    });
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
                                  padding: EdgeInsets.all(10),
                                  child: const Text(
                                    'পিএইচ',
                                    style: TextStyle(
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding:
                                      const EdgeInsets.fromLTRB(10, 0, 10, 10),
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
                                  padding: const EdgeInsets.all(10),
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
                                    '$tempS °সেঃ',
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
                                  padding: EdgeInsets.all(10),
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
                                    '$saltsS পিপিএম',
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
                            color: Colors.greenAccent,
                            clipBehavior: Clip.hardEdge,
                            child: InkWell(
                              splashColor: Colors.blue.withAlpha(30),
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('pH: $phS, Temp: $tempS, Salt: $saltsS')),
                                );
                              },
                              child: Container(
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
                                  (states) => Colors.green),
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
                        : TextButton(
                            style: ButtonStyle(
                              backgroundColor: MaterialStateColor.resolveWith(
                                  (states) => Colors.redAccent),
                              padding: MaterialStateProperty.resolveWith(
                                  (states) =>
                                      const EdgeInsets.symmetric(vertical: 10)),
                            ),
                            child: const Text(
                              'ডিভাইসের সংযোগ বিচ্ছিন্ন করুন',
                              style: TextStyle(color: Colors.white),
                            ),
                            onPressed: () {
                              setState(() {
                                connecting = false;
                                disconnect();
                              });
                            }),
                  ],
                ))));
  }
}
