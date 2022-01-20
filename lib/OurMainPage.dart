import 'dart:async';

import 'package:die/BackgroundCollectingTask.dart';
import 'package:die/ChartView.dart';
import 'package:die/DiscoveryView.dart';
import 'package:die/SelectDeviceView.dart';
import 'package:die/Settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

import './SelectBondedDevicePage.dart';

/// Kommunismus meine Kammeraden!
class OurMainPage extends StatefulWidget {
  const OurMainPage({Key? key}) : super(key: key);

  @override
  State<OurMainPage> createState() => _OurMainPageState();
}

class _OurMainPageState extends State<OurMainPage> {
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;

  BluetoothDevice? chosenDevice;

  String _address = "...";
  String _name = "...";

  Timer? _discoverableTimeoutTimer;
  int _discoverableTimeoutSecondsLeft = 0;

  BackgroundCollectingTask? _collectingTask;

  bool _autoAcceptPairingRequests = false;

  @override
  void initState() {
    super.initState();

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

  void _chooseDevice(BluetoothDevice? device) {
    setState(() => chosenDevice = device);
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
            icon: Icon(Icons.settings),
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (_bluetoothState.isEnabled) {
            //return Text("Cool");
            if (chosenDevice == null) {
              // TODO: Display divice selection list
              // List<BluetoothDevice> devices = [];
              // return StreamBuilder<BluetoothDiscoveryResult>(
              //   stream: FlutterBluetoothSerial.instance.startDiscovery(),
              //   builder: (context, snapshot) {
              //     if (snapshot.hasData &&
              //         devices.indexWhere((element) =>
              //                 element.name == snapshot.data!.device.name) ==
              //             -1) {
              //       devices.add(snapshot.data!.device);
              //     }
              //     return RefreshIndicator(
              //       onRefresh: () async {},
              //       child: ListView.builder(
              //         itemCount: devices.length + 1,
              //         itemBuilder: (context, index) {
              //           if (index < devices.length) {
              //             return ListTile(
              //               title: Text(devices[index].name.toString()),
              //               subtitle: Text(devices[index].address.toString()),
              //             );
              //           } else {
              //             return ListTile(
              //                 title: ElevatedButton(
              //                     onPressed: () {
              //                       // TODO: Show device
              //                       showDialog(
              //                         context: context,
              //                         builder: (context) {
              //                           return Dialog(
              //                               child: Padding(
              //                             padding: const EdgeInsets.all(8.0),
              //                             child: Text(
              //                               "Fack u!!",
              //                               style: Theme.of(context)
              //                                   .textTheme
              //                                   .headline1,
              //                             ),
              //                           ));
              //                         },
              //                       );
              //                     },
              //                     child: Text("My device isn't shown")));
              //           }
              //         },
              //       ),
              //     );
              //   },
              // );
              // return Text("devices");
              return DiscoveryView(
                onDeviceChosen: _chooseDevice,
              );
            } else {
              return ChartView(device: chosenDevice!, onDisconnect: _chooseDevice,);
              return const Center(
                child: Text("Graph"),
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
        },
      ),
    );
  }
}
