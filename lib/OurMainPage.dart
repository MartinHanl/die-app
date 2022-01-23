import 'dart:async';
import 'dart:io';

import 'package:die/BackgroundCollectingTask.dart';
import 'package:die/ChartView.dart';
import 'package:die/DiscoveryView.dart';
import 'package:die/SerialPortView.dart';
import 'package:die/Settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';


/// Kommunismus meine Kammeraden!
class OurMainPage extends StatefulWidget {
  const OurMainPage({Key? key}) : super(key: key);

  @override
  State<OurMainPage> createState() => _OurMainPageState();
}

class _OurMainPageState extends State<OurMainPage> {
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;

  BluetoothDevice? chosenDevice;
  SerialPort? chosenPort;

  String _address = "...";
  String _name = "...";

  Timer? _discoverableTimeoutTimer;
  int _discoverableTimeoutSecondsLeft = 0;

  BackgroundCollectingTask? _collectingTask;

  bool _autoAcceptPairingRequests = false;

  @override
  void initState() {
    super.initState();

    if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
    } else {
      // Get current state
      FlutterBluetoothSerial.instance.state.then((state) {
        setState(() {
          _bluetoothState = state;
        });
      });

      Future.doWhile(() async {
        // Wait if adapter not enabled
        if ((await FlutterBluetoothSerial.instance.isEnabled) ?? false) {
          return false;
        }
        await Future.delayed(Duration(milliseconds: 0xDD));
        return true;
      }).then((_) {
        // Update the address field
        FlutterBluetoothSerial.instance.address.then((address) {
          setState(() {
            _address = address!;
          });
        });
      });

      FlutterBluetoothSerial.instance.name.then((name) {
        setState(() {
          _name = name!;
        });
      });

      // Listen for futher state changes
      FlutterBluetoothSerial.instance.onStateChanged().listen(
        (BluetoothState state) {
          setState(
            () {
              _bluetoothState = state;

              // Discoverable mode is disabled when Bluetooth gets disabled
              _discoverableTimeoutTimer = null;
              _discoverableTimeoutSecondsLeft = 0;
            },
          );
        },
      );
    }
  }

  void _chooseDevice(BluetoothDevice? device) {
    setState(() => chosenDevice = device);
  }

  void _choosePort(SerialPort? port) {
    setState(() => chosenPort = port);
  }

  @override
  void dispose() {
    FlutterBluetoothSerial.instance.setPairingRequestHandler(null);
    _collectingTask?.dispose();
    _discoverableTimeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('die'.toUpperCase()),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) {
                    return const Settings();
                  },
                ),
              );
            },
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
            if (chosenPort == null) {
              return SerialPortView(
                onPortChosen: _choosePort,
              );
            } else {
              return ChartView(
                port: chosenPort,
                onBluetoothDisconnect: _chooseDevice,
                onSerialDisconnect: _choosePort,
              );
            }
          } else {
            if (_bluetoothState.isEnabled) {
              //return Text("Cool");
              if (chosenDevice == null) {
                return DiscoveryView(
                  onDeviceChosen: _chooseDevice,
                );
              } else {
                return ChartView(
                  device: chosenDevice!,
                  onBluetoothDisconnect: _chooseDevice,
                  onSerialDisconnect: _choosePort,
                );
              }
            } else {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Ehhh!! Shoit bluetoothe ei!!"),
                    ElevatedButton.icon(
                      onPressed: FlutterBluetoothSerial.instance.requestEnable,
                      icon: Icon(Icons.bluetooth),
                      label: Text("Ei schoitn"),
                    ),
                  ],
                ),
              );
            }
          }
        },
      ),
    );
  }
}
