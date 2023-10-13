import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';
// import 'dart:js' as js;
import 'package:desktop_window/desktop_window.dart';
import 'package:http/http.dart' as https;
import 'package:alert_dialog/alert_dialog.dart';
import 'package:async/async.dart';
import 'package:circular_buffer/circular_buffer.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:fialogs/fialogs.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_audio_waveforms/flutter_audio_waveforms.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:fps_widget/fps_widget.dart';
import 'package:mfi/mfi.dart';

import 'package:mic_stream/mic_stream.dart';
import 'package:nativec/nativec.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:srmobileapp/firebase_options.dart';
// import 'package:flutter_wasm/flutter_wasm.dart';
import 'package:srmobileapp/library.dart';
import 'package:srmobileapp/dart_library.dart';
// import 'package:quick_usb/quick_usb.dart';
import 'package:gesture_x_detector/gesture_x_detector.dart';

// if platform isWindows
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:winaudio/winaudio.dart';
import 'package:usb_serial/usb_serial.dart';

import 'bloc/main_bloc.dart';
import 'dialog/custom_audio_dialog.dart';
import 'dialog/custom_serial_dialog.dart';
import 'utils/debouncers.dart';

const max_markers = 300;

int DISPLAY_CHANNEL_FIX = 1;
int DISPLAY_CHANNEL = 1;
var DEVICE_PRODUCT = {};
var DEVICE_CATALOG = {};
var CURRENT_DEVICE = {};
var EXPANSION_BOARD = {};

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
double divider = 6;
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

// PLAYING WAV
bool isPlayingWav = false;
bool isPaused = false;
Nativec nativec = Nativec();



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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await DesktopWindow.setWindowSize(Size(800, 600));
    await DesktopWindow.setMinWindowSize(Size(800, 600));
  }
  if (kIsWeb) {
    // await Firebase.initializeApp(options: DefaultFirebaseConfig.platformOptions);
  } else if (Platform.isWindows) {
    // await Firebase.initializeApp(options: {

    // });
  } else if (Platform.isAndroid) {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
  } else {
    await Firebase.initializeApp();
  }

  
  // _nativec.getPlatformVersion();
  // _nativec.init();
  runApp(const MyApp());
  // final data = File('fib.wasm').readAsBytesSync();

  // readFileAsync();
}

getScreenBuffers(
    c,
    globalIdx,
    int start,
    int to,
    int prevSegment,
    int surfaceWidth,
    head,
    offsetHead,
    globalPositionCap,
    halfwayCap,
    skipCount,
    int excess,
    cBuff,
    eventPositionResultInt,
    eventPositionInt,
    eventGlobalPositionInt,
    arrMarkers,
    List<double> envelopeSamples) {
  int bufferCount = 0;
  if (globalIdx == 0) {
    if (to - prevSegment < 0) {
      List<double> arr = allEnvelopes[c][level].sublist(0, to);
      // print(arr);
      bufferCount = arr.length;
      cBuff.setAll(prevSegment - arr.length, arr);
    } else {
      start = to - prevSegment;

      List<double> arr = allEnvelopes[c][level].sublist(start, to);
      bufferCount = arr.length;
      cBuff.setAll(prevSegment - arr.length, arr);
    }

    if (c == 0) {
      int bufferLength = prevSegment;
      int evtCounter = arrMarkers.length;
      eventPositionResultInt.fillRange(0, max_markers, 0);
      double offsetTail = offsetHead - bufferLength / 2 * skipCount;

      for (int ctr = 0; ctr < evtCounter; ctr++) {
        if (eventGlobalPositionInt[ctr] >= globalPositionCap) {
          int headPosition = (eventPositionInt[ctr] / skipCount * 2)
              .floor(); // headPosition in envelope realm
          if (headPosition < start) {
            eventPositionResultInt[ctr] = 0;
          } else //{
          if (headPosition >= start && headPosition <= to) {
            eventPositionResultInt[ctr] =
                (bufferLength - excess - (to - (headPosition))) /
                    bufferLength *
                    surfaceWidth;
          }
        }
      }
    }
  } else {
    if (start < 0) {
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
        } catch (err) {
          print("err signal dividing");
          print(err);
        }
        bufferCount = firstPartOfData.length + secondPartOfData.length;
      } else {
        cBuff.setAll(
            bufferLength - firstPartOfData.length - 1, firstPartOfData);
        bufferCount = firstPartOfData.length;
      }

      if (c == 0) {
        int evtCounter = arrMarkers.length;

        for (int ctr = 0; ctr < evtCounter; ctr++) {
          int headPosition = (eventPositionInt[ctr] / skipCount * 2)
              .floor(); // headPosition in envelope realm

          if (eventGlobalPositionInt[ctr] >= halfwayCap) {
            if (headPosition < start && headPosition > to) {
              eventPositionResultInt[ctr] = 0;
            } else {
              if (headPosition <= envelopeSamples.length &&
                  headPosition >= start) {
                // upper
                int counter = bufferLength -
                    (envelopeSamples.length -
                        headPosition +
                        secondPartOfData.length);
                eventPositionResultInt[ctr] =
                    counter / bufferLength * surfaceWidth;
                // console.log("upper ", eventPositionResultInt[ctr].toString());
              } else //{ // headPosition < to // below
              if (headPosition <= to && headPosition >= 0) {
                // console.log("below");
                int counter = bufferLength - excess - (to - (headPosition));
                eventPositionResultInt[ctr] =
                    counter / bufferLength * surfaceWidth;
              }
            }
          }
        }
      }
    } else {
      // print("start > 0");
      cBuff = List<double>.from(allEnvelopes[c][level].sublist(start, to));
      bufferCount = cBuff.length;

      if (c == 0) {
        int bufferLength = prevSegment;
        int evtCounter = arrMarkers.length;

        for (int ctr = 0; ctr < evtCounter; ctr++) {
          if (eventGlobalPositionInt[ctr] >= globalPositionCap) {
            int headPosition = (eventPositionInt[ctr] / skipCount * 2)
                .floor(); // headPosition in envelope realm
            if (headPosition < start) {
              eventPositionResultInt[ctr] = 0;
            } else if (headPosition >= start && headPosition <= to) {
              // eventPositionResultInt[ctr] = prevSegment - excess - ( to - (headPosition) );
              eventPositionResultInt[ctr] =
                  (bufferLength - excess - (to - (headPosition))) /
                      bufferLength *
                      surfaceWidth;
            }
          }
        }
      }
    }
  }
  return bufferCount;
}

void sampleBufferingEntryPoint(List<dynamic> values) {
  final iReceivePort = ReceivePort();
  SendPort sendPort = values[0];
  allEnvelopes = values[1];
  int cBufferSize = values[2];
  sendPort.send(iReceivePort.sendPort);
  int cBuffIdx = 0;
  int globalIdx = 0;
  List<int> arrHeads = List<int>.generate(6, (index) => 0);
  List<int> arrOffsetHeads = List<int>.generate(6, (index) => 0);
  List<String> arrMarkers = [];
  List<double> eventPositionInt =
      List<double>.generate(max_markers, (index) => 0.0);
  List<double> eventPositionResultInt =
      List<double>.generate(max_markers, (index) => 0.0);
  List<int> eventGlobalPositionInt =
      List<int>.generate(max_markers, (index) => 0);
  List<int> arrGlobalIdx = List<int>.generate(6, (index) => 0);
  int tempPrevSegment = 0;
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
    var rawSamples = arr[0];
    // int globalIdx = arr[2];
    // var surfaceSize = arr[2];
    var level = arr[1];
    var divider = arr[2];
    var numberOfChannels = arr[3];
    int CUR_START = arr[4];
    bool isPaused = arr[5];
    String curKey = arr[6];
    double surfaceWidth = arr[7];

    int maxSize = (allEnvelopes[0][0]).length;
    int globalPositionCap = (globalIdx * maxSize / 2).floor();

    List<List<double>> samples =
        getAllChannelsSample(rawSamples, numberOfChannels);

    // print("!=======");
    // print(level);
    // print(divider);
    // print(CUR_START);

    // print(arr[5]);
    // print("divider");
    // print(divider);
    // print("level");
    // print(level);

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

    if (!isPaused) {
      for (int c = 0; c < numberOfChannels; c++) {
        cBuffIdx = arrHeads[c];
        globalIdx = arrGlobalIdx[c];
        samples[c].forEach((tmp) {
          // print("allEnvelopes 3");
          // print(tmp);
          // print(nativec.gain(tmp.toDouble(), 10.0));
          try {
            envelopingSamples(cBuffIdx, nativec.gain(tmp.toDouble(), 10.0) , allEnvelopes[c],
                SIZE_LOGS2, skipCounts);

            cBuffIdx++;
            if (cBuffIdx >= cBufferSize - 1) {
              cBuffIdx = 0;
              globalIdx++;
            }
          } catch (err) {
            print("err");
            print(err);
          }
        });
        arrHeads[c] = cBuffIdx;
        arrGlobalIdx[c] = globalIdx;
      }

      if (curKey != "") {
        cBuffIdx = arrHeads[0];
        if (arrMarkers.length + 1 >= max_markers) {
          arrMarkers.clear();
        }
        int markerIdx = arrMarkers.length;
        eventPositionInt[markerIdx] = (cBuffIdx.toDouble());

        eventGlobalPositionInt[markerIdx] = globalPositionCap + cBuffIdx;

        // eventPositionResultInt[markerIdx] = (cBuffIdx.toDouble());
        arrMarkers.add(curKey);
      }
    }

    // // filter
    // // print("level");
    // // print(level);
    // print("samples");
    // print(samples);
    List<List<double>> buffers = [];
    const maxMinMultiplier = 2;
    const excess = 0;
    int halfwayCap =
        // globalPositionCap - ((globalPositionCap * 0.2) / currentCap).floor();
        globalPositionCap - (globalPositionCap * 0.2).floor();

    for (int c = 0; c < numberOfChannels; c++) {
      List<double> envelopeSamples = allEnvelopes[c][level];
      int prevSegment = (envelopeSamples.length / divider).floor();
      if (tempPrevSegment != prevSegment) {
        print("prevSegment " + level.toString());
        print(prevSegment);
        tempPrevSegment = prevSegment;
      }
      // print(envelopeSamples.length);
      // print(divider);
      List<double> cBuff =
          List<double>.generate(prevSegment, (i) => 0, growable: false);
      int rawHead = arrHeads[c];
      int rawOffsetHead = arrOffsetHeads[c];
      // print("CUR_START");
      // print(CUR_START);
      if (CUR_START != 0) {
        // print("CUR_START");
        // print(CUR_START);
        if (rawHead - CUR_START >= 0) {
          rawHead = rawHead - (CUR_START);
          if (rawHead > cBuffIdx) {
            rawHead = cBuffIdx;
          }
          // print("cBuffIdx");
          // print(cBuffIdx);
          // print(rawHead);
          // rawOffsetHead = rawOffsetHead - (CUR_START) ;
        } else {
          // print("zero");
          // print(rawHead - CUR_START);
          // print(rawHead);
          // print(CUR_START);
        }
        // head = head - (CUR_START as int) ;
        // offsetHead = offsetHead - Math.floor(zoomHorizontalDifference) ;
      }
      int skipCount = skipCounts[level];
      int head = (rawHead / skipCount).floor();
      int offsetHead = (rawOffsetHead).floor();

      int interleavedIdx = head * 2;
      int start = interleavedIdx - prevSegment;
      int to = interleavedIdx;

      if (globalIdx == 0) {
        if (to - prevSegment < 0) {
          List<double> arr = allEnvelopes[c][level].sublist(0, to);
          // print(arr);
          cBuff.setAll(prevSegment - arr.length, arr);
        } else {
          start = to - prevSegment;
          // print("----@---");
          // print(start);
          // print(to);
          // print(prevSegment);

          List<double> arr = allEnvelopes[c][level].sublist(start, to);
          cBuff.setAll(prevSegment - arr.length, arr);
        }

        if (c == 0) {
          int bufferLength = prevSegment;
          int evtCounter = arrMarkers.length;
          eventPositionResultInt.fillRange(0, max_markers, 0);
          double offsetTail = offsetHead - bufferLength / 2 * skipCount;

          for (int ctr = 0; ctr < evtCounter; ctr++) {
            if (eventGlobalPositionInt[ctr] >= globalPositionCap) {
              int headPosition = (eventPositionInt[ctr] / skipCount * 2)
                  .floor(); // headPosition in envelope realm
              if (headPosition < start) {
                eventPositionResultInt[ctr] = 0;
              } else //{
              if (headPosition >= start && headPosition <= to) {
                eventPositionResultInt[ctr] =
                    (bufferLength - excess - (to - (headPosition))) /
                        bufferLength *
                        surfaceWidth;
              }
            }
          }
          // print("eventPositionResultInt");
          // print(eventPositionResultInt);

          // for ( int ctr = 0; ctr < evtCounter; ctr++ ){
          //   if ( offsetTail < 0 ) offsetTail = 0;

          //   if (eventGlobalPositionInt[ctr] < offsetTail){
          //     eventPositionResultInt[ctr] = 0;
          //   }else
          //   if (eventGlobalPositionInt[ctr] >= offsetTail && eventGlobalPositionInt[ctr] <= offsetHead){
          //     // eventPositionResultInt[ctr] = ( bufferLength - excess - (to - (markerPosition)) ) / bufferLength * vm.drawSurfaceWidth;
          //     // eventPositionResultInt[ctr] = ( bufferLength - excess - (bufferLength - (markerPosition)) ) / bufferLength * vm.drawSurfaceWidth;
          //     int posMarker = ( (offsetHead - eventGlobalPositionInt[ctr] ) /skipCount * maxMinMultiplier ).floor();
          //     // print("posMarker");
          //     // print(posMarker);
          //     // print(( bufferLength - excess - posMarker ) / bufferLength * surfaceWidth);
          //     eventPositionResultInt[ctr] = ( bufferLength - excess - posMarker ) / bufferLength * surfaceWidth;
          //   }else
          //   if (eventGlobalPositionInt[ctr] > offsetHead){
          //     eventPositionResultInt[ctr] = 0;
          //   }
          //   // print("markers : ");
          //   // print(eventPositionResultInt);

          // }

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
            } catch (err) {
              print("err signal dividing");
              print(err);
            }
          } else {
            cBuff.setAll(
                bufferLength - firstPartOfData.length - 1, firstPartOfData);
          }

          if (c == 0) {
            int evtCounter = arrMarkers.length;

            for (int ctr = 0; ctr < evtCounter; ctr++) {
              int headPosition = (eventPositionInt[ctr] / skipCount * 2)
                  .floor(); // headPosition in envelope realm

              if (eventGlobalPositionInt[ctr] >= halfwayCap) {
                if (headPosition < start && headPosition > to) {
                  eventPositionResultInt[ctr] = 0;
                } else {
                  if (headPosition <= envelopeSamples.length &&
                      headPosition >= start) {
                    // upper
                    int counter = bufferLength -
                        (envelopeSamples.length -
                            headPosition +
                            secondPartOfData.length);
                    eventPositionResultInt[ctr] =
                        counter / bufferLength * surfaceWidth;
                    // console.log("upper ", eventPositionResultInt[ctr].toString());
                  } else //{ // headPosition < to // below
                  if (headPosition <= to && headPosition >= 0) {
                    // console.log("below");
                    int counter = bufferLength - excess - (to - (headPosition));
                    eventPositionResultInt[ctr] =
                        counter / bufferLength * surfaceWidth;
                  }
                }
              }
            }
          }
        } else {
          // print("start > 0");
          cBuff = List<double>.from(allEnvelopes[c][level].sublist(start, to));

          if (c == 0) {
            int bufferLength = prevSegment;
            int evtCounter = arrMarkers.length;

            for (int ctr = 0; ctr < evtCounter; ctr++) {
              if (eventGlobalPositionInt[ctr] >= globalPositionCap) {
                int headPosition = (eventPositionInt[ctr] / skipCount * 2)
                    .floor(); // headPosition in envelope realm
                if (headPosition < start) {
                  eventPositionResultInt[ctr] = 0;
                } else if (headPosition >= start && headPosition <= to) {
                  // eventPositionResultInt[ctr] = prevSegment - excess - ( to - (headPosition) );
                  eventPositionResultInt[ctr] =
                      (bufferLength - excess - (to - (headPosition))) /
                          bufferLength *
                          surfaceWidth;
                }
              }
            }
          }
        }
      }
      buffers.add(cBuff);
      // print("cBuff.length " + c.toString());
      // print(cBuff.length);
    }

    // print("cBuff.length");
    // print("cBuff.length");
    // print(level);
    // print(cBuff.length);
    // print(start);
    // print(to);
    // print("buffers[1]");
    // print(buffers[1]);
    sendPort.send([buffers, arrHeads[0], eventPositionResultInt]);
    // List<double> data =
    //     List.generate(samples.length, (index) => index.toDouble());
    // sendPort.send(samples);
  });
}

void serialBufferingEntryPoint(List<dynamic> values) {
  final iReceivePort = ReceivePort();
  SendPort sendPort = values[0];
  List<List<List<double>>> allEnvelopes = values[1];
  int cBufferSize = values[2];
  Uint8List rawCircularBuffer = values[3];
  String deviceType = values[4];
  // print(values[5]);
  DEVICE_CATALOG = values[5];
  // iReceiveDeviceInfoPort = values[6];
  deviceInfoPort = values[6];

  Uint8List messagesBuffer = Uint8List(SIZE_OF_INPUT_HARDWARE_CIRC_BUFFER);

  int numberOfChannels = 1;
  //NEED to be an array
  int cBuffIdx = 0;
  int globalIdx = 0;
  List<int> arrHeads = List<int>.generate(6, (index) => 0);
  List<int> arrOffsetHeads = List<int>.generate(6, (index) => 0);
  List<String> arrMarkers = [];
  List<double> eventPositionInt =
      List<double>.generate(max_markers, (index) => 0.0);
  List<double> eventPositionResultInt =
      List<double>.generate(max_markers, (index) => 0.0);
  List<int> eventGlobalPositionInt =
      List<int>.generate(max_markers, (index) => 0);
  List<int> arrGlobalIdx = List<int>.generate(6, (index) => 0);

  int cBufHead = 0;
  int cBufTail = 0;
  MainBloc deviceBloc = MainBloc();

  bool weAreInsideEscapeSequence = false;
  int escapeSequenceDetectorIndex = 0;
  int messageBufferIndex = 0;

  List<int> escapeSequence = [255, 255, 1, 1, 129, 255];

  sendPort.send(iReceivePort.sendPort);

  iReceivePort.listen((Object? message) async {
    List<dynamic> arr = message as List<dynamic>;
    List<int> samples = arr[0] as List<int>;
    var level = arr[1];
    var divider = arr[2];
    var deviceChannel = arr[3];
    // print('deviceChannel');
    // print(deviceChannel);
    var _sampleRate = arr[4];
    var _maxSampleRate = arr[5];
    int CUR_START = arr[6];
    bool isPaused = arr[7];
    String curKey = arr[8];
    double surfaceWidth = arr[9];
    int maxSize = (allEnvelopes[0][0]).length;
    int globalPositionCap = (globalIdx * maxSize / 2).floor();

    numberOfChannels = deviceChannel;
    if (cBuffIdx == -1) {
      cBuffIdx = 0;
      // print("reset CBUFFIDX");
      // print(cBuffIdx);
      final maxChannels = max(numberOfChannels, 6);
      for (int c = 0; c < maxChannels; c++) {
        for (int l = 0; l < skipCounts.length; l++) {
          allEnvelopes[c][l].clear();
        }
      }
    }

    if (!isPaused) {
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

        Map<String, dynamic> oBufHead = {
          "value": cBufHead,
          "weAreInsideEscapeSequence": weAreInsideEscapeSequence
        };
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
          weAreInsideEscapeSequence = oBufHead["weAreInsideEscapeSequence"]!;
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
          weAreInsideEscapeSequence = oBufHead["weAreInsideEscapeSequence"]!;
        }
      }
      int LSB;
      int MSB;
      bool haveData = true;
      bool weAlreadyProcessedBeginingOfTheFrame;
      int numberOfParsedChannels;
      int sample;
      // String deviceType = 'serial';

      Map<String, dynamic> map = {
        'cBufTail': cBufTail,
        'numberOfParsedChannels': 0,
        'numberOfChannels': deviceChannel,
        'numberOfFrames': numberOfFrames,
        'cBufHead': cBufHead,
        'deviceType': deviceType,
        // 'cBuffIdx': cBuffIdx,
        'globalIdx': globalIdx,
        'arrHeads': arrHeads,
      };

      serialParsing(rawCircularBuffer, allEnvelopes, map, cBufferSize,
          SIZE_LOGS2, skipCounts);
      cBufTail = map['cBufTail'];
      numberOfParsedChannels = map['numberOfParsedChannels'];
      numberOfChannels = map['numberOfChannels'];
      numberOfFrames = map['numberOfFrames'];
      cBufHead = map['cBufHead'];
      deviceType = map['deviceType'];
      // cBuffIdx = map['cBuffIdx'];
      globalIdx = map['globalIdx'];
      arrHeads = map['arrHeads'];

      if (curKey != "") {
        cBuffIdx = arrHeads[0];
        if (arrMarkers.length + 1 >= max_markers) {
          arrMarkers.clear();
        }
        int markerIdx = arrMarkers.length;
        eventPositionInt[markerIdx] = (cBuffIdx.toDouble());
        eventGlobalPositionInt[markerIdx] = globalPositionCap + cBuffIdx;
        arrMarkers.add(curKey);
      }
    }

    // level = 7;
    // int deviceChannel = 2;
    List<dynamic> buffers = [];
    const excess = 0;
    int halfwayCap =
        // globalPositionCap - ((globalPositionCap * 0.2) / currentCap).floor();
        globalPositionCap - (globalPositionCap * 0.2).floor();
    for (int c = 0; c < deviceChannel; c++) {
      List<double> envelopeSamples = allEnvelopes[c][level];
      double factor = _sampleRate / _maxSampleRate;
      int bufferLength =
          (_sampleRate * 60 / divider * 2 / skipCounts[level]).floor();
      List<double> cBuff = List<double>.generate(bufferLength, (i) => 0);
      int prevSegment = (envelopeSamples.length / divider * factor).floor();
      // print(bufferLength.toString() + " VS " + (prevSegment).toString());
      int rawHead = arrHeads[c];
      int rawOffsetHead = arrOffsetHeads[c];
      if (CUR_START != 0) {
        if (rawHead - CUR_START >= 0) {
          rawHead = rawHead - (CUR_START);
        } else {
          print("rawHead - Curstart <= 0");
        }
      }

      int skipCount = skipCounts[level];
      // int cBuffHead = arrHeads[c];
      // int head = (cBuffHead / skipCount).floor();
      int head = (rawHead / skipCount).floor();
      int offsetHead = (rawOffsetHead).floor();

      int interleavedIdx = head * 2;
      int start = interleavedIdx - prevSegment;
      int to = interleavedIdx;
      int nearFull = head * 2 + prevSegment;
      // print("Zerial Level : " + level.toString());

      if (globalIdx == 0) {
        if (start < 0) start = 0;
        List<double> arr = allEnvelopes[c][level].sublist(start, to);

        if (arr.length < bufferLength) {
          // if (to-prevSegment < bufferLength) {
          // print(arr);
          cBuff.setAll(bufferLength - arr.length - 1, arr);
        } else {
          // start = to - bufferLength;
          cBuff.setAll(0, arr);
        }

        if (c == 0) {
          int bufferLength = prevSegment;
          int evtCounter = arrMarkers.length;
          eventPositionResultInt.fillRange(0, max_markers, 0);
          double offsetTail = offsetHead - bufferLength / 2 * skipCount;

          for (int ctr = 0; ctr < evtCounter; ctr++) {
            if (eventGlobalPositionInt[ctr] >= globalPositionCap) {
              int headPosition = (eventPositionInt[ctr] / skipCount * 2)
                  .floor(); // headPosition in envelope realm
              if (headPosition < start) {
                eventPositionResultInt[ctr] = 0;
              } else //{
              if (headPosition >= start && headPosition <= to) {
                eventPositionResultInt[ctr] =
                    (bufferLength - excess - (to - (headPosition))) /
                        bufferLength *
                        surfaceWidth;
              }
            }
          }
        }
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

          if (c == 0) {
            int evtCounter = arrMarkers.length;

            for (int ctr = 0; ctr < evtCounter; ctr++) {
              int headPosition = (eventPositionInt[ctr] / skipCount * 2)
                  .floor(); // headPosition in envelope realm

              if (eventGlobalPositionInt[ctr] >= halfwayCap) {
                if (headPosition < start && headPosition > to) {
                  eventPositionResultInt[ctr] = 0;
                } else {
                  if (headPosition <= envelopeSamples.length &&
                      headPosition >= start) {
                    // upper
                    int counter = bufferLength -
                        (envelopeSamples.length -
                            headPosition +
                            secondPartOfData.length);
                    eventPositionResultInt[ctr] =
                        counter / bufferLength * surfaceWidth;
                    // console.log("upper ", eventPositionResultInt[ctr].toString());
                  } else //{ // headPosition < to // below
                  if (headPosition <= to && headPosition >= 0) {
                    // console.log("below");
                    int counter = bufferLength - excess - (to - (headPosition));
                    eventPositionResultInt[ctr] =
                        counter / bufferLength * surfaceWidth;
                  }
                }
              }
            }
          }
        } else {
          // print("start > 0");
          cBuff = List<double>.from(allEnvelopes[c][level].sublist(start, to));
          if (c == 0) {
            int bufferLength = prevSegment;
            int evtCounter = arrMarkers.length;

            for (int ctr = 0; ctr < evtCounter; ctr++) {
              if (eventGlobalPositionInt[ctr] >= globalPositionCap) {
                int headPosition = (eventPositionInt[ctr] / skipCount * 2)
                    .floor(); // headPosition in envelope realm
                if (headPosition < start) {
                  eventPositionResultInt[ctr] = 0;
                } else if (headPosition >= start && headPosition <= to) {
                  // eventPositionResultInt[ctr] = prevSegment - excess - ( to - (headPosition) );
                  eventPositionResultInt[ctr] =
                      (bufferLength - excess - (to - (headPosition))) /
                          bufferLength *
                          surfaceWidth;
                }
              }
            }
          }
        }
      }
      buffers.add(cBuff);
    }

    sendPort.send([buffers, arrHeads[0], eventPositionResultInt]);
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
      home: const MyHomePage(title: 'Spike Recorder Flutter'),
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
  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static FirebaseAnalyticsObserver observer =
      FirebaseAnalyticsObserver(analytics: analytics);

  bool isFeedback = false;

  double surfaceWidth = 0;

  int CURRENT_START = 0;

  List<double> markersData = [];

  List<int> globalMarkers = [];
  String currentKey = "";

  // bool isZoomingWhilePlaying = false;

  Future<void> _sendAnalyticsEvent(eventName, params) async {
    await analytics.logEvent(
      name: eventName,
      parameters: params,
      // parameters: <String, dynamic>{
      //   'string': 'string',
      //   'int': 42,
      //   'long': 12345678910,
      //   'double': 42.0,
      //   // Only strings and numbers (ints & doubles) are supported for GA custom event parameters:
      //   // https://developers.google.com/analytics/devguides/collection/analyticsjs/custom-dims-mets#overview
      //   'bool': true.toString(),
      //   'items': [itemCreator()]
      // },
    );
  }

  String versionNumber = '1.2.1';
  int isOpeningFile = 0;
  // int _counter = 0;

  int extraChannels = 0;
  int minChannels = 0;
  int maxChannels = 0;

  int localChannel = 1;

  double prevY = 0.0;

  List<double> channelGains = [10000, 10000, 10000, 10000, 10000, 10000];
  List<double> channelZoom = [10000, 10000, 10000, 10000, 10000, 10000];

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
  List<List<double>> channelsData = [[], []];

  var horizontalDiff = 0;

  num timeScale = 10000; //10ms to 10 seconds
  num curTimeScaleBar = 1000; //10ms to 10 seconds
  num curSkipCounts = 256;
  num curFps = 30;
  int sampleRate = 48000;
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

  // late WaveformData sampleData = WaveformData(
  //     version: 1,
  //     channels: 1,
  //     sampleRate: 44100,
  //     sampleSize: 1,
  //     bits: 1,
  //     length: 1034,
  //     data: []);
  // late List<WaveformData> channels;

  // List<_ChartData> chartLiveData = [];

  // ChartSeriesController? _chartSeriesController;

  double maxAxis = 441;

  double curLevel = 0;
  List<int> lblTimescale = [10, 40, 80, 160, 320, 625, 1250, 2500, 5000, 10000];
  List<int> arrTimescaleBar = [
    10000,
    5000,
    2500,
    1250,
    625,
    320,
    160,
    80,
    40,
    10
  ];
  List<double> arrTimeScale = [0.1, 1, 10, 50, 100, 500, 1000, 5000, 10000];
  List<double> myArrTimescale = [];

  late TutorialCoachMark tutorialCoachMark;
  List<TargetFocus> targets = <TargetFocus>[];
  // GlobalKey keyTutorial = GlobalKey();
  GlobalKey keyTutorialNavigation = GlobalKey();
  GlobalKey keyTutorialAudio = GlobalKey();
  GlobalKey keyTutorialAudioLevel = GlobalKey();
  GlobalKey keyTutorialAudioGainPlus = GlobalKey();
  GlobalKey keyTutorialAudioGainMinus = GlobalKey();
  GlobalKey keyTutorialSerial = GlobalKey();
  GlobalKey keyTutorialHid = GlobalKey();
  GlobalKey keyTutorialSetting = GlobalKey();
  GlobalKey keyTutorialTimescale = GlobalKey();
  GlobalKey keyTutorialEnd = GlobalKey();

  final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
  Map<String, dynamic> _deviceData = <String, dynamic>{};

  // THIS IS PER Circular buffer
  List<double> arrScaleBar = [
    0.1,
    0.1098901099,
    0.1219512195,
    0.1369863014,
    0.15625,
    0.1818181818,
    0.2173913043,
    0.2702702703,
    0.3571428571,
    0.5263157895,
    1,
    1.098901099,
    1.219512195,
    1.369863014,
    1.5625,
    1.818181818,
    2.173913043,
    2.702702703,
    3.571428571,
    5.263157895,
    10,
    10.86956522,
    11.9047619,
    13.15789474,
    14.70588235,
    16.66666667,
    19.23076923,
    22.72727273,
    27.77777778,
    35.71428571,
    50,
    52.63157895,
    55.55555556,
    58.82352941,
    62.5,
    66.66666667,
    71.42857143,
    76.92307692,
    83.33333333,
    90.90909091,
    100,
    108.6956522,
    119.047619,
    131.5789474,
    147.0588235,
    166.6666667,
    192.3076923,
    227.2727273,
    277.7777778,
    357.1428571,
    500,
    526.3157895,
    555.5555556,
    588.2352941,
    625,
    666.6666667,
    714.2857143,
    769.2307692,
    833.3333333,
    909.0909091,
    1000,
    1086.956522,
    1190.47619,
    1315.789474,
    1470.588235,
    1666.666667,
    1923.076923,
    2272.727273,
    2777.777778,
    3571.428571,
    5000,
    5263.157895,
    5555.555556,
    5882.352941,
    6250,
    6666.666667,
    7142.857143,
    7692.307692,
    8333.333333,
    9090.909091,
    10000,
  ];

  final SIZE_LOGS2 = 10;
  final NUMBER_OF_SEGMENTS = 60;
  final SEGMENT_SIZE = 44100;
  int SIZE = 0;

  // List<int> arrCounts = [32, 64, 128, 256, 512, 1024, 2048, 4096, 8192, 16384];
  ScaleUpdateDetails scaleDetails = ScaleUpdateDetails();
  late DragDownDetails dragDownDetails;
  late var dragDetails;
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
    "strokeOptions": [1.00, 1.25, 1.5, 1.75, 2.00],
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

  Debouncer debouncer = Debouncer(milliseconds: 3);
  Debouncer debouncerScale = Debouncer(milliseconds: 30);
  Debouncer debouncerPlayback = Debouncer(milliseconds: 300);

  bool isLoadingFile = false;

  bool isShowingResetButton = true;

  bool isShowingTimebar = true;

  bool initFPS = true;

  Positioned feedbackButton = new Positioned(child: Container());
  Positioned openFileButton = new Positioned(child: Container());
  Positioned lastPositionButton = new Positioned(child: Container());
  Positioned settingDialogButton = new Positioned(child: Container());

  int _counter = 0;
  ReceivePort _receivePort = ReceivePort();
  ReceivePort _receiveAudioPort = ReceivePort();
  ReceivePort iReceiveDeviceInfoPort = ReceivePort();
  ReceivePort iReceiveExpansionDeviceInfoPort = ReceivePort();
  late SendPort iSendPort;
  late SendPort iSendAudioPort;
  late var _isolate;
  late StreamQueue _receiveQueue = StreamQueue(_receivePort);
  late StreamQueue _receiveAudioQueue = StreamQueue(_receiveAudioPort);
  // CircularBuffer cBuff = CircularBuffer(2);

  StreamController<List<double>> simulateDataController =
      new StreamController<List<double>>();
  late StreamSubscription subscriptionSimulateData;

  // Platform.isWindows
  late SerialPort serialPort;
  late SerialPortReader serialReader;

  // Platform.isAndroid
  late UsbPort port;

  StreamSubscription<List<int>>? audioListener;

  StreamSubscription<dynamic>? winAudioSubscription;

  StreamSubscription<dynamic>? audioQueueSubscription;

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
    Stream<List<int>>? stream =
        await MicStream.microphone(sampleRate: sampleRate);
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

  js2Dart(params) {
    cBuffDouble = (params[0]).toList().cast<double>();
    setState(() {});
  }

  callbackErrorLog(params) {
    // _sendAnalyticsEvent( params[0], { "parameters" : params[1] } );
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
    if (kIsWeb) {
      // js.context.callMethod('setFlagChannelDisplay', [
      //   settingParams["flagDisplay1"],
      //   settingParams["flagDisplay2"],
      //   settingParams["flagDisplay3"],
      //   settingParams["flagDisplay4"],
      //   settingParams["flagDisplay5"],
      //   settingParams["flagDisplay6"]
      // ]);
    } else {}
    setState(() {});
  }

  setZoomLevel(data) async {
    int realTimeLevel;
    double innerWidth = MediaQuery.of(context).size.width;
    int skipCount = skipCounts[level];
    int curLevel;
    int transformedScale;
    var row = data;

    if ((isPlaying != 2 && isOpeningFile == 0) ||
        (isPlayingWav && isPlaying == 2)) {
      // isZoomingWhilePlaying = true;
      print("running");

      // when zoomed and play again, and zoom, it needs to show the current data
      // CURRENT_START = 0;
      curLevel = calculateLevel(
          row["timeScaleBar"], sampleRate, innerWidth, skipCounts);
      // timeScaleBar = timeScaleBar;
      level = curLevel;
      realTimeLevel = curLevel;
      transformedScale = (row["levelScale"]).floor();
      levelScale = (row["levelScale"]).floor();
      skipCount = skipCounts[curLevel];
      divider = myArrTimescale[transformedScale] / 10;
      // level = curLevel;

      /*
      if (curLevel == -1){
        sabDrawingState[DRAW_STATE.SKIP_COUNTS] = 1;
        sabDrawingState[DRAW_STATE.LEVEL] = -1;
      }else{
        sabDrawingState[DRAW_STATE.SKIP_COUNTS] = arrCounts[curLevel];
        sabDrawingState[DRAW_STATE.LEVEL] = curLevel;
      }
    
      sabDrawingState[DRAW_STATE.DIVIDER] = arrTimescale[ transformedScale ]; // 0 - 40  
      sabDrawingState[DRAW_STATE.SURFACE_WIDTH] = window.innerWidth;
      skipCounts = sabDrawingState[DRAW_STATE.SKIP_COUNTS];
      level = sabDrawingState[DRAW_STATE.LEVEL];    

      sbwNode.redraw();
      */
      setState(() {});
      return;
    }

    // print("isZoomingWhilePlaying");
    // print(isZoomingWhilePlaying);
    // if (isZoomingWhilePlaying) {
    //   int _transformedScale = (row['levelScale']).floor();
    //   int _divider = (myArrTimescale[_transformedScale] / 10).floor();
    //   if (_divider == 6) {
    //     isZoomingWhilePlaying = false;
    //   }
    //   return;
    // }
    // print("pausing");

    final NUMBER_OF_SEGMENTS = 60;
    int SEGMENT_SIZE = sampleRate;
    double SIZE = (NUMBER_OF_SEGMENTS * SEGMENT_SIZE).toDouble();
    final SIZE_LOGS2 = 10;

    double size = SIZE;
    // size/=2;
    var envelopeSizes = [];
    int i = 0;
    for (; i < SIZE_LOGS2; i++) {
      // final sz = (size).floor();
      envelopeSizes.add(size);
      size /= 2;
    }

    int initialPosition;
    initialPosition = screenPositionToElementPosition(row["posX"], "first : ",
        level, skipCount, envelopeSizes[level], cBuffIdx, divider, innerWidth);
    // double initialLength = envelopeSizes[level];
    // console.log("INITIAL ", row["timeScaleBar"]);

    curLevel =
        calculateLevel(row["timeScaleBar"], sampleRate, innerWidth, skipCounts);
    // curLevel = level;
    // timeScaleBar = row["timeScaleBar"].floor();
    realTimeLevel = curLevel;

    transformedScale = (row['levelScale']).floor();
    levelScale = (row['levelScale']).floor();
    skipCount = skipCounts[curLevel];

    divider = myArrTimescale[transformedScale] / 10; // 0 - 40
    surfaceWidth = innerWidth;
    {
      level = curLevel;
      int _divider = (divider).floor();
      // console.log("divider : ",divider);
      if (_divider == 6) {
        // sabDrawingState[DRAW_STATE.CURRENT_START] = 0;
        // isZoomingWhilePlaying = false;
        CURRENT_START = 0;
        isZooming = false;
      }
      // const subArrMaxSize = Math.floor ( SIZE / divider );

      int endingPosition;
      endingPosition = screenPositionToElementPosition(
          row["posX"],
          "second : ",
          level,
          skipCount,
          envelopeSizes[level],
          cBuffIdx,
          divider,
          innerWidth);
      print("CURRENT_POSITION_START");
      print(endingPosition.toString() + " @: " + initialPosition.toString());

      // if (level == -1){
      //   endingPosition = screenPositionToElementPosition(row["posX"], "second : ", level, skipCounts,SIZE);
      // }else{
      //   endingPosition = screenPositionToElementPosition(row["posX"], "second : ", level, skipCounts,envelopeSizes[level]);
      // }

      // const endingLength = envelopeSizes[level];

      int diffPosition;
      double platformMultiplier = MediaQuery.of(context).devicePixelRatio;
      print("platformMultiplier");
      print(platformMultiplier);
      if (Platform.isWindows) {
        platformMultiplier = 2;
      }
      // if (Platform.isMacOS || Platform.isIOS) {
      //   platformMultiplier = 2;
      // }

      if (deviceType == 0) {
        if (level == 0) {
          diffPosition =
              ((endingPosition - initialPosition) * platformMultiplier).floor();
        } else {
          diffPosition =
              ((endingPosition - initialPosition) * platformMultiplier).floor();
        }
      } else {
        if (deviceType == 1) {
          if (level == 0) {
            diffPosition =
                ((endingPosition - initialPosition) * platformMultiplier)
                    .floor();
          } else {
            diffPosition =
                ((endingPosition - initialPosition) * platformMultiplier)
                    .floor();
          }
        } else {
          if (isOpeningFile == 1) {
            if (level == 0) {
              diffPosition = ((endingPosition - initialPosition) / 1).floor();
            } else {
              diffPosition = ((endingPosition - initialPosition) / 1).floor();
            }
          } else {
            if (level == 0) {
              diffPosition = ((endingPosition - initialPosition) / 2).floor();
            } else {
              diffPosition = ((endingPosition - initialPosition) / 2).floor();
            }
          }
        }
      }
      // if (row["direction"] == 1){ // UP

      // }else{ //DOWN

      // }

      // int head = sabDrawingState[DRAW_STATE.CURRENT_HEAD];
      // int head = cBuffIdx;
      // const distanceX = (window.innerWidth - posX) * skipCounts;
      // int curStart = head + (diffPosition/2).floor();
      // sabDrawingState[DRAW_STATE.CURRENT_START] += ( diffPosition).floor();
      CURRENT_START += (diffPosition).floor();

      /*
      int curPageSamples =
          (envelopeSizes[level] / 2 / divider * skipCount).floor();
      int rawLeftHeadPosition = screenPositionToElementPosition(
          0,
          "left head : ",
          level,
          skipCount,
          envelopeSizes[level],
          cBuffIdx,
          divider,
          innerWidth);

      int rangeStart =
          ((rawLeftHeadPosition / curPageSamples).floor() * curPageSamples)
              .floor();
      int rangeEnd = (((rawLeftHeadPosition / curPageSamples).floor() + 1) *
              curPageSamples)
          .floor();

      int rawCurPageSamples = rangeEnd - rangeStart;

      int leftHeadPosition = (rawLeftHeadPosition).floor();
      print("CUR PAGE SAMPLES = " + (curPageSamples).toString());
      print("RANGE START = " + (rangeStart).toString());
      print(divider.toString() + " Cbuff Idx = " + (cBuffIdx).toString());
      print("RANGE END = " + (rangeEnd).toString());
      print((leftHeadPosition).toString());

      print((cBuffIdx).toString() + " < " + rawCurPageSamples.toString());
      if (cBuffIdx - leftHeadPosition < rawCurPageSamples) {
        // get screen buffers
        //int screenBuffersTotal = getScreenBuffers(cBuffIdx,); // signal thread
        // tempGap = curPageSamples - screenBuffersTotal;
        diffPosition = -(rawCurPageSamples - (cBuffIdx - leftHeadPosition));
        CURRENT_START += (diffPosition).floor();
        print(level.toString() +
            " xyzCURRENT_START DIF POSTION " +
            diffPosition.toString());
        print(CURRENT_START);
      } else {
        CURRENT_START += (diffPosition).floor();
        // print(level.toString() +
        //     " CURRENT_START DIF POSTION " +
        //     deviceType.toString());
        print(CURRENT_START);
      }
      // console.log("curStart : ",curStart, head, initialPosition, endingPosition,  diffPosition, sabDrawingState[DRAW_STATE.CURRENT_START]);
*/
    }

    try {
      // if (isPlaying == 2)
      //   sbwNode.redraw();
      // window.callbackHorizontalDiff( [ sabDrawingState[DRAW_STATE.CURRENT_START] ] );
    } catch (err) {
      // console.log("err");
      // console.log(err);
    }

    return;
  }

  callbackAudioInit(params) {
    deviceType = params[0];
    isPlaying = params[1];
    // startRecordingTime = (DateTime.now());
    channelGains = [10000, 10000, 10000, 10000, 10000, 10000];
    listIndexSerial = [5, 5, 5, 5, 5, 5];
    listIndexHid = [7, 7, 7, 7, 7, 7];
    listIndexAudio = [9, 9];

    settingParams["flagDisplay1"] = 1;
    settingParams["flagDisplay2"] = 0;
    settingParams["defaultMicrophoneLeftColor"] = 0;
    settingParams["defaultMicrophoneRightColor"] = 1;
    channelsColor[0] = audioChannelColors[0];
    channelsColor[1] = audioChannelColors[1];
    // print("channelsColor[0] : "+channelsColor[0].toString());
    // print("channelsColor[1] : "+channelsColor[1].toString());

    if (kIsWeb) {
      // js.context.callMethod('setFlagChannelDisplay', [
      //   settingParams["flagDisplay1"],
      //   settingParams["flagDisplay2"],
      //   settingParams["flagDisplay3"],
      //   settingParams["flagDisplay4"],
      //   settingParams["flagDisplay5"],
      //   settingParams["flagDisplay6"]
      // ]);
    } else {}

    setState(() {});
  }

  callbackOpenWavFile(params) {}
  callbackOpeningFile(params) {}
  callbackIsOpeningWavFile(params) {}
  changeResetPlayback(params) {}
  resetToAudio(params) {}

  void closeIsolate() {
    // if (_isolate != null) {
    // }
    // if (audioListener != null) {
    // }
    _isolate?.kill(priority: Isolate.immediate);
    audioListener?.cancel();
    try {
      winAudioSubscription?.cancel();
      audioQueueSubscription?.cancel();
    } catch (err) {
      print("Audio Subscription Error : ");
      print(err);
    }
  }

  void getMicrophoneData() async {
    this.deviceType = 0;
    DISPLAY_CHANNEL_FIX = 2;
    isPlaying = 1;
    callbackAudioInit([0, 0]);
    // closeIsolate();
    // if (kIsWeb) {
    //   js.context['jsToDart'] = js2Dart;
    //   js.context['callbackErrorLog'] = callbackErrorLog;
    //   js.context['callbackGetDeviceInfo'] = callbackGetDeviceInfo;
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

    // if (Platform.isMacOS) {
    // https://github.com/BackyardBrains/Spike-Recorder/blob/327cd6ff142238c657a7cb68ff536f65fcbb2b98/src/engine/RecordingManager.cpp#L879
    // (Winaudio()).getPlatformVersion();
    // return;
    // await (Winaudio()).initBassAudio(48000);
    // await (Winaudio()).startRecording();
    // }
    // if android : audioRecord.getRoutedDevice()   https://developer.android.com/reference/android/media/AudioDeviceInfo#getChannelCounts()
    int maxOsChannel = 1;
    if (Platform.isWindows || Platform.isMacOS) {
      maxOsChannel = 2;
      print("isWINDOWS or MAC");
      try {
        if (await Permission.microphone.request().isGranted) {
          // Either the permission was already granted before or the user just granted it.
        }
      } catch (err) {}
      sampleRate = 48000;
      double _sampleRate = sampleRate.toDouble();
      List<int> envelopeSizes = [];
      int SEGMENT_SIZE = _sampleRate.toInt();
      int SIZE = NUMBER_OF_SEGMENTS * SEGMENT_SIZE;
      double size = SIZE.toDouble() * 2;
      allEnvelopes = [];
      //get audio Channel
      unitInitializeEnvelope(
          maxOsChannel, allEnvelopes, envelopeSizes, size, SIZE, SIZE_LOGS2);
      int cBufferSize = ((_sampleRate * 60).floor()).floor();
      print("start Isolate ");
      _receivePort = ReceivePort();
      _receiveAudioPort = ReceivePort();

      _receiveQueue = StreamQueue(_receivePort);
      _receiveAudioQueue = StreamQueue(_receiveAudioPort);

      _isolate = await Isolate.spawn<List<dynamic>>(sampleBufferingEntryPoint, [
        _receiveAudioPort.sendPort,
        allEnvelopes,
        cBufferSize,
        [197]
      ]);
      iSendAudioPort = await _receiveAudioQueue.next;

      double innerWidth = MediaQuery.of(context).size.width;
      level =
          calculateLevel(10000, _sampleRate.toInt(), innerWidth, skipCounts);
      print("calculate level");

      int skipCount = skipCounts[level];

      List<double> envelopeSamples = allEnvelopes[0][level];
      int prevSegment = (envelopeSamples.length / divider).floor();

      cBuffDouble = List<double>.generate(prevSegment, (i) => 0);
      cBuff = List<double>.generate(prevSegment, (i) => 0);
      globalIdx = 0;
      int channelIdx = 0;

      // START RECORDING
      if (Platform.isMacOS) {
        // await (Winaudio()).initBassAudio(48000);
        // await (Winaudio()).startRecording();
        // Future.delayed(Duration(seconds: 1), () {
        //   (Winaudio()).startRecording();
        // });
      }
      await (Winaudio()).initBassAudio(sampleRate);
      Future.delayed(Duration(milliseconds: 300), () {
        (Winaudio()).startRecording();
      });

      print("start Recording - end");

      _receiveAudioQueue.rest.listen((curSamples) {
        // cBuffDouble = List<double>.from(curSamples);
        channelsData = List<List<double>>.from(curSamples[0]);
        cBuffIdx = curSamples[1];
        markersData = curSamples[2];
        // if (markersData.length> 0){
        //   print("markersData");
        //   print(markersData);
        // }

        // print("cBuffDouble");
        // print(cBuffDouble);
        setState(() {});
      });

      winAudioSubscription?.cancel();
      winAudioSubscription = Winaudio.audioData().listen((samples) {
        // print("samples audio data : !!! ");
        // print(samples);
        // List<List<double>> arrVisibleSamples = [];
        final divider = myArrTimescale[timeScaleBar] / 10;
        // CURRENT_START = 100;

        if (isPaused) {
          // print("CURRENT_START paused");
          // print(currentStart);
          iSendAudioPort.send([
            [],
            level,
            divider,
            maxOsChannel,
            CURRENT_START,
            isPaused,
            currentKey,
            MediaQuery.of(context).size.width,
            // DISPLAY_CHANNEL_FIX,
          ]);
          currentKey = "";
          return;
        }

        // getAllChannelsSample(samples,maxOsChannel);
        // print("arrVisibleSamples[0]");
        // print(arrVisibleSamples[0]);
        iSendAudioPort.send([
          samples,
          level,
          divider,
          maxOsChannel,
          CURRENT_START,
          isPaused,
          currentKey,
          MediaQuery.of(context).size.width
          // DISPLAY_CHANNEL_FIX,
        ]);
        currentKey = "";

        // cBuffIdx = (cBuffIdx + arrVisibleSamples[0].length);
        // if (cBuffIdx >= cBufferSize) {
        //   globalIdx++;
        //   cBuffIdx %= cBufferSize;
        // }
      });

      // Winaudio wa = new Winaudio();
      // String? version = await wa.getPlatformVersion();
      // print("version");
      // print(version);
      return;
    }
    settingParams["maxAudioChannels"] = maxOsChannel;
    cBuffIdx = 0;

    double? tempSampleRate = (await MicStream.sampleRate);
    int? bitDepth = await MicStream.bitDepth;
    int? bufferSize = await MicStream.bufferSize;
    // sampleRate = tempSampleRate!.floor();
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
    sampleRate = _sampleRate.floor();
    List<int> envelopeSizes = [];
    int SEGMENT_SIZE = _sampleRate.toInt();
    int SIZE = NUMBER_OF_SEGMENTS * SEGMENT_SIZE;
    double size = SIZE.toDouble() * 2;
    allEnvelopes = [];
    unitInitializeEnvelope(DISPLAY_CHANNEL_FIX, allEnvelopes, envelopeSizes,
        size, SIZE, SIZE_LOGS2);
    // print(" unitInitializeEnvelope :");
    // print(allEnvelopes);
    int cBufferSize = ((_sampleRate * 60).floor()).floor();
    // cBuff = CircularBuffer<int>(surfaceSize);
    _receivePort = ReceivePort();
    _receiveAudioPort = ReceivePort();

    _receiveQueue = StreamQueue(_receivePort);
    _receiveAudioQueue = StreamQueue(_receiveAudioPort);

    _isolate = await Isolate.spawn<List<dynamic>>(sampleBufferingEntryPoint, [
      _receiveAudioPort.sendPort,
      allEnvelopes,
      cBufferSize,
      [197]
    ]);
    iSendAudioPort = await _receiveAudioQueue.next;

    double innerWidth = MediaQuery.of(context).size.width;
    level = calculateLevel(10000, _sampleRate.toInt(), innerWidth, skipCounts);
    // print("getMicrophone Data : " +
    //     level.toString() +
    //     " _ " +
    //     sampleRate.toString() +
    //     " _ " +
    //     innerWidth.toString());
    // print("skipCounts");
    // print(skipCounts);

    int skipCount = skipCounts[level];

    List<double> envelopeSamples = allEnvelopes[0][level];
    int prevSegment = (envelopeSamples.length / divider).floor();

    cBuffDouble = List<double>.generate(prevSegment, (i) => 0);
    cBuff = List<double>.generate(prevSegment, (i) => 0);
    globalIdx = 0;
    int channelIdx = 0;

    // Start listening to the stream
    audioListener?.cancel();
    audioListener = stream?.listen((samples) async {
      final divider = myArrTimescale[timeScaleBar] / 10;
      if (isPaused) {
        iSendAudioPort.send([
          [],
          level,
          divider,
          maxOsChannel,
          CURRENT_START,
          isPaused,
          currentKey,
          MediaQuery.of(context).size.width,
          // DISPLAY_CHANNEL_FIX,
        ]);
      } else {
        iSendAudioPort.send([
          samples,
          level,
          divider,
          maxOsChannel,
          CURRENT_START,
          isPaused,
          currentKey,
          MediaQuery.of(context).size.width
          // DISPLAY_CHANNEL_FIX,
        ]);
        currentKey = "";
      }

      /* PERFORMANCE TWEAK
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
      */

      // // print("sending to isolate");
      // iSendPort.send(visibleSamples);

      // cBuffIdx = (cBuffIdx + visibleSamples.length);
      // if (cBuffIdx >= cBufferSize) {
      //   globalIdx++;
      //   cBuffIdx %= cBufferSize;
      // }
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
    audioQueueSubscription?.cancel();
    audioQueueSubscription = _receiveAudioQueue.rest.listen((curSamples) {
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
      channelsData = List<List<double>>.from(curSamples[0]);
      cBuffIdx = curSamples[1];
      markersData = curSamples[2];

      // cBuffDouble = List<double>.from(curSamples);
      // channelsData[0] = cBuffDouble;
      // channelsData[1] = cBuffDouble;
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

  zoomGesture(dragDetails) {
    // const arrTimeScale = [0.1, 1, 10, 50, 100, 500, 1000, 5000, 10000];
    int direction = 0;
    // print("previousLevel : ");
    // print(level);

    int tempTimeScaleBar = timeScaleBar;
    if (dragDetails.delta.dx == 0.0 && dragDetails.delta.dy == 0.0) {
      return;
    } else if (dragDetails.delta.dy > 0.0) {
      // y0 is more bigger than y1 direction DOWN, scale both side
      direction = -1;
      if (timeScaleBar - 1 < 0) {
      } else {
        timeScaleBar--;
      }
    } else if (dragDetails.delta.dy < 0) {
      // direction UP
      direction = 1;
      if (timeScaleBar + 1 > 80) {
      } else {
        timeScaleBar++;
      }
    }

    if (!kIsWeb) {
      double tempDivider = myArrTimescale[timeScaleBar] / 10;
      int tempLevel = calculateLevel(myArrTimescale[timeScaleBar], sampleRate,
          MediaQuery.of(context).size.width, skipCounts);
      int prevSegment =
          (allEnvelopes[0][tempLevel].length / tempDivider).floor();
      // print(prevSegment);
      if (prevSegment <= 2) {
        timeScaleBar = tempTimeScaleBar;
        return;
      }
    }

    int transformScale = (timeScaleBar / 10).floor();

    scaleBarWidth = MediaQuery.of(context).size.width /
        (arrScaleBar[timeScaleBar]) *
        arrTimeScale[transformScale] /
        10;
    curTimeScaleBar = (arrTimeScale[transformScale] / 10);
    var localPosition;
    try {
      if (dragDetails is DragUpdateDetails) {
        localPosition = dragDetails.localPosition;
      } else {
        localPosition = dragDetails.localPos;
      }
    } catch (err) {}
    var data = {
      "timeScaleBar": arrTimeScale[transformScale], // label in UI
      "levelScale": timeScaleBar, //scrollIdx
      "posX": localPosition.dx,
      "direction": direction
    };
    // print("data");
    // print(data);

    if (timeScaleBar == -1) {
      isZooming = false;
      timeScale = 1;
    } else {
      isZooming = true;
      timeScale = arrTimeScale[transformScale];
    }

    // level = calculateLevel(
    //     timeScale, sampleRate, MediaQuery.of(context).size.width, skipCounts);
    if (deviceType == 0) {
    } else {}
    if (kIsWeb) {
      //   // js.context.callMethod('setZoomLevel', [json.encode(data)]);
      //   level = calculateLevel(
      //       timeScale, sampleRate, MediaQuery.of(context).size.width, skipCounts);
    } else {
      // if (isPaused){
      setZoomLevel(data);
      // }
    }
    // print("after Level : ");
    // print(level);
    // print(timeScale);
    // print(sampleRate);

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!isFeedback) FocusScope.of(context).requestFocus(keyboardFocusNode);

    if (Platform.isAndroid || Platform.isIOS) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: XGestureDetector(
          behavior: HitTestBehavior.translucent,
          // onScaleUpdate: (ScaleUpdateDetails details) {
          onScaleUpdate: (details) {
            //ScaleUpdateDetails(focalPoint: Offset(104.9, 124.4), localFocalPoint: Offset(104.9, 124.4), scale: 1.0382496909924845, horizontalScale: 1.0382496909924845, verticalScale: 1.0382496909924845, rotation: 0.0, pointerCount: 1, focalPointDelta: Offset(0.0, 0.0))
            // print(details);
            int channelIdx = -1;
            double centerX = MediaQuery.of(context).size.width / 2;
            for (int c = 0; c < channelsData.length; c++) {
              double median =
                  levelMedian[c] == -1 ? initialLevelMedian[c] : levelMedian[c];
              Rect rectPoints = Rect.fromCenter(
                  center: Offset(centerX, median),
                  width: MediaQuery.of(context).size.width,
                  height:
                      MediaQuery.of(context).size.height / channelsData.length);
              if (rectPoints.contains(details.focalPoint)) {
                channelIdx = c;
                break;
              }
            }

            // print("channelIdx");
            // print(channelIdx);
            if (channelIdx == -1) return;
            if (details.scale > 1) {
              // scale Up
              if (((details.scale * 10).round()) % 2 == 0) {
                debouncerScale.run(() {
                  increaseGain(channelIdx);
                });
              }
            } else {
              if (((details.scale * 10).round()) % 2 == 0) {
                debouncerScale.run(() {
                  decreaseGain(channelIdx);
                });
              }
              // scale Down
            }
          },
          // onVerticalDragUpdate: (DragUpdateDetails details) {
          onMoveUpdate: (details) {
            dragDetails = details;
            if (!kIsWeb) {
              zoomGesture(dragDetails);
            }
          },
          // onVerticalDragEnd: (DragEndDetails dragEndDetails) {
          onMoveEnd: (dragEndDetails) {
            if (kIsWeb) zoomGesture(dragDetails);
          },

          child: Focus(
            onKey: (FocusNode node, RawKeyEvent event) =>
                KeyEventResult.handled,
            child: RawKeyboardListener(
              onKey: (key) {
                if (isFeedback) return;

                if (key.character == null) {
                  prevKey = "~";
                  currentKey = "";
                } else {
                  if (key.character.toString().codeUnitAt(0) >= 48 &&
                      key.character.toString().codeUnitAt(0) <= 57) {
                    if (prevKey != key.character.toString()) {
                      prevKey = key.character.toString();
                      if (kIsWeb) {
                        // js.context.callMethod('setEventKeypress', [prevKey]);
                      } else {
                        if (globalMarkers.length + 1 >= max_markers) {
                          globalMarkers.clear();
                        }
                        globalMarkers.add((prevKey.codeUnitAt(0) - 48));
                        currentKey = prevKey;
                      }
                    }
                  }
                }
                return;
              },
              focusNode: keyboardFocusNode,
              child: isLoadingFile
                  ? getLoadingWidget(context)
                  : (isFeedback ? getFeedbackWidget() : getMainWidget()),
            ),
          ),
        ),
      );
    } else {
      return Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onScaleUpdate: (ScaleUpdateDetails details) {
            // onScaleUpdate: (details) {
            //ScaleUpdateDetails(focalPoint: Offset(104.9, 124.4), localFocalPoint: Offset(104.9, 124.4), scale: 1.0382496909924845, horizontalScale: 1.0382496909924845, verticalScale: 1.0382496909924845, rotation: 0.0, pointerCount: 1, focalPointDelta: Offset(0.0, 0.0))
            // print(details);
            int channelIdx = -1;
            double centerX = MediaQuery.of(context).size.width / 2;
            for (int c = 0; c < channelsData.length; c++) {
              double median =
                  levelMedian[c] == -1 ? initialLevelMedian[c] : levelMedian[c];
              Rect rectPoints = Rect.fromCenter(
                  center: Offset(centerX, median),
                  width: MediaQuery.of(context).size.width,
                  height:
                      MediaQuery.of(context).size.height / channelsData.length);
              if (rectPoints.contains(details.focalPoint)) {
                channelIdx = c;
                break;
              }
            }

            // print("channelIdx");
            // print(channelIdx);
            if (channelIdx == -1) return;
            if (details.scale > 1) {
              // scale Up
              if (((details.scale * 10).round()) % 2 == 0) {
                debouncerScale.run(() {
                  increaseGain(channelIdx);
                });
              }
            } else {
              if (((details.scale * 10).round()) % 2 == 0) {
                debouncerScale.run(() {
                  decreaseGain(channelIdx);
                });
              }
              // scale Down
            }
          },
          onVerticalDragUpdate: (DragUpdateDetails details) {
            // onMoveUpdate: (details) {
            dragDetails = details;
            if (!kIsWeb) {
              zoomGesture(dragDetails);
            }
          },
          onVerticalDragEnd: (DragEndDetails dragEndDetails) {
            // onMoveEnd: (dragEndDetails) {
            if (kIsWeb) zoomGesture(dragDetails);
          },
          // behavior: HitTestBehavior.translucent,
          // onHorizontalDragUpdate: (DragUpdateDetails details) {
          //   dragHorizontalDetails = details;
          // },
          // onHorizontalDragDown: (DragDownDetails details) {
          //   dragDownDetails = details;
          // },
          // onHorizontalDragEnd: (DragEndDetails dragEndDetails) {
          //   if (isOpeningFile == 1 && isPlaying == 2) {
          //     if (dragHorizontalDetails.delta.dx == 0.0 &&
          //         dragHorizontalDetails.delta.dy == 0.0) {
          //       return;
          //     } else {
          //       if (dragHorizontalDetails.delta.dx > 0.0) {
          //         // x0 is more bigger than x1 ; Hand Swipe direction LEFT,
          //         print("SLIDE RIGHT");
          //         print(dragDownDetails.localPosition.dx);
          //         if (kIsWeb) {
          //           // js.context.callMethod('setScrollDrag', [
          //           //   1,
          //           //   dragHorizontalDetails.delta.dx,
          //           //   dragDownDetails.localPosition.dx,
          //           //   horizontalDragX,
          //           //   horizontalDragXFix
          //           // ]);
          //         } else {}
          //       } else if (dragHorizontalDetails.delta.dx < 0.0) {
          //         // x1 is more bigger than x0 ; Hand Swipe direction RIGHT,
          //         print("SLIDE LEFT");
          //         print(dragDownDetails.localPosition.dx);
          //         if (kIsWeb) {
          //           // js.context.callMethod('setScrollDrag', [
          //           //   -1,
          //           //   dragHorizontalDetails.delta.dx,
          //           //   dragDownDetails.localPosition.dx,
          //           //   horizontalDragX,
          //           //   horizontalDragXFix
          //           // ]);

          //         } else {}
          //       }
          //     }
          //   }
          // },

          child: Focus(
            onKey: (FocusNode node, RawKeyEvent event) =>
                KeyEventResult.handled,
            child: RawKeyboardListener(
              onKey: (key) {
                if (isFeedback) return;

                if (key.character == null) {
                  prevKey = "~";
                  currentKey = "";
                } else {
                  if (key.character.toString().codeUnitAt(0) >= 48 &&
                      key.character.toString().codeUnitAt(0) <= 57) {
                    if (prevKey != key.character.toString()) {
                      prevKey = key.character.toString();
                      if (kIsWeb) {
                        // js.context.callMethod('setEventKeypress', [prevKey]);
                      } else {
                        if (globalMarkers.length + 1 >= max_markers) {
                          globalMarkers.clear();
                        }
                        globalMarkers.add((prevKey.codeUnitAt(0) - 48));
                        currentKey = prevKey;
                      }
                    }
                  }
                }
                return;
              },
              focusNode: keyboardFocusNode,
              child: isLoadingFile
                  ? getLoadingWidget(context)
                  : (isFeedback ? getFeedbackWidget() : getMainWidget()),
            ),
          ),
        ),
      );
    }
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
    getCachedWidget();
    calculateArrScaleBar();
    getDeviceCatalog();
    



    initPorts();
    Future.delayed(new Duration(milliseconds: 10), () {
      int transformScale = (timeScaleBar / 10).floor();
      print("(arrScaleBar[timeScaleBar]) * arrTimeScale[transformScale] / 10");
      print(arrScaleBar[timeScaleBar]);
      print(arrTimescaleBar[transformScale]);

      scaleBarWidth = MediaQuery.of(context).size.width /
          (arrScaleBar[timeScaleBar]) *
          arrTimeScale[transformScale] /
          10;
    });
    getMicrophoneData();
  }

  //Platform.isWindows
  void closeRawSerial() async {
    try {
      port.close();
    } catch (err) {}

    try {
      serialPort.close();
      serialPort.dispose();
      serialReader.close();
    } catch (err) {}
  }

  void closeAudio() {
    try {
      winAudioSubscription?.cancel();
      audioListener?.cancel();
      audioQueueSubscription?.cancel();
    } catch (err) {}
  }

  void getSerialParsing() async {
    if (DEVICE_CATALOG.keys.length == 0) {
      return;
    }
    closeAudio();
    DISPLAY_CHANNEL = 1;
    String deviceType = 'serial';
    int numberOfChannels = DISPLAY_CHANNEL;
    double _sampleRate = 10000;
    sampleRate = _sampleRate.floor();
    List<int> envelopeSizes = [];
    int SEGMENT_SIZE = _sampleRate.toInt();
    int SIZE = NUMBER_OF_SEGMENTS * SEGMENT_SIZE;
    double size = SIZE.toDouble() * 2;

    _sendAnalyticsEvent("button_serial_connected", {
      "device": "Serial",
      "deviceType": 'serial',
      "isStartingSerial": 1,
      "isStartingAudio": 0
    });
    this.deviceType = 1;
    closeIsolate();
    allEnvelopes = [];
    unitInitializeEnvelope(
        6, allEnvelopes, envelopeSizes, size, SIZE, SIZE_LOGS2);
    int surfaceSize = ((_sampleRate * NUMBER_OF_SEGMENTS).floor());

    Uint8List rawCircularBuffer = Uint8List(SIZE_OF_INPUT_HARDWARE_CIRC_BUFFER);
    iReceiveDeviceInfoPort = ReceivePort();
    iReceiveExpansionDeviceInfoPort = ReceivePort();

    _isolate = await Isolate.spawn<List<dynamic>>(serialBufferingEntryPoint, [
      _receivePort.sendPort,
      allEnvelopes,
      surfaceSize,
      rawCircularBuffer,
      deviceType,
      DEVICE_CATALOG,
      iReceiveDeviceInfoPort.sendPort,
      iReceiveExpansionDeviceInfoPort.sendPort,
      [217]
    ]);
    iSendPort = await _receiveQueue.next;

    double innerWidth = MediaQuery.of(context).size.width;
    level = calculateLevel(10000, _sampleRate.toInt(), innerWidth, skipCounts);
    print("Serial Level : " + level.toString());
    int skipCount = skipCounts[level];

    iReceiveExpansionDeviceInfoPort.listen((message) {
      EXPANSION_BOARD = message;
      //change sample rate, channels
      sampleRate = EXPANSION_BOARD['maxSampleRate'];
      DISPLAY_CHANNEL = CURRENT_DEVICE['maxNumberOfChannels'] +
          EXPANSION_BOARD['maxNumberOfChannels'];
      DISPLAY_CHANNEL_FIX = CURRENT_DEVICE['maxNumberOfChannels'];
      numberOfChannels = DISPLAY_CHANNEL;
    });
    iReceiveDeviceInfoPort.listen((message) {
      print("DEVICE_CATALOG MESSAGE");
      print(message);

      CURRENT_DEVICE = DEVICE_CATALOG[message];
      minChannels = 1;
      int maxExpansionChannels = 0;
      List<int> sampleRates = [];
      if (CURRENT_DEVICE["expansionBoards"].length > 0) {
        minChannels = int.parse(CURRENT_DEVICE['maxNumberOfChannels']);
        // sampleRates.add(int.parse(CURRENT_DEVICE["maxSampleRate"])/minChannels);
        CURRENT_DEVICE['expansionBoards'].forEach((board) {
          maxExpansionChannels = max(
              maxExpansionChannels, int.parse(board['maxNumberOfChannels']));
        });
        maxChannels = minChannels + maxExpansionChannels;
      } else if (maxExpansionChannels == 0) {
        maxChannels = int.parse(CURRENT_DEVICE['maxNumberOfChannels']);
        if (CURRENT_DEVICE["channels"].length > 5) {
          minChannels = 1;
        } else {
          minChannels = int.parse(CURRENT_DEVICE['maxNumberOfChannels']);
        }
      }

      sampleRate =
          (int.parse(CURRENT_DEVICE['maxSampleRate']) / minChannels).floor();
      print(sampleRate);
      DISPLAY_CHANNEL_FIX = minChannels;
      if (maxChannels > 5) {
        DISPLAY_CHANNEL = 1;
      } else {
        DISPLAY_CHANNEL = maxChannels;
      }
      numberOfChannels = DISPLAY_CHANNEL;

      // List<int> channels = [];

      // for (int i = minChannels; i <= maxChannels; i++) {
      //   channels.add(i);
      // }
      // var params = {
      //   "maxSamplingRate": 1000,
      //   "minChannels": minChannels,
      //   "maxChannels": maxChannels,
      //   "channels": channels,
      //   "sampleRates": [10000, 5000, 3333, 2500, 2000, 1666],
      //   "baudRate": 222222,
      // };
      // '67_1240' : { //Muscle SpikerShield
      //     "deviceIdx" : 4,
      //     "maxSamplingRate" : 10000,
      //     "minChannels" : 1,
      //     "maxChannels" : 6,
      //     "channels" : [1,2,3,4,5,6],
      //     "sampleRates" : [10000,5000,3333,2500,2000,1666],
      //     "baudRate" : 222222,
      // },
      // extraChannels = params[0];
      // minChannels = params[1];
      // maxChannels = params[2];
      // settingParams["channelCount"] = minChannels;
      for (int c = 0; c < maxChannels; c++) {
        double idx = listIndexSerial[c];
        channelGains[c] = listChannelSerial[idx.toInt()];
      }

      callbackGetDeviceInfo([maxExpansionChannels, minChannels, maxChannels]);
    });

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
        final divider = myArrTimescale[timeScaleBar] / 10;
        int maxSampleRate = 10000;
        if (CURRENT_DEVICE.keys.length > 0) {
          maxSampleRate = int.parse(CURRENT_DEVICE['maxSampleRate']);
        }
        // var timeScale = arrTimeScale[transformScale];
        //10000;//
        level = calculateLevel(timeScale, sampleRate, innerWidth, skipCounts);
        iSendPort.send([
          isPaused ? List<int>.generate(0, (index) => 0) : visibleSamples,
          level,
          divider,
          DISPLAY_CHANNEL,
          sampleRate,
          maxSampleRate,
          CURRENT_START,
          isPaused,
          currentKey,
          MediaQuery.of(context).size.width,
        ]);
        currentKey = "";
      });

      _receiveQueue.rest.listen((curSamples) {
        // cBuffDouble
        channelsData = List<List<double>>.from(curSamples[0]);
        cBuffIdx = curSamples[1];
        markersData = curSamples[2];

        setState(() {});
      });

      Future.delayed(new Duration(seconds: 2), () {
        print('getDeviceInfo');
        getDeviceInfo();
      });

      return;
    } else if (Platform.isIOS) {
      // Mfi.initMfi();
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
        List<int> visibleSamples = [];
        for (int sample in samples) {
          visibleSamples.add(sample);
        }

        final divider = myArrTimescale[timeScaleBar] / 10;
        final maxSampleRate = int.parse(CURRENT_DEVICE['maxSampleRate']);
        level = calculateLevel(timeScale, sampleRate, innerWidth, skipCounts);

        iSendPort.send([
          isPaused ? List<int>.generate(0, (index) => 0) : visibleSamples,
          level,
          divider,
          DISPLAY_CHANNEL,
          sampleRate,
          maxSampleRate,
          CURRENT_START,
          isPaused,
          currentKey,
          MediaQuery.of(context).size.width,
        ]);
        currentKey = "";
      });

      _receiveQueue.rest.listen((curSamples) {
        // cBuffDouble = List<double>.from(curSamples);
        channelsData = List<List<double>>.from(curSamples[0]);
        cBuffIdx = curSamples[1];
        markersData = curSamples[2];
        setState(() {});
      });

      return;
    }

    //ELSE IF NOT ANDROID
    var address = availablePorts.last;
    serialPort = SerialPort(address);
    // var data = asciiToUint8Array("c:"+channelParam.channelCount+";\n");
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
    Future.delayed(new Duration(seconds: 2), () {
      getDeviceInfo();
      // DISPLAY_CHANNEL = 4;
      // numberOfChannels = DISPLAY_CHANNEL;
      // var data = asciiToUint8Array("c:" + DISPLAY_CHANNEL.toString() + ";\n");
      // serialPort.write(data);
    });

    serialReader = SerialPortReader(serialPort);
    serialReader.stream.listen((samples) {
      bool first = true;
      List<int> visibleSamples = [];
      // change to rawBytes not visible Samples
      for (int sample in samples) {
        visibleSamples.add(sample);
      }

      final divider = myArrTimescale[timeScaleBar] / 10;
      int maxSampleRate = 1;
      if (CURRENT_DEVICE['maxSampleRate'] != null) {
        maxSampleRate = int.parse(CURRENT_DEVICE['maxSampleRate']);
      } else {
        maxSampleRate = sampleRate;
      }
      level = calculateLevel(timeScale, sampleRate, innerWidth, skipCounts);

      iSendPort.send([
        isPaused ? List<int>.generate(0, (index) => 0) : visibleSamples,
        level,
        divider,
        DISPLAY_CHANNEL,
        sampleRate,
        maxSampleRate,
        CURRENT_START,
        isPaused,
        currentKey,
        MediaQuery.of(context).size.width,
      ]);
      currentKey = "";
    });

    _receiveQueue.rest.listen((curSamples) {
      // channelsData = [];
      // int viewChannel = min(DISPLAY_CHANNEL, curSamples.length);
      // for (int i = 0; i < viewChannel; i++) {
      //   var tempBuffDouble = List<double>.from(curSamples[0][i]);
      //   channelsData.add(tempBuffDouble);
      // }
      channelsData = List<List<double>>.from(curSamples[0]);
      cBuffIdx = curSamples[1];
      markersData = curSamples[2];
      // var cBuffDouble2 = List<double>.generate(
      //     cBuffDouble.length, (index) => index.toDouble());
      // channelsData[1] = cBuffDouble;

      setState(() {});
    });
  }

  void getMfiTest() async {
    double _sampleRate = 10000;
    List<int> envelopeSizes = [];
    int SEGMENT_SIZE = _sampleRate.toInt();
    int SIZE = NUMBER_OF_SEGMENTS * SEGMENT_SIZE;
    double size = SIZE.toDouble() * 2;
    allEnvelopes = [];
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
      final divider = myArrTimescale[timeScaleBar] / 10;
      iSendPort.send([visibleSamples, level, divider, DISPLAY_CHANNEL]);
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

    // Mfi.setDeviceStatus("connected");
  }

  void getWebSerial() {
    // js.context
    //     .callMethod('recordSerial', ['Flutter is calling upon JavaScript!']);
  }

  // UI

  getCachedWidget() {
    // if (feedbackButton != null){
    {
      feedbackButton = Positioned(
        key: keyTutorialEnd,
        top: 10,
        right: 80,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            fixedSize: const Size(50, 50),
            shape: const CircleBorder(),
            shadowColor: Colors.blue,
            primary: Colors.white,
            onPrimary: Colors.green,
            onSurface: Colors.red,
          ),
          child: const Icon(
            Icons.question_answer_rounded,
            color: Color(0xFF800000),
          ),
          onPressed: () {
            isFeedback = true;
            _sendAnalyticsEvent("button_feedback", {
              "deviceType": deviceType,
              "isStarting": 1,
              "isStartingAudio": 0
            });

            setState(() {});
            // showFeedbackDialog(context, settingParams).then((params){

            // });
          },
        ),
      );
    }
    openFileButton =
        // // HIDE FOR NOW!
        // // OPEN FILE
        Positioned(
      top: 10,
      right: 10,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          fixedSize: const Size(50, 50),
          shape: const CircleBorder(),
          shadowColor: Colors.blue,
          primary: Colors.white,
          onPrimary: Colors.green,
          onSurface: Colors.red,
        ),
        onPressed: () async {
          if (kIsWeb) {
            // js.context.callMethod('openReadWavFile', ["openReadWavFile"]);
          }
          // _sendAnalyticsEvent("button_open_file", {"isOpeningFile": 1});
        },
        child: const Icon(
          Icons.menu,
          color: Color(0xFF800000),
        ),
      ),
    );

    settingDialogButton = Positioned(
      top: 10,
      left: 10,
      child: Container(
        key: keyTutorialSetting,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            fixedSize: const Size(50, 50),
            shape: const CircleBorder(),
            shadowColor: Colors.blue,
            primary: Colors.white,
            onPrimary: Colors.green,
            onSurface: Colors.red,
          ),
          child: Icon(
            Icons.settings,
            color: Color(0xFF800000),
          ),
          onPressed: () {
            if (deviceType == 0) {
              _sendAnalyticsEvent("button_setting", {
                "device": "Audio",
                "deviceType": deviceType,
              });
              bool enableDeviceLegacy =
                  settingParams["enableDeviceLegacy"] as bool;
              showCustomAudioDialog(context, settingParams).then((params) {
                try {
                  print("params");
                  print(params);
                  if (params == null) return;

                  settingParams = params;

                  if (params["enableDeviceLegacy"] != enableDeviceLegacy) {
                    _sendAnalyticsEvent("enable_legacy_device",
                        {"isEnableDeviceLegacy": params["enableDeviceLegacy"]});
                  }

                  channelsColor[0] = audioChannelColors[
                      settingParams["defaultMicrophoneLeftColor"] as int];
                  channelsColor[1] = audioChannelColors[
                      settingParams["defaultMicrophoneRightColor"] as int];
                  print("channelsColor[1] : " + channelsColor[1].toString());
                  // need to check again
                  if (channelsColor[1] != Color(0xff000000)) {
                    var data = {
                      "channelCount": 2,
                    };

                    if (kIsWeb) {
                      // js.context.callMethod('changeChannel', [json.encode(data)]);
                    }
                  }

                  setState(() {});
                } catch (err) {
                  print("err 123");
                  print(err);
                }
              });
            } else {
              if (deviceType == 1) {
                _sendAnalyticsEvent("button_setting", {
                  "device": "Serial",
                  "deviceType": deviceType,
                });
              } else {
                _sendAnalyticsEvent("button_setting", {
                  "device": "HID",
                  "deviceType": deviceType,
                });
              }

              int prevChannelCount = settingParams["channelCount"] as int;
              if (prevChannelCount == -1) {
                settingParams['channelCount'] = 1;
              } else {
                settingParams['channelCount'] = prevChannelCount;
              }

              if (extraChannels == 0) {
                settingParams["minSerialChannels"] = minChannels;
                settingParams["maxSerialChannels"] = maxChannels;
              } else {
                settingParams["minSerialChannels"] = minChannels;
                settingParams["maxSerialChannels"] = extraChannels;
              }
              print("settingParams");
              print(minChannels);
              print(maxChannels);
              print(settingParams);
              if (deviceTypeInt == 2) {
                settingParams['deviceType'] = 'hid';
                if (extraChannels == 0) {
                  settingParams['channelCount'] = minChannels;
                } else {
                  settingParams['channelCount'] = maxChannels;
                }
              } else {
                settingParams.remove('deviceType');
              }

              // if (settingParams['maxSerialChannels'] as int > 5) {
              settingParams['displayChannelCount'] = true;
              // }

              bool enableDeviceLegacy =
                  settingParams["enableDeviceLegacy"] as bool;

              showCustomSerialDialog(context, settingParams).then((params) {
                // check with previous data
                try {
                  settingParams.remove('displayChannelCount');

                  int val = params["channelCount"];
                  if (val != prevChannelCount) {
                    var data = {
                      "channelCount": val,
                    };
                    callChangeSerialChannel(data);
                  }

                  print(val.toString() +
                      " @@ " +
                      settingParams["channelCount"].toString());
                  if (params["enableDeviceLegacy"] != enableDeviceLegacy) {
                    _sendAnalyticsEvent("enable_legacy_device",
                        {"isEnableDeviceLegacy": params["enableDeviceLegacy"]});
                  }

                  if (params['commandType'] == 'update') {
                    params.remove('commandType');
                    if (kIsWeb) {
                      // js.context.callMethod('updateFirmware', ['hid']);
                    } else {}
                    setState(() {});
                    return;
                  }
                  if (params['deviceType'] == 'hid') {
                    deviceType = 2;
                    deviceTypeInt = 2;
                  } else {
                    deviceType = 1;
                    deviceTypeInt = 1;
                  }

                  settingParams = params;

                  channelsColor[0] = serialChannelColors[
                      settingParams["defaultSerialColor1"] as int];
                  if (settingParams["channelCount"] as int >= 2)
                    channelsColor[1] = serialChannelColors[
                        settingParams["defaultSerialColor2"] as int];
                  if (settingParams["channelCount"] as int >= 3)
                    channelsColor[2] = serialChannelColors[
                        settingParams["defaultSerialColor3"] as int];
                  if (settingParams["channelCount"] as int >= 4)
                    channelsColor[3] = serialChannelColors[
                        settingParams["defaultSerialColor4"] as int];
                  if (settingParams["channelCount"] as int >= 5)
                    channelsColor[4] = serialChannelColors[
                        settingParams["defaultSerialColor5"] as int];
                  if (settingParams["channelCount"] as int >= 6)
                    channelsColor[5] = serialChannelColors[
                        settingParams["defaultSerialColor6"] as int];

                  if (kIsWeb) {
                    // js.context.callMethod('setFlagChannelDisplay', [
                    //   settingParams["flagDisplay1"],
                    //   settingParams["flagDisplay2"],
                    //   settingParams["flagDisplay3"],
                    //   settingParams["flagDisplay4"],
                    //   settingParams["flagDisplay5"],
                    //   settingParams["flagDisplay6"]
                    // ]);
                  }

                  setState(() {});
                } catch (err) {
                  print("err 12356");
                  print(err);
                }
              });
            }
          },
        ),
      ),
    );
  }

  void calculateArrScaleBar() {
    List<double> myTimeScale = [];
    int factor = 0;
    var factors = [1, 2, 10, 20, 100, 1000, 10000, 100000];
    var targets = [6, 12, 60, 120, 600, 1200, 6000, 60000, 600000];
    int idx = 0;
    for (int idxBar = 0; idxBar < 81; idxBar++) {
      int myIdx = (idx / 10).floor();
      double res;
      if (idxBar == 80) {
        res = targets[myIdx] * 10;
      } else {
        if (idxBar % 10 == 0) {
          factor = 0;
        }
        int range = targets[myIdx + 1] - targets[myIdx];
        // myTimeScale.push( Math.round(range *100 * (1+factor/10 * factors[myIdx]) )/10 );
        res = (targets[myIdx] + (range * factor / 10)) * 10;
      }

      myTimeScale.add(res);
      factor++;
      idx++;
    }
    List<double> myArrTimescale = new List.from(myTimeScale.reversed);
    List<double> myArrScaleBar = [];
    // let mytargets = [0.6,6,60, 300,600,3000, 6000,30000,60000];
    const circularBuffersTime = 6000 * 10;
    for (int idxBar = 0; idxBar < 81; idxBar++) {
      // const divIdx = Math.floor( idxBar / 10 );
      // myTimeScale.push( Math.round(range *100 * (1+factor/10 * factors[myIdx]) )/10 );

      double res = circularBuffersTime / (myArrTimescale[idxBar] / 10);
      // if (isNaN (res)) res = targets[divIdx] * 10;

      myArrScaleBar.add(res);
    }
    this.myArrTimescale = myArrTimescale;
    arrScaleBar = myArrScaleBar;
    // print(myArrScaleBar);
  }

  List<Widget> getDataWidgets() {
    const shapeLevelHeight = 35;
    int _channelActive = -1;
    for (var c = 0; c < channelsData.length; c++) {
      initialLevelMedian[c] =
          (c * MediaQuery.of(context).size.height / channelsData.length) +
              MediaQuery.of(context).size.height / channelsData.length / 2;
      int channelNumber = c + 1;
      if (settingParams["flagDisplay" + channelNumber.toString()] == 1 &&
          _channelActive == -1) {
        _channelActive = c;
      }
    }

    List<Widget> dataWidgets = [];
    if (!isLocal && channelsData.length > 0) {
      for (int channelIdx = 0; channelIdx < channelsData.length; channelIdx++) {
        if (settingParams["flagDisplay" + (channelIdx + 1).toString()] != 0) {
          dataWidgets.add(
            PolygonWaveform(
              // inactiveColor: Colors.green,
              inactiveColor: channelsColor[channelIdx],
              activeColor: Colors.transparent,
              maxDuration: const Duration(days: 1),
              elapsedDuration: const Duration(hours: 0),
              samples: channelsData[channelIdx],
              channelIdx: channelIdx,
              channelActive: _channelActive,
              // channelTop: top,
              height: MediaQuery.of(context).size.height / channelsData.length,
              width: MediaQuery.of(context).size.width,
              gain: channelGains[channelIdx],
              levelMedian: levelMedian[channelIdx] == -1
                  ? initialLevelMedian[channelIdx]
                  : levelMedian[channelIdx],
              strokeWidth: settingParams["strokeWidth"] as double,
              eventMarkersNumber: globalMarkers,
              eventMarkersPosition: markersData,
            ),
          );
        }
      }
    }

    List<Widget> dataAdditionalWidgets = <Widget>[
      Positioned(
        top: 0,
        left: 0,
        width: 50,
        height: MediaQuery.of(context).size.height,
        child: Container(
          width: 50,
          height: MediaQuery.of(context).size.height,
          color: Colors.black,
        ),
      ),
      Positioned(
        bottom: 170,
        right: 50,
        child: Center(
            child: Text(
          curTimeScaleBar == 1000
              ? "1s"
              : curTimeScaleBar == 500
                  ? "0.5s"
                  : curTimeScaleBar.floor().toString() + "ms",
          style: TextStyle(color: Colors.white),
        )
            // child: Container(
            //   width: MediaQuery.of(context).size.width/5,
            //   height:15,
            //   child: Text(curTimeScaleBar.toString()+"ms", style: TextStyle(color: Colors.white),)
            // ),
            ),
      ),
      Positioned(
        key: keyTutorialTimescale,
        bottom: 200,
        right: 50,
        child: Container(
          width: scaleBarWidth,
          height: 1,
          color: Colors.white,
          // child: Text(scaleBarWidth.toString(), style: TextStyle(color: Colors.red),)
        ),
      ),
    ];

    dataWidgets.addAll(dataAdditionalWidgets);
    // if (!isLocal && channelsData.length > 0) ...{
    //   Positioned(
    //     top: 0,
    //     left: 0,
    //     child: settingParams["flagDisplay1"] == 0
    //         ? Container()
    //         : PolygonWaveform(
    //             // inactiveColor: Colors.green,
    //             inactiveColor: channelsColor[0],
    //             activeColor: Colors.transparent,
    //             maxDuration: const Duration(days: 1),
    //             elapsedDuration: const Duration(hours: 0),
    //             samples: channelsData[0],
    //             channelIdx: 0,
    //             channelActive: _channelActive,
    //             // channelTop: top,
    //             height:
    //                 MediaQuery.of(context).size.height / channelsData.length,
    //             width: MediaQuery.of(context).size.width,
    //             gain: channelGains[0],
    //             levelMedian: levelMedian[0] == -1
    //                 ? initialLevelMedian[0]
    //                 : levelMedian[0],
    //             strokeWidth: settingParams["strokeWidth"] as double,
    //             eventMarkersNumber: globalMarkers,
    //             eventMarkersPosition: markersData,
    //           ),
    //   ),
    //   if (channelsData.length >= 2) ...{
    //     Positioned(
    //       // top:MediaQuery.of(context).size.height/channelsData.length,
    //       top: 0,
    //       left: 0,
    //       child: settingParams["flagDisplay2"] == 0
    //           ? Container()
    //           : PolygonWaveform(
    //               // inactiveColor: Colors.green,
    //               inactiveColor: channelsColor[1],
    //               activeColor: Colors.transparent,
    //               maxDuration: const Duration(days: 1),
    //               elapsedDuration: const Duration(hours: 0),
    //               samples: channelsData[1],
    //               channelIdx: 1,
    //               channelActive: _channelActive,
    //               // channelTop: top,

    //               height: MediaQuery.of(context).size.height /
    //                   channelsData.length,
    //               width: MediaQuery.of(context).size.width,
    //               gain: channelGains[1],
    //               levelMedian: levelMedian[1] == -1
    //                   ? initialLevelMedian[1]
    //                   : levelMedian[1],
    //               strokeWidth: settingParams["strokeWidth"] as double,
    //               eventMarkersNumber: eventMarkersNumber,
    //               eventMarkersPosition: eventMarkersPosition,
    //             ),
    //     ),
    //   },
    //   if (channelsData.length >= 3) ...{
    //     Positioned(
    //       // top:2*MediaQuery.of(context).size.height/channelsData.length,
    //       top: 0,
    //       left: 0,
    //       child: Container(
    //         // color: Colors.red,
    //         padding: EdgeInsets.only(top: 10),
    //         child: settingParams["flagDisplay3"] == 0
    //             ? Container()
    //             : PolygonWaveform(
    //                 // inactiveColor: Colors.green,
    //                 inactiveColor: channelsColor[2],
    //                 activeColor: Colors.transparent,
    //                 maxDuration: Duration(days: 1),
    //                 elapsedDuration: Duration(hours: 0),
    //                 samples: channelsData[2],
    //                 channelIdx: 2,
    //                 channelActive: _channelActive,
    //                 // channelTop: top,

    //                 height: MediaQuery.of(context).size.height /
    //                     channelsData.length,
    //                 width: MediaQuery.of(context).size.width,
    //                 gain: channelGains[2],
    //                 levelMedian: (levelMedian[2] == -1
    //                         ? initialLevelMedian[2]
    //                         : levelMedian[2]) *
    //                     0.985,
    //                 strokeWidth: settingParams["strokeWidth"] as double,
    //                 eventMarkersNumber: eventMarkersNumber,
    //                 eventMarkersPosition: eventMarkersPosition,
    //               ),
    //       ),
    //     ),
    //   },
    //   if (channelsData.length >= 4) ...{
    //     Positioned(
    //       // top:3*MediaQuery.of(context).size.height/channelsData.length,
    //       top: 0,
    //       left: 0,
    //       child: settingParams["flagDisplay4"] == 0
    //           ? Container()
    //           : PolygonWaveform(
    //               // inactiveColor: Colors.green,
    //               inactiveColor: channelsColor[3],
    //               activeColor: Colors.transparent,
    //               maxDuration: Duration(days: 1),
    //               elapsedDuration: Duration(hours: 0),
    //               samples: channelsData[3],
    //               channelIdx: 3,
    //               channelActive: _channelActive,
    //               // channelTop: top,

    //               height: MediaQuery.of(context).size.height /
    //                   channelsData.length,
    //               width: MediaQuery.of(context).size.width,
    //               gain: channelGains[3],
    //               levelMedian: levelMedian[3] == -1
    //                   ? initialLevelMedian[3]
    //                   : levelMedian[3],
    //               strokeWidth: settingParams["strokeWidth"] as double,
    //               eventMarkersNumber: eventMarkersNumber,
    //               eventMarkersPosition: eventMarkersPosition,
    //             ),
    //     ),
    //   },
    //   if (channelsData.length >= 5) ...{
    //     Positioned(
    //       // top:4*MediaQuery.of(context).size.height/channelsData.length,
    //       top: 0,
    //       left: 0,
    //       child: settingParams["flagDisplay5"] == 0
    //           ? Container()
    //           : PolygonWaveform(
    //               // inactiveColor: Colors.green,
    //               inactiveColor: channelsColor[4],
    //               activeColor: Colors.transparent,
    //               maxDuration: Duration(days: 1),
    //               elapsedDuration: Duration(hours: 0),
    //               samples: channelsData[4],
    //               channelIdx: 4,
    //               channelActive: _channelActive,
    //               // channelTop: top,

    //               height: MediaQuery.of(context).size.height /
    //                   channelsData.length,
    //               width: MediaQuery.of(context).size.width,
    //               gain: channelGains[4],
    //               levelMedian: levelMedian[4] == -1
    //                   ? initialLevelMedian[4]
    //                   : levelMedian[4],
    //               strokeWidth: settingParams["strokeWidth"] as double,
    //               eventMarkersNumber: eventMarkersNumber,
    //               eventMarkersPosition: eventMarkersPosition,
    //             ),
    //     ),
    //   },
    //   if (channelsData.length >= 6) ...{
    //     Positioned(
    //       // top:5*MediaQuery.of(context).size.height/channelsData.length,
    //       top: 0,
    //       left: 0,
    //       child: settingParams["flagDisplay6"] == 0
    //           ? Container()
    //           : PolygonWaveform(
    //               // inactiveColor: Colors.green,
    //               inactiveColor: channelsColor[5],
    //               activeColor: Colors.transparent,
    //               maxDuration: Duration(days: 1),
    //               elapsedDuration: Duration(hours: 0),
    //               samples: channelsData[5],
    //               channelIdx: 5,
    //               channelActive: _channelActive,
    //               // channelTop: top,

    //               height: MediaQuery.of(context).size.height /
    //                   channelsData.length,
    //               width: MediaQuery.of(context).size.width,
    //               gain: channelGains[5],
    //               levelMedian: levelMedian[5] == -1
    //                   ? initialLevelMedian[5]
    //                   : levelMedian[5],
    //               strokeWidth: settingParams["strokeWidth"] as double,
    //               eventMarkersNumber: eventMarkersNumber,
    //               eventMarkersPosition: eventMarkersPosition,
    //             ),
    //     ),
    //   },
    // },
    if (Platform.isMacOS) {
      dataWidgets.add(
        Positioned(
          top: 10,
          left: MediaQuery.of(context).size.width / 3,
          child: ElevatedButton(
            onPressed: () async {
              if (Platform.isMacOS) {
                // Stream<List<int>>? stream = await MicStream.microphone(
                //     audioSource: AudioSource.DEFAULT,
                //     sampleRate: 48000,
                //     channelConfig: ChannelConfig.CHANNEL_IN_MONO,
                //     audioFormat: AudioFormat.ENCODING_PCM_16BIT);

                // double _sampleRate = await MicStream.sampleRate!;
                // MicStream.stopListening();

                // print("_sampleRate");
                // print(_sampleRate);
                // (Winaudio()).initBassAudio(48000);
              }
              // await (Winaudio()).initBassAudio(48000);
              // Future.delayed(Duration(seconds: 1), () {
              // await (Winaudio()).startRecording();
              // });
              // winAudioSubscription?.cancel();
              // winAudioSubscription = Winaudio.audioData().listen((samples) {
              //   // print(samples.length);
              // });

              closeRawSerial();
              print("abcd");
            },
            child: Text("Close Serial"),
          ),
        ),
      );
    }
    List<Widget> widgetsChannelGainLevel = [];
    Color curColor = Colors.white;
    if (Platform.isIOS || Platform.isAndroid) {
      curColor = Colors.black;
    }

    for (var c = 0; c < channelsData.length; c++) {
      widgetsChannelGainLevel.add(Positioned(
        // top : levelMedian[c] == -1?(c * MediaQuery.of(context).size.height/channelsData.length) + MediaQuery.of(context).size.height/channelsData.length / 2 - shapeLevelHeight : levelMedian[c],
        top: levelMedian[c] == -1
            ? initialLevelMedian[c] - shapeLevelHeight
            : levelMedian[c] - shapeLevelHeight,
        left: 10,
        child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              if (c > -1) {
                if (isRecording < 10) {
                  settingParams["flagDisplay" + (c + 1).toString()] =
                      settingParams["flagDisplay" + (c + 1).toString()] == 0
                          ? 1
                          : 0;
                  if (kIsWeb) {
                    // js.context.callMethod('setFlagChannelDisplay', [
                    //   settingParams["flagDisplay1"],
                    //   settingParams["flagDisplay2"],
                    //   settingParams["flagDisplay3"],
                    //   settingParams["flagDisplay4"],
                    //   settingParams["flagDisplay5"],
                    //   settingParams["flagDisplay6"]
                    // ]);
                  }
                }
                _sendAnalyticsEvent("button_level_marker", {
                  "deviceType": deviceType,
                  "channel": c,
                  "gains": channelGains[c],
                });

                setState(() {});
              }
            },
            onVerticalDragUpdate: (dragUpdateVerticalDetails) {
              levelMedian[c] = dragUpdateVerticalDetails.globalPosition.dy;
              if (isPlaying == 2) {
                setState(() {});
              }
            },
            child: Container(
              // color:Colors.red,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (Platform.isMacOS || Platform.isWindows) {
                        print("c");
                        print(c);
                        increaseGain(c);
                        setState(() {});
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: curColor,
                      ),
                      child: Icon(Icons.add, color: Colors.black, size: 17),
                    ),
                  ),
                  // Icon(Icons.arrow_circle_right_rounded, color: Colors.white,),
                  Transform.rotate(
                    angle: 90 * pi / 180,
                    // child: settingParams["flagDisplay"+(c+1).toString()] == 0? Icon(Icons.water_drop_outlined ,color: audioChannelColors[c],size: 37,):Icon(Icons.water_drop_rounded,color: channelsColor[c],size: 37,),
                    child:
                        settingParams["flagDisplay" + (c + 1).toString()] == 0
                            ? Icon(
                                Icons.water_drop_outlined,
                                color: channelsColor[c],
                                size: 37,
                              )
                            : Icon(
                                Icons.water_drop_rounded,
                                color: channelsColor[c],
                                size: 37,
                              ),
                  ),
                  GestureDetector(
                    onTap: () {
                      if (Platform.isMacOS || Platform.isWindows) {
                        decreaseGain(c);
                        setState(() {});
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: curColor,
                      ),
                      child: Icon(Icons.remove, color: Colors.black, size: 17),
                    ),
                  ),
                ],
              ),
            )),
      ));
    }
    dataWidgets.addAll(widgetsChannelGainLevel);

    // Putting Toolbar Button
    // // FILE RECORD

    if (isOpeningFile == 1) {
      // strMinTime = "00:00 000";
      dataWidgets.add(Positioned(
        left: 50,
        bottom: 70,
        child: Text(strMinTime,
            textAlign: TextAlign.left, style: TextStyle(color: Colors.white)),
      ));
      dataWidgets.add(Positioned(
        right: 50,
        bottom: 70,
        child: Container(
            width: 150,
            child: Text(strMaxTime,
                textAlign: TextAlign.right,
                style: TextStyle(color: Colors.white))),
      ));

      // ScrollBar When Opening File
      if (isPlaying == 2) {
        dataWidgets.add(Positioned(
          left: 0,
          bottom: 100,
          child: GestureDetector(
            onTapDown: (onTapDownDetails) {
              horizontalDragX = onTapDownDetails.localPosition.dx - 50;
              if (horizontalDragX < 0) {
                horizontalDragX = 0;
              }
              if (horizontalDragX >
                  MediaQuery.of(context).size.width - 100 - 20) {
                horizontalDragX = MediaQuery.of(context).size.width - 100 - 20;
              }

              strMinTime =
                  getStrMinTime(horizontalDragX, horizontalDragXFix, maxTime);
              setState(() {});

              debouncer.run(() {
                if (kIsWeb) {
                  // js.context.callMethod(
                  //     'setScrollValue', [horizontalDragX, horizontalDragXFix]);

                } else {}
              });
            },
            onHorizontalDragUpdate: (dragUpdateHorizontalDetails) {
              horizontalDragX =
                  dragUpdateHorizontalDetails.globalPosition.dx - 50;
              if (horizontalDragX < 0) {
                horizontalDragX = 0;
              }
              if (horizontalDragX >
                  MediaQuery.of(context).size.width - 100 - 20) {
                horizontalDragX = MediaQuery.of(context).size.width - 100 - 20;
              }

              strMinTime =
                  getStrMinTime(horizontalDragX, horizontalDragXFix, maxTime);
              setState(() {});

              debouncer.run(() {
                if (kIsWeb) {
                  // js.context.callMethod(
                  //     'setScrollValue', [horizontalDragX, horizontalDragXFix]);

                } else {}
              });
            },
            child: Container(
                color: const Color(0xFF505050),
                margin: const EdgeInsets.only(left: 50, right: 50),
                width: MediaQuery.of(context).size.width - 100,
                height: 20,
                child: Stack(
                  children: [
                    Positioned(
                      left: horizontalDragX,
                      child: Container(
                        // color: Colors.green,
                        color: const Color(0xFF808080),
                        width: 20,
                        height: 20,
                      ),
                    )
                  ],
                )),
          ),
        ));
      }
    }

    if (isOpeningFile == 1) {
    } else {
      dataWidgets.add(
        Positioned(
          top: 10,
          right: 160,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              // style: ButtonStyle(
              fixedSize: const Size(50, 50),
              shape: const CircleBorder(),
              shadowColor: Colors.blue,

              primary: Colors.white,
              onPrimary: Colors.green,
              onSurface: Colors.red,
              // backgroundColor: getColor(Colors.blueGrey, Colors.blueGrey),
              // overlayColor: getColor(Colors.white60, Colors.white70)
            ),
            onPressed: () {
              bool flag = false;
              for (int c = 0; c < 6; c++) {
                if (settingParams["flagDisplay" + c.toString()] == '1') {
                  flag = true;
                }
              }
              if (flag) {
                infoDialog(
                  context,
                  "Warning",
                  "To start recording, please activate a channel first.",
                  positiveButtonText: "OK",
                  positiveButtonAction: () {},
                  negativeButtonText: "",
                  negativeButtonAction: null,
                  hideNeutralButton: true,
                  closeOnBackPress: false,
                );
              }
              if (deviceType == 0) {
                if (isRecording < 10) {
                  // isRecording = 10;
                  _sendAnalyticsEvent("button_stop_rec", {
                    "deviceType": deviceType,
                    "device": "Audio",
                  });
                } else {
                  isRecording = 0;
                  _sendAnalyticsEvent("button_start_rec", {
                    "deviceType": deviceType,
                    "device": "Audio",
                  });
                }
                print("flagDisplay12");
                print(settingParams);
                print(settingParams["flagDisplay1"]);
                print(settingParams["flagDisplay2"]);
                if (kIsWeb) {
                  // js.context.callMethod('fileRecordAudio', [
                  //   settingParams["flagDisplay1"] as int,
                  //   settingParams["flagDisplay2"] as int,
                  //   settingParams["defaultMicrophoneLeftColor"] as int,
                  //   settingParams['defaultMicrophoneRightColor'] as int
                  // ]);

                } else {}
              } else if (deviceType == 1) {
                if (isRecording < 10) {
                  // isRecording = 11;
                  _sendAnalyticsEvent("button_start_rec", {
                    "deviceType": deviceType,
                    "device": "Serial",
                  });
                } else {
                  isRecording = 0;
                  _sendAnalyticsEvent("button_stop_rec", {
                    "deviceType": deviceType,
                    "device": "Serial",
                  });
                }
                if (kIsWeb) {
                  // js.context.callMethod('fileRecordSerial', [
                  //   settingParams["flagDisplay1"],
                  //   settingParams["flagDisplay2"],
                  //   settingParams["flagDisplay3"],
                  //   settingParams["flagDisplay4"],
                  //   settingParams["flagDisplay5"],
                  //   settingParams["flagDisplay6"],
                  //   settingParams['defaultSerialColor1'] as int,
                  //   settingParams['defaultSerialColor2'] as int,
                  //   settingParams['defaultSerialColor3'] as int,
                  //   settingParams['defaultSerialColor4'] as int,
                  //   settingParams['defaultSerialColor5'] as int,
                  //   settingParams['defaultSerialColor6'] as int
                  // ]);

                } else {}
              } else if (deviceType == 2) {
                if (isRecording < 10) {
                  // isRecording = 12;
                  _sendAnalyticsEvent("button_start_rec", {
                    "deviceType": deviceType,
                    "device": "Audio",
                  });
                } else {
                  isRecording = 0;
                  _sendAnalyticsEvent("button_stop_rec", {
                    "deviceType": deviceType,
                    "device": "Hid",
                  });
                }
                if (kIsWeb) {
                  // js.context.callMethod('fileRecordSerial', [
                  //   settingParams["flagDisplay1"],
                  //   settingParams["flagDisplay2"],
                  //   settingParams["flagDisplay3"],
                  //   settingParams["flagDisplay4"],
                  //   settingParams["flagDisplay5"],
                  //   settingParams["flagDisplay6"],
                  //   settingParams['defaultSerialColor1'] as int,
                  //   settingParams['defaultSerialColor2'] as int,
                  //   settingParams['defaultSerialColor3'] as int,
                  //   settingParams['defaultSerialColor4'] as int,
                  //   settingParams['defaultSerialColor5'] as int,
                  //   settingParams['defaultSerialColor6'] as int
                  // ]);

                } else {}
              }
            },
            child: const Icon(
              Icons.fiber_manual_record_rounded,
              color: Color(0xFF800000),
            ),
          ),
        ),
      );
    }

    if (isRecording == 0) {
      dataWidgets.add(feedbackButton);
      // }

      // if ( isRecording == 0 ){
      dataWidgets.add(openFileButton);
    }

    if (isRecording > 0 || isOpeningFile == 1) {
    } else {
      dataWidgets.add(settingDialogButton);
    }

    if (isRecording > 0 || isOpeningFile == 1) {
    } else {
      if (DEVICE_CATALOG.keys.length > 0) {
        dataWidgets.add(
          Positioned(
            top: 10,
            left: 80,
            child: Container(
              key: keyTutorialSerial,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  fixedSize: const Size(50, 50),
                  shape: const CircleBorder(),
                  shadowColor: Colors.blue,
                  primary: Colors.white,
                  onPrimary: Colors.green,
                  onSurface: Colors.red,
                ),
                child: Transform.rotate(
                  angle: 90 * pi / 180,
                  child: Icon(
                    Icons.usb_rounded,
                    color: deviceType == 1 && isPlaying == 1
                        ? Colors.amber.shade900
                        : Color(0xFF800000),
                  ),
                ),
                onPressed: () {
                  if (deviceType == 0 || deviceType == 2) {
                    deviceTypeInt = 1;
                    deviceType = 1;
                    if (kIsWeb) {
                      // js.context.callMethod(
                      //     'recordSerial', ['Flutter is calling upon JavaScript!']);

                    } else {
                      getSerialParsing();
                    }

                    setState(() {});
                    _sendAnalyticsEvent("button_serial", {
                      "deviceType": deviceType,
                      "isStartingSerial": 1,
                      "isStartingAudio": 0
                    });
                  } else {
                    // if (deviceType == 1){

                    deviceTypeInt = 0;
                    deviceType = 0;
                    if (kIsWeb) {
                      // js.context.callMethod(
                      //     'recordAudio', ['Flutter is calling upon JavaScript!']);

                    } else {
                      closeRawSerial();
                      getMicrophoneData();
                    }

                    setState(() {});
                    _sendAnalyticsEvent("button_serial", {
                      "deviceType": deviceType,
                      "isStartingSerial": 0,
                      "isStartingAudio": 1
                    });
                  }
                },
              ),
            ),
          ),
        );
      }
    }
    if (isRecording > 0 || isOpeningFile == 1) {
    } else {
      // if ( isRecording == 0 ){
      dataWidgets.add(
        !((settingParams["enableDeviceLegacy"]) as bool)
            ? Container()
            : Positioned(
                key: keyTutorialHid,
                top: 10,
                left: 150,
                child: Stack(children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      fixedSize: const Size(50, 50),
                      shape: const CircleBorder(),
                      shadowColor: Colors.blue,
                      primary: Colors.white,
                      onPrimary: Colors.green,
                      onSurface: Colors.red,
                    ),
                    child: Transform.rotate(
                      angle: 90 * pi / 180,
                      child: Icon(
                        Icons.usb_outlined,
                        color: deviceType == 2 && isPlaying == 1
                            ? Colors.yellow
                            : Color(0xFF800000),
                      ),
                    ),
                    onPressed: () {
                      if (deviceType == 0 || deviceType == 1) {
                        deviceTypeInt = 2;
                        deviceType = 2;
                        if (kIsWeb) {
                          // js.context.callMethod('recordHid',
                          //     ['Flutter is calling upon JavaScript!']);

                        } else {}

                        setState(() {});
                      } else {
                        // if (deviceType == 1){

                        deviceTypeInt = 0;
                        deviceType = 0;
                        if (kIsWeb) {
                          // js.context.callMethod('recordAudio',
                          //     ['Flutter is calling upon JavaScript!']);

                        } else {}

                        setState(() {});
                      }
                    },
                  ),
                  Positioned(
                    bottom: 0,
                    right: 12,
                    child: GestureDetector(
                      onTap: () {
                        if (deviceType == 0 || deviceType == 1) {
                          deviceTypeInt = 2;
                          deviceType = 2;
                          if (kIsWeb) {
                            // js.context.callMethod('recordHid',
                            //     ['Flutter is calling upon JavaScript!']);
                          } else {}

                          setState(() {});
                          _sendAnalyticsEvent("button_hid", {
                            "deviceType": deviceType,
                            "isStartingHid": 1,
                            "isStartingAudio": 0
                          });
                        } else {
                          // if (deviceType == 1){

                          deviceTypeInt = 0;
                          deviceType = 0;
                          if (kIsWeb) {
                            // js.context.callMethod('recordAudio',
                            //     ['Flutter is calling upon JavaScript!']);
                          } else {}

                          setState(() {});
                          _sendAnalyticsEvent("button_hid", {
                            "deviceType": deviceType,
                            "isStartingHid": 0,
                            "isStartingAudio": 1
                          });
                        }
                      },
                      child: Text(
                        "  PRO",
                        style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 15),
                      ),
                    ),
                  ),
                ]),
              ),
      );
    }

    if (isPlaying == 2 || isZooming) {
      lastPositionButton = Positioned(
          bottom: 20,
          left: MediaQuery.of(context).size.width / 2 + 70,
          child: Container(
            width: 60,
            height: 40,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                // style: ButtonStyle(
                fixedSize: const Size(50, 50),
                shape: const CircleBorder(),
                shadowColor: Colors.blue,

                primary: Colors.white,
                onPrimary: Colors.green,
                onSurface: Colors.red,
                // backgroundColor: getColor(Colors.blueGrey, Colors.blueGrey),
                // overlayColor: getColor(Colors.white60, Colors.white70)
              ),

              child: Icon(
                Icons.arrow_right_alt_rounded,
                color: Color(0xFF800000),
              ),
              // onPressed:  null,
              onPressed: () {
                if (isPlaying == 2) {
                  horizontalDiff = 0;
                  isPlaying = 1;
                  CURRENT_START = 0;
                  // if (deviceType == 0){
                  isPaused = false;
                  if (isOpeningFile == 0) {
                    if (kIsWeb) {
                      // js.context.callMethod('pauseResume', [3]);
                    } else {}

                    _sendAnalyticsEvent("return_play", {
                      "openingFile": 0,
                      "previous_playing": 0,
                      "deviceType": deviceType
                    });
                  } else {
                    isOpeningFile = 1;
                    if (kIsWeb) {
                      // js.context.callMethod('playData', [3]);
                    } else {}

                    _sendAnalyticsEvent("return_play", {
                      "openingFile": 1,
                      "previous_playing": 0,
                      "deviceType": deviceType
                    });
                  }
                  // }else{

                  // }
                } else if (isPlaying == 1) {
                  isPaused = false;
                  horizontalDiff = 0;
                  CURRENT_START = 0;
                  if (isOpeningFile == 0) {
                    if (kIsWeb) {
                      // js.context.callMethod('pauseResume', [3]);
                    } else {}

                    _sendAnalyticsEvent("return_play", {
                      "openingFile": 0,
                      "previous_playing": 1,
                      "deviceType": deviceType
                    });
                  } else {
                    isOpeningFile = 1;
                    if (kIsWeb) {
                      // js.context.callMethod('playData', [3]);
                    } else {}

                    _sendAnalyticsEvent("return_play", {
                      "openingFile": 1,
                      "previous_playing": 1,
                      "deviceType": deviceType
                    });
                  }
                }

                setState(() {});
              },
            ),
          ));

      dataWidgets.add(lastPositionButton);
    }

    if (isOpeningFile == 1 && isShowingResetButton) {
      dataWidgets.add(Positioned(
        bottom: 20,
        left: MediaQuery.of(context).size.width / 2 - 70,
        child: Container(
            width: 55,
            height: 35,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                fixedSize: const Size(30, 30),
                shape: const CircleBorder(),
                shadowColor: Colors.blue,
                primary: Colors.white,
                onPrimary: Colors.green,
                onSurface: Colors.red,
              ),
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.rotationY(pi),
                child: const Icon(Icons.refresh, color: Color(0xFF800000)),
              ),
              onPressed: () {
                if (kIsWeb) {
                  // js.context.callMethod('resetPlayback', [1]);
                } else {}

                setState(() {});
                _sendAnalyticsEvent("button_reset_playback", {
                  "isOpeningFile": 1,
                  "deviceType": deviceType,
                });
              },
            )),
      ));
    }

    if (isRecording == 0) {
      dataWidgets.add(Positioned(
        bottom: 20,
        left: MediaQuery.of(context).size.width / 2,
        child: Center(
          child: Container(
              width: 60,
              height: 40,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  // style: ButtonStyle(
                  fixedSize: const Size(50, 50),
                  shape: const CircleBorder(),
                  shadowColor: Colors.blue,

                  primary: Colors.white,
                  onPrimary: Colors.green,
                  onSurface: Colors.red,
                  // backgroundColor: getColor(Colors.blueGrey, Colors.blueGrey),
                  // overlayColor: getColor(Colors.white60, Colors.white70)
                ),

                child: isPlaying == 1
                    ? Icon(Icons.pause, color: Color(0xFF800000))
                    : Icon(
                        Icons.play_arrow,
                        color: Color(0xFF800000),
                      ),

                // onPressed:  null,
                onPressed: () {
                  // if (isPlaying==1){
                  //   return;
                  // }else
                  print("isOpeningFile");
                  print(isOpeningFile);
                  if (isOpeningFile == 0) {
                    if (isPlaying == 1) {
                      debouncerPlayback.run(() {
                        if (kIsWeb) {
                          // js.context.callMethod('pauseResume', [1]);
                        } else {}
                        isPaused = true;

                        isPlaying = 2;
                        setState(() {});
                        _sendAnalyticsEvent("button_play", {
                          "isOpeningFile": 0,
                          "isPlaying": 2,
                          "deviceType": deviceType
                        });
                      });
                    } else {
                      debouncerPlayback.run(() {
                        if (kIsWeb) {
                          // js.context.callMethod('pauseResume', [2]);
                        } else {}
                        isPaused = false;

                        isPlaying = 1;
                        setState(() {});
                        _sendAnalyticsEvent("button_play", {
                          "isOpeningFile": 0,
                          "isPlaying": 1,
                          "deviceType": deviceType
                        });
                      });
                    }
                  } else {
                    if (isPlaying == 1) {
                      debouncerPlayback.run(() {
                        if (kIsWeb) {
                          // js.context.callMethod('playData', [2]);
                        } else {}

                        isPlaying = 2;
                        setState(() {});
                        _sendAnalyticsEvent("button_play", {
                          "isOpeningFile": 1,
                          "isPlaying": 2,
                          "deviceType": deviceType
                        });
                      });
                    } else {
                      debouncerPlayback.run(() {
                        if (kIsWeb) {
                          // js.context.callMethod('playData', [1]);
                        } else {}

                        isPlaying = 1;
                        setState(() {});
                        _sendAnalyticsEvent("button_play", {
                          "isOpeningFile": 1,
                          "isPlaying": 1,
                          "deviceType": deviceType
                        });
                      });
                    }
                  }

                  setState(() {});
                },
              )),
        ),
      ));
    }
    // END adding TOOLBAR Button

    if (isTutored == '0' && tutorialStep == 1) {
      double tempMedian = (MediaQuery.of(context).size.height / 2 / 2);

      dataWidgets.insert(
        0,
        Positioned(
          key: keyTutorialAudio,
          top: tempMedian - 20,
          left: 170,
          child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: Icon(Icons.add,
                        // key: keyTutorialAudioGainPlus,
                        color: Colors.black,
                        size: 17),
                  ),
                  SizedBox(width: 10),
                  Text('Increase Gain',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.white)),
                ]),
                Text('To increase the signal gain click on plus sign',
                    style: TextStyle(fontSize: 12, color: Colors.white)),
                SizedBox(
                  height: 10,
                ),
                Row(
                  children: [
                    Transform.rotate(
                      angle: 90 * pi / 180,
                      child: Icon(Icons.water_drop_outlined,
                          // key: keyTutorialAudioLevel,
                          color: Colors.green),
                    ),
                    SizedBox(width: 10),
                    Text('Level',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.white)),
                  ],
                ),
                // Text( 'This is the median of the sample data', style: TextStyle( fontSize: 12, color:Colors.white) ),
                Text('This is the origin (y=0) point of the signal channel. ',
                    style: TextStyle(fontSize: 12, color: Colors.white)),
                Text('Click this button to toggle the channel on/off and ',
                    style: TextStyle(fontSize: 12, color: Colors.white)),
                Text('drag it to move the channel up or down. ',
                    style: TextStyle(fontSize: 12, color: Colors.white)),

                SizedBox(
                  height: 10,
                ),
                Row(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: Icon(Icons.remove,
                          // key: keyTutorialAudioGainMinus,
                          color: Colors.black,
                          size: 17),
                    ),
                    SizedBox(width: 10),
                    Text('Decrease Gain',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.white)),
                  ],
                ),
                Text('To decrease the signal gain click on minus sign',
                    style: TextStyle(fontSize: 12, color: Colors.white)),
                SizedBox(
                  height: 50,
                ),

                Text('Click here to continue',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.white)),
              ]),
        ),
      );
    }

    if (isTutored == '0' && tutorialStep == 0) {
      dataWidgets.insert(
          0,
          Positioned(
              top: MediaQuery.of(context).size.height / 2,
              left: MediaQuery.of(context).size.width / 2 - 100,
              child: Container(
                width: 150,
                height: 200,
                child: Column(
                  key: keyTutorialNavigation,
                  children: [
                    Image.asset('assets/sr_icon.png', width: 128, height: 128),
                    const Text(
                      "Welcome to Spike Recorder Web Edition",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const Text(
                      "Click the brain icon to start your neuroscience journey!",
                      style: TextStyle(fontSize: 12, color: Colors.white),
                      textAlign: TextAlign.center,
                    )
                  ],
                ),
              )));
    }

    // dataWidgets.add(
    //   Positioned(
    //     left: 10,
    //     top: MediaQuery.of(context).size.height * 0.75,
    //     child: Text(channelsData.length.toString(),
    //         style: TextStyle(color: Colors.white)),
    //   ),
    // );

    return dataWidgets;
  }

  String getStrMinTime(horizontalDragX, horizontalDragXFix, maxTime) {
    String strMinTime = '';
    double minTime = horizontalDragX / horizontalDragXFix * maxTime;
    // print("minTime");
    // print(minTime);
    if (minTime > 3600) {
      final lastDecimals =
          (minTime - minTime.floor()).toStringAsFixed(3).replaceFirst("0.", "");
      strMinTime =
          ((minTime / 3600).floor() % (3600 * 24)).toString().padLeft(2, "0") +
              ":" +
              ((minTime / 60).floor() % 3600).toString().padLeft(2, "0") +
              ":" +
              (minTime.floor() % 60).toString().padLeft(2, "0") +
              " " +
              lastDecimals;
    } else {
      final lastDecimals =
          (minTime - minTime.floor()).toStringAsFixed(3).replaceFirst("0.", "");
      strMinTime = ((minTime / 60).floor() % 3600).toString().padLeft(2, "0") +
          ":" +
          (minTime.floor() % 60).toString().padLeft(2, "0") +
          " " +
          lastDecimals;
    }
    // print("minTime");
    // print(strMinTime);
    return strMinTime;
  }

  Widget getMainWidget() {
    // return Stack(
    //     children: getDataWidgets(),
    // );
    // final ScrollController canvasController = ScrollController();
    // canvasController.addListener((){
    //   print(canvasController.initialScrollOffset);
    //   print(canvasController.offset);
    // });
    // return ScrollConfiguration(
    //   behavior: CanvasScrollBehavior(),
    //   child: ListView(
    //     children:[
    //       Stack(
    //         children: getDataWidgets(),
    //       )
    //     ]
    //   ),
    // );
    return Listener(
        onPointerSignal: (PointerSignalEvent dragDetails) {
          if (dragDetails is PointerScrollEvent) {
            int tempTimeScaleBar = timeScaleBar;
            int direction = 0;
            const arrTimeScale = [0.1, 1, 10, 50, 100, 500, 1000, 5000, 10000];

            if (dragDetails.kind != PointerDeviceKind.mouse) {
              return;
            }

            if (dragDetails.scrollDelta.dx == 0.0 &&
                dragDetails.scrollDelta.dy == 0.0) {
              return;
            } else if (dragDetails.scrollDelta.dy < 0 &&
                dragDetails.scrollDelta.dy > -500) {
              prevY = dragDetails.scrollDelta.dy;
              //down
              direction = -1;

              if (timeScaleBar - 1 < 10) {
              } else {
                timeScaleBar--;
              }
            } else if (dragDetails.scrollDelta.dy > 0 &&
                dragDetails.scrollDelta.dy < 500) {
              direction = 1;
              prevY = dragDetails.scrollDelta.dy;
              if (timeScaleBar + 1 > 80) {
              } else {
                timeScaleBar++;
              }
            }

            double tempDivider = myArrTimescale[timeScaleBar] / 10;
            int tempLevel = calculateLevel(myArrTimescale[timeScaleBar],
                sampleRate, MediaQuery.of(context).size.width, skipCounts);
            int prevSegment =
                (allEnvelopes[0][tempLevel].length / tempDivider).floor();
            // print(prevSegment);
            if (prevSegment <= 2) {
              timeScaleBar = tempTimeScaleBar;
              return;
            }

            int transformScale = (timeScaleBar / 10).floor();
            scaleBarWidth = MediaQuery.of(context).size.width /
                (arrScaleBar[timeScaleBar]) *
                arrTimeScale[transformScale] /
                10;
            curTimeScaleBar = (arrTimeScale[transformScale] / 10);
            var data = {
              "timeScaleBar": arrTimeScale[transformScale], // label in UI
              "levelScale": timeScaleBar, //scrollIdx
              "posX": dragDetails.localPosition.dx,
              "direction": direction
            };
            print("data onPointerSignal");
            print(data);

            if (timeScaleBar == -1) {
              timeScale = 1;
            } else {
              timeScale = arrTimeScale[transformScale];
            }
            if (kIsWeb) {
              //   // js.context.callMethod('setZoomLevel', [json.encode(data)]);
              //   level = calculateLevel(
              //       timeScale, sampleRate, MediaQuery.of(context).size.width, skipCounts);
            } else {
              // if (isPaused){
              setZoomLevel(data);
              // }
            }

            setState(() {});
          }
        },
        child: SafeArea(
          child: (isRecording > 9 && topRecordingBar > 0)
              ? Column(children: [
                  Container(
                    color: const Color(0xFF5b0303),
                    width: MediaQuery.of(context).size.width,
                    height: topRecordingBar,
                    child: Center(
                        child: Text("Recording   " + labelDuration,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold))),
                  ),
                  Container(
                    color: Colors.black,
                    width: MediaQuery.of(context).size.width,
                    height:
                        MediaQuery.of(context).size.height - topRecordingBar,
                    child: Stack(children: getDataWidgets()),
                  ),
                ])
              : Container(
                  color: Colors.black,
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height - topRecordingBar,
                  child: Stack(children: getDataWidgets()),
                ),
        ));
  }

  getLoadingWidget(BuildContext context) {
    return Container(
      color: const Color(0x77CCCCFF),
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      alignment: Alignment.center,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          SizedBox(height: 10),
          Text("Loading file..."),
        ],
      ),
    );
  }

  Widget getFeedbackWidget() {
    // print("globalChromeVersion");
    // print(globalChromeVersion);
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.white,
      child: FormBuilder(
          key: _formKey,
          // enabled: false,
          onChanged: () {
            // _formKey.currentState!.save();
            // debugPrint(_formKey.currentState!.value.toString());
          },
          // initialValue: {
          //   'chromeversion': globalChromeVersion
          // },

          autovalidateMode: AutovalidateMode.disabled,
          // initialValue: const {
          // },
          skipDisabled: true,
          child: Column(
            children: [
              FormBuilderTextField(
                autovalidateMode: AutovalidateMode.always,
                name: 'Feedback description',
                decoration: InputDecoration(
                  labelText: 'Feedback Description',
                  suffixIcon: _ageHasError
                      ? const Icon(Icons.error, color: Colors.red)
                      : const Icon(Icons.check, color: Colors.green),
                ),
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(),
                ]),
                // initialValue: '12',
                textInputAction: TextInputAction.next,
              ),
              // FormBuilderTextField(
              //   autovalidateMode: AutovalidateMode.always,
              //   readOnly: true,
              //   name: 'chromeversion',
              //   decoration: InputDecoration(
              //     labelText: 'Chrome Version',
              //   ),
              //   validator: FormBuilderValidators.compose([
              //     FormBuilderValidators.required(),
              //   ]),
              //   initialValue: globalChromeVersion,
              //   textInputAction: TextInputAction.next,
              // ),
              FormBuilderTextField(
                autovalidateMode: AutovalidateMode.always,
                name: 'Name',
                decoration: InputDecoration(
                  labelText: 'Name',
                  suffixIcon: _ageHasError
                      ? const Icon(Icons.error, color: Colors.red)
                      : const Icon(Icons.check, color: Colors.green),
                ),
                validator: FormBuilderValidators.compose([]),
                // initialValue: '12',
                textInputAction: TextInputAction.next,
              ),

              FormBuilderTextField(
                autovalidateMode: AutovalidateMode.always,
                name: 'Email',
                decoration: InputDecoration(
                  labelText: 'Email address',
                  suffixIcon: _ageHasError
                      ? const Icon(Icons.error, color: Colors.red)
                      : const Icon(Icons.check, color: Colors.green),
                ),
                // valueTransformer: (text) => num.tryParse(text),
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(),
                  FormBuilderValidators.email(
                      errorText: "Please put correct email"),
                ]),
                // initialValue: '12',
                textInputAction: TextInputAction.next,
              ),

              Text(errorMessage),
              Row(children: <Widget>[
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      isFeedback = false;
                      setState(() {});
                    },
                    style: ElevatedButton.styleFrom(
                      primary: Colors.red, // background
                      onPrimary: Colors.white, // foreground
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                SizedBox(width: 30),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState?.saveAndValidate() ?? false) {
                        debugPrint(_formKey.currentState?.value.toString());
                        errorMessage = "";
                        sendFeedbackForm(_formKey.currentState?.value);
                      } else {
                        debugPrint(_formKey.currentState?.value.toString());
                        errorMessage = "Validation failed";
                      }
                      setState(() {});
                    },
                    child: const Text(
                      'Submit',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ]),
            ],
          )),
    );
  }

  bool autoValidate = true;
  bool readOnly = false;
  bool showSegmentedControl = true;
  bool _ageHasError = false;
  bool _genderHasError = false;
  String errorMessage = "";
  final _formKey = GlobalKey<FormBuilderState>();

  void sendFeedbackForm(mapValue) async {
    var url = Uri.parse('https://staging-bybrain.web.app/feedback');
    var mapPost = new Map<String, String>.from(mapValue);

    // mapPost['chromeVersion'] = globalChromeVersion;
    _deviceData.forEach((key, value) {
      mapPost[key] = value;
    });
    mapPost["level"] = curLevel.toString();
    mapPost["skipCounts"] = curSkipCounts.toString();
    mapPost["sampleRate"] = sampleRate.toString();
    // mapPost["fps"] = curFps.toString();
    mapPost["deviceWidth"] = MediaQuery.of(context).size.width.toString();

    print("mapPos t");
    print(mapPost);

    var response = https.post(url, body: json.encode(mapPost));
    _sendAnalyticsEvent(
        "feedback_sent", {"deviceType": deviceType, "feedbackSent": 1});
    infoDialog(
      context,
      "Feedback Saved",
      "Thank you so much for your feedback, we will process the feedback to make the app better",
      positiveButtonText: "OK",
      positiveButtonAction: () {
        isFeedback = false;
        setState(() {});
      },
      negativeButtonText: "",
      negativeButtonAction: () {
        isFeedback = false;
        setState(() {});
      },
      hideNeutralButton: true,
      closeOnBackPress: false,
    );
  }

  getDeviceCatalog() async {
    String url =
        "https://backyardbrains.com/products/firmwares/devices/board-config.json";
    final response = (await https.get(Uri.parse(url)));
    if (response.statusCode == 200) {
      var catalog = json.decode(response.body);
      catalog['config']['boards'].forEach((board) {
        print(board['uniqueName']);
        DEVICE_CATALOG[board["uniqueName"].toString().trim()] = board;
      });
    }
  }

  getDeviceInfo() async {
    if (kIsWeb) {
      // js.context
      //     .callMethod('changeSerialChannel', [json.encode(data)]);
    } else if (Platform.isAndroid) {
      var data = asciiToUint8Array("b:;\n");
      print(data);
      port.write(data);
    } else {
      var data = asciiToUint8Array("b:;\n");
      print(data);
      serialPort.write(data);
      // print(serialPort.bytesToWrite);
      print("getDeviceInfo()");
    }
  }

  void callChangeSerialChannel(Map<String, int> params) {
    if (kIsWeb) {
      // js.context
      //     .callMethod('changeSerialChannel', [json.encode(data)]);
    } else {
      DISPLAY_CHANNEL = params['channelCount'] as int;
      String str = "c:" + DISPLAY_CHANNEL.toString() + ";\n";
      var data = asciiToUint8Array(str);
      print("write serial data");
      print(str);
      print(data);
      if (Platform.isAndroid) {
        port.write(data);
      } else {
        serialPort.write(data);
      }

      DISPLAY_CHANNEL = params["channelCount"] as int;
      sampleRate =
          (int.parse(CURRENT_DEVICE['maxSampleRate']) / DISPLAY_CHANNEL)
              .floor();
      cBuffIdx = -1;
      print(sampleRate);
    }
  }

  @override
  void dispose() {
    super.dispose();
    print("dispose");
    closeRawSerial();
  }

  void increaseGain(int c) {
    //Increase Gain
    if (deviceType == 0) {
      // if (channelGains[c] - 200 > 0){
      //   channelGains[c]-=200;
      // }
      double idx = listIndexAudio[c];
      if (idx - 1 > minIndexAudio) {
        idx--;
        listIndexAudio[c] = idx;
        channelGains[c] = listChannelAudio[idx.toInt()];
      }
      _sendAnalyticsEvent("button_gain_inc", {
        "device": "Audio",
        "deviceType": deviceType,
        "channel": c,
        "gains": channelGains[c],
      });
    } else if (deviceType == 2) {
      // if (channelGains[c] - 50 > 50){
      //   channelGains[c] -= 50;
      // }
      double idx = listIndexHid[c];
      if (idx - 1 > minIndexHid) {
        idx--;
        listIndexHid[c] = idx;
        channelGains[c] = listChannelHid[idx.toInt()];
      }
      _sendAnalyticsEvent("button_gain_inc", {
        "device": "HID",
        "deviceType": deviceType,
        "channel": c,
        "gains": channelGains[c],
      });
    } else {
      double idx = listIndexSerial[c];
      if (idx - 1 > minIndexSerial) {
        idx--;
        listIndexSerial[c] = idx;

        channelGains[c] = listChannelSerial[idx.toInt()];
      }
      _sendAnalyticsEvent("button_gain_inc", {
        "device": "Serial",
        "deviceType": deviceType,
        "channel": c,
        "gains": channelGains[c],
      });
    }
  }

  void decreaseGain(int c) {
    //Decrease Gain
    if (deviceType == 0) {
      // if (channelGains[c] + 200 < 20000){
      //   channelGains[c]+=200;
      // }
      double idx = listIndexAudio[c];
      if (idx + 1 < maxIndexAudio) {
        idx++;
        listIndexAudio[c] = idx;
        channelGains[c] = listChannelAudio[idx.toInt()];
      }
      _sendAnalyticsEvent("button_gain_dec", {
        "device": "Audio",
        "deviceType": deviceType,
        "channel": c,
        "gains": channelGains[c],
      });
    } else if (deviceType == 2) {
      // if (channelGains[c] + 50 < 1000){
      //   channelGains[c]+=50;
      // }
      double idx = listIndexHid[c];
      if (idx + 1 < maxIndexHid) {
        idx++;
        listIndexHid[c] = idx;

        channelGains[c] = listChannelHid[idx.toInt()];
      }
      _sendAnalyticsEvent("button_gain_dec", {
        "device": "HID",
        "deviceType": deviceType,
        "channel": c,
        "gains": channelGains[c],
      });
    } else {
      // if (channelGains[c] + 100 < 1800){
      //   channelGains[c]+=100;
      // }
      double idx = listIndexSerial[c];
      if (idx + 1 < maxIndexSerial) {
        idx++;
        listIndexSerial[c] = idx;
        channelGains[c] = listChannelSerial[idx.toInt()];
      }
      _sendAnalyticsEvent("button_gain_dec", {
        "device": "Serial",
        "deviceType": deviceType,
        "channel": c,
        "gains": channelGains[c],
      });
    }
    print("deviceType ++");
    print(deviceType);
    print(channelGains);
    print(listIndexSerial);
  }
}
