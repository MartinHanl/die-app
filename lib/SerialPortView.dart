import 'package:flutter/material.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';

class SerialPortView extends StatefulWidget {
  final ValueChanged<SerialPort> onPortChosen;

  const SerialPortView({Key? key, required this.onPortChosen}) : super(key: key);

  @override
  _SerialPortViewState createState() => _SerialPortViewState();
}

extension IntToString on int {
  String toHex() => '0x${toRadixString(16)}';
  String toPadded([int width = 3]) => toString().padLeft(width, '0');
  String toTransport() {
    switch (this) {
      case SerialPortTransport.usb:
        return 'USB';
      case SerialPortTransport.bluetooth:
        return 'Bluetooth';
      case SerialPortTransport.native:
        return 'Native';
      default:
        return 'Unknown';
    }
  }
}

class _SerialPortViewState extends State<SerialPortView> {
  var availablePorts = [];

  @override
  void initState() {
    super.initState();
    initPorts();
  }

  void initPorts() {
    setState(() => availablePorts = SerialPort.availablePorts);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Scrollbar(
        child: ListView(
          children: [
            for (final address in availablePorts)
              Builder(builder: (context) {
                final port = SerialPort(address);
                return ListTile(
                  title: Text(port.description.toString()),
                  onTap: () => widget.onPortChosen(port),
                );
              }),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.refresh),
        onPressed: initPorts,
      ),
    );
  }
}

class CardListTile extends StatelessWidget {
  final String name;
  final String? value;

  CardListTile(this.name, this.value);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(value ?? 'N/A'),
        subtitle: Text(name),
      ),
    );
  }
}
