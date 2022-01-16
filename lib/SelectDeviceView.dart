import 'dart:async';

import 'package:die/BluetoothDeviceListEntry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class SelectDeviceView extends StatefulWidget {
  SelectDeviceView({
    Key? key,
    required this.chosenDevice,
    this.checkAvailability = true,
  }) : super(key: key);

  BluetoothDevice? chosenDevice;

  final bool checkAvailability;

  @override
  State<SelectDeviceView> createState() => _SelectDeviceViewState();
}

enum _DeviceAvailability {
  no,
  maybe,
  yes,
}

class _DeviceWithAvailability {
  BluetoothDevice device;
  _DeviceAvailability availability;
  int? rssi;

  _DeviceWithAvailability(this.device, this.availability, [this.rssi]);
}

class _SelectDeviceViewState extends State<SelectDeviceView> {
  List<_DeviceWithAvailability> devices =
      List<_DeviceWithAvailability>.empty(growable: true);

  // Availability
  StreamSubscription<BluetoothDiscoveryResult>? _discoveryStreamSubscription;
  bool _isDiscovering = false;

  @override
  void initState() {
    super.initState();

    _isDiscovering = widget.checkAvailability;

    if (_isDiscovering) {
      _startDiscovery();
    }

    // Setup a list of the bonded devices
    FlutterBluetoothSerial.instance.getBondedDevices().then(
      (List<BluetoothDevice> bondedDevices) {
        setState(
          () {
            devices = bondedDevices
                .map(
                  (device) => _DeviceWithAvailability(
                    device,
                    widget.checkAvailability
                        ? _DeviceAvailability.maybe
                        : _DeviceAvailability.yes,
                  ),
                )
                .toList();
          },
        );
      },
    );
  }

  Future _restartDiscovery() async {
    setState(
      () {
        _isDiscovering = true;
      },
    );

    _startDiscovery();
  }

  void _startDiscovery() {
    _discoveryStreamSubscription =
        FlutterBluetoothSerial.instance.startDiscovery().listen(
      (r) {
        setState(
          () {
            Iterator i = devices.iterator;
            while (i.moveNext()) {
              var _device = i.current;
              if (_device.device == r.device) {
                _device.availability = _DeviceAvailability.yes;
                _device.rssi = r.rssi;
              }
            }
          },
        );
      },
    );

    _discoveryStreamSubscription?.onDone(
      () {
        setState(
          () {
            _isDiscovering = false;
          },
        );
      },
    );
  }

  @override
  void dispose() {
    // Avoid memory leak (`setState` after dispose) and cancel discovery
    _discoveryStreamSubscription?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<_DeviceWithAvailability> filteredDevices =
        devices.where((element) => element.device.name == "HC-05").toList();
    List<BluetoothDeviceListEntry> list = filteredDevices
        .map(
          (_device) => BluetoothDeviceListEntry(
            device: _device.device,
            rssi: _device.rssi,
            enabled: _device.availability == _DeviceAvailability.yes,
            onTap: () {
              widget.chosenDevice = _device.device;
            },
          ),
        )
        .toList();
    return RefreshIndicator(
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: list,
      ),
      onRefresh: _restartDiscovery,
    );
  }
}
