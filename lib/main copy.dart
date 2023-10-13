import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_audio_waveforms/flutter_audio_waveforms.dart';
import 'package:mic_stream/mic_stream.dart';
// import 'package:flutter_wasm/flutter_wasm.dart';

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
  sendPort.send(iReceivePort.sendPort);

  // enveloping
  // filter

  // String data = values[1];
  iReceivePort.listen((Object? message) async {
    sendPort.send(message);
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
  List<double> cBuff = [];
  List<double> cBuffDouble = [];
  int cBuffIdx = 0;

  StreamController<List<double>> simulateDataController =
      new StreamController<List<double>>();
  late StreamSubscription subscriptionSimulateData;

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
      _counter++;
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
    double? sampleRate = await MicStream.sampleRate;
    int? bitDepth = await MicStream.bitDepth;
    int? bufferSize = await MicStream.bufferSize;
    Stream<List<int>>? stream = await MicStream.microphone(
        audioSource: AudioSource.DEFAULT,
        sampleRate: 48000,
        channelConfig: ChannelConfig.CHANNEL_IN_MONO,
        audioFormat: AudioFormat.ENCODING_PCM_16BIT);

    // Start listening to the stream
    int surfaceSize =
        ((48000 * 60 * 2) / MediaQuery.of(context).size.width * 2).floor();
    // cBuff = CircularBuffer<int>(surfaceSize);
    cBuffDouble = List<double>.generate(surfaceSize, (i) => 0);
    cBuff = List<double>.generate(surfaceSize, (i) => 0);

    StreamSubscription? listener = stream?.listen((samples) async {
      bool first = true;
      List<int> visibleSamples = [];

      int tmp = 0;
      for (int sample in samples) {
        // print(sample);
        if (sample > 128) sample -= 255;
        if (first) {
          tmp = sample * 128;
        } else {
          tmp += sample;
          visibleSamples.add(tmp);

          tmp = 0;
        }
        first = !first;
      }
      int len = visibleSamples.length;
      for (int i = 0; i < len; i++) {
        cBuff[cBuffIdx] = visibleSamples[i].toDouble();
        cBuffIdx++;
        if (cBuffIdx >= surfaceSize) {
          cBuffIdx = 0;
        }
      }
      // print("visibleSamples");
      // print(visibleSamples);
      cBuffDouble = List<double>.from(cBuff);

      setState(() {});
    });

    setState(() {
      _counter++;
    });
  }

  void getMicrophoneData() async {
    double? sampleRate = await MicStream.sampleRate;
    int? bitDepth = await MicStream.bitDepth;
    int? bufferSize = await MicStream.bufferSize;
    // int SIZE = sampleRate!.toInt() * 60 * 2;
    // int SIZE = 48000 * 60 * 2;
    // cBuff = CircularBuffer<int>(SIZE);
    int surfaceSize =
        ((48000 * 60 * 2) / MediaQuery.of(context).size.width * 2).floor();
    // cBuff = CircularBuffer<int>(surfaceSize);
    cBuff = List<double>.generate(surfaceSize, (i) => 0);

    _isolate = await Isolate.spawn<List<dynamic>>(sampleBufferingEntryPoint, [
      _receivePort.sendPort,
      [197]
    ]);
    iSendPort = await _receiveQueue.next;
    // Init a new Stream
    Stream<List<int>>? stream = await MicStream.microphone(
        audioSource: AudioSource.DEFAULT,
        sampleRate: 48000,
        channelConfig: ChannelConfig.CHANNEL_IN_MONO,
        audioFormat: AudioFormat.ENCODING_PCM_16BIT);

    // Start listening to the stream
    StreamSubscription? listener = stream?.listen((samples) async {
      bool first = true;
      List<int> visibleSamples = [];
      int tmp = 0;
      for (int sample in samples) {
        if (sample > 128) sample -= 255;
        if (first) {
          tmp = sample * 128;
        } else {
          tmp += sample;
          visibleSamples.add(tmp);

          // localMax ??= visibleSamples.last;
          // localMin ??= visibleSamples.last;
          // localMax = max(localMax!, visibleSamples.last);
          // localMin = min(localMin!, visibleSamples.last);

          tmp = 0;
        }
        first = !first;
      }

      iSendPort.send(visibleSamples);
      // print(visibleSamples);
      // return await _receiveQueue.next;
    });

    _receiveQueue.rest.listen((curSamples) {
      // final curSamples = dataToSamples(samples as Uint8List);

      // cBuff.addAll(curSamples);
      for (int i = 0; i < curSamples.length; i++) {
        cBuff[cBuffIdx] = curSamples[i].toDouble();
        cBuffIdx++;
        if (cBuffIdx >= surfaceSize) {
          cBuffIdx = 0;
        }
      }
      // cBuffDouble = cBuff.map((i) => i.toDouble()).toList().cast<double>();
      cBuffDouble = cBuff.map((i) => i.toDouble()).toList().cast<double>();
      // cBuffDouble = cBuff.toList().cast<double>();
      setState(() {});
      // print(curSamples.length);
    });

    // _receivePort.asBroadcastStream().listen((Object? samples){
    //   print(dataToSamples(samples as Uint8List));
    // });

    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                        gain: 100000,
                        levelMedian: 300,
                        strokeWidth: 1,
                        eventMarkersNumber: [],
                        eventMarkersPosition: [],
                      )),
            Positioned(
                left: 0,
                bottom: 50,
                child: ElevatedButton(
                  onPressed: () {
                    getMicrophoneData();
                  },
                  child: Text("Continuous Isolate"),
                )),
            Positioned(
                right: 0,
                bottom: 50,
                child: ElevatedButton(
                  onPressed: () {
                    getStandardMicrophoneData();
                  },
                  child: Text("Standard Stream Listener"),
                )),
            Positioned(
                left: 0,
                bottom: 100,
                child: ElevatedButton(
                  onPressed: () {
                    getIsolateNativeData();
                  },
                  child: Text("Sim. Isolate Native data"),
                )),
            Positioned(
                left: 0,
                bottom: 150,
                child: ElevatedButton(
                  onPressed: () {
                    getNativeData();
                  },
                  child: Text("Simulate Native data"),
                )),
            Positioned(
                right: 0,
                bottom: 150,
                child: ElevatedButton(
                  onPressed: () {
                    getSimulateData();
                    Timer timer = Timer.periodic(
                        new Duration(milliseconds: 200), (Timer timer) {
                      List<double> randoms = getRandomList(600, 32768);
                      // print("randoms");
                      // print(randoms);
                      simulateDataController.sink.add(randoms);
                    });
                  },
                  child: Text("Simulate data"),
                )),
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
}
