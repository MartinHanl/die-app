import 'package:flutter/material.dart';

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
          const ListTile(
            title: Text("ebic"),
            //TODO aussafinden wie der in aktuellen state und so zruckgibt
          ),
          ListTile(
            title: const Text("About"),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationIcon: Image.asset("assets/icon/DIE-Icon_125.png"),
                applicationName: "DIE",
                applicationVersion: "0.3.0",
              );
            },
          ),
        ],
      ),
    );
  }
}
