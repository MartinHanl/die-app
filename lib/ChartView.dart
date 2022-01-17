/// Example of a simple line chart.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class DataSample {
  final double value;
  final DateTime dateTime;

  DataSample(this.value, this.dateTime);
}

class ChartView extends StatefulWidget {
  final BluetoothDevice device;

  final ValueChanged<BluetoothDevice?> onDisconnect;

  ChartView({Key? key, required this.device, required this.onDisconnect}) : super(key: key);

  @override
  _ChartViewState createState() => _ChartViewState();
}

class _ChartViewState extends State<ChartView> {
  BluetoothConnection? connection;
  List<DataSample> _dataSamples = [];
  List<charts.Series<DataSample, int>> seriesList = [];
  late StreamSubscription<Uint8List> streamSubscription;

  @override
  void initState() {
    // TODO: implement initState
    connectToDevice(widget.device);
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    if (connection != null) {
      connection?.dispose();
      connection = null;
    }
    connection?.dispose();
    connection = null;
    streamSubscription.cancel();
    super.dispose();
  }

  String _messageBuffer = '';
  bool isConnecting = false;
  Future<void> connectToDevice(BluetoothDevice device) async {
    setState(() {
      isConnecting = true;
    });
    connection = await BluetoothConnection.toAddress(device.address);
    if (connection != null) {
      setState(() {
        isConnecting = false;
      });
    }
    print("Completed connection");
    streamSubscription = connection!.input!.listen((event) {
      print("New stream data: ${ascii.decode(event).endsWith("\r\n")} from $event");
        
        // Allocate buffer for parsed data
        int backspacesCounter = 0;
        for (int byte in event) {
          if (byte == 8 || byte == 127) {
            backspacesCounter++;
          }
        }
        Uint8List buffer = Uint8List(event.length - backspacesCounter);
        int bufferIndex = buffer.length;

        // Apply backspace control character
        backspacesCounter = 0;
        for (int i = event.length - 1; i >= 0; i--) {
          if (event[i] == 8 || event[i] == 127) {
            backspacesCounter++;
          } else {
            if (backspacesCounter > 0) {
              backspacesCounter--;
            } else {
              buffer[--bufferIndex] = event[i];
            }
          }
        }

        // Create message if there is new line character
        String dataString = String.fromCharCodes(buffer);
        int index = buffer.indexOf(13);
        if (~index != 0) {
          setState(() {
            double value = double.parse(
                backspacesCounter > 0
                    ? _messageBuffer.substring(0, _messageBuffer.length - backspacesCounter)
                    : _messageBuffer + dataString.substring(0, index),
            );
            _dataSamples.add(
              DataSample(
                value,
                DateTime.now(),
              ),
            );
            seriesList = [
              charts.Series(
                id: "DataSamples",
                data: _dataSamples,
                domainFn: (DataSample sample, _) =>
                    sample.dateTime.difference(DateTime.now()).inMilliseconds,
                measureFn: (DataSample sample, _) => sample.value,
              ),
            ];
            _messageBuffer = dataString.substring(index);
          });
        } else {
          _messageBuffer = (backspacesCounter > 0
              ? _messageBuffer.substring(0, _messageBuffer.length - backspacesCounter)
              : _messageBuffer + dataString);
        }
        // setState(() {
        //   _buffer.add(
        //     DataSample(
        //       double.parse(ascii.decode(event)),
        //       DateTime.now(),
        //     ),
        //   );
        //   seriesList = [
        //     charts.Series(
        //       id: "DataSamples",
        //       data: _buffer,
        //       domainFn: (DataSample sample, _) =>
        //           sample.dateTime.difference(DateTime.now()).inMilliseconds,
        //       measureFn: (DataSample sample, _) => sample.value,
        //     ),
        //   ];
        // });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          // mainAxisSize: MainAxisSize.max,
          children: [
            Builder(
              builder: (context) {
                if (isConnecting) {
                  return CircularProgressIndicator();
                } else {
                  return seriesList.length > 0
                      ? Expanded(
                          child: charts.LineChart(
                            seriesList,
                            animate: true,
                          ),
                        )
                      : Container(
                          child: Text("No Data"),
                        );
                }
              },
            ),
            ElevatedButton(
                onPressed: () async {
                  connection?.dispose();
                  widget.onDisconnect(null);
                },
                child: const Text("Disconnect")),
          ],
        ),
      ),
    );
  }
}

class SimpleLineChart extends StatelessWidget {
  final List<charts.Series<DataSample, int>> seriesList;
  final bool animate;

  SimpleLineChart(this.seriesList, {this.animate = true});

  // Creates a [LineChart] with sample data and no transition.
  factory SimpleLineChart.withSampleData() {
    return SimpleLineChart(
      _createSampleData(),
      // Disable animations for image tests.
      animate: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return charts.LineChart(seriesList, animate: animate);
  }

  // Create one series with sample hard coded data.
  static List<charts.Series<DataSample, int>> _createSampleData() {
    final data = [
      DataSample(0, DateTime.now().subtract(const Duration(minutes: 1))),
      DataSample(1, DateTime.now().subtract(const Duration(minutes: 2))),
      DataSample(2, DateTime.now().subtract(const Duration(minutes: 3))),
      DataSample(3, DateTime.now().subtract(const Duration(minutes: 4))),
    ];

    return [
      charts.Series<DataSample, int>(
        id: 'SampleData',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (DataSample sales, _) => sales.dateTime.millisecondsSinceEpoch,
        measureFn: (DataSample sales, _) => sales.value,
        data: data,
      )
    ];
  }
}

/// Sample linear data type.
// class LinearSales {
//   final int year;
//   final int sales;

//   LinearSales(this.year, this.sales);
// }
