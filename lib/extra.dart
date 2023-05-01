import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SCMFP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const MyHomePage(title: 'SCMFP'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int salt = 0, tds = 0;
  double ph = 0.0, bat = 0.0, temp = 0.0;
  String data = '', stat='Connect';

  BluetoothDevice? connectedDevice;
  StreamSubscription? scanSubscription;
  FlutterBluePlus flutterBluePlus = FlutterBluePlus.instance;

  @override
  void initState() {
    super.initState();
    // Start scanning for BLE devices
    scanSubscription = flutterBluePlus.scan().listen((scanResult) async {
      print('Found device: ${scanResult.device.name} (${scanResult.device.id})');
      // If we find a device with the specified MAC address, connect to it
      if (scanResult.device.id.toString() == 'C0:00:00:00:8B:4D') {
        try {
          // Connect to the specified device
          await scanResult.device.connect();
          await scanResult.device.discoverServices();
          setState(() {
            connectedDevice = scanResult.device;
          });
          print('Connected to ${scanResult.device.name} (${scanResult.device.id})');
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

  void _disconnectFromDevice() async {
    if (connectedDevice != null) {
      try {
        // Disconnect from the currently connected device
        await connectedDevice!.disconnect();
        setState(() {
          connectedDevice = null;
        });
        print('Disconnected from ${connectedDevice!.name} (${connectedDevice!.id})');
      } catch (e) {
        print('Error disconnecting from device: $e');
      }
    }
  }

  void disconnect() {
    setState(() {
      /*flutterBluePlus.startScan(timeout: const Duration(seconds: 5));
      flutterBluePlus.scanResults.listen((results) async {
        for (ScanResult r in results) {
          if (r.device.name == "BLE-C600") {
            flutterBluePlus.stopScan();
            r.device.disconnect();
            print('Disconnected Device');
          }
        }
      });*/
      Future<List<BluetoothDevice>> devices = flutterBluePlus.connectedDevices;

    });
  }

  void backlight() {
    setState(() {
      flutterBluePlus.startScan(timeout: const Duration(seconds: 5));
      flutterBluePlus.scanResults.listen((results) async {
        for (ScanResult r in results) {
          if (r.device.name == "BLE-C600") {
            flutterBluePlus.stopScan();
            List<BluetoothService> services = await r.device.discoverServices();
            services.forEach((service) async {
              var characteristics = service.characteristics;
              for (BluetoothCharacteristic c in characteristics) {
                if (c.uuid.toString().contains('ff02')) {
                  await c.write(utf8.encode('0x01'));
                }
              }
            });
          }
        }
      });
    });
  }

  void connect() {
    flutterBluePlus.startScan(timeout: const Duration(seconds: 5));
    flutterBluePlus.scanResults.listen((results) async {
      for (ScanResult r in results) {
        if (r.device.name == "BLE-C600") {
          flutterBluePlus.stopScan();
          await r.device.connect(timeout: const Duration(seconds: 10));
          Future<BluetoothDeviceState> streamState = r.device.state.first;
          //if (streamState == BluetoothDeviceState.connected) {
          r.device.requestMtu(512);
          List<BluetoothService> services = await r.device.discoverServices();
          services.forEach((service) async {
            var characteristics = service.characteristics;
            for (BluetoothCharacteristic c in characteristics) {
              if (c.uuid.toString().contains('ff02')) {
                await Future.delayed(const Duration(seconds: 2));
                setState(() async {
                  List<int> value = await c.read();
                  List<int> coded = deCode(value, value.length);
                  ph = ((coded[3]) << 8 | (coded[4])) / 100;
                  bat = ((coded[15]) << 8 | (coded[16])) * 0.125 - 275;
                  temp = ((coded[13]) << 8 | (coded[14])) / 10;
                  salt = ((coded[9]) << 8 | (coded[10]));
                  tds = ((coded[7]) << 8 | (coded[8]));
                  print(
                      'pH: $ph\nBattery: $bat %\nTemperature: $temp°C\nTDS: $tds ppm\nSalt: $salt');
                  //c.write([0x01, 0x00]);
                });
              }
            }
          });
          //}
        }
      }
    });
    flutterBluePlus.stopScan();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.title),
          actions: <Widget> [
            stat == 'Connect'
                ? TextButton(
              style: TextButton.styleFrom(
                  textStyle: const TextStyle(fontSize: 16),
                  primary: Colors.white),
              onPressed: null,
              child: Text(stat),
            )
                : TextButton(
              style: TextButton.styleFrom(
                  textStyle: const TextStyle(fontSize: 16),
                  primary: Colors.white),
              onPressed: null,
              child: Text(stat),
            )
          ]
      ),
      body: Center(
        child: Column(
          //mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            temp == 0.0
                ? const Text('No data found!')
                : Column(
              //mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(10),
                      child: Text(
                        'pH: $ph',
                        style: Theme.of(context).textTheme.bodyText1,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(10),
                      child: Text(
                        'Temp: $temp°C',
                        style: Theme.of(context).textTheme.bodyText1,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(10),
                      child: Text(
                        'Salt: $salt ppm',
                        style: Theme.of(context).textTheme.bodyText1,
                      ),
                    )
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(10),
                      child: Text('TDS: $tds ppm',
                          style: Theme.of(context).textTheme.bodyText1,
                          textAlign: TextAlign.start),
                    ),
                    Padding(
                      padding: EdgeInsets.all(10),
                      child: Text(
                        'Battery: $bat %',
                        style: Theme.of(context).textTheme.bodyText1,
                        textAlign: TextAlign.start,
                      ),
                    )
                  ],
                )
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Padding(
                  padding: EdgeInsets.all(10),
                  child: Text(
                    'pH: $ph',
                    style: Theme.of(context).textTheme.bodyText1,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(10),
                  child: Text(
                    'Temp: $temp°C',
                    style: Theme.of(context).textTheme.bodyText1,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(10),
                  child: Text(
                    'Salt: $salt',
                    style: Theme.of(context).textTheme.bodyText1,
                  ),
                )
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Padding(
                  padding: EdgeInsets.all(10),
                  child: Text('TDS: $tds ppm',
                      style: Theme.of(context).textTheme.bodyText1,
                      textAlign: TextAlign.start),
                ),
                Padding(
                  padding: EdgeInsets.all(10),
                  child: Text(
                    'Battery: $bat %',
                    style: Theme.of(context).textTheme.bodyText1,
                    textAlign: TextAlign.start,
                  ),
                )
              ],
            ),
            MaterialButton(
              onPressed: backlight,
              color: Colors.lightGreen,
              child: const Text(
                'On Light',
              ),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: connect,
        tooltip: 'Connect',
        child: const Icon(Icons.search),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
