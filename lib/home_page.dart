import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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
  double _valueUpload = 0;
  double velocityDL1 = 0;
  double velocityDL2 = 0;

  double velocityUL = 0;
  double lostTime = 0;
  Dio dio = Dio();

  late String tempDir;

  void _restartValues() {
    setState(() {
      _value = 0;
      _valueUpload = 0;
      velocityDL1 = 0;
      velocityDL2 = 0;

      velocityUL = 0;

      lostTime = 0;
    });
  }

  void _startUpload() async {
    tempDir = "${(await getTemporaryDirectory()).path}test.bin";

    int currentTime = 0;
    double totalTime = 0;

    int packageSize = 5 * 1024 * 1024;

    Uint8List bytesToUpload = Uint8List(packageSize);
    File fileToUpload = File(tempDir)..writeAsBytesSync(bytesToUpload);

    FormData dataToSend = FormData.fromMap({
      "file":
          await MultipartFile.fromFile(fileToUpload.path, filename: "test.bin")
    });

    print("Starting uploading");

    int startDownloadTime = DateTime.now().millisecondsSinceEpoch;
    await dio.post(
      "http://181.176.254.106:8165/qos-service/api/file/upload",
      data: dataToSend,
      options: Options(headers: {HttpHeaders.acceptEncodingHeader: "*"}),
      onSendProgress: (count, total) {
        currentTime = DateTime.now().millisecondsSinceEpoch;

        // if (!firstPackedReceived) {
        //   firstPackedReceived = true;
        //   startDownloadTime2 = currentTime;
        //   firstPackedSize = count;
        //   lostTime = (currentTime - startDownloadTime1) / 1000;
        //   setState(() {});
        // }

        totalTime = (currentTime - startDownloadTime).toDouble() / 1000;

        debugPrint("UL>>> Count and total: $count / $total");
        debugPrint("UL>>> Ratio: ${count / total}");
        debugPrint("UL>>> Total Time2: $totalTime");
        setState(() {
          velocityUL = (count / totalTime / 1024 / 1024);
          _valueUpload = count / total;
        });
      },
    )
        // .timeout(const Duration(seconds: 21))
        .whenComplete(() {});
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
          velocityDL1 = (count / totalTime1 / 1024 / 1024);
          velocityDL2 = ((count - firstPackedSize) / totalTime2 / 1024 / 1024);
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
            onPressed: _startUpload,
            child: const Text("Upload Test"),
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
                  "Velocidad fórmula 1: ${(velocityDL1 * 8).toStringAsFixed(2)}"),
              Text(
                  "Velocidad fórmula 2: ${(velocityDL2 * 8).toStringAsFixed(2)}"),
              const SizedBox(height: 20),
              lostTime != 0 ? Text("Lost time: $lostTime") : Container(),
            ],
          ),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: LinearPercentIndicator(
                  lineHeight: 20.0,
                  percent: _valueUpload,
                  center: Text("${(_valueUpload * 100).toStringAsFixed(1)}%"),
                  // linearStrokeCap: LinearStrokeCap.roundAll,
                  progressColor: Colors.purple,
                ),
              ),
              const Text("Upload rate (MB/s)"),
              Text(
                  "Velocidad fórmula 1: ${(velocityUL * 8).toStringAsFixed(2)}"),
              const SizedBox(height: 20),
            ],
          ),
        ],
      ),
    );
  }
}
