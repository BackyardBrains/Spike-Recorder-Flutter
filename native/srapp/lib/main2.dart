import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';
import 'dart:js' as js;

import 'package:async/async.dart';
import 'package:circular_buffer/circular_buffer.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_audio_waveforms/flutter_audio_waveforms.dart';
import 'package:fps_widget/fps_widget.dart';
import 'package:mic_stream/mic_stream.dart';
// import 'package:flutter_wasm/flutter_wasm.dart';
import 'package:srmobileapp/multiply.dart';

const SIZE_LOGS2 = 10;
const NUMBER_OF_SEGMENTS = 60;
const skipCounts = [1, 2, 4, 8, 16, 32, 64, 128, 256, 512];

int cBuffIdx = 0;
int tempBuffIdx = 0;
List<double> cBuff = [];
List<double> cBuffDouble = [];

List<List<List<double>>> allEnvelopes = [];
int level = 8;
int divider = 6;
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
      envelopingSamples(
          cBuffIdx, tmp.toDouble(), allEnvelopes[0], SIZE_LOGS2, skipCounts);
      cBuffIdx++;
      if (cBuffIdx > surfaceSize) {
        cBuffIdx = 0;
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
      // home: const MyHomePage(title: 'Flutter Demo Home Page'),
      home: FPSWidget(
        child: MyHomePage(title: 'FPS Widget Demo'),
      ),
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
          tmp = multiply( 0.5,(byteData.getInt16(0, Endian.little)).toDouble() ).toInt();
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
      _counter++;
    });
  }
  js2Dart( params ) {
    cBuffDouble = (params[0]).toList().cast<double>();
    setState((){});
    
  }
  callbackErrorLog( params ){
    // _sendAnalyticsEvent( params[0], { "parameters" : params[1] } );
  }
  callbackAudioInit( params ) {
  }  
  callbackOpenWavFile( params ) {
  }  
  callbackOpeningFile( params ) {
  }  
  callbackIsOpeningWavFile( params ) {
  }  
  changeResetPlayback( params ) {
  }  
  resetToAudio( params ) {
  }  


  void getMicrophoneData() async {
    if (kIsWeb){
      js.context['jsToDart'] = js2Dart;
      js.context['callbackErrorLog'] = callbackErrorLog;
      js.context['callbackAudioInit'] = callbackAudioInit;
      js.context['callbackOpenWavFile'] = callbackOpenWavFile;
      js.context['callbackOpeningFile'] = callbackOpeningFile;
      js.context['callbackIsOpeningWavFile'] = callbackIsOpeningWavFile;
      js.context['changeResetPlayback'] = changeResetPlayback;
      js.context['resetToAudio'] = resetToAudio;
      js.context['changeSampleRate'] = ( params ){
        // sampleRate = params[0];
        // curSkipCounts = params[1];
        // curLevel = params[2];
      };
      

      js.context.callMethod('recordAudio', ['Flutter is calling upon JavaScript!']);
      return;
    }

    cBuffIdx = 0;

    double? sampleRate = await MicStream.sampleRate;
    int? bitDepth = await MicStream.bitDepth;
    int? bufferSize = await MicStream.bufferSize;
    // int SIZE = sampleRate!.toInt() * 60 * 2;
    // int SIZE = 48000 * 60 * 2;
    // cBuff = CircularBuffer<int>(SIZE);
    // Init a new Stream
    Stream<List<int>>? stream = await MicStream.microphone(
        audioSource: AudioSource.DEFAULT,
        sampleRate: 48000,
        channelConfig: ChannelConfig.CHANNEL_IN_MONO,
        audioFormat: AudioFormat.ENCODING_PCM_16BIT);

    double _sampleRate = await MicStream.sampleRate!;
    List<int> envelopeSizes = [];
    int SEGMENT_SIZE = _sampleRate.toInt();
    int SIZE = NUMBER_OF_SEGMENTS * SEGMENT_SIZE;
    double size = SIZE.toDouble() * 2;
    unitInitializeEnvelope(
        1, allEnvelopes, envelopeSizes, size, SIZE, SIZE_LOGS2);
    // print(" unitInitializeEnvelope :");
    // print(allEnvelopes);
    int surfaceSize = ((_sampleRate * 60).floor()).floor();
    // cBuff = CircularBuffer<int>(surfaceSize);

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
    int prevSegment = (envelopeSamples.length / divider).floor();

    cBuffDouble = List<double>.generate(prevSegment, (i) => 0);
    cBuff = List<double>.generate(prevSegment, (i) => 0);
    globalIdx = 0;
    int channelIdx = 0;

    // Start listening to the stream
    StreamSubscription? listener = stream?.listen((samples) async {
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

          cBuffIdx++;
          if (cBuffIdx >= surfaceSize) {
            globalIdx++;
            cBuffIdx = 0;
          }
          tmp = 0;
        }
        first = !first;
      }
      // // print("sending to isolate");
      // iSendPort.send(visibleSamples);
      iSendPort.send([cBuffIdx, visibleSamples, globalIdx]);
      // iSendPort.send({
      //   "cBuffIdx": cBuffIdx,
      //   "samples": visibleSamples,
      //   "envelopes": allEnvelopes,
      //   "surfaceSize": surfaceSize,
      // });
      // iSendPort.send(visibleSamples);
      // // print(visibleSamples);
      // // return await _receiveQueue.next;
      // cBuffDouble = List<double>.from(visibleSamples);
      // setState(() {});
    });

    _receiveQueue.rest.listen((curSamples) {
      // final curSamples = dataToSamples(samples as Uint8List);

      // cBuff.addAll(curSamples);
      // for (int i = 0; i < curSamples.length; i++) {
      //   cBuff[cBuffIdx] = curSamples[i].toDouble();
      //   cBuffIdx++;
      //   if (cBuffIdx >= surfaceSize) {
      //     cBuffIdx = 0;
      //   }
      // }
      // print("curSamples");
      // print(curSamples);
      // cBuffDouble = curSamples.map((i) => i.toDouble()).toList().cast<double>();
      // cBuffDouble = cBuff.map((i) => i.toDouble()).toList().cast<double>();
      // cBuffDouble = cBuff.toList().cast<double>();
      // print("curSamples");
      // print(curSamples);
      cBuffDouble = List<double>.from(curSamples);
      // print("cBuffDouble");
      // print(cBuffDouble);
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
                        gain: 10000,
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
                  child: Text("Continuous Audio Isolate"),
                )),
            Positioned(
                right: 0,
                bottom: 50,
                child: ElevatedButton(
                  onPressed: () {
                    getStandardMicrophoneData();
                  },
                  child: Text("Audio Stream Listener"),
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
