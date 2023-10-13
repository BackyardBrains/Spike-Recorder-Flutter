import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';
// import 'dart:js' as js;

import 'package:alert_dialog/alert_dialog.dart';
import 'package:async/async.dart';
import 'package:circular_buffer/circular_buffer.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_audio_waveforms/flutter_audio_waveforms.dart';
import 'package:fps_widget/fps_widget.dart';
import 'package:mfi/mfi.dart';

import 'package:mic_stream/mic_stream.dart';
import 'package:permission_handler/permission_handler.dart';
// import 'package:flutter_wasm/flutter_wasm.dart';
import 'package:srmobileapp/multiply.dart';
// import 'package:quick_usb/quick_usb.dart';

// if platform isWindows
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:winaudio/winaudio.dart';
import 'package:usb_serial/usb_serial.dart';

// import 'package:quick_usb/quick_usb.dart';
const SIZE_LOGS2 = 10;
const NUMBER_OF_SEGMENTS = 60;
const skipCounts = [1, 2, 4, 8, 16, 32, 64, 128, 256, 512];

int cBuffIdx = 0;
int tempBuffIdx = 0;
List<double> cBuff = [];
List<double> cBuffDouble = [];

int writeInteger = 0;
int numberOfFrames = 0;
int numberOfZeros = 0;
int lastWasZero = 0;

List<List<List<double>>> allEnvelopes = [];
int level = 6;
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
  int cBuffIdx = 0;
  int globalIdx = 0;

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
    // int cBuffIdx = arr[0];
    var samples = arr[1];
    // int globalIdx = arr[2];
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
          globalIdx++;
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

void serialBufferingEntryPoint(List<dynamic> values) {
  final iReceivePort = ReceivePort();
  SendPort sendPort = values[0];
  List<List<List<double>>> allEnvelopes = values[1];
  int surfaceSize = values[2];
  Uint8List rawCircularBuffer = values[3];
  String deviceType = values[4];
  Uint8List messagesBuffer = Uint8List(SIZE_OF_INPUT_HARDWARE_CIRC_BUFFER);

  int numberOfChannels = 1;

  int cBuffIdx = 0;
  int globalIdx = 0;
  int cBufHead = 0;
  int cBufTail = 0;

  bool weAreInsideEscapeSequence = false;
  int escapeSequenceDetectorIndex = 0;
  int messageBufferIndex = 0;

  List<int> escapeSequence = [255, 255, 1, 1, 129, 255];

  sendPort.send(iReceivePort.sendPort);
  // indexPort.send([cBuffHead,cbufTail]);

  iReceivePort.listen((Object? message) async {
    // List<dynamic> arr = message as List<dynamic>;
    // var samples = arr[1];
    List<int> samples = message as List<int>;
    // print(arr);
    // print("samples");
    // print(samples);

    int len = samples.length;
    int i = 0;
    for (i = 0; i < len; i++) {
      int sample = samples[i];

      if (weAreInsideEscapeSequence) {
        messagesBuffer[messageBufferIndex] = sample;
        messageBufferIndex++;
      } else {
        rawCircularBuffer[cBufHead++] = sample;
        //uint debugMSB  = ((uint)(buffer[i])) & 0xFF;

        if (cBufHead >= SIZE_OF_INPUT_HARDWARE_CIRC_BUFFER)
        // if(cBufHead>=CONFIG.ringBufferLength)
        {
          cBufHead = 0;
        }
      }

      Map<String, int> oBufHead = {"value": cBufHead};
      if (deviceType == "serial") {
        if (sample == 0) {
          if (lastWasZero == 1) {
            numberOfZeros++;
          }
          lastWasZero = 1;
        } else {
          lastWasZero = 0;
        }

        testEscapeSequence(
            sample & 0xFF,
            (((i - (numberOfZeros > 0 ? numberOfZeros + 1 : 0)) / 2) /
                    numberOfChannels -
                1),
            messagesBuffer,
            weAreInsideEscapeSequence,
            messageBufferIndex,
            escapeSequenceDetectorIndex,
            oBufHead);
        cBufHead = oBufHead["value"]!;
      } else {
        testEscapeSequence(
            sample,
            (((i) / 2) / numberOfChannels - 1).floor(),
            messagesBuffer,
            weAreInsideEscapeSequence,
            messageBufferIndex,
            escapeSequenceDetectorIndex,
            oBufHead);
        cBufHead = oBufHead["value"]!;
      }
    }
    int LSB;
    int MSB;
    bool haveData = true;
    bool weAlreadyProcessedBeginingOfTheFrame;
    int numberOfParsedChannels;
    int sample;

    while (haveData) {
      MSB = (rawCircularBuffer[cBufTail]) & 0xFF;
      bool additionalFlag = true;
      if (MSB > 127 && additionalFlag) //if we are at the begining of frame
      {
        weAlreadyProcessedBeginingOfTheFrame = false;
        numberOfParsedChannels = 0;
        if (checkIfHaveWholeFrame(rawCircularBuffer, cBufTail, cBufHead)) {
          numberOfFrames++;
          int idxChannelLoop = 0;
          while (true) {
            if (deviceType != "hid") {
              // console.log("SERIAL ? ",deviceType);
              MSB = (rawCircularBuffer[cBufTail]) & 0xFF;
              if (weAlreadyProcessedBeginingOfTheFrame && MSB > 127) {
                numberOfFrames--;
                break; //continue as if we have new frame
              }
            }

            MSB = (rawCircularBuffer[cBufTail]) & 0x7F;
            weAlreadyProcessedBeginingOfTheFrame = true;

            cBufTail++;
            if (cBufTail >= SIZE_OF_INPUT_HARDWARE_CIRC_BUFFER) {
              cBufTail = 0;
            }
            LSB = (rawCircularBuffer[cBufTail]) & 0xFF;
            if (LSB > 127) {
              numberOfFrames--;
              if (deviceType == 'hid') {
                return;
              } else {
                break;
              }
            }
            LSB = (rawCircularBuffer[cBufTail]) & 0x7F;

            MSB = MSB << 7;
            writeInteger = LSB | MSB;

            numberOfParsedChannels++;

            if (deviceType == 'hid') {
              if (numberOfParsedChannels > numberOfChannels) {
                break;
              }
            } else if (numberOfParsedChannels > numberOfChannels) {
              //std::cout<< "More channels than expected\n";
              // break;//continue as if we have new frame
              // return;//continue as if we have new frame
            }

            if (deviceType == 'hid') {
              sample = -((writeInteger - 512));
            } else {
              // if (deviceIds[0] == 4){
              //   sample =  (-(writeInteger - 8192)); // SpikeDesktop 448
              // }else{
              sample = -((writeInteger - 512)); // SpikeDesktop 448
              // }

            }

            // if (MyConfig[2] != -1){
            //   if (numberOfParsedChannels == 1 && !isStartRecording){
            //     isStartRecording = true
            //     console.log("Start Recording : ", -sample, currentIdxEnd, numberOfParsedChannels);
            //   }
            //   if (isStartRecording){
            //     if (flagChannelDisplays[numberOfParsedChannels-1] == 1){
            //       currentTempInt[currentIdxEnd++] = -sample;
            //     }else{
            //     }
            //   }
            // }else{
            //   isStartRecording = false;
            // }

            // arrMaxInt = allArrMaxInt[numberOfParsedChannels - 1];
            // envelopes = allEnvelopes[numberOfParsedChannels - 1];
            // _head = _arrHeadsInt[numberOfParsedChannels - 1];
            // envelopingSamples(_head, sample, envelopes);
            // print(sample.toDouble());
            envelopingSamples(cBuffIdx, sample.toDouble(), allEnvelopes[0],
                SIZE_LOGS2, skipCounts);
            cBuffIdx++;
            if (cBuffIdx == surfaceSize - 1) {
              cBuffIdx = 0;
              // _arrIsFullInt[numberOfParsedChannels-1]++;
              if (numberOfParsedChannels == 1) {
                // globalPositionCap[0]++;
                globalIdx++;
              }

              // isFull = true;
            }

            // const interleavedHeadSignalIdx = _head * 2;
            // arrMaxInt[interleavedHeadSignalIdx] = sample;
            // arrMaxInt[interleavedHeadSignalIdx + 1] = sample;

            // _head++;
            // if (_head == SIZE){
            //   _head = 0;
            //   _arrIsFullInt[numberOfParsedChannels-1]++;
            //   if (numberOfParsedChannels == 1) {
            //     globalPositionCap[0]++;
            //   }

            //   isFull = true;
            // }

            // _arrHeadsInt[numberOfParsedChannels-1] = _head;
            // if (numberOfParsedChannels == 1){
            //   if (drawState){
            //     if (drawState[DRAW_STATE.EVENT_FLAG] == 1){
            //       drawState[DRAW_STATE.EVENT_POSITION] = _arrHeadsInt[0];

            //       let ctr = drawState[DRAW_STATE.EVENT_COUNTER];
            //       eventsInt[ctr] = drawState[DRAW_STATE.EVENT_NUMBER];
            //       eventPositionInt[ctr] = _arrHeadsInt[0];
            //       eventGlobalPositionInt[ctr] = globalPositionCap[0] * SIZE + _head;
            //       eventsIdxInt[ctr] = drawState[DRAW_STATE.EVENT_NUMBER];
            //       ctr++;
            //       if ( ctr >= MAX_EVENT_MARKERS){
            //         ctr=ctr % MAX_EVENT_MARKERS;
            //         eventsCounterInt.fill(0);
            //         eventsInt.fill(0);
            //         eventPositionInt.fill(0);
            //         eventsPositionResultInt.fill(0);
            //       }
            //       eventsCounterInt[0]=ctr;

            //       drawState[DRAW_STATE.EVENT_COUNTER] = ctr;
            //       console.log("eventsCounter : ", ctr, "head : ", _head);
            //       console.log("Position : ", eventPositionInt);
            //       console.log("Result : ", eventPositionResultInt);

            //       drawState[DRAW_STATE.EVENT_FLAG] = 0;
            //     }
            //   }
            // }

            if (areWeAtTheEndOfFrame(rawCircularBuffer, cBufTail)) {
              break;
            } else {
              cBufTail++;
              if (cBufTail >= SIZE_OF_INPUT_HARDWARE_CIRC_BUFFER) {
                cBufTail = 0;
              }
            }
          }
        } else {
          haveData = false;
          // console.log("have data false");
          break;
        }
      }
      if (!haveData) {
        break;
      }
      cBufTail++;
      if (cBufTail >= SIZE_OF_INPUT_HARDWARE_CIRC_BUFFER) {
        cBufTail = 0;
      }

      if (cBufTail == cBufHead) {
        haveData = false;
        break;
      }
    }

    // samples.forEach((tmp) {
    //   // print("allEnvelopes 3");
    //   // print(tmp);
    //   try {
    //     envelopingSamples(
    //         cBuffIdx, tmp.toDouble(), allEnvelopes[0], SIZE_LOGS2, skipCounts);

    //     cBuffIdx++;
    //     if (cBuffIdx >= surfaceSize - 1) {
    //       cBuffIdx = 0;
    //     }
    //   } catch (err) {
    //     print("err");
    //     print(err);
    //     // print(cbuffIdx, surfaceSize, allEnvelopes[0]);
    //     // print("cBuffIdx");
    //     // print(cBuffIdx);
    //     // print(surfaceSize);
    //     // print(SIZE_LOGS2);
    //   }
    // });

    // // filter
    // print("level");
    // print(level);
    List<double> envelopeSamples = allEnvelopes[0][6];
    // List<double> envelopeSamples = [];
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
    // sendPort.send({
    //   "cBuffIdx": cBuffIdx,
    //   "cBufHead": cBufHead,
    //   "cBufTail": cBufTail,
    //   "data": cBuff,
    //   "globalIdx": globalIdx
    // });
    // sendPort.send([
    //   cBuffIdx,
    //   cBufHead,
    //   cBufTail,
    //   cBuff,
    //   globalIdx,
    // ]);
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

  // Platform.isWindows
  late SerialPort serialPort;
  late SerialPortReader serialReader;

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
      _counter++;
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

  void getMicrophoneData() async {
    // if (kIsWeb) {
    //   js.context['jsToDart'] = js2Dart;
    //   js.context['callbackErrorLog'] = callbackErrorLog;
    //   js.context['callbackAudioInit'] = callbackAudioInit;
    //   js.context['callbackOpenWavFile'] = callbackOpenWavFile;
    //   js.context['callbackOpeningFile'] = callbackOpeningFile;
    //   js.context['callbackIsOpeningWavFile'] = callbackIsOpeningWavFile;
    //   js.context['changeResetPlayback'] = changeResetPlayback;
    //   js.context['resetToAudio'] = resetToAudio;
    //   js.context['changeSampleRate'] = (params) {
    //     // sampleRate = params[0];
    //     // curSkipCounts = params[1];
    //     // curLevel = params[2];
    //   };

    //   js.context
    //       .callMethod('recordAudio', ['Flutter is calling upon JavaScript!']);
    //   return;
    // }

    if (Platform.isWindows) {
      print("isWINDOWS ");
      if (await Permission.microphone.request().isGranted) {
        // Either the permission was already granted before or the user just granted it.
      }

      double _sampleRate = 48000;
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
      level =
          calculateLevel(10000, _sampleRate.toInt(), innerWidth, skipCounts);
      int skipCount = skipCounts[level];

      List<double> envelopeSamples = allEnvelopes[0][level];
      int prevSegment = (envelopeSamples.length / divider).floor();

      cBuffDouble = List<double>.generate(prevSegment, (i) => 0);
      cBuff = List<double>.generate(prevSegment, (i) => 0);
      globalIdx = 0;
      int channelIdx = 0;

      _receiveQueue.rest.listen((curSamples) {
        cBuffDouble = List<double>.from(curSamples);
        setState(() {});
      });

      Winaudio.audioData().listen((samples) {
        // print("samples audio data : !!! ");
        // print(samples);

        bool first = true;
        List<double> visibleSamples = [];

        int tmp = 0;
        Uint8List byteArray = Uint8List(2);
        tempBuffIdx = cBuffIdx;
        for (int sample in samples) {
          if (first) {
            byteArray[0] = sample;
          } else {
            byteArray[1] = sample;

            ByteData byteData = ByteData.view(byteArray.buffer);
            tmp = (byteData.getInt16(0, Endian.little));
            visibleSamples.add(tmp.toDouble());

            tmp = 0;
          }
          first = !first;
        }
        iSendPort.send([cBuffIdx, visibleSamples, globalIdx]);
        cBuffIdx = (cBuffIdx + visibleSamples.length);
        if (cBuffIdx >= surfaceSize) {
          globalIdx++;
          cBuffIdx %= surfaceSize;
        }
      });

      Winaudio wa = new Winaudio();
      String? version = await wa.getPlatformVersion();
      print("version");
      print(version);
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

          tmp = 0;
        }
        first = !first;
      }
      // // print("sending to isolate");
      // iSendPort.send(visibleSamples);
      iSendPort.send([cBuffIdx, visibleSamples, globalIdx]);
      cBuffIdx = (cBuffIdx + visibleSamples.length);
      if (cBuffIdx >= surfaceSize) {
        globalIdx++;
        cBuffIdx %= surfaceSize;
      }
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
                        gain: 1000,
                        levelMedian: 300,
                        strokeWidth: 1,
                        eventMarkersNumber: [],
                        eventMarkersPosition: [],
                      )),
            Positioned(
                left: 0,
                top: 100,
                child: ElevatedButton(
                  onPressed: () {
                    getMfiTest();
                  },
                  child: Text("MFI Demo"),
                )),
            Positioned(
                left: 0,
                top: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (kIsWeb) {
                      getWebSerial();
                    } else {
                      // getRawSerial();
                      // print("getSerialParsing");
                      getSerialParsing();
                    }
                  },
                  child: Text("Serial Demo"),
                )),
            Positioned(
                right: 0,
                top: 50,
                child: ElevatedButton(
                  onPressed: () {
                    closeRawSerial();
                  },
                  child: Text("Close Serial Demo"),
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

  void initPorts() {
    // Platform.isWindows
    if (Platform.isWindows || Platform.isMacOS)
      availablePorts = SerialPort.availablePorts;

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
    initPorts();
  }

  //Platform.isWindows
  void closeRawSerial() async {
    serialReader.close();
    serialPort.close();
    serialPort.dispose();
  }

  void getRawSerial() async {
    // if (kIsWeb) {
    //   js.context['jsToDart'] = js2Dart;
    // }

    // cBuffIdx = 0;

    double _sampleRate = 10000;
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

    if (Platform.isAndroid) {
      List<UsbDevice> devices = await UsbSerial.listDevices();
      print(devices);

      UsbPort port;
      // alert(context,title: Text('Alert5'),content: Text(devices.toString()),textOK: Text('Yes'),);
      if (devices.length == 0) {
        return;
      }
      port = (await devices[0].create())!;

      bool openResult = await port.open();
      if (!openResult) {
        print("Failed to open");
        // alert(context,title: Text('Failed'),content: Text("Failed to open"),textOK: Text('Yes'),);
        return;
      }

      await port.setDTR(true);
      await port.setRTS(true);

      port.setPortParameters(
          222222, UsbPort.DATABITS_8, UsbPort.STOPBITS_1, UsbPort.PARITY_NONE);

      // print first result and close port.
      port.inputStream?.listen((Uint8List samples) {
        bool first = true;
        List<double> visibleSamples = [];

        int tmp = 0;
        Uint8List byteArray = Uint8List(2);
        tempBuffIdx = cBuffIdx;
        for (int sample in samples) {
          // // if (sample > 128) sample -= 255;
          if (first) {
            byteArray[0] = sample;
          } else {
            byteArray[1] = sample;

            // ByteData byteData = ByteData.view(byteArray.buffer);
            // tmp = (byteData.getInt16(0, Endian.little));
            if (byteArray[0] > 128) {
              //[128.0, 122.0, 128.0, 123.0, 128.0, 124.0, 128.0, 125.0, 128.0, 126.0, 128.0, 127.0, 129.0, 0.0, 129.0, 1.0, 129.0, 2.0, 129.0, 3.0, 129.0, 4.0, 129.0, 5.0, 129.0, 6.0, 129.0, 7.0, 129.0, 8.0, 129.0, 9.0, 129.0, 10.0, 129.0, 11.0, 129.0, 12.0, 129.0, 13.0, 129.0, 14.0, 129.0, 15.0, 129.0, 16.0, 129.0, 17.0, 129.0, 18.0, 129.0, 19.0, 129.0, 20.0, 129.0, 21.0, 129.0, 22.0, 129.0, 23.0, 129.0, 24.0, 129.0, 25.0]
              tmp = 128 + sample;
            } else if (byteArray[1] > 128) {
              //[128.0, 122.0, 128.0, 123.0, 128.0, 124.0, 128.0, 125.0, 128.0, 126.0, 128.0, 127.0, 129.0, 0.0, 129.0, 1.0, 129.0, 2.0, 129.0, 3.0, 129.0, 4.0, 129.0, 5.0, 129.0, 6.0, 129.0, 7.0, 129.0, 8.0, 129.0, 9.0, 129.0, 10.0, 129.0, 11.0, 129.0, 12.0, 129.0, 13.0, 129.0, 14.0, 129.0, 15.0, 129.0, 16.0, 129.0, 17.0, 129.0, 18.0, 129.0, 19.0, 129.0, 20.0, 129.0, 21.0, 129.0, 22.0, 129.0, 23.0, 129.0, 24.0, 129.0, 25.0]
              tmp = 128 + byteArray[0];
            } else {
              if (byteArray[0] == 128) {
                tmp = byteArray[1];
              } else {
                tmp = byteArray[0];
              }
            }
            // tempBuffIdx++;
            // if (tempBuffIdx >= surfaceSize) {
            //   globalIdx++;
            // }

            // print(tmp.toString() + " " + sample.toString());
            visibleSamples.add(-10 * tmp.toDouble());
            // int interleavedSignalIdx = cBuffIdx * 2;

            tmp = 0;
          }
          first = !first;
          // visibleSamples.add(sample.toDouble());
        }
        // // print("sending to isolate");
        // iSendPort.send(visibleSamples);
        iSendPort.send([cBuffIdx, visibleSamples, globalIdx]);
        // cBuffIdx = (cBuffIdx + visibleSamples.length);
        // if (cBuffIdx >= surfaceSize) {
        //   globalIdx++;
        //   cBuffIdx %= surfaceSize;
        // }

        // setState((){});
        // port.close();
      });

      _receiveQueue.rest.listen((curSamples) {
        cBuffDouble = List<double>.from(curSamples);
        setState(() {});
      });

      // var init = await QuickUsb.init();
      // List<UsbDevice>? _deviceList = await QuickUsb.getDeviceList();
      // // alert(context,title: Text('Alert1'),content: Text(_deviceList.toString()),textOK: Text('Yes'),);

      // var hasPermission = await QuickUsb.hasPermission(_deviceList.first);
      // if (!hasPermission){
      //   await QuickUsb.requestPermission(_deviceList.first);
      // }
      // hasPermission = await QuickUsb.hasPermission(_deviceList.first);
      // // alert(context,title: Text('Alert2'),content: Text(hasPermission.toString()),textOK: Text('Yes'),);
      // try{
      //   var openDevice = await QuickUsb.openDevice(_deviceList.first);
      //   // print('openDevice $openDevice');

      //   UsbConfiguration? _configuration = await QuickUsb.getConfiguration(0);
      //   // alert(context,title: Text('Alert3'),content: Text(_configuration.toString()),textOK: Text('Yes'),);

      //   var claimInterface = await QuickUsb.claimInterface(_configuration.interfaces[0]);
      //   // alert(context,title: Text('Alert4'),content: Text(claimInterface.toString()),textOK: Text('Yes'),);

      //   var endpoint = _configuration.interfaces[0].endpoints
      //       .firstWhere((e) => e.direction == UsbEndpoint.DIRECTION_IN);
      //   alert(context,title: Text('Alert5'),content: Text(endpoint.toString()),textOK: Text('Yes'),);

      //   var bulkTransferIn = await QuickUsb.bulkTransferIn(endpoint, 1024);
      //   alert(context,title: Text('Alert6'),content: Text(bulkTransferIn.toString()),textOK: Text('Yes'),);
      // }catch(err){
      //   alert(context,title: Text('Alert Err'),content: Text(err.toString()),textOK: Text('Yes'),);
      // }

      return;
    }
    //ELSE IF NOT ANDROID
    var address = availablePorts.last;
    serialPort = SerialPort(address);
    if (!serialPort.openReadWrite()) {
      print("SerialPort.lastError");
      print(SerialPort.lastError);
    }

    // print(serialPort.productId.toString());
    // print(serialPort.vendorId.toString());
    // print(serialPort.config.bits.toString());
    // print("port.config.cts.toString()");
    // print(serialPort.config.cts.toString());
    // print(serialPort.config.dsr.toString());
    // print(serialPort.config.dtr.toString());
    // print(serialPort.config.parity.toString());
    // print(serialPort.config.rts.toString());
    // print(serialPort.config.stopBits.toString());

    // serialPort.config.parity = 0;
    // serialPort.config.stopBits = 1;
    // serialPort.config.dtr = 1;
    // serialPort.config.rts = 1;
    // serialPort.config.bits = 8;
    // // serialPort.config.setFlowControl(SerialPortFlowControl.none);
    // serialPort.config.baudRate = 222222;

    SerialPortConfig config = SerialPortConfig();
    config.baudRate = 222222;
    config.stopBits = 1;
    config.dtr = 1;
    config.rts = 1;
    config.parity = 0;
    config.bits = 8;
    config.setFlowControl(SerialPortFlowControl.none);
    serialPort.config = config;
    // print(serialPort.productId.toString());
    // print(serialPort.vendorId.toString());
    // print(serialPort.config.bits.toString());
    // print("port.config.cts.toString()");
    // print(serialPort.config.cts.toString());
    // print(serialPort.config.dsr.toString());
    // print(serialPort.config.dtr.toString());
    // print(serialPort.config.parity.toString());
    // print(serialPort.config.rts.toString());
    // print(serialPort.config.stopBits.toString());

    print(serialPort.config.baudRate.toString());

    // Uint8List list = port.read(100);
    // print(list);

    serialReader = SerialPortReader(serialPort);
    serialReader.stream.listen((samples) {
      // print('received: $samples');
      // return;
      bool first = true;
      List<double> visibleSamples = [];

      int tmp = 0;
      Uint8List byteArray = Uint8List(2);
      tempBuffIdx = cBuffIdx;
      for (int sample in samples) {
        // // if (sample > 128) sample -= 255;
        if (first) {
          byteArray[0] = sample;
        } else {
          byteArray[1] = sample;

          // ByteData byteData = ByteData.view(byteArray.buffer);
          // tmp = (byteData.getInt16(0, Endian.little));
          if (byteArray[0] > 128) {
            //[128.0, 122.0, 128.0, 123.0, 128.0, 124.0, 128.0, 125.0, 128.0, 126.0, 128.0, 127.0, 129.0, 0.0, 129.0, 1.0, 129.0, 2.0, 129.0, 3.0, 129.0, 4.0, 129.0, 5.0, 129.0, 6.0, 129.0, 7.0, 129.0, 8.0, 129.0, 9.0, 129.0, 10.0, 129.0, 11.0, 129.0, 12.0, 129.0, 13.0, 129.0, 14.0, 129.0, 15.0, 129.0, 16.0, 129.0, 17.0, 129.0, 18.0, 129.0, 19.0, 129.0, 20.0, 129.0, 21.0, 129.0, 22.0, 129.0, 23.0, 129.0, 24.0, 129.0, 25.0]
            tmp = 128 + sample;
          } else if (byteArray[1] > 128) {
            //[128.0, 122.0, 128.0, 123.0, 128.0, 124.0, 128.0, 125.0, 128.0, 126.0, 128.0, 127.0, 129.0, 0.0, 129.0, 1.0, 129.0, 2.0, 129.0, 3.0, 129.0, 4.0, 129.0, 5.0, 129.0, 6.0, 129.0, 7.0, 129.0, 8.0, 129.0, 9.0, 129.0, 10.0, 129.0, 11.0, 129.0, 12.0, 129.0, 13.0, 129.0, 14.0, 129.0, 15.0, 129.0, 16.0, 129.0, 17.0, 129.0, 18.0, 129.0, 19.0, 129.0, 20.0, 129.0, 21.0, 129.0, 22.0, 129.0, 23.0, 129.0, 24.0, 129.0, 25.0]
            tmp = 128 + byteArray[0];
          } else {
            if (byteArray[0] == 128) {
              tmp = byteArray[1];
            } else {
              tmp = byteArray[0];
            }
          }
          tempBuffIdx++;
          if (tempBuffIdx >= surfaceSize) {
            globalIdx++;
          }

          // print(tmp.toString() + " " + sample.toString());
          visibleSamples.add(-10 * tmp.toDouble());
          // int interleavedSignalIdx = cBuffIdx * 2;

          tmp = 0;
        }
        first = !first;
        // visibleSamples.add(sample.toDouble());
      }
      // print(visibleSamples);
      // // print("sending to isolate");
      // iSendPort.send(visibleSamples);
      iSendPort.send([cBuffIdx, visibleSamples, globalIdx]);
      cBuffIdx = (cBuffIdx + visibleSamples.length);
      if (cBuffIdx >= surfaceSize) {
        globalIdx++;
        cBuffIdx %= surfaceSize;
      }
    });

    _receiveQueue.rest.listen((curSamples) {
      cBuffDouble = List<double>.from(curSamples);
      // print(cBuffDouble);
      setState(() {});
    });
  }

  void getSerialParsing() async {
    double _sampleRate = 10000;
    List<int> envelopeSizes = [];
    int SEGMENT_SIZE = _sampleRate.toInt();
    int SIZE = NUMBER_OF_SEGMENTS * SEGMENT_SIZE;
    double size = SIZE.toDouble() * 2;
    unitInitializeEnvelope(
        1, allEnvelopes, envelopeSizes, size, SIZE, SIZE_LOGS2);
    int surfaceSize = ((_sampleRate * 60).floor()).floor();

    String deviceType = 'serial';
    int numberOfChannels = 1;
    Uint8List rawCircularBuffer = Uint8List(SIZE_OF_INPUT_HARDWARE_CIRC_BUFFER);

    _isolate = await Isolate.spawn<List<dynamic>>(serialBufferingEntryPoint, [
      _receivePort.sendPort,
      allEnvelopes,
      surfaceSize,
      rawCircularBuffer,
      deviceType,
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

    if (Platform.isAndroid) {
      List<UsbDevice> devices = await UsbSerial.listDevices();
      print(devices);

      UsbPort port;
      // alert(context,title: Text('Alert5'),content: Text(devices.toString()),textOK: Text('Yes'),);
      if (devices.length == 0) {
        return;
      }
      port = (await devices[0].create())!;

      bool openResult = await port.open();
      if (!openResult) {
        print("Failed to open");
        // alert(context,title: Text('Failed'),content: Text("Failed to open"),textOK: Text('Yes'),);
        return;
      }

      await port.setDTR(true);
      await port.setRTS(true);

      port.setPortParameters(
          222222, UsbPort.DATABITS_8, UsbPort.STOPBITS_1, UsbPort.PARITY_NONE);

      // print first result and close port.
      port.inputStream?.listen((Uint8List samples) {
        List<int> visibleSamples = [];
        for (int sample in samples) {
          visibleSamples.add(sample);
        }

        iSendPort.send(visibleSamples);
      });

      _receiveQueue.rest.listen((curSamples) {
        cBuffDouble = List<double>.from(curSamples);
        setState(() {});
      });

      return;
    }
    //ELSE IF NOT ANDROID
    var address = availablePorts.last;
    serialPort = SerialPort(address);
    if (!serialPort.openReadWrite()) {
      print("SerialPort.lastError");
      print(SerialPort.lastError);
    }

    SerialPortConfig config = SerialPortConfig();
    config.baudRate = 222222;
    config.stopBits = 1;
    config.dtr = 1;
    config.rts = 1;
    config.parity = 0;
    config.bits = 8;
    config.setFlowControl(SerialPortFlowControl.none);
    serialPort.config = config;

    print(serialPort.config.baudRate.toString());

    serialReader = SerialPortReader(serialPort);
    serialReader.stream.listen((samples) {
      bool first = true;
      List<int> visibleSamples = [];
      for (int sample in samples) {
        visibleSamples.add(sample);
      }

      iSendPort.send(visibleSamples);
    });

    _receiveQueue.rest.listen((curSamples) {
      cBuffDouble = List<double>.from(curSamples);
      setState(() {});
    });
  }

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
    // js.context
    //     .callMethod('recordSerial', ['Flutter is calling upon JavaScript!']);
  }
}
