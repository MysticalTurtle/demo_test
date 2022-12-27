import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double _value = 0;
  double velocity1 = 0;
  double velocity2 = 0;
  double lostTime = 0;
  Dio dio = Dio();

  late String tempDir;

  void _restartValues() {
    setState(() {
      _value = 0;
      velocity1 = 0;
      velocity2 = 0;
      lostTime = 0;
    });
  }

  void _startDownload() async {
    tempDir = "${(await getTemporaryDirectory()).path}test.bin";

    int currentTime = 0;
    double totalTime1 = 0;
    double totalTime2 = 0;

    bool firstPackedReceived = false;
    int firstPackedSize = 0;

    late int startDownloadTime2;
    int startDownloadTime1 = DateTime.now().millisecondsSinceEpoch;

    print("Starting download");
    await dio.downloadUri(
      Uri.parse(
          "http://181.176.254.106:8165/qos-service/api/file/download?n=51200"),
      tempDir,
      options: Options(headers: {HttpHeaders.acceptEncodingHeader: "*"}),
      onReceiveProgress: (count, total) {
        currentTime = DateTime.now().millisecondsSinceEpoch;

        if (!firstPackedReceived) {
          firstPackedReceived = true;
          startDownloadTime2 = currentTime;
          firstPackedSize = count;
          lostTime = (currentTime - startDownloadTime1) / 1000;
          setState(() {});
        }

        totalTime1 = (currentTime - startDownloadTime1).toDouble() / 1000;
        totalTime2 = (currentTime - startDownloadTime2).toDouble() / 1000;

        debugPrint("DL>>> Count and total: $count / $total");
        debugPrint("DL>>> Ratio: ${count / total}");
        debugPrint("DL>>> Total Time1: $totalTime1");
        debugPrint("DL>>> Total Time2: $totalTime2");
        setState(() {
          velocity1 = (count / totalTime1 / 1024 / 1024);
          velocity2 = ((count - firstPackedSize) / totalTime2 / 1024 / 1024);
          _value = count / total;
        });
      },
    )
        // .timeout(const Duration(seconds: 21))
        .whenComplete(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SpeedTest Demo"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          ElevatedButton(
            onPressed: _startDownload,
            child: const Text("Download Test"),
          ),
          ElevatedButton(
            onPressed: _restartValues,
            child: const Text("Restart Test"),
          ),
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.all(20),
            child: LinearPercentIndicator(
              lineHeight: 20.0,
              percent: _value,
              center: Text("${(_value * 100).toStringAsFixed(1)}%"),
              // linearStrokeCap: LinearStrokeCap.roundAll,
              progressColor: Colors.green,
            ),
          ),
          Column(
            children: [
              const Text("Download rate (MB/s)"),
              Text(
                  "Velocidad fórmula 1: ${(velocity1 * 8).toStringAsFixed(2)}"),
              Text(
                  "Velocidad fórmula 2: ${(velocity2 * 8).toStringAsFixed(2)}"),
              const SizedBox(height: 20),
              lostTime != 0 ? Text("Lost time: $lostTime") : Container(),
            ],
          )
        ],
      ),
    );
  }
}
