import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class Settings extends StatelessWidget {
  const Settings({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Settings'.toUpperCase()),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text("ebic"),
            subtitle: Text(FlutterBluetoothSerial.instance.name.toString()),
            //TODO aussafinden wie der in aktuellen state und so zruckgibt
          ),
          ListTile(
            title: const Text("About"),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationIcon: Image.asset("assets/icon/DIE-Icon.png"),
                applicationName: "DIE",
                applicationVersion: "0.2.0",
              );
            },
          ),
        ],
      ),
    );
  }
}
