import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

import './BluetoothDeviceListEntry.dart';

class DiscoveryView extends StatefulWidget {
  /// If true, discovery starts on page start, otherwise user must press action button.
  final bool start;

  // BluetoothDevice? chosenDevice;

  final ValueChanged<BluetoothDevice> onDeviceChosen;

  const DiscoveryView({Key? key, required this.onDeviceChosen, this.start = true})
      : super(key: key);

  @override
  _DiscoveryView createState() => new _DiscoveryView();
}

class _DiscoveryView extends State<DiscoveryView> {
  StreamSubscription<BluetoothDiscoveryResult>? _streamSubscription;
  List<BluetoothDiscoveryResult> results = List<BluetoothDiscoveryResult>.empty(growable: true);
  bool isDiscovering = false;

  _DiscoveryView();

  @override
  void initState() {
    super.initState();

    isDiscovering = widget.start;
    if (isDiscovering) {
      _startDiscovery();
    }
  }

  void _restartDiscovery() async {
    setState(() {
      results.clear();
      isDiscovering = true;
    });
    await FlutterBluetoothSerial.instance.cancelDiscovery();
    _startDiscovery();
  }

  void _startDiscovery() {
    FlutterBluetoothSerial.instance.getBondedDevices().then((bondedDevices) {
      results = bondedDevices.map((e) => BluetoothDiscoveryResult(device: e)).toList();
    });
    _streamSubscription = FlutterBluetoothSerial.instance.startDiscovery().listen((r) {
      setState(() {
        final existingIndex =
            results.indexWhere((element) => element.device.address == r.device.address);
        if (existingIndex >= 0)
          results[existingIndex] = r;
        else
          results.add(r);
      });
    });

    _streamSubscription!.onDone(() {
      setState(() {
        isDiscovering = false;
      });
    });
  }

  // @TODO . One day there should be `_pairDevice` on long tap on something... ;)

  @override
  void dispose() {
    // Avoid memory leak (`setState` after dispose) and cancel discovery
    _streamSubscription?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        _restartDiscovery();
      },
      child: ListView.builder(
        itemCount: isDiscovering ? results.length + 1 : results.length,
        itemBuilder: (BuildContext context, index) {
          if (results.length > index) {
            BluetoothDiscoveryResult result = results[index];
            final device = result.device;
            final address = device.address;
            return BluetoothDeviceListEntry(
              device: device,
              rssi: result.rssi,
              onTap: () {
                // TODO: Check if bonded -> connect and set as chosen device
                widget.onDeviceChosen(device);
                if (device.isBonded) {}
              },
            );
          }
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          );
        },
      ),
    );
  }
}
