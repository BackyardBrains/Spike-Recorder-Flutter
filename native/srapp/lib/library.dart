import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:srmobileapp/main.dart';

import 'bloc/main_bloc.dart';

multiply(a, b) {
  return a * b;
}

floor(val) {
  return val.floor();
  // return Math.floor();
}

generateArray(size, initialValue) {
  List<int> array = [];
  for (var i = 0; i < size; ++i) {
    List<int> temp = [...array, initialValue];
    array = temp;
  }
  return array;
}

envelopingSamples(
    _head, sample, _envelopes, SIZE_LOGS2, skipCounts, forceLevel) {
  try {
    for (var j = 0; j < SIZE_LOGS2; j++) {
      if (forceLevel > -1 && j != forceLevel) continue;
      var skipCount = skipCounts[j];
      var envelopeSampleIndex = floor(_head / skipCount);
      var interleavedSignalIdx = envelopeSampleIndex * 2;

      if (_head % skipCount == 0) {
        _envelopes[j][interleavedSignalIdx] = sample;
        _envelopes[j][interleavedSignalIdx + 1] = sample;
      } else {
        if (sample < _envelopes[j][interleavedSignalIdx]) {
          _envelopes[j][interleavedSignalIdx] = sample;
        }
        if (sample > _envelopes[j][interleavedSignalIdx + 1]) {
          _envelopes[j][interleavedSignalIdx + 1] = sample;
        }
      }
    }
  } catch (err) {
    print("allEnvelopes 3");
    print(err);
    print('end err');
  }

}

calculateLevel(timescale, sampleRate, innerWidth, arrCounts) {
  var rawPocket = timescale * sampleRate / innerWidth / 1000;
  var currentLevel = arrCounts.length - 1;
  var i = arrCounts.length - 2;
  // if ((rawPocket).floor() < 4) {
  //   currentLevel = -1;
  // } else {
  if (kIsWeb) {
    if ((rawPocket).floor() < 4) {
      currentLevel = -1;
    }
    // } else
    // if (){
  } else if ((rawPocket).floor() < 1) {
    currentLevel = 0;
  } else {
    for (; i >= 0; i--) {
      if (arrCounts[i + 1] >= rawPocket && arrCounts[i] < rawPocket) {
        currentLevel = i + 1;
      }
    }
    if (currentLevel > arrCounts.length - 1) {
      currentLevel = arrCounts.length - 1;
    }
  }
  // print("Calculate Level : ");
  // print(timescale);
  // print(sampleRate);
  // print(innerWidth);
  // print(currentLevel);

  return currentLevel;
}

// late MainBloc libDeviceBloc;
late SendPort deviceInfoPort;
late SendPort expansionDeviceInfoPort;
// SERIAL
const RAW_SIZE_OF_INPUT_HARDWARE_CIRC_BUFFER = 4096 * 2;
const SIZE_OF_INPUT_HARDWARE_CIRC_BUFFER = 4096 * 4;
const SIZE_OF_MESSAGES_BUFFER = 64;
const ESCAPE_SEQUENCE_LENGTH = 6;
const const_data = 4096 * 4;
// const const_data = 4096 * 4;

// int cBufHead = 0;
// int cBufTail = 0;

// bool weAreInsideEscapeSequence = false;
// int escapeSequenceDetectorIndex = 0;
// int messageBufferIndex = 0;

var escapeSequence = [255, 255, 1, 1, 128, 255];
var endOfescapeSequence = [255, 255, 1, 1, 129, 255];
bool isThreshold = false;
Uint8List circularBuffer = Uint8List(0);
// endOfescapeSequence[0] = 255;
// endOfescapeSequence[1] = 255;
// endOfescapeSequence[2] = 1;
// endOfescapeSequence[3] = 1;
// endOfescapeSequence[4] = 129;
// endOfescapeSequence[5] = 255;

setCircularBuffer(Uint8List cirBuf){
  circularBuffer = cirBuf;
}

executeOneMessage(String typeOfMessage, String valueOfMessage, int offsetin, Map<String, dynamic> writeResult) {
  // print("typeOfMessage");
  // print(typeOfMessage);
  if (typeOfMessage == "HWT") {
    var hardwareType = (valueOfMessage);
    if (DEVICE_CATALOG[hardwareType] != null) {
      CURRENT_DEVICE = DEVICE_CATALOG[hardwareType];
      //SEND INTO STREAM, REDRAW
      deviceInfoPort.send(hardwareType);
    }
  } else if (typeOfMessage == "EVNT") {
    // try{
    var mkey = valueOfMessage.codeUnitAt(0) - 48;
    // print('mkey');
    // print(mkey);
    if (writeResult['isThresholding']){

      if (writeResult['thresholdingType'] == 0){

      }else
      if (writeResult['thresholdingType'] != mkey){
        return;
      }
    }
    if (writeResult['eventsData'] == null){
      writeResult['eventsData'] = {};
      writeResult['eventsData']['indices'] = List<int>.filled(0, 0, growable: true);
      writeResult['eventsData']['numbers'] = List<String>.filled(0, "", growable: true);
      writeResult['eventsData']['positions'] = List<double>.filled(0, 0.0, growable: true);
      writeResult['eventsData']['eventIndices'] = List<int>.filled(0, 0, growable: true);
      // writeResult['eventsData']['drawIndices'] = List<int>.filled(0, 0, growable: true);
      writeResult['eventsData']['counter'] = 0;
    }

    writeResult['eventsData']['indices'].add(mkey);
    writeResult['eventsData']['numbers'].add(mkey.toString());

    writeResult['eventsData']['positions'].add(writeResult['cBufHead'].toDouble() + offsetin);
    writeResult['eventsData']['eventIndices'].add(writeResult['posCurSample']);
    writeResult['eventsData']['counter']++;

  } //EVNT
  else if (typeOfMessage == "BRD") {
    var newAddOnBoard = valueOfMessage.toString().codeUnitAt(0) - 48;
    CURRENT_DEVICE["expansionBoards"].forEach((board) {
      if (board["boardType"] == newAddOnBoard) {
        expansionDeviceInfoPort.send(board);
      }
    });
    // var newAddOnBoard = valueOfMessage.charCodeAt(0) - 48;
    // if (newAddOnBoard == 0) {
    //   drawState[DRAW_STATE.CHANNEL_COUNTS] = drawState[DRAW_STATE.MIN_CHANNELS];
    //   drawState[DRAW_STATE.EXTRA_CHANNELS] = 0;
    //   drawState[DRAW_STATE.MAX_CHANNELS] =
    //       (new Uint8Array(SharedBuffers.maxChannels))[0];

    //   // productId : new SharedArrayBuffer( 1 * Uint16Array.BYTES_PER_ELEMENT),
    //   // maxSampleRate : new SharedArrayBuffer( 1 * Uint16Array.BYTES_PER_ELEMENT),
    //   // minChannels : new SharedArrayBuffer( 1 * Uint8Array.BYTES_PER_ELEMENT),
    //   // maxChannels : new SharedArrayBuffer( 1 * Uint8Array.BYTES_PER_ELEMENT),
    //   // sampleRates : new SharedArrayBuffer( 6 * Uint16Array.BYTES_PER_ELEMENT),
    //   // channels : new SharedArrayBuffer( 6 * Uint8Array.BYTES_PER_ELEMENT),
    //   currentAddOnBoard = 0;
    // } else if (newAddOnBoard == BOARD_WITH_ADDITIONAL_INPUTS) {
    //   if (currentAddOnBoard != BOARD_WITH_ADDITIONAL_INPUTS) {
    //     if (drawState[DRAW_STATE.EXTRA_CHANNELS] == 0) {
    //       drawState[DRAW_STATE.CHANNEL_COUNTS] = 4;
    //       drawState[DRAW_STATE.MAX_CHANNELS] = 4;
    //       drawState[DRAW_STATE.EXTRA_CHANNELS] = 4;
    //       // clearBuffer();
    //     } else {
    //       drawState[DRAW_STATE.CHANNEL_COUNTS] =
    //           drawState[DRAW_STATE.MIN_CHANNELS];
    //       drawState[DRAW_STATE.EXTRA_CHANNELS] = 0;
    //       // clearBuffer();

    //     }
    //     // drawState[DRAW_STATE.MAX_CHANNELS] = drawState[DRAW_STATE.MIN_CHANNELS] + 4;

    //     currentAddOnBoard = newAddOnBoard;
    //     _shouldRestartDevice = true;
    //   }
    // } else if (newAddOnBoard == BOARD_WITH_HAMMER) {
    //   if (currentAddOnBoard != BOARD_WITH_HAMMER) {
    //     console.log("HAMMER : ", drawState[DRAW_STATE.EXTRA_CHANNELS]);
    //     if (drawState[DRAW_STATE.EXTRA_CHANNELS] == 0) {
    //       // drawState[DRAW_STATE.SAMPLE_RATE] = 1000;
    //       drawState[DRAW_STATE.CHANNEL_COUNTS] = 3;
    //       drawState[DRAW_STATE.MAX_CHANNELS] = 3;
    //       drawState[DRAW_STATE.EXTRA_CHANNELS] = 3;
    //       // clearBuffer();
    //     } else {
    //       drawState[DRAW_STATE.CHANNEL_COUNTS] =
    //           drawState[DRAW_STATE.MIN_CHANNELS];
    //       drawState[DRAW_STATE.EXTRA_CHANNELS] = 0;
    //       // clearBuffer();

    //     }

    //     // drawState[DRAW_STATE.MAX_CHANNELS] = drawState[DRAW_STATE.MIN_CHANNELS] + 3;
    //     currentAddOnBoard = newAddOnBoard;
    //     _shouldRestartDevice = true;
    //   }
    // } else if (newAddOnBoard == BOARD_WITH_JOYSTICK) {
    //   if (currentAddOnBoard != BOARD_WITH_JOYSTICK) {
    //     if (drawState[DRAW_STATE.EXTRA_CHANNELS] == 0) {
    //       // drawState[DRAW_STATE.SAMPLE_RATE] = 1000;
    //       drawState[DRAW_STATE.CHANNEL_COUNTS] = 3;
    //       drawState[DRAW_STATE.MAX_CHANNELS] = 3;
    //       drawState[DRAW_STATE.EXTRA_CHANNELS] = 3;
    //       // clearBuffer();
    //     } else {
    //       drawState[DRAW_STATE.CHANNEL_COUNTS] =
    //           drawState[DRAW_STATE.MIN_CHANNELS];
    //       drawState[DRAW_STATE.EXTRA_CHANNELS] = 0;
    //       // clearBuffer();
    //     }
    //     // drawState[DRAW_STATE.MAX_CHANNELS] = drawState[DRAW_STATE.MIN_CHANNELS] + 3;

    //     currentAddOnBoard = newAddOnBoard;
    //     _shouldRestartDevice = true;
    //   }
    // } else if (newAddOnBoard == BOARD_WITH_EVENT_INPUTS) {
    //   if (currentAddOnBoard != BOARD_WITH_EVENT_INPUTS) {
    //     if (drawState[DRAW_STATE.EXTRA_CHANNELS] == 0) {
    //       // drawState[DRAW_STATE.SAMPLE_RATE] = 1000;
    //       drawState[DRAW_STATE.CHANNEL_COUNTS] = 2;
    //       drawState[DRAW_STATE.MAX_CHANNELS] = 2;
    //       drawState[DRAW_STATE.EXTRA_CHANNELS] = 2;
    //       // clearBuffer();
    //     } else {
    //       drawState[DRAW_STATE.CHANNEL_COUNTS] =
    //           drawState[DRAW_STATE.MIN_CHANNELS];
    //       drawState[DRAW_STATE.EXTRA_CHANNELS] = 0;
    //       // clearBuffer();
    //     }
    //     // drawState[DRAW_STATE.MAX_CHANNELS] = drawState[DRAW_STATE.MIN_CHANNELS] + 3;

    //     currentAddOnBoard = newAddOnBoard;
    //     _shouldRestartDevice = true;
    //   }
    // } else if (newAddOnBoard == BOARD_ERG) {
    //   if (currentAddOnBoard != BOARD_ERG) {
    //     if (drawState[DRAW_STATE.EXTRA_CHANNELS] == 0) {
    //       // drawState[DRAW_STATE.SAMPLE_RATE] = 3000;
    //       drawState[DRAW_STATE.CHANNEL_COUNTS] = 3;
    //       drawState[DRAW_STATE.MAX_CHANNELS] = 3;
    //       drawState[DRAW_STATE.EXTRA_CHANNELS] = 3;
    //       // clearBuffer();
    //     } else {
    //       drawState[DRAW_STATE.CHANNEL_COUNTS] =
    //           drawState[DRAW_STATE.MIN_CHANNELS];
    //       drawState[DRAW_STATE.EXTRA_CHANNELS] = 0;
    //       // clearBuffer();
    //     }
    //     // drawState[DRAW_STATE.MAX_CHANNELS] = drawState[DRAW_STATE.MIN_CHANNELS] + 3;

    //     currentAddOnBoard = newAddOnBoard;
    //     _shouldRestartDevice = true;
    //   }
    // } else {
    //   if (DRAW_STATE.CHANNEL_COUNTS != 2) {
    //     if (drawState[DRAW_STATE.EXTRA_CHANNELS] == 0) {
    //       // drawState[DRAW_STATE.SAMPLE_RATE] = 1000;
    //       drawState[DRAW_STATE.CHANNEL_COUNTS] = 2;
    //       drawState[DRAW_STATE.MAX_CHANNELS] = 2;
    //       drawState[DRAW_STATE.EXTRA_CHANNELS] = 2;
    //       // clearBuffer();
    //     } else {
    //       drawState[DRAW_STATE.CHANNEL_COUNTS] =
    //           drawState[DRAW_STATE.MIN_CHANNELS];
    //       drawState[DRAW_STATE.EXTRA_CHANNELS] = 0;
    //       // clearBuffer();
    //     }
    //     // drawState[DRAW_STATE.MAX_CHANNELS] = drawState[DRAW_STATE.MIN_CHANNELS] + 3;

    //     currentAddOnBoard = newAddOnBoard;
    //     _shouldRestartDevice = true;
    //   }
    // }
    // drawState[DRAW_STATE.SAMPLE_RATE] = drawState[DRAW_STATE.SAMPLING_RATE_1 +
    //     (drawState[DRAW_STATE.CHANNEL_COUNTS] - 1)];
  } //BRD

  // if(typeOfMessage == "HWT")
  // {
  //     hardwareType = valueOfMessage;

  //     let found=hardwareType.indexOf("PLANTSS");
  //     if (found>-1)
  //     {
  //         // setDeviceTypeToCurrentPort(ArduinoSerial::plant);
  //     }
  //     else
  //     {
  //         found=hardwareType.indexOf("MUSCLESS");
  //         if (found>-1)
  //         {
  //             // setDeviceTypeToCurrentPort(ArduinoSerial::muscle);
  //         }
  //         else
  //         {
  //             found=hardwareType.indexOf("HEARTSS");
  //             if (found>-1)
  //             {
  //                 // setDeviceTypeToCurrentPort(ArduinoSerial::heart);
  //             }
  //             else
  //             {
  //                 found=hardwareType.indexOf("HBLEOSB");//leonardo heart and brain with one channel only
  //                 if (found>-1)
  //                 {
  //                     // setDeviceTypeToCurrentPort(ArduinoSerial::heartOneChannel);
  //                 }
  //                 else
  //                 {
  //                     found=hardwareType.indexOf("HBSBPRO");//leonardo heart and brain with one channel only
  //                     if (found>-1)
  //                     {
  //                         // setDeviceTypeToCurrentPort(ArduinoSerial::heartPro);
  //                     }
  //                     else
  //                     {
  //                         //NEURONSS
  //                         found=hardwareType.indexOf("NEURONSS");//neuron SpikerBox one channel
  //                         if (found>-1)
  //                         {
  //                             // setDeviceTypeToCurrentPort(ArduinoSerial::neuronOneChannel);
  //                         }
  //                         else
  //                         {
  //                             found=hardwareType.indexOf("MUSCUSB1");
  //                             if (found>-1)
  //                             {
  //                                 // setDeviceTypeToCurrentPort(ArduinoSerial::muscleusb);
  //                             }
  //                             else
  //                             {
  //                                 found=hardwareType.indexOf("HUMANSB");
  //                                 if (found>-1)
  //                                 {
  //                                     // setDeviceTypeToCurrentPort(ArduinoSerial::humansb);
  //                                     // _manager->checkIfFirmwareIsAvailableForBootloader();
  //                                 }
  //                                 else
  //                                 {
  //                                     found=hardwareType.indexOf("HHIBOX");
  //                                     if (found>-1)
  //                                     {
  //                                         // setDeviceTypeToCurrentPort(ArduinoSerial::hhibox);
  //                                     }

  //                                 }

  //                             }
  //                         }
  //                     }
  //                 }
  //             }
  //         }
  //     }
  // }

  // if(!_justScanning)
  // if(true)
  // {

  ////////////
  //   if(typeOfMessage == "EVNT")
  //   {
  //     // try{
  //       const mkey = valueOfMessage.codeUnitAt(0)-48;
  //       if (sabDraw){

  //           let ctr = drawState[DRAW_STATE.EVENT_COUNTER];
  //           eventsInt[ctr] = mkey;
  //           eventPositionInt[ctr] = _arrHeadsInt[0] + offsetin;

  //           eventGlobalPositionInt[ctr] = globalPositionCap[0] * SIZE + _arrHeadsInt[0];
  //           // eventsIdxInt[ctr] = drawState[DRAW_STATE.EVENT_NUMBER];
  //           eventsIdxInt[ctr] = mkey;

  //           ctr = (ctr + 1) % 200;
  //           eventsCounterInt[0] = ctr;
  //           drawState[DRAW_STATE.EVENT_NUMBER] = mkey;

  //           drawState[DRAW_STATE.EVENT_COUNTER] = ctr;
  //           drawState[DRAW_STATE.EVENT_POSITION] = _arrHeadsInt[0] + offsetin;
  //           console.log("_arrHeadsInt[0] : ", _arrHeadsInt[0]);

  //         // drawState[DRAW_STATE.EVENT_FLAG] = 1;
  //         // drawState[DRAW_STATE.EVENT_NUMBER] = mkey;
  //       }

  //     // }catch(err){
  //     //   console.log("evnt error");
  //     // }
  //   }//EVNT
  //   else

  //   if(typeOfMessage == "BRD")
  //   {
  //       clearBuffer();
  //       // console.log("EXPANSION BOARDD!!!");
  //       // Log::msg("Change board type on serial");
  //       // int newAddOnBoard = (int)((unsigned int)valueOfMessage[0]-48);
  //       const newAddOnBoard = valueOfMessage.charCodeAt(0)-48;
  //       // const newAddOnBoard = parseInt(valueOfMessage[0]) - 1;
  //       console.log("EXPANSION BOARDD!!! ", newAddOnBoard);
  //       if (newAddOnBoard == 0){

  //         drawState[DRAW_STATE.CHANNEL_COUNTS] = drawState[DRAW_STATE.MIN_CHANNELS];
  //         drawState[DRAW_STATE.EXTRA_CHANNELS] = 0;
  //         drawState[DRAW_STATE.MAX_CHANNELS] = (new Uint8Array(SharedBuffers.maxChannels) )[0];

  //               // productId : new SharedArrayBuffer( 1 * Uint16Array.BYTES_PER_ELEMENT),
  //               // maxSampleRate : new SharedArrayBuffer( 1 * Uint16Array.BYTES_PER_ELEMENT),
  //               // minChannels : new SharedArrayBuffer( 1 * Uint8Array.BYTES_PER_ELEMENT),
  //               // maxChannels : new SharedArrayBuffer( 1 * Uint8Array.BYTES_PER_ELEMENT),
  //               // sampleRates : new SharedArrayBuffer( 6 * Uint16Array.BYTES_PER_ELEMENT),
  //               // channels : new SharedArrayBuffer( 6 * Uint8Array.BYTES_PER_ELEMENT),
  //         currentAddOnBoard = 0;
  //       }else
  //       if(newAddOnBoard == BOARD_WITH_ADDITIONAL_INPUTS)
  //       {
  //           if(currentAddOnBoard != BOARD_WITH_ADDITIONAL_INPUTS)
  //           {
  //             if (drawState[DRAW_STATE.EXTRA_CHANNELS] == 0){
  //               drawState[DRAW_STATE.CHANNEL_COUNTS] = 4;
  //               drawState[DRAW_STATE.MAX_CHANNELS] =4;
  //               drawState[DRAW_STATE.EXTRA_CHANNELS] = 4;
  //               // clearBuffer();
  //             }else{
  //               drawState[DRAW_STATE.CHANNEL_COUNTS] = drawState[DRAW_STATE.MIN_CHANNELS];
  //               drawState[DRAW_STATE.EXTRA_CHANNELS] = 0;
  //               // clearBuffer();

  //             }
  //             // drawState[DRAW_STATE.MAX_CHANNELS] = drawState[DRAW_STATE.MIN_CHANNELS] + 4;

  //             currentAddOnBoard =newAddOnBoard;
  //             _shouldRestartDevice = true;

  //           }

  //       }
  //       else if(newAddOnBoard == BOARD_WITH_HAMMER)
  //       {
  //           if(currentAddOnBoard != BOARD_WITH_HAMMER)
  //           {
  //             console.log("HAMMER : ",drawState[DRAW_STATE.EXTRA_CHANNELS]);
  //             if (drawState[DRAW_STATE.EXTRA_CHANNELS] == 0){
  //               // drawState[DRAW_STATE.SAMPLE_RATE] = 1000;
  //               drawState[DRAW_STATE.CHANNEL_COUNTS] = 3;
  //               drawState[DRAW_STATE.MAX_CHANNELS] = 3;
  //               drawState[DRAW_STATE.EXTRA_CHANNELS] = 3;
  //               // clearBuffer();
  //             }else{
  //               drawState[DRAW_STATE.CHANNEL_COUNTS] = drawState[DRAW_STATE.MIN_CHANNELS];
  //               drawState[DRAW_STATE.EXTRA_CHANNELS] = 0;
  //               // clearBuffer();

  //             }

  //             // drawState[DRAW_STATE.MAX_CHANNELS] = drawState[DRAW_STATE.MIN_CHANNELS] + 3;
  //             currentAddOnBoard =newAddOnBoard;
  //             _shouldRestartDevice = true;
  //           }
  //       }
  //       else if(newAddOnBoard == BOARD_WITH_JOYSTICK)
  //       {
  //           if(currentAddOnBoard != BOARD_WITH_JOYSTICK)
  //           {
  //             if (drawState[DRAW_STATE.EXTRA_CHANNELS] == 0){

  //               // drawState[DRAW_STATE.SAMPLE_RATE] = 1000;
  //               drawState[DRAW_STATE.CHANNEL_COUNTS] = 3;
  //               drawState[DRAW_STATE.MAX_CHANNELS] = 3;
  //               drawState[DRAW_STATE.EXTRA_CHANNELS] = 3;
  //               // clearBuffer();
  //             }else{
  //               drawState[DRAW_STATE.CHANNEL_COUNTS] = drawState[DRAW_STATE.MIN_CHANNELS];
  //               drawState[DRAW_STATE.EXTRA_CHANNELS] = 0;
  //               // clearBuffer();
  //             }
  //             // drawState[DRAW_STATE.MAX_CHANNELS] = drawState[DRAW_STATE.MIN_CHANNELS] + 3;

  //             currentAddOnBoard =newAddOnBoard;
  //             _shouldRestartDevice = true;
  //           }
  //       }
  //       else if(newAddOnBoard == BOARD_WITH_EVENT_INPUTS)
  //       {
  //           if(currentAddOnBoard != BOARD_WITH_EVENT_INPUTS)
  //           {
  //             if (drawState[DRAW_STATE.EXTRA_CHANNELS] == 0){
  //               // drawState[DRAW_STATE.SAMPLE_RATE] = 1000;
  //               drawState[DRAW_STATE.CHANNEL_COUNTS] = 2;
  //               drawState[DRAW_STATE.MAX_CHANNELS] = 2;
  //               drawState[DRAW_STATE.EXTRA_CHANNELS] = 2;
  //               // clearBuffer();
  //             }else{
  //               drawState[DRAW_STATE.CHANNEL_COUNTS] = drawState[DRAW_STATE.MIN_CHANNELS];
  //               drawState[DRAW_STATE.EXTRA_CHANNELS] = 0;
  //               // clearBuffer();
  //             }
  //             // drawState[DRAW_STATE.MAX_CHANNELS] = drawState[DRAW_STATE.MIN_CHANNELS] + 3;

  //             currentAddOnBoard =newAddOnBoard;
  //             _shouldRestartDevice = true;

  //           }
  //       }
  //       else if(newAddOnBoard == BOARD_ERG)
  //       {
  //           if(currentAddOnBoard != BOARD_ERG)
  //           {
  //             if (drawState[DRAW_STATE.EXTRA_CHANNELS] == 0){
  //               // drawState[DRAW_STATE.SAMPLE_RATE] = 3000;
  //               drawState[DRAW_STATE.CHANNEL_COUNTS] = 3;
  //               drawState[DRAW_STATE.MAX_CHANNELS] = 3;
  //               drawState[DRAW_STATE.EXTRA_CHANNELS] = 3;
  //               // clearBuffer();
  //             }else{
  //               drawState[DRAW_STATE.CHANNEL_COUNTS] = drawState[DRAW_STATE.MIN_CHANNELS];
  //               drawState[DRAW_STATE.EXTRA_CHANNELS] = 0;
  //               // clearBuffer();
  //             }
  //             // drawState[DRAW_STATE.MAX_CHANNELS] = drawState[DRAW_STATE.MIN_CHANNELS] + 3;

  //             currentAddOnBoard =newAddOnBoard;
  //             _shouldRestartDevice = true;
  //           }
  //       }
  //       else
  //       {
  //           if(DRAW_STATE.CHANNEL_COUNTS != 2)
  //           {
  //             if (drawState[DRAW_STATE.EXTRA_CHANNELS] == 0){

  //               // drawState[DRAW_STATE.SAMPLE_RATE] = 1000;
  //               drawState[DRAW_STATE.CHANNEL_COUNTS] = 2;
  //               drawState[DRAW_STATE.MAX_CHANNELS] = 2;
  //               drawState[DRAW_STATE.EXTRA_CHANNELS] = 2;
  //               // clearBuffer();
  //             }else{
  //               drawState[DRAW_STATE.CHANNEL_COUNTS] = drawState[DRAW_STATE.MIN_CHANNELS];
  //               drawState[DRAW_STATE.EXTRA_CHANNELS] = 0;
  //               // clearBuffer();
  //             }
  //             // drawState[DRAW_STATE.MAX_CHANNELS] = drawState[DRAW_STATE.MIN_CHANNELS] + 3;

  //             currentAddOnBoard =newAddOnBoard;
  //             _shouldRestartDevice = true;
  //           }
  //       }
  //       drawState[DRAW_STATE.SAMPLE_RATE] = drawState[DRAW_STATE.SAMPLING_RATE_1 + ( drawState[DRAW_STATE.CHANNEL_COUNTS] - 1) ];

  //   }//BRD
  ////////////

  // }
}

executeContentOfMessageBuffer(int offset,Uint8List messagesBuffer, Map<String, dynamic> writeResult) {
  var stillProcessing = true;
  var currentPositionInString = 0;
//   let message = new Uint8Array(SIZE_OF_MESSAGES_BUFFER);
  List<int> message = generateArray(SIZE_OF_MESSAGES_BUFFER, 0);
  var endOfMessage = 0;
  var startOfMessage = 0;

  while (stillProcessing) {
    if (messagesBuffer[currentPositionInString] == ';'.codeUnitAt(0)) {
    // if (messagesBuffer[currentPositionInString] == 59) {
      for (var k = 0; k < endOfMessage - startOfMessage; k++) {
        if (message[k] == ':'.codeUnitAt(0)) {
        // if (message[k] == 58) {
          //   const str = String.fromCharCode(...message);
          // try{
            // print("message execute " + message.length.toString() + ' _ ' + k.toString() + ' __ ' +currentPositionInString.toString());
            // print('offset'+offset.toString());
            // print('inside escape? '+ writeResult['weAreInsideEscapeSequence'].toString());
            
            // print(message.sublist(0, currentPositionInString));
            // print(k);

            var str = utf8.decode(message.sublist(0, currentPositionInString));
            // print(str);
            var arrStr = str.split(':');
            var typeOfMessage = arrStr[arrStr.length-2];
            var valueOfMessage = arrStr[arrStr.length-1];

            // var arr1 = message.sublist(k);
            // var arr2 = message.sublist(k+1, (endOfMessage-startOfMessage)-k-2);
            // var typeOfMessage = utf8.decode(arr1);
            // var valueOfMessage = utf8.decode(arr2);
            var offsetMessage = offset;
            // print('typeOfMessage');
            // print(typeOfMessage);
            // print(valueOfMessage);

            executeOneMessage(typeOfMessage, valueOfMessage, offsetMessage, writeResult);
            break;

          // }catch(err){
          //   writeResult['debugError'] = true;
          //   break;
          // }
        }
      }
      startOfMessage = endOfMessage + 1;
      currentPositionInString++;
      endOfMessage++;
    } else {
      message[currentPositionInString - startOfMessage] =
          messagesBuffer[currentPositionInString];
      currentPositionInString++;
      endOfMessage++;
    }

    if (currentPositionInString >= SIZE_OF_MESSAGES_BUFFER) {
      stillProcessing = false;
    }
  }
}

testEscapeSequence(int newByte,int offset,Uint8List messagesBuffer, bool weAreInsideEscapeSequence,
    _messageBufferIndex, escapeSequenceDetectorIndex, writeResult, _isThreshold, int sampleIndex) {

  int cBufHead = writeResult['cBufHead'];
  int cBufTail = writeResult['cBufTail'];
  int totalRawMessage = writeResult['totalRawMessage'];
  int resetHead = writeResult['resetHead'];
  int messageBufferIndex = writeResult['messageBufferIndex'];
  isThreshold = _isThreshold;
  if (weAreInsideEscapeSequence) {
    totalRawMessage++;
    if (messageBufferIndex >= SIZE_OF_MESSAGES_BUFFER) {
      weAreInsideEscapeSequence = false; //end of escape sequence
      // print('weAreInsideEscapeSequence false');
      executeContentOfMessageBuffer(offset, messagesBuffer, writeResult);
      escapeSequenceDetectorIndex = 0;
      totalRawMessage = 0;
      // messageBufferIndex = 0;
      //prepare for detecting begining of sequence
      writeResult['weAreInsideEscapeSequence'] = weAreInsideEscapeSequence;
    } else if (endOfescapeSequence[escapeSequenceDetectorIndex] == newByte) {
      escapeSequenceDetectorIndex++;
      if (escapeSequenceDetectorIndex == ESCAPE_SEQUENCE_LENGTH) {
        weAreInsideEscapeSequence = false; //end of escape sequence
        // print('executing');
        // print(messagesBuffer.sublist(0, messageBufferIndex));

        // print('weAreInsideEscapeSequence false2');
        executeContentOfMessageBuffer(offset, messagesBuffer,writeResult);
        escapeSequenceDetectorIndex = 0;
        totalRawMessage = 0;
        // messageBufferIndex = 0;
        //prepare for detecting begining of sequence

        writeResult['weAreInsideEscapeSequence'] = weAreInsideEscapeSequence;
        writeResult['isEndEscapeSequence'] = true;
      }
    } else {
      escapeSequenceDetectorIndex = 0;
    }
  } else {
    if (escapeSequence[escapeSequenceDetectorIndex] == newByte) {
      escapeSequenceDetectorIndex++;
      totalRawMessage++;

      if (escapeSequenceDetectorIndex == ESCAPE_SEQUENCE_LENGTH) {
        // print('reverting');
        // print(messagesBuffer.sublist(0, messageBufferIndex));
        
        weAreInsideEscapeSequence = true; //found escape sequence
        // for (var i = 0; i < SIZE_OF_MESSAGES_BUFFER; i++) {
        //   messagesBuffer[i] = 0;
        // }
        messagesBuffer.fillRange(0,SIZE_OF_MESSAGES_BUFFER,0);
        // print(messagesBuffer.sublist(0, messageBufferIndex));
        messageBufferIndex = 0; //prepare for receiving message
        escapeSequenceDetectorIndex = 0;
        totalRawMessage = 0;

        //prepare for detecting end of esc. sequence

        //rewind writing head and effectively delete escape sequence from data
        for (int i = 0; i < ESCAPE_SEQUENCE_LENGTH; i++) {
          cBufHead--;
          if (cBufHead < 0) {
            cBufHead = const_data - 1;
          }
          resetHead--;
          if (resetHead < 0) {
            resetHead = 0;
          }
          // cBufTail--;
          // if (cBufTail < 0) {
          //   cBufTail = 0;
          // }

        }
        if (sampleIndex - ESCAPE_SEQUENCE_LENGTH < 0){
          cBufTail = cBufTail - (ESCAPE_SEQUENCE_LENGTH);
          if (cBufTail < 0) {
            cBufTail = 0;
          }

        }else{
          cBufTail = cBufTail - ESCAPE_SEQUENCE_LENGTH;
          if (cBufTail < 0) {
            cBufTail = 0;
          }
        }

        // writeResult['messagesBuffer'] = messagesBuffer;
        writeResult['cBufHead'] = cBufHead;
        writeResult['cBufTail'] = cBufTail;
        writeResult['resetHead'] = resetHead;
        // print('weAreInsideEscapeSequence true '+cBufHead.toString());
        writeResult['weAreInsideEscapeSequence'] = weAreInsideEscapeSequence;
      }
    } else {
      escapeSequenceDetectorIndex = 0;
      if (escapeSequence[escapeSequenceDetectorIndex] == newByte){
        print('newByte');
        print(newByte);
        print(escapeSequence[escapeSequenceDetectorIndex]);
        escapeSequenceDetectorIndex++;
        cBufHead--;
        writeResult['cBufHead'] = cBufHead;
      }
    }
  }

  writeResult['weAreInsideEscapeSequence'] = weAreInsideEscapeSequence;
  writeResult['escapeSequenceDetectorIndex'] = escapeSequenceDetectorIndex;
  writeResult['messageBufferIndex'] = messageBufferIndex;
  writeResult['totalRawMessage'] = totalRawMessage;

  // print("messagesBuffer");
  // print(messagesBuffer.sublist(0, 30));
}

frameHasAllBytes(int _numberOfChannels, int cBufTail) {
  var tempTail = cBufTail + 1;
  if (tempTail >= SIZE_OF_INPUT_HARDWARE_CIRC_BUFFER) {
    tempTail = 0;
  }
  for (var i = 0; i < (_numberOfChannels * 2 - 1); i++) {
    var nextByte = (circularBuffer[tempTail]) & 0xFF;
    if (nextByte > 127) {
      // Log::msg("HID frame with less bytes");
      return false;
    }
    tempTail++;
    if (tempTail >= SIZE_OF_INPUT_HARDWARE_CIRC_BUFFER) {
      tempTail = 0;
    }
  }
  return true;
}

checkIfHaveWholeFrame(int cBufTail,int cBufHead) {
  var tempTail = cBufTail + 1;
  if (tempTail >= SIZE_OF_INPUT_HARDWARE_CIRC_BUFFER)
  // if(tempTail>= CONFIG.ringBufferLength)
  {
    tempTail = 0;
  }
  while (tempTail != cBufHead) {
    var nextByte = (circularBuffer[tempTail]) & 0xFF;
    if (nextByte > 127) {
      // print("have whole frame");
      return true;
    }
    tempTail++;
    if (tempTail >= SIZE_OF_INPUT_HARDWARE_CIRC_BUFFER)
    // if(tempTail>= CONFIG.ringBufferLength)
    {
      tempTail = 0;
    }
  }
  return false;
}

areWeAtTheEndOfFrame( int cBufTail) {
  var tempTail = cBufTail + 1;
  if (tempTail >= SIZE_OF_INPUT_HARDWARE_CIRC_BUFFER)
  // if(tempTail>= CONFIG.ringBufferLength)
  {
    tempTail = 0;
  }
  // let nextByte  = ((uint)(circularBuffer[tempTail])) & 0xFF;
  var nextByte = (circularBuffer[tempTail]) & 0xFF;
  if (nextByte > 127) {
    // print('areWeAtTheEndOfFrame');
    return true;
  }
  return false;
}


bool forceQuit = false;
serialParsing(List<List<Int16List>> allEnvelopes,Map<String, dynamic> map,int surfaceSize, int SIZE_LOGS2,
    List<int> skipCounts, bool isThresholding, List<double> snapshotAveragedSamples, List<int> thresholdValue) {
  var LSB;
  var MSB;

  bool weAtTheEndOfFrame = false;
  bool breakBeginningFrameMSB = false;
  bool breakLSB = false;
  bool haveData = true;
  bool weAlreadyProcessedBeginingOfTheFrame = false;
  var sample;
  int cBufTail = map['cBufTail'];
  int numberOfParsedChannels = map['numberOfParsedChannels'];
  int numberOfChannels = map['numberOfChannels'];
  int numberOfFrames = map['numberOfFrames'];
  int cBufHead = map['cBufHead'];
  // print('cBufHead');
  // print(cBufHead);
  // print(cBufTail);
  String deviceType = map['deviceType'];
  // int cBuffIdx = map['cBuffIdx'];
  int cBuffIdx;
  int globalIdx = map['globalIdx'];
  List<int> arrHeads = map['arrHeads'];
  var writeInteger = 0;

  List<List<int>> processedSamples = List.generate(6, (index) => []);

  while (haveData) {
    MSB = (circularBuffer[cBufTail]) & 0xFF;
    var additionalFlag = true;
    if (MSB > 127 && additionalFlag) //if we are at the begining of frame
    {
      weAlreadyProcessedBeginingOfTheFrame = false;
      numberOfParsedChannels = 0;
      if (checkIfHaveWholeFrame(cBufTail, cBufHead)) {
        numberOfFrames++;
        /* var idxChannelLoop = 0; */
        while (true) {
          
          // if (deviceType != "hid") {
            // console.log("SERIAL ? ",deviceType);
            MSB = (circularBuffer[cBufTail]) & 0xFF;
            if (weAlreadyProcessedBeginingOfTheFrame && MSB > 127) {
              numberOfFrames--;
              breakBeginningFrameMSB = true;

              break; //continue as if we have new frame
            }
          // }
          

          MSB = (circularBuffer[cBufTail]) & 0x7F;
          weAlreadyProcessedBeginingOfTheFrame = true;

          cBufTail++;
          if (cBufTail >= SIZE_OF_INPUT_HARDWARE_CIRC_BUFFER) {
            cBufTail = 0;
          }
          LSB = (circularBuffer[cBufTail]) & 0xFF;
          if (LSB > 127) {
            numberOfFrames--;
            // print('circularBuffer.sublist(0, cBufTail)');
            // print(circularBuffer.sublist(0, cBufTail));
            // print(map['escapeSequenceDetectorIndex']);
            breakLSB = true;
            /*
            if (deviceType == 'hid') {
              return;
            } else {
            */
              // print("BREAKING !");
              break;
              /*
            }
            */
          }
          LSB = (circularBuffer[cBufTail]) & 0x7F;

          MSB = MSB << 7;
          writeInteger = LSB | MSB;


          numberOfParsedChannels++;
          // if(numberOfParsedChannels>numberOfChannels)
          // {
          //     //we have more data in frame than we need
          //     //something is wrong with this frame
          //     //numberOfFrames--;
          //     //std::cout<< "More channels than expected\n";
          //     break;//continue as if we have new frame
          // }          
          // if (numberOfParsedChannels > 1) {
          //   print("numberOfParsedChannels " + numberOfChannels.toString());
          //   print(deviceType);
          //   print(numberOfParsedChannels);
          // }

          /*
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
          */
            // if (deviceIds[0] == 4){
            //   sample =  (-(writeInteger - 8192)); // SpikeDesktop 448
            // }else{

            // print("MINUS 512");
            sample = -((writeInteger - 512)); // SpikeDesktop 448
            // sample = -((writeInteger)); // SpikeDesktop 448
            // }
            /*
          }
          */
          
          //
          // put function postProcessing or additionalProcessing();
          // communicate with other isolate and send this sample to another receiverport

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
          if (!isThresholding) {
            // try {
              if (numberOfParsedChannels <= 6){

                cBuffIdx = arrHeads[numberOfParsedChannels - 1];
                // print('cBufHead');
                // print(cBufHead);
                // print(cBufTail);
                // print(cBuffIdx);
                envelopingSamples(
                    cBuffIdx,
                    // sample.toDouble(),
                    sample,
                    allEnvelopes[numberOfParsedChannels - 1],
                    SIZE_LOGS2,
                    skipCounts,
                    -1);

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
                // if (numberOfParsedChannels > 3) {
                //   print('numberOfParsedChannels');
                //   print(sample);
                //   print(allEnvelopes[numberOfParsedChannels - 1][9].sublist(0, cBuffIdx));
                // }

                arrHeads[numberOfParsedChannels - 1] = cBuffIdx;
              }
            // } catch (err) {}
          } else {
            if (numberOfParsedChannels<6) {
              // print('numberOfParsedChannels');
              // print(numberOfParsedChannels);
              processedSamples[numberOfParsedChannels - 1].add(sample);
            }
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

          if (areWeAtTheEndOfFrame(cBufTail)) {
            weAtTheEndOfFrame = true;
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
        // print("have data false");
        break;
      }
    }
    if (!haveData) {
      print('doesn;t have data');
      break;
    }
    cBufTail++;
    if (cBufTail >= SIZE_OF_INPUT_HARDWARE_CIRC_BUFFER) {
      cBufTail = 0;
    }

    if (cBufTail == cBufHead) {
      print('tail = head');
      print(weAtTheEndOfFrame);
      print(breakBeginningFrameMSB);
      print(breakLSB);

      haveData = false;
      break;
    }
  }

  map['cBufTail'] = cBufTail;
  map['numberOfParsedChannels'] = numberOfParsedChannels;
  map['numberOfChannels'] = numberOfChannels;
  map['numberOfFrames'] = numberOfFrames;
  map['cBufHead'] = cBufHead;
  map['deviceType'] = deviceType;
  // map['cBuffIdx'] = cBuffIdx;
  map['globalIdx'] = globalIdx;
  map['arrHeads'] = arrHeads;
  // if (isThresholding){
  // List<Int16List> newSamples = List<Int16List>.generate(6, (index) => Int16List(processedSamples[index].length));
  List<List<int>> newSamples = List<List<int>>.filled(6, []);
  if (isThresholding){
    for (int i = 0; i < 6; i++) {
      // newSamples[i] = Int16List.fromList(processedSamples[i]);
      newSamples[i] = List<int>.from(processedSamples[i]);
    }
  }
  map['processedSamples'] = newSamples;

  // }
}
