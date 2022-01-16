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

  BluetoothConnection? connection;

  final ValueChanged<BluetoothDevice?> onDisconnect;

  List<DataSample> _buffer = [];

  List<charts.Series<DataSample, int>> seriesList = [];

  late StreamSubscription<Uint8List> streamSubscription;

  ChartView({Key? key, required this.device, required this.onDisconnect}) : super(key: key);

  @override
  _ChartViewState createState() => _ChartViewState();
}

class _ChartViewState extends State<ChartView> {
  @override
  void initState() {
    // TODO: implement initState
    connectToDevice(widget.device);
    super.initState();
  }

  void connectToDevice(BluetoothDevice device) async {
    await BluetoothConnection.toAddress(device.address).then((value) => widget.connection);
    widget.streamSubscription = widget.connection!.input!.listen((event) {
      setState(() {
        widget._buffer.add(
          DataSample(
            double.parse(ascii.decode(event)),
            DateTime.now(),
          ),
        );
        widget.seriesList = [
          charts.Series(
            id: "SampleData",
            data: widget._buffer,
            domainFn: (DataSample sample, _) =>
                sample.dateTime.difference(DateTime.now()).inMilliseconds,
            measureFn: (DataSample sample, _) => sample.value,
          ),
        ];
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          widget.seriesList.length > 0 ? charts.LineChart(widget.seriesList) : Expanded(child: Container()),
          ElevatedButton(onPressed: () => widget.onDisconnect(null), child: const Text("Disconnect")),
        ],
      ),
    );
  }
}

class SimpleLineChart extends StatelessWidget {
  final List<charts.Series<DataSample, int>> seriesList;
  final bool animate;

  SimpleLineChart(this.seriesList, {this.animate = true});

  /// Creates a [LineChart] with sample data and no transition.
  // factory SimpleLineChart.withSampleData() {
  //   return new SimpleLineChart(
  //     _createSampleData(),
  //     // Disable animations for image tests.
  //     animate: false,
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return new charts.LineChart(seriesList, animate: animate);
  }

  /// Create one series with sample hard coded data.
  // static List<charts.Series<LinearSales, int>> _createSampleData() {
  //   final data = [
  //     new LinearSales(0, 5),
  //     new LinearSales(1, 25),
  //     new LinearSales(2, 100),
  //     new LinearSales(3, 75),
  //   ];

  //   return [
  //     new charts.Series<LinearSales, int>(
  //       id: 'Sales',
  //       colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
  //       domainFn: (LinearSales sales, _) => sales.year,
  //       measureFn: (LinearSales sales, _) => sales.sales,
  //       data: data,
  //     )
  //   ];
  // }
}

/// Sample linear data type.
// class LinearSales {
//   final int year;
//   final int sales;

//   LinearSales(this.year, this.sales);
// }
