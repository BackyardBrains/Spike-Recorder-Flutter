import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';
import 'dart:js' as js;

import 'package:alert_dialog/alert_dialog.dart';
import 'package:async/async.dart';
import 'package:circular_buffer/circular_buffer.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_audio_waveforms/flutter_audio_waveforms.dart';
// import 'package:fps_widget/fps_widget.dart';
import 'package:mfi/mfi.dart';

import 'package:mic_stream/mic_stream.dart';
import 'package:permission_handler/permission_handler.dart';
// import 'package:flutter_wasm/flutter_wasm.dart';
import 'package:srmobileapp/multiply.dart';
// import 'package:quick_usb/quick_usb.dart';

// if platform isWindows
// import 'package:flutter_libserialport/flutter_libserialport.dart';
// import 'package:winaudio/winaudio.dart';
// import 'package:usb_serial/usb_serial.dart';

// import 'package:quick_usb/quick_usb.dart';
const SIZE_LOGS2 = 10;
const NUMBER_OF_SEGMENTS = 60;
const skipCounts = [1, 2, 4, 8, 16, 32, 64, 128, 256, 512];

int cBuffIdx = 0;
int tempBuffIdx = 0;
List<double> cBuff = [];
List<double> cBuffDouble = [];

List<List<List<double>>> allEnvelopes = [];
int level = 4;
int divider = 60;
int globalIdx = 0;

final _data = Uint8List.fromList([
  0x00, 0x61, 0x73, 0x6d, 0x01, 0x00, 0x00, 0x00, 0x01, 0x06, 0x01, 0x60, //
  0x01, 0x7e, 0x01, 0x7e, 0x03, 0x02, 0x01, 0x00, 0x04, 0x05, 0x01, 0x70,
  0x01, 0x01, 0x01, 0x05, 0x03, 0x01, 0x00, 0x02, 0x06, 0x08, 0x01, 0x7f,
  0x01, 0x41, 0x80, 0x88, 0x04, 0x0b, 0x07, 0x13, 0x02, 0x06, 0x6d, 0x65,
  0x6d, 0x6f, 0x72, 0x79, 0x02, 0x00, 0x06, 0x73, 0x71, 0x75, 0x61, 0x72,
  0x65, 0x00, 0x00, 0x0a, 0x09, 0x01, 0x07, 0x00, 0x20, 0x00, 0x20, 0x00,
  0x7e, 0x0b,
]);

// final mod = WasmModule(data);
// print(mod.describe());
// final inst = mod.builder().build();
// final square = inst.lookupFunction('square');

// Future<dynamic> readFileAsync() async {
//   ByteData data = await rootBundle.load("wasm/fib.wasm");
//   final dataList = data.buffer.asUint8List(0);
//   print("dataList");
//   print(dataList);
//   final _inst = WasmModule(dataList).builder().build();
//   final _wasmSquare = _inst.lookupFunction('fib');

//   print("_wasmSquare(12)");
//   print(_wasmSquare(10));
//   return _wasmSquare(10);
// }

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
  // final data = File('fib.wasm').readAsBytesSync();

  // readFileAsync();
}

void sampleBufferingEntryPoint(List<dynamic> values) {
  final iReceivePort = ReceivePort();
  SendPort sendPort = values[0];
  List<List<List<double>>> allEnvelopes = values[1];
  int surfaceSize = values[2];
  sendPort.send(iReceivePort.sendPort);

  // List<List<List<double>>> allEnvelopes = [];
  // int level = 8;
  // int divider = 6;
  // int globalIdx = 0;
  // int surfaceSize = (48000 * 60);
  // String data = values[1];
  iReceivePort.listen((Object? message) async {
    // print("allEnvelopes");
    // print(allEnvelopes);
    List<dynamic> arr = message as List<dynamic>;
    int cBuffIdx = arr[0];
    var samples = arr[1];
    int globalIdx = arr[2];
    // var surfaceSize = arr[2];

    // Map<String, dynamic> map = message as Map<String, dynamic>;
    // // enveloping
    // var surfaceSize = map["surfaceSize"];
    // var cBuffIdx = map["cBuffIdx"];
    // var samples = map["samples"];
    // allEnvelopes = map["envelopes"];
    // print(surfaceSize);
    // print(divider);
    // print(globalIdx);

    // print("cBuffIdx 0");
    // print(allEnvelopes[0][8].sublist(0, 100));
    // print(samples);

    samples.forEach((tmp) {
      // print("allEnvelopes 3");
      // print(tmp);
      try {
        envelopingSamples(
            cBuffIdx, tmp.toDouble(), allEnvelopes[0], SIZE_LOGS2, skipCounts);

        cBuffIdx++;
        if (cBuffIdx >= surfaceSize - 1) {
          cBuffIdx = 0;
        }
      } catch (err) {
        print("err");
        print(err);
        // print(cbuffIdx, surfaceSize, allEnvelopes[0]);
        // print("cBuffIdx");
        // print(cBuffIdx);
        // print(surfaceSize);
        // print(SIZE_LOGS2);
      }
    });

    // // filter
    // // print("level");
    // // print(level);
    List<double> envelopeSamples = allEnvelopes[0][level];
    int prevSegment = (envelopeSamples.length / divider).floor();
    List<double> cBuff = List<double>.generate(prevSegment, (i) => 0);

    int skipCount = skipCounts[level];
    int head = (cBuffIdx / skipCount).floor();
    int interleavedIdx = head * 2;
    int start = interleavedIdx - prevSegment;
    int to = interleavedIdx;

    if (globalIdx == 0) {
      if (to - prevSegment < 0) {
        List<double> arr = allEnvelopes[0][level].sublist(0, to);
        // print(arr);
        cBuff.setAll(prevSegment - arr.length, arr);
      } else {
        start = to - prevSegment;
        List<double> arr = allEnvelopes[0][level].sublist(start, to);
        cBuff.setAll(prevSegment - arr.length, arr);
      }
      // print(prevSegment - arr.length);
    } else {
      if (start < 0) {
        // it is divided into 2 sections
        int processedHead = head * 2;
        int segmentCount = prevSegment;
        int bufferLength = prevSegment;

        segmentCount = segmentCount - processedHead - 1;
        start = envelopeSamples.length - segmentCount;
        List<double> firstPartOfData = envelopeSamples.sublist(start);
        List<double> secondPartOfData =
            envelopeSamples.sublist(0, processedHead + 1);
        if (secondPartOfData.length > 0) {
          try {
            cBuff.setAll(0, firstPartOfData);
            cBuff.setAll(firstPartOfData.length, secondPartOfData);
          } catch (err) {}
        } else {
          cBuff.setAll(
              bufferLength - firstPartOfData.length - 1, firstPartOfData);
        }
      } else {
        // print("start > 0");
        cBuff = List<double>.from(allEnvelopes[0][level].sublist(start, to));
      }
    }

    sendPort.send(cBuff);
    // List<double> data =
    //     List.generate(samples.length, (index) => index.toDouble());
    // sendPort.send(samples);
  });
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
      // home: FPSWidget(
      //   child: MyHomePage(title: 'FPS Widget Demo'),
      // ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  final ReceivePort _receivePort = ReceivePort();
  late final SendPort iSendPort;
  late var _isolate;
  late final StreamQueue _receiveQueue = StreamQueue(_receivePort);
  // CircularBuffer cBuff = CircularBuffer(2);

  StreamController<List<double>> simulateDataController =
      new StreamController<List<double>>();
  late StreamSubscription subscriptionSimulateData;

  // Platform.isWindows
  // late SerialPort serialPort;
  // late SerialPortReader serialReader;

  String versionNumber = '1.2.1';
  int isOpeningFile = 0;

  int extraChannels = 0;
  int minChannels = 0;
  int maxChannels = 0;

  int localChannel = 1;

  double prevY = 0.0;

  List<double> channelGains = [10000, 10000, 10000, 10000, 10000, 10000];

  int minIndexSerial = 1;
  int maxIndexSerial = 25;

  int minIndexHid = 1;
  int maxIndexHid = 15;

  int minIndexAudio = 1;
  int maxIndexAudio = 20;

  List<double> listIndexSerial = [5, 5, 5, 5, 5, 5];
  List<double> listIndexHid = [7, 7, 7, 7, 7, 7];
  List<double> listIndexAudio = [9, 9];

  List<double> listChannelSerial = [
    500,
    600,
    700,
    800,
    900,
    1000,
    1100,
    1200,
    1300,
    1400,
    1500,
    1600,
    1700,
    1800,
    1900,
    2000,
    4000,
    8000,
    12000,
    16000,
    20000,
    25000,
    30000,
    40000,
    80000,
    200000
  ];
  List<double> listChannelHid = [
    0.5,
    0.75,
    1,
    5,
    20,
    70,
    250,
    500,
    550,
    600,
    650,
    700,
    800,
    900,
    1000
  ];
  List<double> listChannelAudio = [
    100,
    300,
    700,
    1000,
    2000,
    6000,
    7000,
    8000,
    9000,
    10000,
    11000,
    14000,
    20000,
    22000,
    30000,
    33000,
    40000,
    47000,
    55000,
    70000
  ];

  List<double> levelMedian = [-1, -1, -1, -1, -1, -1];
  List<double> initialLevelMedian = [0, 0, 0, 0, 0, 0];

  List<double> chartData = [];
  List<List<double>> channelsData = [];

  var horizontalDiff = 0;

  num timeScale = 10000; //10ms to 10 seconds
  num curTimeScaleBar = 1000; //10ms to 10 seconds
  num curSkipCounts = 256;
  num curFps = 30;
  int sampleRate = 44100;
  List<double> arrDataMax = []; //10 seconds
  List<double> arrData = []; // current

  int capacity = 1;
  int capacityMin = 1;
  int capacityMax = 1;

  int isPlaying = 0;
  int isRecording = 0;
  int deviceType = 0; // 0 - audio | 1 - serial

  DateTime startRecordingTime = DateTime.now();
  DateTime currentRecordingTime = DateTime.now();
  Duration duration = Duration(hours: 0);
  String labelDuration = "";

  double startPosition = 1.0;
  double zoomLevel = 1.0;

  bool isLocal = false;

  double maxAxis = 441;

  double curLevel = 0;
  List<int> lblTimescale = [10, 40, 80, 160, 320, 625, 1250, 2500, 5000, 10000];
  List<int> arrTimescale = [10000, 5000, 2500, 1250, 625, 320, 160, 80, 40, 10];

  Map<String, dynamic> _deviceData = <String, dynamic>{};

  List<double> arrScaleBar = [
    0.1,
    0.1098901099, 0.1219512195, 0.1369863014, 0.15625, 0.1818181818,
    0.2173913043, 0.2702702703, 0.3571428571, 0.5263157895, 1,
    1.098901099, 1.219512195, 1.369863014, 1.5625, 1.818181818, 2.173913043,
    2.702702703, 3.571428571, 5.263157895, 10,
    10.86956522, 11.9047619, 13.15789474, 14.70588235, 16.66666667, 19.23076923,
    22.72727273, 27.77777778, 35.71428571, 50,
    52.63157895, 55.55555556, 58.82352941, 62.5, 66.66666667, 71.42857143,
    76.92307692, 83.33333333, 90.90909091, 100,
    108.6956522, 119.047619, 131.5789474, 147.0588235, 166.6666667, 192.3076923,
    227.2727273, 277.7777778, 357.1428571, 500,
    526.3157895, 555.5555556, 588.2352941, 625, 666.6666667, 714.2857143,
    769.2307692, 833.3333333, 909.0909091, 1000,
    1086.956522, 1190.47619, 1315.789474, 1470.588235, 1666.666667, 1923.076923,
    2272.727273, 2777.777778, 3571.428571, 5000,
    5263.157895, 5555.555556, 5882.352941, 6250, 6666.666667, 7142.857143,
    7692.307692, 8333.333333, 9090.909091, 10000,
    // 6,6.6,  7.2,7.8,  8.4,9,  9.6,10.2,  10.8,11.4,
    // 12,16.8,  21.6,26.4,  31.2,36,  40.8,45.6,  50.4,552,
    // 60,66, 72,78, 84,90, 96,102, 108,114,
    // 120,168, 216,264, 312,360, 408,456, 504,552,
    // 600,660,  720,780,  840,900,  960,1020,  1080,1140,
    // 1200,1680, 2160,2640, 3120,3600, 4080,4560, 5040,5520,
    // 6000,11400, 16800,22200, 27600,33000, 38400,43800, 49200,54600,
    // 60000,114000, 168000,222000, 276000,330000, 384000,438000, 492000,546000,
    // 600000

    // 6,8.4,10.8,  13.2,15.6,18,  20.4,22.8,25.2,  27.6,
    // 60,84,108,  132,156,180,  204,228,252,  276,
    // 600,840,1080,  1320,1560,1800,  2040,2280,2520,  2760,
    // 3000,3300,3600,  3900,4200,4500,  4800,5100,5400,  5700,
    // 6000,8400,10800,  13200,15600,18000,  20400,22800,25200,  27600,
    // 30000,33000,36000,  39000,42000,45000,  48000,51000,54000,  57000,
    // 60000,84000,108000,  132000,156000,180000,  204000,228000,252000,  276000,
    // 300000,330000,360000,  390000,420000,450000,  480000,510000,540000,  570000,
    // 600000
  ];

  final SIZE_LOGS2 = 10;
  final NUMBER_OF_SEGMENTS = 60;
  final SEGMENT_SIZE = 44100;
  int SIZE = 0;

  List<int> arrCounts = [32, 64, 128, 256, 512, 1024, 2048, 4096, 8192, 16384];
  ScaleUpdateDetails scaleDetails = ScaleUpdateDetails();
  late DragDownDetails dragDownDetails;
  late DragUpdateDetails dragDetails;
  late DragUpdateDetails dragHorizontalDetails;
  int levelScale = 0;
  int maxCountPerLevel = 0;
  int timeScaleBar = 80;
  double scaleBarWidth = 2.0;

  String isTutored = '';
  int tutorialStep = 0;

  int stepperValue = 1;
  var settingParams = {
    "channelCount": -1,
    "maxAudioChannels": 2,
    "maxSerialChannels": 6,
    "initialMaxSerialChannels": 6,
    "muteSpeakers": true,
    "lowFilterValue": "0",
    "highFilterValue": "1000",
    "notchFilter50": false,
    "notchFilter60": false,
    "defaultMicrophoneLeftColor": 0,
    "defaultMicrophoneRightColor": 1,
    "defaultSerialColor1": 0,
    "defaultSerialColor2": 1,
    "defaultSerialColor3": 2,
    "defaultSerialColor4": 3,
    "defaultSerialColor5": 4,
    "defaultSerialColor6": 5,
    "flagDisplay1": 1,
    "flagDisplay2": 0,
    "flagDisplay3": 0,
    "flagDisplay4": 0,
    "flagDisplay5": 0,
    "flagDisplay6": 0,
    "strokeWidth": 1.25,
    "strokeOptions": [1, 1.25, 1.5, 1.75, 2],
    "enableDeviceLegacy": false
  };

  List<Color> audioChannelColors = [
    Color(0xFF10ff00),
    Color(0xFFff0035),
    Color(0xFFe1ff4b),
    Color(0xFFff8755),
    Color(0xFF6bf063),
    Color(0xFF00c0c9),
  ];
  // List<Color> audioChannelColors = [Colors.black, Color(0xFF10ff00), Color(0xFFff0035), Color(0xFFe1ff4b), Color(0xFFff8755), Color(0xFF6bf063),Color(0xFF00c0c9),];
  // List<Color> serialChannelColors = [Colors.black, Color(0xFF1ed400), Color(0xFFffff00), Color(0xFF20b4aa), Color(0xFFdc0000), Color(0xFFdcdcdc),Color(0xFFff3800),];
  // List<Color> serialChannelColors = [Colors.black, Color(0xFF1ed400), Color(0xFFff0035),Color(0xFFffff00), Color(0xFF20b4aa), Color(0xFFdcdcdc),Color(0xFFff3800),];
  List<Color> serialChannelColors = [
    Color(0xFF1ed400),
    Color(0xFFff0035),
    Color(0xFFffff00),
    Color(0xFF20b4aa),
    Color(0xFFdcdcdc),
    Color(0xFFff3800),
  ];
  List<Color> channelsColor = [
    Colors.green,
    Color(0xFFff0035),
    Colors.green,
    Colors.green,
    Colors.green,
    Colors.green
  ];

  FocusNode keyboardFocusNode = FocusNode(debugLabel: "Keyboard Label");

  String prevKey = "";

  int deviceTypeInt = 0;

  List<double> eventMarkersPosition = [];
  List<int> eventMarkersNumber = [];

  double topRecordingBar = 0;

  bool isZooming = false;

  String globalChromeVersion = "";

  double horizontalDragX = 0;

  double horizontalDragXFix = 0;

  String strMaxTime = '';

  String strMinTime = '';

  double maxTime = 0;

  bool isLoadingFile = false;

  bool isShowingResetButton = true;

  bool isShowingTimebar = true;

  bool initFPS = true;

  Positioned feedbackButton = new Positioned(child: Container());
  Positioned openFileButton = new Positioned(child: Container());
  Positioned lastPositionButton = new Positioned(child: Container());
  Positioned settingDialogButton = new Positioned(child: Container());

  static Int16List dataToSamples(Uint8List data) {
    final buffer = data.buffer.asByteData(data.offsetInBytes);

    final samples = Int16List(data.length >> 1);
    var offset = 0;
    var idx = 0;
    while (offset < buffer.lengthInBytes) {
      samples[idx++] = buffer.getInt16(offset, Endian.little);
      offset += 2;
    }

    return samples;
  }

  void _standardDisplay() async {
    Stream<List<int>>? stream = await MicStream.microphone(sampleRate: 48000);
    StreamSubscription<List<int>>? listener =
        stream?.listen((samples) => print(dataToSamples(samples as Uint8List)));
  }

  List<double> getRandomList(count, maxRandom) {
    List<double> temp = [];
    Random rng = new Random();
    for (var i = 0; i < count; i++) {
      temp.add(rng.nextInt(maxRandom).toDouble() * (rng.nextBool() ? -1 : 1));
    }
    return temp;
  }

  void getIsolateNativeData() async {
    int surfaceSize =
        ((48000 * 60 * 2) / MediaQuery.of(context).size.width * 2).floor();
    // cBuff = CircularBuffer<int>(surfaceSize);
    cBuff = List<double>.generate(surfaceSize, (i) => 0);

    _isolate = await Isolate.spawn<List<dynamic>>(sampleBufferingEntryPoint, [
      _receivePort.sendPort,
      [197]
    ]);
    iSendPort = await _receiveQueue.next;

    Stream<Int32List>? stream = await MicStream.nativeData();
    StreamSubscription? listener = stream.listen((curSamples) async {
      bool first = true;
      List<int> visibleSamples = [];
      for (int i = 0; i < curSamples.length; i++) {
        visibleSamples.add(curSamples[i]);
      }

      iSendPort.send(visibleSamples);
    });

    _receiveQueue.rest.listen((curSamples) {
      for (int i = 0; i < curSamples.length; i++) {
        cBuff[cBuffIdx] = curSamples[i].toDouble();
        cBuffIdx++;
        if (cBuffIdx >= surfaceSize) {
          cBuffIdx = 0;
        }
      }
      cBuffDouble = cBuff.map((i) => i.toDouble()).toList().cast<double>();
      setState(() {});
    });

    setState(() {
      // _counter++;
    });
  }

  void getNativeData() async {
    int surfaceSize =
        ((48000 * 60 * 2) / MediaQuery.of(context).size.width * 2).floor();
    cBuffDouble = List<double>.generate(surfaceSize, (i) => 0);
    cBuff = List<double>.generate(surfaceSize, (i) => 0);
    print("getNativeData");

    Stream<Int32List>? stream = await MicStream.nativeData();
    cBuffIdx = 0;
    stream.listen((Int32List curSamples) {
      for (int i = 0; i < curSamples.length; i++) {
        // cBuff[cBuffIdx] = int.parse(curSamples[i].toString()).toDouble();
        cBuff[cBuffIdx] = curSamples[i].toDouble();
        cBuffIdx++;
        // print(curSamples[i].toDouble());
        if (cBuffIdx >= surfaceSize) {
          cBuffIdx = 0;
        }
        // print("cBuff[cBuffIdx]");
      }
      cBuffDouble = cBuff.map((i) => i.toDouble()).toList().cast<double>();
      // print(cBuffDouble);
      setState(() {});
    });
  }

  void getSimulateData() async {
    int surfaceSize =
        ((48000 * 60 * 2) / MediaQuery.of(context).size.width * 2).floor();
    cBuffDouble = List<double>.generate(surfaceSize, (i) => 0);
    cBuff = List<double>.generate(surfaceSize, (i) => 0);

    subscriptionSimulateData =
        simulateDataController.stream.listen((List<double> curSamples) {
      for (int i = 0; i < curSamples.length; i++) {
        cBuff[cBuffIdx] = curSamples[i].toDouble();
        cBuffIdx++;
        if (cBuffIdx >= surfaceSize) {
          cBuffIdx = 0;
        }
      }
      cBuffDouble = cBuff.map((i) => i.toDouble()).toList().cast<double>();
      setState(() {});
    });
  }

  void getStandardMicrophoneData() async {
    cBuffIdx = 0;

    double? sampleRate = await MicStream.sampleRate;
    int? bitDepth = await MicStream.bitDepth;
    int? bufferSize = await MicStream.bufferSize;
    Stream<Uint8List>? stream = await MicStream.microphone(
        audioSource: AudioSource.DEFAULT,
        sampleRate: 48000,
        channelConfig: ChannelConfig.CHANNEL_IN_MONO,
        audioFormat: AudioFormat.ENCODING_PCM_16BIT);

    // Start listening to the stream
    double _sampleRate = await MicStream.sampleRate!;
    print("_sampleRate");
    print(_sampleRate);

    List<int> envelopeSizes = [];
    int SEGMENT_SIZE = _sampleRate.toInt();
    int SIZE = NUMBER_OF_SEGMENTS * SEGMENT_SIZE;

    double size = SIZE.toDouble() * 2;

    unitInitializeEnvelope(
        1, allEnvelopes, envelopeSizes, size, SIZE, SIZE_LOGS2);
    // print(allEnvelopes);
    // print("envelopeSizes");
    // print(envelopeSizes);

    // int surfaceSize =
    //     ((_sampleRate * 60 * 2) / MediaQuery.of(context).size.width * 2)
    //         .floor();
    int surfaceSize = ((_sampleRate * 60).floor()).floor();

    print("surfaceSize ");
    print(surfaceSize);
    print(MediaQuery.of(context).size.width);
    // cBuff = CircularBuffer<int>(surfaceSize);
    double innerWidth = MediaQuery.of(context).size.width;
    int level =
        calculateLevel(10000, _sampleRate.toInt(), innerWidth, skipCounts);
    int divider = 6;
    int skipCount = skipCounts[level];

    List<double> envelopeSamples = allEnvelopes[0][level];
    int prevSegment = (envelopeSamples.length / divider).floor();

    cBuffDouble = List<double>.generate(prevSegment, (i) => 0);
    cBuff = List<double>.generate(prevSegment, (i) => 0);
    int globalIdx = 0;
    int channelIdx = 0;

    StreamSubscription? listener = stream?.listen((samples) async {
      bool first = true;
      // print("ENDIANNESSS");
      // var visibleSamples = [];
      // var samples;
      // var bitDepth = await MicStream.bitDepth;
      // print(bitDepth);

      // if (bitDepth == 32)
      //   samples = (_samples).buffer.asUint16List();
      // // samples = dataToSamples(_samples);
      // else {
      // samples = _samples;
      // }
      // visibleSamples = samples;
      int tmp = 0;
      Uint8List byteArray = Uint8List(2);
      for (int sample in samples) {
        // if (sample > 128) sample -= 255;
        if (first) {
          // tmp = multiply(0.5, sample * 128).floor();
          byteArray[0] = sample;
        } else {
          // tmp += multiply(0.5, sample.toDouble()).floor();
          byteArray[1] = sample;

          ByteData byteData = ByteData.view(byteArray.buffer);
          // visibleSamples.add(tmp);
          // visibleSamples.add((byteData.getInt16(0, Endian.little)));
          tmp = multiply(0.5, (byteData.getInt16(0, Endian.little)).toDouble())
              .toInt();
          // int interleavedSignalIdx = cBuffIdx * 2;
          // cBuff[interleavedSignalIdx] = tmp.toDouble();
          // cBuff[interleavedSignalIdx + 1] = tmp.toDouble();
          envelopingSamples(cBuffIdx, tmp.toDouble(), allEnvelopes[channelIdx],
              SIZE_LOGS2, skipCounts);

          cBuffIdx++;
          // if (cBuffIdx >= surfaceSize) {
          //   cBuffIdx = 0;
          // }
          if (cBuffIdx >= surfaceSize) {
            globalIdx++;
            cBuffIdx = 0;
          }

          // localMax ??= visibleSamples.last;
          // localMin ??= visibleSamples.last;
          // localMax = max(localMax!, visibleSamples.last);
          // localMin = min(localMin!, visibleSamples.last);

          // envelopingSamples(cBuffIdx, tmp.toDouble(), allEnvelopes[0],
          //     SIZE_LOGS2, skipCounts);

          // cBuffIdx++;
          // if (cBuffIdx >= SIZE) {
          //   cBuffIdx = 0;
          // }

          tmp = 0;
        }
        first = !first;
      }
      // int len = visibleSamples.length;
      // // int envelopeIdx = 0;
      // for (int i = 0; i < len; i++) {
      //   // if (cBuffIdx % 20 == 0) {
      //   //   cBuff[cBuffIdx] = 7000;
      //   // } else {
      //   //   cBuff[cBuffIdx] = visibleSamples[i].toDouble();
      //   // }
      //   // envelopingSamples(cBuffIdx, visibleSamples[i].toDouble(),
      //   //     allEnvelopes[envelopeIdx], SIZE_LOGS2, skipCounts);

      //   int interleavedSignalIdx = cBuffIdx * 2;
      //   cBuff[interleavedSignalIdx] = visibleSamples[i].toDouble();
      //   cBuff[interleavedSignalIdx + 1] = visibleSamples[i].toDouble();

      //   cBuffIdx++;
      //   // if (cBuffIdx >= surfaceSize) {
      //   //   cBuffIdx = 0;
      //   // }
      //   if (cBuffIdx >= surfaceSize) {
      //     cBuffIdx = 0;
      //   }
      // }
      // print("visibleSamples");
      // print(cBuffIdx);
      // cBuffDouble = List<double>.from(cBuff);
      int head = (cBuffIdx / skipCount).floor();
      int interleavedIdx = head * 2;
      int start = interleavedIdx - prevSegment;
      int to = interleavedIdx;

      if (globalIdx == 0) {
        // cBuffDouble = List<double>.from(allEnvelopes[0][level].sublist(0, to));
        if (to - prevSegment < 0) {
          List<double> arr = allEnvelopes[0][level].sublist(0, to);
          cBuff.setAll(prevSegment - arr.length, arr);
        } else {
          start = to - prevSegment;
          List<double> arr = allEnvelopes[0][level].sublist(start, to);
          cBuff.setAll(prevSegment - arr.length, arr);
        }
        // print(prevSegment - arr.length);
      } else {
        if (start < 0) {
          // it is divided into 2 sections
          // print("start < 0");

          // int head = cBuffIdx;
          int processedHead = head * 2;
          int segmentCount = prevSegment;
          int bufferLength = prevSegment;

          segmentCount = segmentCount - processedHead - 1;
          start = envelopeSamples.length - segmentCount;
          List<double> firstPartOfData = envelopeSamples.sublist(start);
          List<double> secondPartOfData =
              envelopeSamples.sublist(0, processedHead + 1);
          // int secondIdx = bufferLength - secondPartOfData.length - 1;
          if (secondPartOfData.length > 0) {
            // print("secondpartdata is >= zero");
            // print(processedHead);
            // print(segmentCount);
            // print(prevSegment);
            // print(start);
            // print(firstPartOfData.length);
            // print(secondPartOfData.length);
            try {
              cBuff.setAll(0, firstPartOfData);
              cBuff.setAll(firstPartOfData.length, secondPartOfData);
            } catch (err) {
              // console.log(err);
              // console.log(
              //     drawBuffer,
              //     envelopeSamples,
              //     start,
              //     segmentCount,
              //     processedHead,
              //     firstPartOfData.length,
              //     secondPartOfData.length);
            }
          } else {
            print("secondPartOfData.length");
            print(secondPartOfData.length);

            cBuff.setAll(
                bufferLength - firstPartOfData.length - 1, firstPartOfData);
          }
        } else {
          // print("start > 0");
          cBuff = List<double>.from(allEnvelopes[0][level].sublist(start, to));
        }
      }
      //   cBuffIdx++;
      //   // if (cBuffIdx >= surfaceSize) {
      //   //   cBuffIdx = 0;
      //   // }
      //   if (cBuffIdx >= surfaceSize) {
      //     cBuffIdx = 0;
      //   }
      cBuffDouble = List<double>.from(cBuff);

      // cBuffDouble = allEnvelopes[0][8];

      setState(() {});
    });

    setState(() {
      // _counter++;
    });
  }

  js2Dart(params) {
    cBuffDouble = (params[0]).toList().cast<double>();
    setState(() {});
  }

  callbackErrorLog(params) {
    // _sendAnalyticsEvent( params[0], { "parameters" : params[1] } );
  }
  callbackAudioInit(params) {}
  callbackOpenWavFile(params) {}
  callbackOpeningFile(params) {}
  callbackIsOpeningWavFile(params) {}
  changeResetPlayback(params) {}
  resetToAudio(params) {}

  callbackSerialInit(params) {
    deviceType = params[0];
    isPlaying = params[1];
    // startRecordingTime = (DateTime.now());
    listIndexSerial = [5, 5, 5, 5, 5, 5];
    listIndexHid = [7, 7, 7, 7, 7, 7];
    listIndexAudio = [9, 9];

    if (deviceType == 2) {
      channelGains = [500, 500, 500, 500, 500, 500];
    } else if (deviceType == 1) {
      channelGains = [1000, 1000, 1000, 1000, 1000, 1000];
    } else {}
    js.context.callMethod('setFlagChannelDisplay', [
      settingParams["flagDisplay1"],
      settingParams["flagDisplay2"],
      settingParams["flagDisplay3"],
      settingParams["flagDisplay4"],
      settingParams["flagDisplay5"],
      settingParams["flagDisplay6"]
    ]);
    setState(() {});
  }

  callbackGetDeviceInfo(params) {
    // extra_channels,max min, channels
    print("callback params");
    print(params);
    extraChannels = params[0];
    minChannels = params[1];
    maxChannels = params[2];
    settingParams["channelCount"] = minChannels;

    if (extraChannels != 0) {
      for (int i = 1; i <= maxChannels; i++) {
        settingParams["flagDisplay" + i.toString()] = 1;
        channelsColor[i - 1] = serialChannelColors[i - 1];
      }
    } else {
      for (int i = 1; i <= minChannels; i++) {
        settingParams["flagDisplay" + i.toString()] = 1;
        channelsColor[i - 1] = serialChannelColors[i - 1];
      }
    }
    js.context.callMethod('setFlagChannelDisplay', [
      settingParams["flagDisplay1"],
      settingParams["flagDisplay2"],
      settingParams["flagDisplay3"],
      settingParams["flagDisplay4"],
      settingParams["flagDisplay5"],
      settingParams["flagDisplay6"]
    ]);
    setState(() {});
  }

  void getMicrophoneData() async {
    // if (Platform.isWindows || Platform.isMacOS) {
    //   print("isWINDOWS ");
    //   if (await Permission.microphone.request().isGranted) {
    //     // Either the permission was already granted before or the user just granted it.
    //   }

    //   double _sampleRate = 48000;
    //   List<int> envelopeSizes = [];
    //   int SEGMENT_SIZE = _sampleRate.toInt();
    //   int SIZE = NUMBER_OF_SEGMENTS * SEGMENT_SIZE;
    //   double size = SIZE.toDouble() * 2;
    //   unitInitializeEnvelope(
    //       1, allEnvelopes, envelopeSizes, size, SIZE, SIZE_LOGS2);
    //   int surfaceSize = ((_sampleRate * 60).floor()).floor();

    //   _isolate = await Isolate.spawn<List<dynamic>>(sampleBufferingEntryPoint, [
    //     _receivePort.sendPort,
    //     allEnvelopes,
    //     surfaceSize,
    //     [197]
    //   ]);
    //   iSendPort = await _receiveQueue.next;

    //   double innerWidth = MediaQuery.of(context).size.width;
    //   level =
    //       calculateLevel(10000, _sampleRate.toInt(), innerWidth, skipCounts);
    //   int skipCount = skipCounts[level];

    //   List<double> envelopeSamples = allEnvelopes[0][level];
    //   int prevSegment = (envelopeSamples.length / divider).floor();

    //   cBuffDouble = List<double>.generate(prevSegment, (i) => 0);
    //   cBuff = List<double>.generate(prevSegment, (i) => 0);
    //   globalIdx = 0;
    //   int channelIdx = 0;

    //   _receiveQueue.rest.listen((curSamples) {
    //     cBuffDouble = List<double>.from(curSamples);
    //     setState(() {});
    //   });

    //   Winaudio.audioData().listen((samples) {
    //     // print("samples audio data : !!! ");
    //     // print(samples);

    //     bool first = true;
    //     List<double> visibleSamples = [];

    //     int tmp = 0;
    //     Uint8List byteArray = Uint8List(2);
    //     tempBuffIdx = cBuffIdx;
    //     for (int sample in samples) {
    //       if (first) {
    //         byteArray[0] = sample;
    //       } else {
    //         byteArray[1] = sample;

    //         ByteData byteData = ByteData.view(byteArray.buffer);
    //         tmp = (byteData.getInt16(0, Endian.little));
    //         visibleSamples.add(tmp.toDouble());

    //         tmp = 0;
    //       }
    //       first = !first;
    //     }
    //     iSendPort.send([cBuffIdx, visibleSamples, globalIdx]);
    //     cBuffIdx = (cBuffIdx + visibleSamples.length);
    //     if (cBuffIdx >= surfaceSize) {
    //       globalIdx++;
    //       cBuffIdx %= surfaceSize;
    //     }
    //   });

    //   Winaudio wa = new Winaudio();
    //   String? version = await wa.getPlatformVersion();
    //   print("version");
    //   print(version);
    //   return;
    // }

    // cBuffIdx = 0;

    // double? sampleRate = await MicStream.sampleRate;
    // int? bitDepth = await MicStream.bitDepth;
    // int? bufferSize = await MicStream.bufferSize;
    // // int SIZE = sampleRate!.toInt() * 60 * 2;
    // // int SIZE = 48000 * 60 * 2;
    // // cBuff = CircularBuffer<int>(SIZE);
    // // Init a new Stream
    // Stream<List<int>>? stream = await MicStream.microphone(
    //     audioSource: AudioSource.DEFAULT,
    //     sampleRate: 48000,
    //     channelConfig: ChannelConfig.CHANNEL_IN_MONO,
    //     audioFormat: AudioFormat.ENCODING_PCM_16BIT);

    // double _sampleRate = await MicStream.sampleRate!;
    // List<int> envelopeSizes = [];
    // int SEGMENT_SIZE = _sampleRate.toInt();
    // int SIZE = NUMBER_OF_SEGMENTS * SEGMENT_SIZE;
    // double size = SIZE.toDouble() * 2;
    // unitInitializeEnvelope(
    //     1, allEnvelopes, envelopeSizes, size, SIZE, SIZE_LOGS2);
    // // print(" unitInitializeEnvelope :");
    // // print(allEnvelopes);
    // int surfaceSize = ((_sampleRate * 60).floor()).floor();
    // // cBuff = CircularBuffer<int>(surfaceSize);

    // _isolate = await Isolate.spawn<List<dynamic>>(sampleBufferingEntryPoint, [
    //   _receivePort.sendPort,
    //   allEnvelopes,
    //   surfaceSize,
    //   [197]
    // ]);
    // iSendPort = await _receiveQueue.next;

    // double innerWidth = MediaQuery.of(context).size.width;
    // level = calculateLevel(10000, _sampleRate.toInt(), innerWidth, skipCounts);
    // int skipCount = skipCounts[level];

    // List<double> envelopeSamples = allEnvelopes[0][level];
    // int prevSegment = (envelopeSamples.length / divider).floor();

    // cBuffDouble = List<double>.generate(prevSegment, (i) => 0);
    // cBuff = List<double>.generate(prevSegment, (i) => 0);
    // globalIdx = 0;
    // int channelIdx = 0;

    // // Start listening to the stream
    // StreamSubscription? listener = stream?.listen((samples) async {
    //   bool first = true;
    //   List<double> visibleSamples = [];

    //   int tmp = 0;
    //   Uint8List byteArray = Uint8List(2);
    //   tempBuffIdx = cBuffIdx;
    //   for (int sample in samples) {
    //     // if (sample > 128) sample -= 255;
    //     if (first) {
    //       byteArray[0] = sample;
    //     } else {
    //       byteArray[1] = sample;

    //       ByteData byteData = ByteData.view(byteArray.buffer);
    //       tmp = (byteData.getInt16(0, Endian.little));
    //       visibleSamples.add(tmp.toDouble());
    //       // int interleavedSignalIdx = cBuffIdx * 2;

    //       tmp = 0;
    //     }
    //     first = !first;
    //   }
    //   // // print("sending to isolate");
    //   // iSendPort.send(visibleSamples);
    //   iSendPort.send([cBuffIdx, visibleSamples, globalIdx]);
    //   cBuffIdx = (cBuffIdx + visibleSamples.length);
    //   if (cBuffIdx >= surfaceSize) {
    //     globalIdx++;
    //     cBuffIdx %= surfaceSize;
    //   }
    //   // iSendPort.send({
    //   //   "cBuffIdx": cBuffIdx,
    //   //   "samples": visibleSamples,
    //   //   "envelopes": allEnvelopes,
    //   //   "surfaceSize": surfaceSize,
    //   // });
    //   // iSendPort.send(visibleSamples);
    //   // // print(visibleSamples);
    //   // // return await _receiveQueue.next;
    //   // cBuffDouble = List<double>.from(visibleSamples);
    //   // setState(() {});
    // });

    // _receiveQueue.rest.listen((curSamples) {
    //   // final curSamples = dataToSamples(samples as Uint8List);

    //   // cBuff.addAll(curSamples);
    //   // for (int i = 0; i < curSamples.length; i++) {
    //   //   cBuff[cBuffIdx] = curSamples[i].toDouble();
    //   //   cBuffIdx++;
    //   //   if (cBuffIdx >= surfaceSize) {
    //   //     cBuffIdx = 0;
    //   //   }
    //   // }
    //   // print("curSamples");
    //   // print(curSamples);
    //   // cBuffDouble = curSamples.map((i) => i.toDouble()).toList().cast<double>();
    //   // cBuffDouble = cBuff.map((i) => i.toDouble()).toList().cast<double>();
    //   // cBuffDouble = cBuff.toList().cast<double>();
    //   // print("curSamples");
    //   // print(curSamples);
    //   cBuffDouble = List<double>.from(curSamples);
    //   // print("cBuffDouble");
    //   // print(cBuffDouble);
    //   setState(() {});
    //   // print(curSamples.length);
    // });

    // // _receivePort.asBroadcastStream().listen((Object? samples){
    // //   print(dataToSamples(samples as Uint8List));
    // // });

    // setState(() {
    //   _counter++;
    // });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Stack(
          children: [
            Positioned(
                left: 0,
                top: 0,
                child: cBuff.length == 2
                    ? Container()
                    : PolygonWaveform(
                        inactiveColor: Colors.green,
                        activeColor: Colors.transparent,
                        maxDuration: const Duration(days: 1),
                        elapsedDuration: const Duration(hours: 0),
                        samples:
                            (cBuffDouble), //list.map((i) => i.toDouble()).toList();
                        channelIdx: 0,
                        channelActive: 1,
                        // channelTop: top,
                        height: MediaQuery.of(context).size.height / 2,
                        width: MediaQuery.of(context).size.width,
                        gain: 10000,
                        levelMedian: 300,
                        strokeWidth: 1,
                        eventMarkersNumber: [],
                        eventMarkersPosition: [],
                      )),
            // Positioned(
            //     left: 0,
            //     top: 100,
            //     child: ElevatedButton(
            //       onPressed: () {
            //         getMfiTest();
            //       },
            //       child: Text("MFI Demo"),
            //     )),
            Positioned(
                left: 0,
                top: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (kIsWeb) {
                      getWebSerial();
                    } else {
                      // getRawSerial();
                    }
                  },
                  child: Text("Serial Triangle Demo"),
                )),
            // Positioned(
            //     right: 0,
            //     top: 50,
            //     child: ElevatedButton(
            //       onPressed: () {
            //         closeRawSerial();
            //       },
            //       child: Text("Close Serial Triangle Demo"),
            //     )),
            // Positioned(
            //     left: 0,
            //     bottom: 50,
            //     child: ElevatedButton(
            //       onPressed: () {
            //         getMicrophoneData();
            //       },
            //       child: Text("Continuous Audio Isolate"),
            //     )),
            // Positioned(
            //     right: 0,
            //     bottom: 50,
            //     child: ElevatedButton(
            //       onPressed: () {
            //         getStandardMicrophoneData();
            //       },
            //       child: Text("Audio Stream Listener"),
            //     )),
            // Positioned(
            //     left: 0,
            //     bottom: 100,
            //     child: ElevatedButton(
            //       onPressed: () {
            //         getIsolateNativeData();
            //       },
            //       child: Text("Sim. Isolate Native data"),
            //     )),
            // Positioned(
            //     left: 0,
            //     bottom: 150,
            //     child: ElevatedButton(
            //       onPressed: () {
            //         getNativeData();
            //       },
            //       child: Text("Simulate Native data"),
            //     )),
            // Positioned(
            //     right: 0,
            //     bottom: 150,
            //     child: ElevatedButton(
            //       onPressed: () {
            //         getSimulateData();
            //         Timer timer = Timer.periodic(
            //             new Duration(milliseconds: 200), (Timer timer) {
            //           List<double> randoms = getRandomList(600, 32768);
            //           // print("randoms");
            //           // print(randoms);
            //           simulateDataController.sink.add(randoms);
            //         });
            //       },
            //       child: Text("Simulate data"),
            //     )),
          ],
        ),

        // child: Column(

        //   mainAxisAlignment: MainAxisAlignment.center,
        //   children: <Widget>[
        //     const Text(
        //       'You have pushed the button this many times:',
        //     ),
        //     Text(
        //       '$_counter',
        //       style: Theme.of(context).textTheme.headline4,
        //     ),
        //   ],
        // ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: _incrementCounter,
      //   tooltip: 'Increment',
      //   child: const Icon(Icons.add),
      // ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  void initPorts() {
    // Platform.isWindows
    // if (Platform.isWindows || Platform.isMacOS)
    //   availablePorts = SerialPort.availablePorts;

    // for (final address in availablePorts) {

    // getRawSerial();
    // print('Transport' + port.transport.toTransport());
    // print('Manufacturer' + port.manufacturer!);
    // print('Product Name' + port.productName!);
    // print('Serial Number' + port.serialNumber!);
    // print('MAC Address' + port.macAddress!);
    // }
  }

  var availablePorts = [];
  void initState() {
    super.initState();
    if (kIsWeb) {
      js.context['jsToDart'] = js2Dart;
      js.context['callbackErrorLog'] = callbackErrorLog;
      js.context['callbackAudioInit'] = callbackAudioInit;
      js.context['callbackOpenWavFile'] = callbackOpenWavFile;
      js.context['callbackOpeningFile'] = callbackOpeningFile;
      js.context['callbackIsOpeningWavFile'] = callbackIsOpeningWavFile;
      js.context['changeResetPlayback'] = changeResetPlayback;
      js.context['resetToAudio'] = resetToAudio;
      js.context['changeSampleRate'] = (params) {
        // sampleRate = params[0];
        // curSkipCounts = params[1];
        // curLevel = params[2];
      };
      js.context['callbackSerialInit'] = callbackSerialInit;
      js.context['callbackGetDeviceInfo'] = callbackGetDeviceInfo;

      js.context
          .callMethod('recordAudio', ['Flutter is calling upon JavaScript!']);
      return;
    }

    initPorts();
  }

  //Platform.isWindows
  void closeRawSerial() async {
    // serialReader.close();
    // serialPort.close();
    // serialPort.dispose();
  }

  // void getRawSerial() async {
  //   // if (kIsWeb) {
  //   //   js.context['jsToDart'] = js2Dart;
  //   // }

  //   // cBuffIdx = 0;

  //   double _sampleRate = 10000;
  //   List<int> envelopeSizes = [];
  //   int SEGMENT_SIZE = _sampleRate.toInt();
  //   int SIZE = NUMBER_OF_SEGMENTS * SEGMENT_SIZE;
  //   double size = SIZE.toDouble() * 2;
  //   unitInitializeEnvelope(
  //       1, allEnvelopes, envelopeSizes, size, SIZE, SIZE_LOGS2);
  //   int surfaceSize = ((_sampleRate * 60).floor()).floor();

  //   _isolate = await Isolate.spawn<List<dynamic>>(sampleBufferingEntryPoint, [
  //     _receivePort.sendPort,
  //     allEnvelopes,
  //     surfaceSize,
  //     [197]
  //   ]);
  //   iSendPort = await _receiveQueue.next;

  //   double innerWidth = MediaQuery.of(context).size.width;
  //   level = calculateLevel(10000, _sampleRate.toInt(), innerWidth, skipCounts);
  //   int skipCount = skipCounts[level];

  //   List<double> envelopeSamples = allEnvelopes[0][level];
  //   int divider = 60;
  //   int prevSegment = (envelopeSamples.length / divider).floor();

  //   cBuffDouble = List<double>.generate(prevSegment, (i) => 0);
  //   cBuff = List<double>.generate(prevSegment, (i) => 0);
  //   globalIdx = 0;
  //   int channelIdx = 0;

  //   if (Platform.isAndroid) {
  //     List<UsbDevice> devices = await UsbSerial.listDevices();
  //     print(devices);

  //     UsbPort port;
  //     // alert(context,title: Text('Alert5'),content: Text(devices.toString()),textOK: Text('Yes'),);
  //     if (devices.length == 0) {
  //       return;
  //     }
  //     port = (await devices[0].create())!;

  //     bool openResult = await port.open();
  //     if (!openResult) {
  //       print("Failed to open");
  //       // alert(context,title: Text('Failed'),content: Text("Failed to open"),textOK: Text('Yes'),);
  //       return;
  //     }

  //     await port.setDTR(true);
  //     await port.setRTS(true);

  //     port.setPortParameters(
  //         222222, UsbPort.DATABITS_8, UsbPort.STOPBITS_1, UsbPort.PARITY_NONE);

  //     // print first result and close port.
  //     port.inputStream?.listen((Uint8List samples) {
  //       bool first = true;
  //       List<double> visibleSamples = [];

  //       int tmp = 0;
  //       Uint8List byteArray = Uint8List(2);
  //       tempBuffIdx = cBuffIdx;
  //       for (int sample in samples) {
  //         // // if (sample > 128) sample -= 255;
  //         if (first) {
  //           byteArray[0] = sample;
  //         } else {
  //           byteArray[1] = sample;

  //           // ByteData byteData = ByteData.view(byteArray.buffer);
  //           // tmp = (byteData.getInt16(0, Endian.little));
  //           if (byteArray[0] > 128) {
  //             //[128.0, 122.0, 128.0, 123.0, 128.0, 124.0, 128.0, 125.0, 128.0, 126.0, 128.0, 127.0, 129.0, 0.0, 129.0, 1.0, 129.0, 2.0, 129.0, 3.0, 129.0, 4.0, 129.0, 5.0, 129.0, 6.0, 129.0, 7.0, 129.0, 8.0, 129.0, 9.0, 129.0, 10.0, 129.0, 11.0, 129.0, 12.0, 129.0, 13.0, 129.0, 14.0, 129.0, 15.0, 129.0, 16.0, 129.0, 17.0, 129.0, 18.0, 129.0, 19.0, 129.0, 20.0, 129.0, 21.0, 129.0, 22.0, 129.0, 23.0, 129.0, 24.0, 129.0, 25.0]
  //             tmp = 128 + sample;
  //           } else if (byteArray[1] > 128) {
  //             //[128.0, 122.0, 128.0, 123.0, 128.0, 124.0, 128.0, 125.0, 128.0, 126.0, 128.0, 127.0, 129.0, 0.0, 129.0, 1.0, 129.0, 2.0, 129.0, 3.0, 129.0, 4.0, 129.0, 5.0, 129.0, 6.0, 129.0, 7.0, 129.0, 8.0, 129.0, 9.0, 129.0, 10.0, 129.0, 11.0, 129.0, 12.0, 129.0, 13.0, 129.0, 14.0, 129.0, 15.0, 129.0, 16.0, 129.0, 17.0, 129.0, 18.0, 129.0, 19.0, 129.0, 20.0, 129.0, 21.0, 129.0, 22.0, 129.0, 23.0, 129.0, 24.0, 129.0, 25.0]
  //             tmp = 128 + byteArray[0];
  //           } else {
  //             if (byteArray[0] == 128) {
  //               tmp = byteArray[1];
  //             } else {
  //               tmp = byteArray[0];
  //             }
  //           }
  //           tempBuffIdx++;
  //           if (tempBuffIdx >= surfaceSize) {
  //             globalIdx++;
  //           }

  //           // print(tmp.toString() + " " + sample.toString());
  //           visibleSamples.add(-10 * tmp.toDouble());
  //           // int interleavedSignalIdx = cBuffIdx * 2;

  //           tmp = 0;
  //         }
  //         first = !first;
  //         // visibleSamples.add(sample.toDouble());
  //       }
  //       // // print("sending to isolate");
  //       // iSendPort.send(visibleSamples);
  //       iSendPort.send([cBuffIdx, visibleSamples, globalIdx]);
  //       cBuffIdx = (cBuffIdx + visibleSamples.length);
  //       if (cBuffIdx >= surfaceSize) {
  //         globalIdx++;
  //         cBuffIdx %= surfaceSize;
  //       }

  //       // setState((){});
  //       // port.close();
  //     });

  //     _receiveQueue.rest.listen((curSamples) {
  //       cBuffDouble = List<double>.from(curSamples);
  //       setState(() {});
  //     });

  //     // var init = await QuickUsb.init();
  //     // List<UsbDevice>? _deviceList = await QuickUsb.getDeviceList();
  //     // // alert(context,title: Text('Alert1'),content: Text(_deviceList.toString()),textOK: Text('Yes'),);

  //     // var hasPermission = await QuickUsb.hasPermission(_deviceList.first);
  //     // if (!hasPermission){
  //     //   await QuickUsb.requestPermission(_deviceList.first);
  //     // }
  //     // hasPermission = await QuickUsb.hasPermission(_deviceList.first);
  //     // // alert(context,title: Text('Alert2'),content: Text(hasPermission.toString()),textOK: Text('Yes'),);
  //     // try{
  //     //   var openDevice = await QuickUsb.openDevice(_deviceList.first);
  //     //   // print('openDevice $openDevice');

  //     //   UsbConfiguration? _configuration = await QuickUsb.getConfiguration(0);
  //     //   // alert(context,title: Text('Alert3'),content: Text(_configuration.toString()),textOK: Text('Yes'),);

  //     //   var claimInterface = await QuickUsb.claimInterface(_configuration.interfaces[0]);
  //     //   // alert(context,title: Text('Alert4'),content: Text(claimInterface.toString()),textOK: Text('Yes'),);

  //     //   var endpoint = _configuration.interfaces[0].endpoints
  //     //       .firstWhere((e) => e.direction == UsbEndpoint.DIRECTION_IN);
  //     //   alert(context,title: Text('Alert5'),content: Text(endpoint.toString()),textOK: Text('Yes'),);

  //     //   var bulkTransferIn = await QuickUsb.bulkTransferIn(endpoint, 1024);
  //     //   alert(context,title: Text('Alert6'),content: Text(bulkTransferIn.toString()),textOK: Text('Yes'),);
  //     // }catch(err){
  //     //   alert(context,title: Text('Alert Err'),content: Text(err.toString()),textOK: Text('Yes'),);
  //     // }

  //     return;
  //   }
  //   //ELSE IF NOT ANDROID
  //   var address = availablePorts.last;
  //   serialPort = SerialPort(address);
  //   if (!serialPort.openReadWrite()) {
  //     print("SerialPort.lastError");
  //     print(SerialPort.lastError);
  //   }

  //   // print(serialPort.productId.toString());
  //   // print(serialPort.vendorId.toString());
  //   // print(serialPort.config.bits.toString());
  //   // print("port.config.cts.toString()");
  //   // print(serialPort.config.cts.toString());
  //   // print(serialPort.config.dsr.toString());
  //   // print(serialPort.config.dtr.toString());
  //   // print(serialPort.config.parity.toString());
  //   // print(serialPort.config.rts.toString());
  //   // print(serialPort.config.stopBits.toString());

  //   // serialPort.config.parity = 0;
  //   // serialPort.config.stopBits = 1;
  //   // serialPort.config.dtr = 1;
  //   // serialPort.config.rts = 1;
  //   // serialPort.config.bits = 8;
  //   // // serialPort.config.setFlowControl(SerialPortFlowControl.none);
  //   // serialPort.config.baudRate = 222222;

  //   SerialPortConfig config = SerialPortConfig();
  //   config.baudRate = 222222;
  //   config.stopBits = 1;
  //   config.dtr = 1;
  //   config.rts = 1;
  //   config.parity = 0;
  //   config.bits = 8;
  //   config.setFlowControl(SerialPortFlowControl.none);
  //   serialPort.config = config;
  //   // print(serialPort.productId.toString());
  //   // print(serialPort.vendorId.toString());
  //   // print(serialPort.config.bits.toString());
  //   // print("port.config.cts.toString()");
  //   // print(serialPort.config.cts.toString());
  //   // print(serialPort.config.dsr.toString());
  //   // print(serialPort.config.dtr.toString());
  //   // print(serialPort.config.parity.toString());
  //   // print(serialPort.config.rts.toString());
  //   // print(serialPort.config.stopBits.toString());

  //   print(serialPort.config.baudRate.toString());

  //   // Uint8List list = port.read(100);
  //   // print(list);

  //   serialReader = SerialPortReader(serialPort);
  //   serialReader.stream.listen((samples) {
  //     // print('received: $samples');
  //     // return;
  //     bool first = true;
  //     List<double> visibleSamples = [];

  //     int tmp = 0;
  //     Uint8List byteArray = Uint8List(2);
  //     tempBuffIdx = cBuffIdx;
  //     for (int sample in samples) {
  //       // // if (sample > 128) sample -= 255;
  //       if (first) {
  //         byteArray[0] = sample;
  //       } else {
  //         byteArray[1] = sample;

  //         // ByteData byteData = ByteData.view(byteArray.buffer);
  //         // tmp = (byteData.getInt16(0, Endian.little));
  //         if (byteArray[0] > 128) {
  //           //[128.0, 122.0, 128.0, 123.0, 128.0, 124.0, 128.0, 125.0, 128.0, 126.0, 128.0, 127.0, 129.0, 0.0, 129.0, 1.0, 129.0, 2.0, 129.0, 3.0, 129.0, 4.0, 129.0, 5.0, 129.0, 6.0, 129.0, 7.0, 129.0, 8.0, 129.0, 9.0, 129.0, 10.0, 129.0, 11.0, 129.0, 12.0, 129.0, 13.0, 129.0, 14.0, 129.0, 15.0, 129.0, 16.0, 129.0, 17.0, 129.0, 18.0, 129.0, 19.0, 129.0, 20.0, 129.0, 21.0, 129.0, 22.0, 129.0, 23.0, 129.0, 24.0, 129.0, 25.0]
  //           tmp = 128 + sample;
  //         } else if (byteArray[1] > 128) {
  //           //[128.0, 122.0, 128.0, 123.0, 128.0, 124.0, 128.0, 125.0, 128.0, 126.0, 128.0, 127.0, 129.0, 0.0, 129.0, 1.0, 129.0, 2.0, 129.0, 3.0, 129.0, 4.0, 129.0, 5.0, 129.0, 6.0, 129.0, 7.0, 129.0, 8.0, 129.0, 9.0, 129.0, 10.0, 129.0, 11.0, 129.0, 12.0, 129.0, 13.0, 129.0, 14.0, 129.0, 15.0, 129.0, 16.0, 129.0, 17.0, 129.0, 18.0, 129.0, 19.0, 129.0, 20.0, 129.0, 21.0, 129.0, 22.0, 129.0, 23.0, 129.0, 24.0, 129.0, 25.0]
  //           tmp = 128 + byteArray[0];
  //         } else {
  //           if (byteArray[0] == 128) {
  //             tmp = byteArray[1];
  //           } else {
  //             tmp = byteArray[0];
  //           }
  //         }
  //         tempBuffIdx++;
  //         if (tempBuffIdx >= surfaceSize) {
  //           globalIdx++;
  //         }

  //         // print(tmp.toString() + " " + sample.toString());
  //         visibleSamples.add(-10 * tmp.toDouble());
  //         // int interleavedSignalIdx = cBuffIdx * 2;

  //         tmp = 0;
  //       }
  //       first = !first;
  //       // visibleSamples.add(sample.toDouble());
  //     }
  //     // print(visibleSamples);
  //     // // print("sending to isolate");
  //     // iSendPort.send(visibleSamples);
  //     iSendPort.send([cBuffIdx, visibleSamples, globalIdx]);
  //     cBuffIdx = (cBuffIdx + visibleSamples.length);
  //     if (cBuffIdx >= surfaceSize) {
  //       globalIdx++;
  //       cBuffIdx %= surfaceSize;
  //     }
  //   });

  //   _receiveQueue.rest.listen((curSamples) {
  //     cBuffDouble = List<double>.from(curSamples);
  //     // print(cBuffDouble);
  //     setState(() {});
  //   });
  // }

  void getMfiTest() async {
    double _sampleRate = 5000;
    List<int> envelopeSizes = [];
    int SEGMENT_SIZE = _sampleRate.toInt();
    int SIZE = NUMBER_OF_SEGMENTS * SEGMENT_SIZE;
    double size = SIZE.toDouble() * 2;
    unitInitializeEnvelope(
        1, allEnvelopes, envelopeSizes, size, SIZE, SIZE_LOGS2);
    int surfaceSize = ((_sampleRate * 60).floor()).floor();

    _isolate = await Isolate.spawn<List<dynamic>>(sampleBufferingEntryPoint, [
      _receivePort.sendPort,
      allEnvelopes,
      surfaceSize,
      [197]
    ]);
    iSendPort = await _receiveQueue.next;

    double innerWidth = MediaQuery.of(context).size.width;
    level = calculateLevel(10000, _sampleRate.toInt(), innerWidth, skipCounts);
    int skipCount = skipCounts[level];

    List<double> envelopeSamples = allEnvelopes[0][level];
    int divider = 60;
    int prevSegment = (envelopeSamples.length / divider).floor();

    cBuffDouble = List<double>.generate(prevSegment, (i) => 0);
    cBuff = List<double>.generate(prevSegment, (i) => 0);
    globalIdx = 0;
    int channelIdx = 0;

    Mfi.initMfi();
    Mfi.getDeviceStatusStream().listen((event) {
      print("Device Status Stream");
      print(event);
      alert(
        context,
        title: Text('Alert5'),
        content: Text(event.toString()),
        textOK: Text('Yes'),
      );
    });

    Mfi.getSpikeStatusStream().listen((samples) {
      print("Spike Status Stream");
      print(samples);
      bool first = true;
      List<double> visibleSamples = [];

      int tmp = 0;
      Uint8List byteArray = Uint8List(2);
      tempBuffIdx = cBuffIdx;
      for (int sample in samples) {
        // if (sample > 128) sample -= 255;
        if (first) {
          byteArray[0] = sample;
        } else {
          byteArray[1] = sample;

          ByteData byteData = ByteData.view(byteArray.buffer);
          tmp = (byteData.getInt16(0, Endian.little));
          visibleSamples.add(tmp.toDouble());
          // int interleavedSignalIdx = cBuffIdx * 2;

          tmp = 0;
        }
        first = !first;
        // visibleSamples.add(-50 * sample.toDouble());
      }
      iSendPort.send([cBuffIdx, visibleSamples, globalIdx]);
      cBuffIdx = (cBuffIdx + visibleSamples.length);
      if (cBuffIdx >= surfaceSize) {
        globalIdx++;
        cBuffIdx %= surfaceSize;
      }
    });

    _receiveQueue.rest.listen((curSamples) {
      cBuffDouble = List<double>.from(curSamples);
      setState(() {});
    });

    Mfi.setDeviceStatus("connected");
  }

  void getWebSerial() {
    js.context
        .callMethod('recordSerial', ['Flutter is calling upon JavaScript!']);
  }
}
