/// Example of a simple line chart.
import 'dart:async';
import 'dart:typed_data';

import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';

class DataSample {
  final double value;
  final DateTime dateTime;

  DataSample(this.value, this.dateTime);
}

class ChartView extends StatefulWidget {
  final BluetoothDevice? device;
  final SerialPort? port;

  final ValueChanged<BluetoothDevice?> onBluetoothDisconnect;
  final ValueChanged<SerialPort?> onSerialDisconnect;

  ChartView(
      {Key? key,
      this.device,
      this.port,
      required this.onBluetoothDisconnect,
      required this.onSerialDisconnect})
      : super(key: key);

  @override
  _ChartViewState createState() => _ChartViewState();
}

class _ChartViewState extends State<ChartView> {
  BluetoothConnection? connection;

  List<DataSample> _dataSamples = [];
  List<FlSpot> _flSpots = [];

  late StreamSubscription<Uint8List> streamSubscription;
  DateTime _startDate = DateTime.now();

  String _messageBuffer = '';
  bool isConnecting = false;

  late SerialPortReader _portReader;

  @override
  void initState() {
    if (widget.device != null) {
      connectToBluetoothDevice(widget.device!);
    } else if (widget.port != null) {
      widget.port!.openRead();
      _portReader = SerialPortReader(widget.port!, timeout: 2000);
      // _portReader.close();
      streamSubscription = _portReader.stream.listen(onDataRecieved)
        ..onError((e) => print("lol error: $e"));
      // print(widget.port!.openRead());
      // connectToSerialPort(widget.port!);
    }
    super.initState();
  }

  @override
  void dispose() {
    if (connection != null) {
      connection?.dispose();
      connection = null;
    }
    connection?.dispose();
    connection = null;
    streamSubscription.cancel();
    print(widget.port?.close());
    widget.port?.dispose();
    super.dispose();
  }

  void connectToBluetoothDevice(BluetoothDevice device) async {
    setState(() {
      isConnecting = true;
    });
    connection = await BluetoothConnection.toAddress(device.address);
    _setStartDate();
    if (connection != null) {
      setState(() {
        isConnecting = false;
      });
    }
    print("Completed connection");
    streamSubscription = connection!.input!.listen(onDataRecieved);
  }

  void connectToSerialPort(SerialPort port) {
    isConnecting = true;
    SerialPortReader _portReader = SerialPortReader(port, timeout: 2000);
    // streamSubscription = _portReader.stream.listen(onDataRecieved);
    streamSubscription = _portReader.stream.listen((event) {
      print(event);
    });
    isConnecting = false;
  }

  void onDataRecieved(Uint8List event) {
    print(event);
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
        _flSpots = _dataSamples.map((sample) {
          return FlSpot(
            sample.dateTime.difference(_startDate).inMilliseconds.toDouble(),
            sample.value,
          );
        }).toList();
        _messageBuffer = dataString.substring(index);
      });
    } else {
      _messageBuffer = (backspacesCounter > 0
          ? _messageBuffer.substring(0, _messageBuffer.length - backspacesCounter)
          : _messageBuffer + dataString);
    }
  }

  void _setStartDate() {
    setState(() {
      _startDate = DateTime.now();
      _dataSamples = [];
      _flSpots = _dataSamples.map((sample) {
        return FlSpot(
          sample.dateTime.difference(_startDate).inMilliseconds.toDouble(),
          sample.value,
        );
      }).toList();
    });
  }

  SideTitles _bottomTitles() {
    return SideTitles(
      showTitles: true,
      rotateAngle: 45,
      reservedSize: 37,
      getTitles: (value) {
        final Duration dateTime = Duration(milliseconds: value.toInt());
        if (dateTime.inSeconds < 60) {
          return dateTime.toString().substring(5, dateTime.toString().length - 5) + "s";
        } else if (dateTime.inMinutes < 60) {
          return dateTime.toString().substring(2, dateTime.toString().length - 7);
        }
        return dateTime.toString().substring(0, dateTime.toString().length - 10);
      },
    );
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
                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(),
                        ),
                        Text("Connecting"),
                      ],
                    ),
                  );
                } else {
                  return _flSpots.isNotEmpty
                      ? Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(8.0, 16, 8, 8),
                            child: Stack(
                              children: [
                                LineChart(
                                  LineChartData(
                                    // axisTitleData: FlAxisTitleData(
                                    //     leftTitle: AxisTitle(titleText: "rpm", showTitle: true),
                                    //     bottomTitle: AxisTitle(titleText: "timeD", showTitle: true)),
                                    lineBarsData: [
                                      LineChartBarData(
                                          spots: _flSpots,
                                          colors: [Theme.of(context).colorScheme.secondary]),
                                    ],
                                    titlesData: FlTitlesData(
                                      bottomTitles: _bottomTitles(),
                                      topTitles: SideTitles(showTitles: false),
                                    ),
                                  ),
                                  swapAnimationDuration: const Duration(milliseconds: 150),
                                  swapAnimationCurve: Curves.easeInOut,
                                ),
                                Positioned(
                                  left: 0,
                                  top: -5,
                                  child: Text(
                                    "rpm",
                                    style: Theme.of(context).textTheme.headline5!.copyWith(
                                          backgroundColor: Theme.of(context).canvasColor,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(),
                              ),
                              Text("Waiting for data"),
                            ],
                          ),
                        );
                }
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                    onPressed: () async {
                      connection?.dispose();
                      widget.onBluetoothDisconnect(null);
                      widget.onSerialDisconnect(null);
                    },
                    child: const Text("Disconnect")),
                ElevatedButton(
                    onPressed: () {
                      _setStartDate();
                    },
                    child: const Text("Set new Start")),
                // TODO: add button to save data as csv
              ],
            ),
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
