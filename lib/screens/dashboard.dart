import 'dart:async';
import 'package:permission_handler/permission_handler.dart';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:intl/intl.dart';

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

  bool isLoading = false;

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
                    ph = ((coded[3]) << 8 | (coded[4])) / 100;
                    phS = getBengali(ph.toString());
                    bat = ((coded[15]) << 8 | (coded[16])) * 0.125 - 275;
                    batS = getBengali(bat.toString());
                    temp = ((coded[13]) << 8 | (coded[14])) / 10;
                    tempS = getBengali(temp.toString());
                    salts = ((coded[9]) << 8 | (coded[10]));
                    saltsS = getBengali(salts.toString());
                    salt = ((coded[18]) << 8 | (coded[19])) / 1000;
                    saltS = getBengali(salt.toString());
                    tds = ((coded[7]) << 8 | (coded[8]));
                    tdsS = getBengali(tds.toString());
                    print(
                        'pH: $ph\nBattery: $bat %\nTemperature: $temp°C\nTDS: $tds ppm\nSalt: $salt ppm');
                    //c.write([0x01, 0x00]);

                    isLoading = false;
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

  @override
  void dispose() {
    super.dispose();
    // Stop scanning for BLE devices and disconnect from any connected device
    scanSubscription?.cancel();
    connectedDevice?.disconnect();
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
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: <
        Widget>[
      Padding(
        padding: EdgeInsets.all(10),
        child: Center(
            child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                  temp == 0.0
                      ? const Text('কোনো তথ্য পাওয়া যায়নি!')
                      : Column(
                          //mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Text(
                                    'পিএইচ: $phS',
                                    style:
                                        Theme.of(context).textTheme.bodyText1,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Text(
                                    'তাপমাত্রা: $tempS°সেঃ',
                                    style:
                                        Theme.of(context).textTheme.bodyText1,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Text(
                                      'লবণাক্ততা: $saltS এসজি',
                                      style:
                                          Theme.of(context).textTheme.bodyText1,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Text(
                                      'লবণাক্ততা: $saltsS পিপিএম',
                                      style:
                                          Theme.of(context).textTheme.bodyText1,
                                    ),
                                  ),
                                ]),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Text(
                                    'টিডিএস: $tdsS পিপিএম',
                                    style:
                                        Theme.of(context).textTheme.bodyText1,
                                  ),
                                ),
                                Container(
                                  color: Colors.black12,
                                  child: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Text('ব্যাটারী: $batS %',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyText1),
                                  ),
                                )
                              ],
                            )
                          ],
                        ),
                ])),
          ),
          Center(
              child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              stat == 'Connect'
                  ? TextButton(
                      style: TextButton.styleFrom(
                          textStyle: const TextStyle(fontSize: 16),
                          backgroundColor: Colors.green.shade600,
                          primary: Colors.white),
                      onPressed: () {
                        setState(() {
                          isLoading = true;
                        });
                        setState(() {
                          print('Scanning!');
                          scanToConnect();
                        });
                        setState(() {
                          isLoading = false;
                        });
                      },
                      child: (isLoading)
                          ? Row(
                              mainAxisSize: MainAxisSize.max,
                              children: const [
                                Text('Connecting device...'),
                                SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 1.5,
                                  ),
                                )
                              ],
                            )
                          : const Text('ডিভাইস যুক্ত করুন'),
                    )
                  : TextButton(
                      style: TextButton.styleFrom(
                          textStyle: const TextStyle(fontSize: 16),
                          backgroundColor: Colors.redAccent,
                          primary: Colors.white),
                      onPressed: disconnect,
                      child: const Text('ডিভাইসের সংযোগ বিচ্ছিন্ন করুন'),
                    )
            ],
          ))
        ]);
  }
}
